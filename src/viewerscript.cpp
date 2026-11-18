/**
 * @file viewerscript.cpp
 * @brief A script's life in the Viewer: its Lua state (openLua, with
 *        print and the error handler), running it (runScript, parse,
 *        executeLua), and clearing the scene for the next (clear,
 *        closeScript, removeLeftoverBodies).
 */

#include "luahome.h"
#include "viewer.h"
#include "viewer_p.h"

#include "appenv.h"
#include "bppworld.h"
#include "gimpactplane.h"
#include "lua_bullet.h"
#include "lua_converters.h"
#include "prefs.h"
#include "restskipping.h"
#include "dembed.h"
#include "geo.h"

#include "objects/bezierpatch.h"
#include "objects/blob.h"
#include "objects/bound.h"
#include "objects/cam.h"
#include "objects/cone.h"
#include "objects/csg.h"
#include "objects/cube.h"
#include "objects/cylinder.h"
#include "objects/disc.h"
#include "objects/heightfield.h"
#include "objects/layer.h"
#include "objects/mesh.h"
#include "objects/object.h"
#include "objects/openscad.h"
#include "objects/palette.h"
#include "objects/patch.h"
#include "objects/plane.h"
#include "objects/povscriptwriter.h"
#include "objects/referenceobject.h"
#include "objects/rigidsoftcontact.h"
#include "objects/softbody.h"
#include "objects/sphere.h"
#include "objects/superquadric.h"
#include "objects/sweep.h"
#include "objects/terrain.h"
#include "objects/torus.h"
#include "objects/triangle.h"
#include "objects/truetype.h"

#include <BulletSoftBody/btSoftBodyRigidBodyCollisionConfiguration.h>
#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>
#include <BulletDynamics/MLCPSolvers/btMLCPSolverInterface.h> // (clear deletes one)

#include <luabind/class_info.hpp>

#include <cstdlib>
#include <cstring>

/// Standard gravity in m/s^2, used as the default for a fresh world.
constexpr btScalar G = 9.81f;

#if defined(Q_OS_LINUX)
/**
 * @brief Lua allocator that returns 16-byte aligned memory.
 *
 * Bullet's maths types are SIMD-aligned, so a Bullet object Lua allocates and
 * owns has to sit on a 16-byte boundary; the default allocator only promises
 * the platform's malloc alignment. Follows the lua_Alloc contract: a zero
 * @p nsize frees, and a non-null @p ptr reallocates by allocating, copying and
 * freeing, since posix_memalign has no realloc counterpart.
 *
 * @param ud    User data. Unused.
 * @param ptr   Block to resize or free, or null to allocate.
 * @param osize Size of the existing block.
 * @param nsize Requested size, or 0 to free.
 * @return The new block, or null when freeing or on allocation failure.
 */
static void *aligned_lua_alloc(void *ud, void *ptr, size_t osize, size_t nsize) {
  (void)ud;
  (void)osize;
  if (nsize == 0) {
    if (ptr)
      free(ptr);
    return nullptr;
  }
  if (ptr) {
    void *newptr = nullptr;
    if (posix_memalign(&newptr, 16, nsize) != 0)
      return nullptr;
    size_t copy = nsize < osize ? nsize : osize;
    memcpy(newptr, ptr, copy);
    free(ptr);
    return newptr;
  }
  void *newptr = nullptr;
  if (posix_memalign(&newptr, 16, nsize) != 0)
    return nullptr;
  return newptr;
}
#endif

int Viewer::lua_print(lua_State *L) {

  Viewer *p = static_cast<Viewer *>(lua_touserdata(L, lua_upvalueindex(1)));

  if (p) {
    int n = lua_gettop(L); /* number of arguments */

    int i;
    lua_getglobal(L, "tostring");
    for (i = 1; i <= n; i++) {
      const char *s;
      lua_pushvalue(L, -1); /* function to be called */
      lua_pushvalue(L, i);  /* value to print */
      lua_call(L, 1, 1);
      s = lua_tostring(L, -1); /* get result */
      if (s == nullptr)
        return luaL_error(L, "'tostring' must return a string to 'print'");
      // if (i>1) p->emitScriptOutput(QString("\t"));
      p->emitScriptOutput(QString(s));
      lua_pop(L, 1); /* pop result */
    }

    // p->emitScriptOutput(QString("\n"));
  } else {
    return luaL_error(L, "stack has no thread ref", "");
  }

  return 0;
}

/*
void Viewer::luabind_error(lua_State* L) {
    qDebug() << "luabind_error" << "\n";

    // the error message should be on top of the stack
    QString luaWhat = QString("%1").arg(lua_tostring(L, -1));

    //emit scriptHasOutput(QString("%1").arg(luaWhat));
}*/

// Closes the running script: drops its hooks and the Lua references bpp
// holds, takes its bodies and every world's constraints out while they are
// still there, closes its Lua state, and forgets the Bullet pieces that
// freed. The objects themselves are deleted after (clear(), or the
// destructor). parse() and the destructor both close a script this way.
void Viewer::closeScript() {
  // The script's hooks, before its Lua state closes
  _cb_preStart = luabind::object();
  _cb_preDraw = luabind::object();
  _cb_postDraw = luabind::object();
  _cb_preSim = luabind::object();
  _cb_postSim = luabind::object();
  _cb_preStop = luabind::object();
  _cb_onCommand = luabind::object();
  _cb_onJoystick = luabind::object();
  _keys.clear();                     // (shortcuts too: before Lua closes)
  _cb_cycleObject = luabind::object();
  _cb_onSpaceNavigator = luabind::object();
  _hover.clear();

  _params.releaseLua();

  // (removed objects bpp still owns go with the rest)
  for (Object *o : _removed)
    _objects->insert(o);
  _removed.clear();

  // Notify all objects that their luabind weak pointers are invalid
  foreach (Object* o, *_objects) {
    o->preDestructor();
  }

  // Remove rigid bodies from the dynamics world while pointers are still valid.
  if (dynamicsWorld) {
    foreach (Object* o, *_objects) {
      if (o->body != nullptr && !o->isDecoration()) {
        worldOfObject(o)->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        worldOfObject(o)->removeSoftBody(sb->getSoftBody());
      }
    }
    // (and every world's constraints, while the bodies they hold are still
    // there: closing Lua frees a script's own, and dropWorlds() later (in
    // clear() or the destructor) would take the joints out of bodies already
    // gone)
    QList<btSoftRigidDynamicsWorld *> worlds;
    worlds.append(dynamicsWorld);
    for (const PhysWorld &w : _worlds)
      if (w.world != nullptr && w.world != dynamicsWorld)
        worlds.append(w.world);
    for (btSoftRigidDynamicsWorld *dw : worlds)
      for (int k = dw->getNumConstraints() - 1; k >= 0; --k)
        dw->removeConstraint(dw->getConstraint(k));
  }
  removeLeftoverBodies();

  // The objects' motion states go while Lua is still open: one a script
  // made keeps a reference into Lua. (C++ owns them all, see
  // btDefaultMotionState, even those of bodies Lua frees.) Every object's,
  // the ones Lua owns too, which would otherwise free theirs as Lua closes.
  {
    QSet<btMotionState *> motionStates;
    foreach (Object *o, Object::live())
      o->takeMotionStates(motionStates);
    Object::takeOrphanMotionStates(motionStates);   // (objects gone before)
    qDeleteAll(motionStates);
  }
  LuaBullet::freeScriptMotionStates();   // (those of bodies with no object)

  // Release Lua references from the registry BEFORE closing Lua state.
  // These are raw integer refs, not luabind::object instances.
  if (L != nullptr) {
    for (auto& pair : _luabindRegistry) {
      luaL_unref(L, LUA_REGISTRYINDEX, pair.second);
    }
    _luabindRegistry.clear();
    lua_close(L);
    L = nullptr;
  }

  // Null out Bullet object pointers that Lua has freed: a body or shape a
  // script handed in. The C++ Object destructors (in clear() or the
  // destructor) skip these null pointers, avoiding use-after-free and
  // double-free, and free what the objects made themselves.
  foreach (Object* o, *_objects) {
    if (!o->_ownsBody)
      o->body = nullptr;
    if (o->shapeFromLua())
      o->shape = nullptr;
#ifdef HAS_LIB_ASSIMP
    Mesh *m = dynamic_cast<Mesh *>(o);
    if (m) {
      m->luaRelease();
    }
#endif
  }

}

// Opens a fresh Lua state for a script: the standard libraries, bpp's
// helpers, package.path, every bpp class, print, and the collector shim.
void Viewer::openLua() {
  // setup lua
#if defined(Q_OS_LINUX)
  L = lua_newstate(aligned_lua_alloc, nullptr);
#else
  L = luaL_newstate();
#endif

  mainLuaState() = L;   // (values C++ keeps are held from this thread: luahome.h)

  // open all standard Lua libs
  luaL_openlibs(L);

  luaL_dostring(L, "os.setlocale('C')");
  // Lua 5.3+ folded math.atan2(y, x) into a two-argument math.atan;
  // restore the legacy name so older scripts keep working.
  luaL_dostring(L,
      "if type(math) == 'table' and type(math.atan2) ~= 'function' then "
      "math.atan2 = function(y, x) return math.atan(y, x) end end\n"
      "if atan2 == nil then atan2 = math.atan2 end");
  // Lua 5.2 and later dropped these 5.1 names; bpp's scripts are written
  // for 5.1 (Linux and Windows), but Homebrew's Lua (macOS) is 5.4. Each is
  // defined only where it is missing, so on 5.1 this changes nothing. (5.1
  // syntax only: it is parsed on every build. sinh, cosh and tanh agree with
  // the C library's to a few units in the last place: exp(x) - 1 is taken
  // the way Kahan gave, without the loss near 0, and past 22 both sinh and
  // cosh are e^x / 2 as h * (h / 2), h = e^(x/2), finite as far as theirs.)
  luaL_dostring(L,
      "unpack = unpack or table.unpack\n"
      "loadstring = loadstring or load\n"
      "local m = math\n"
      "m.pow = m.pow or function(x, y) return x ^ y end\n"
      "m.log10 = m.log10 or function(x) return m.log(x, 10) end\n"
      "m.ldexp = m.ldexp or function(x, e)\n"
      "  local h = m.floor(e / 2) -- (in two steps: 2^e alone can overflow)\n"
      "  return x * 2.0 ^ h * 2.0 ^ (e - h)\n"
      "end\n"
      "m.frexp = m.frexp or function(x)\n"
      "  if x == 0 or x ~= x or x == m.huge or x == -m.huge then return x, 0 end\n"
      "  local e = m.floor(m.log(m.abs(x), 2)) + 1\n"
      "  local f = m.ldexp(x, -e)\n"
      "  if m.abs(f) >= 1 then f, e = f / 2, e + 1\n"
      "  elseif m.abs(f) < 0.5 then f, e = f * 2, e - 1 end\n"
      "  return f, e\n"
      "end\n"
      "local function expm1(x)\n"
      "  local u = m.exp(x)\n"
      "  if u == 1 then return x end\n"
      "  if u - 1 == -1 then return -1 end\n"
      "  return (u - 1) * x / m.log(u)\n"
      "end\n"
      "local function halfexp(a) local h = m.exp(a / 2); return h * (h / 2) end\n"
      "m.cosh = m.cosh or function(x)\n"
      "  local a = m.abs(x)\n"
      "  if a > 22 then return halfexp(a) end\n"
      "  local e = m.exp(a)\n"
      "  return (e + 1 / e) / 2\n"
      "end\n"
      "m.sinh = m.sinh or function(x)\n"
      "  local a, s = m.abs(x)\n"
      "  if a > 22 then s = halfexp(a)\n"
      "  else local u = expm1(a); s = (u + u / (u + 1)) / 2 end\n"
      "  return x < 0 and -s or s\n"
      "end\n"
      "m.tanh = m.tanh or function(x)\n"
      "  if x ~= x then return x end\n"
      "  local a = m.abs(x)\n"
      "  local t = a > 22 and 1 or expm1(2 * a) / (expm1(2 * a) + 2)\n"
      "  return x < 0 and -t or t\n"
      "end\n");
  luaL_dostring(L, "printf = function(s,...) print(s:format(...)) end");

  // Build Lua package.path: search script directory first (if console mode), then CWD/demo, then installed
  QString defaultPath = getDefaultLuaPath(_scriptBasePath);
  QString path = _settings->value("lua/path").toString();
  if (path.isEmpty()) {
    path = defaultPath;
  } else {
    bool allExist = true;
    for (const QString &entry : path.split(';', Qt::SkipEmptyParts)) {
      QString dir = entry;
      dir.replace("?.lua", "");
      if (!QDir(dir).exists()) {
        allExist = false;
        break;
      }
    }
    if (!allExist)
      path = defaultPath;
  }
  QString p = QString("package.path = package.path..\";%1\"").arg(path);

  int error =
      luaL_loadstring(L, qPrintable(p)) || lua_pcall(L, 0, LUA_MULTRET, 0);

  if (error) {
    lua_error = tr("error: %1").arg(lua_tostring(L, -1));

    if (lua_error.contains(QRegularExpression(tr("stopping$")))) {
      lua_error = tr("script stopped");
      // qDebug() << "lua run : script stopped";
    } else {
      // qDebug() << QString("lua run : %1").arg(lua_error);
      emit scriptHasOutput(lua_error);
    }

    lua_pop(L, 1); /* pop error message from the stack */
  } else {
    lua_error = tr("ok");
  }

  luabind::open(L);

  // Lua's garbage collector stays on. It used to be stopped here, because a
  // script can build its own Bullet pieces (btRigidBody, btGImpactMeshShape,
  // btTriangleMesh, ...) and hand them to an object, which kept only raw
  // pointers to them: collecting them left dangling pointers. Now everything
  // the C++ side uses is kept referenced from Lua: an object keeps the body,
  // shape and mesh a script hands it (Object::keepLua()), and a Bullet
  // constructor that takes another script-made piece keeps it alive
  // (luabind's dependency policy, in lua_bullet_*.cpp). So the collector can
  // run all the time, and scripts no longer need to manage it.

  // register all bpp classes
  LuaBullet::luaBind(L);

  Cam::luaBind(L);
  Object::luaBind(L);
  Cone::luaBind(L);
  Cube::luaBind(L);
  Cylinder::luaBind(L);
  CsgObject::luaBind(L);
  Disc::luaBind(L);
  Heightfield::luaBind(L);
  Torus::luaBind(L);
  PovScriptWriter_luaBind(L);
  LayerManager::luaBind(L);
  BezierPatch::luaBind(L);
  Blob::luaBind(L);
  Bound::luaBind(L);
  Patch::luaBind(L);
  ReferenceObject::luaBind(L);
  Sweep::luaBind(L);
  SuperQuadric::luaBind(L);
  TrueType::luaBind(L);
#ifdef HAS_LIB_ASSIMP
  Mesh::luaBind(L);
  OpenSCAD::luaBind(L);
#endif
  Palette::luaBind(L);
  Plane::luaBind(L);
  RigidSoftContact::luaBind(L);
  SoftBody::luaBind(L);
  Sphere::luaBind(L);
  Terrain::luaBind(L);
  Triangle::luaBind(L);
  DemBed::luaBind(L);
  Geo::luaBind(L);
  Viewer::luaBind(L);

  luabind::bind_class_info(L);

  lua_pushlightuserdata(L, (void *)this);
  lua_pushcclosure(L, &Viewer::lua_print, 1);
  lua_setglobal(L, "print");

  // Scripts written when the collector was kept stopped call
  // collectgarbage("stop") after collecting by hand; that would switch the
  // collector off for good, so it is ignored. "collect", "step", "count"
  // and the rest work as usual. BPP_GC_AUTO tells a script that bpp
  // collects garbage itself.
  if (luaL_dostring(L,
                    "BPP_GC_AUTO = true\n"
                    "do\n"
                    "  local gc = collectgarbage\n"
                    "  collectgarbage = function(opt, ...)\n"
                    "    if opt == 'stop' then return 0 end\n"
                    "    return gc(opt, ...)\n"
                    "  end\n"
                    "end\n") != 0) {
    emit scriptHasOutput(QString("collectgarbage setup: %1").arg(lua_tostring(L, -1)));
    lua_pop(L, 1);
  }
}

namespace {
// runScript()'s message handler: writes where the script was when it
// failed, one "[function] source (line)" a line from where it failed out,
// to the registry (bpp.trace), and passes the error on as it was.
int scriptTrace(lua_State *L) {
  QString trace;
  lua_Debug ar;
  for (int level = 1; lua_getstack(L, level, &ar); level++) {
    lua_getinfo(L, "Snl", &ar);
    QString info = QString("[%1] %2 (%3)")
                    .arg(ar.name ? ar.name : "?")
                    .arg(ar.short_src)
                    .arg(ar.currentline);
    if (trace.isEmpty()) {
      trace = info;
    } else {
      trace += "\n" + info;
    }
  }
  lua_pushstring(L, trace.toUtf8().constData());
  lua_setfield(L, LUA_REGISTRYINDEX, "bpp.trace");
  return 1; // (the error, at the top)
}
} // namespace

// Runs a script in the Lua state: reports an error on the console (the
// script stops there). Returns false if it failed.
bool Viewer::runScript(QString txt) {
  // useful for shell scripting. Example:
  //
  // #!/usr/bin/bpp -f
  // print("Hello, BPP!")

  if (txt.startsWith("#!")) { // remove potential shebang on first line
    QStringList tmp = txt.split("\n");
    tmp.removeAt(0);
    txt = tmp.join("\n");
  }

  // Where the script was when it failed, written down by the message handler
  // below while its stack is still there (after lua_pcall returns, it's gone)
  lua_pushcfunction(L, scriptTrace);
  const int handler = lua_gettop(L);
  int error = luaL_loadstring(L, txt.toUtf8().constData()) ||
              lua_pcall(L, 0, LUA_MULTRET, handler);

  // (Lua's garbage collector runs throughout: see where the classes are
  // registered above for why that is safe.)

  if (error) {
    lua_error = tr("error: %1").arg(lua_tostring(L, -1));

    lua_getfield(L, LUA_REGISTRYINDEX, "bpp.trace");
    const QString trace = lua_isstring(L, -1) ? QString(lua_tostring(L, -1)) : QString();
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_setfield(L, LUA_REGISTRYINDEX, "bpp.trace");

    if (lua_error.contains(QRegularExpression(tr("stopping$")))) {
      lua_error = tr("script stopped");
    } else {
      if (!trace.isEmpty()) {
        emit scriptHasOutput(lua_error + "\n" + trace);
      } else {
        emit scriptHasOutput(lua_error);
      }
    }

    lua_pop(L, 1);
  } else {
    lua_error = tr("ok");
  }
  lua_remove(L, handler);

  return !error;
}

bool Viewer::parse(QString txt) {
  QMutexLocker locker(&mutex);

  emit scriptStopped();

  if (_cb_preStop) {
    try {
      luabind::call_function<void>(_cb_preStop, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preStop()");
    }
  }

  _parsing = true;
  _has_exception = false;

  _scriptContent = txt;

  bool animStarted = animationIsStarted();

  if (animStarted) {
    stopAnimation();
  }

emit scriptStarts();

  if (L != nullptr) {
    setStatusText(QString());   // (a script's status line goes with it)
    _synth.reset();             // (and its voices)
    closeScript();
  }

  clear();

  openLua();

  luaBindInstance(L);

  // Snapshot camera state before script execution so we can detect if
  // the script explicitly positioned the camera (e.g. via cam.pos/cam.look).
  Vec camPosBeforeScript = camera()->position();
  Quaternion camOriBeforeScript = camera()->orientation();

  const bool ok = runScript(txt);

  // If the script changed the camera (e.g. via cam.pos/cam.look), update the
  // initial camera state so the "House" button returns to the script's view.
  Vec camPosAfterScript = camera()->position();
  Quaternion camOriAfterScript = camera()->orientation();
  bool camChanged = (camPosBeforeScript != camPosAfterScript);
  if (!camChanged)
    for (int i = 0; i < 4; ++i)
      if (camOriBeforeScript[i] != camOriAfterScript[i]) { camChanged = true; break; }
  if (!camChanged && !_cameraPlaced) {
    // No window has been shown (bpp -e, headless), so init() never framed
    // the scene, and a script that places no camera would export one at the
    // origin, looking at nothing: a blank render. Frame it as the GUI does
    // when it opens with this script (init()).
    computeBoundingBox();
    showEntireScene();
    _cameraPlaced = true;
    camChanged = true;               // (and the House button returns here)
    camPosAfterScript = camera()->position();
    camOriAfterScript = camera()->orientation();
  }
  if (camChanged) {
    _initialCameraPosition = camPosAfterScript;
    _initialCameraOrientation = camOriAfterScript;
    _initialCameraHorizontalFieldOfView = camera()->horizontalFieldOfView();
    _initialCameraUpVector = camera()->upVector();
  }

  _frameNum = 1; // reset frames counter
  _firstFrame = 1;

  if (animStarted) {
    startAnimation();
  }

  // qDebug() << "Viewer::parse() end";

  emit scriptFinished();

  _parsing = false;

  return ok;
}

// Removes whatever is still in the dynamics world once every object's own
// body is out: a body a script replaced (obj.body = another) stays in the
// world, kept alive from Lua (Object::retireLua()), and Lua frees it when the
// state is closed -- so it has to leave the world first.
void Viewer::removeLeftoverBodies() {
  if (!dynamicsWorld)
    return;
  QList<btSoftRigidDynamicsWorld *> worlds;
  worlds.append(dynamicsWorld);
  for (const PhysWorld &w : _worlds)
    if (w.world != nullptr && w.world != dynamicsWorld)
      worlds.append(w.world);
  for (btSoftRigidDynamicsWorld *dw : worlds) {
    btCollisionObjectArray &all = dw->getCollisionObjectArray();
    for (int i = all.size() - 1; i >= 0; --i) {
      btCollisionObject *co = all[i];
      if (btSoftBody *sb = btSoftBody::upcast(co))
        dw->removeSoftBody(sb);
      else if (btRigidBody *rb = btRigidBody::upcast(co))
        dw->removeRigidBody(rb);
      else
        dw->removeCollisionObject(co);
    }
  }
}

bool Viewer::executeLua(const QString &code) {
  if (!L) return false;
  int err = luaL_dostring(L, code.toUtf8().constData());
  if (err != 0) {
    emit scriptHasOutput(QString("executeLua: %1").arg(lua_tostring(L, -1)));
    lua_pop(L, 1);
    return false;
  }
  return true;
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

  _merge.clear();                        // (before the objects go)

  _params.clear();        // (a script's showParams() filter goes with it)
  emit paramsChanged();

  // Notify all objects that their luabind weak pointers are about to become
  // invalid (C++ objects will be deleted by clear() below).
  foreach (Object* o, *_objects) {
    o->preDestructor();
  }

  // Remove rigid bodies from the dynamics world before deleting anything.
  // Note: body pointers may already be null if they were nulled before
  // lua_close (Lua-owned bodies were freed by Lua GC).
  if (dynamicsWorld) {
    foreach (Object* o, *_objects) {
      if (o->body != nullptr && !o->isDecoration()) {
        worldOfObject(o)->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        worldOfObject(o)->removeSoftBody(sb->getSoftBody());
      }
    }
  }

  // Remove constraints from the dynamics world before deleting them.
  if (dynamicsWorld) {
    foreach (btTypedConstraint* c, *_constraints) {
      const int k = _conWorld.value(c, 0);
      if (!_worlds.empty() && k != _curWorld && k < (int)_worlds.size())
        _worlds[k].world->removeConstraint(c);
      else
        dynamicsWorld->removeConstraint(c);
    }
  }

  // Delete Object instances. Body/shape pointers that were Lua-owned
  // have already been nulled before lua_close, so destructors skip them.
  // C++-owned body pointers (_ownsBody=true) are still valid and get deleted.
  {
    QList<Object*> objs = _objects->values();
    for (Object* o : objs) delete o;
  }
  _objects->clear();
  _takenFromLua.clear();
  _detached.clear();

  {
    QList<btTypedConstraint*> cons = _constraints->values();
    for (btTypedConstraint* c : cons) delete c;
  }
  _constraints->clear();
  qDeleteAll(_consKept);                 // (removed ones the script kept)
  _consKept.clear();
  _consTakenFromLua.clear();
  LuaBullet::freeJointFeedback();        // (their enableForces, all gone now)

  {
    QList<btRaycastVehicle*> rvs = _raycast_vehicles->values();
    for (btRaycastVehicle* rv : rvs) delete rv;
  }
  _raycast_vehicles->clear();

  {
    QList<btVehicleRaycaster*> vrs = _vehicle_raycasters->values();
    for (btVehicleRaycaster* vr : vrs) delete vr;
  }
  _vehicle_raycasters->clear();

  // The other worlds go first (with the scene's own back in use)
  dropWorlds();

  // Delete existing dynamics world and its subcomponents
  if (dynamicsWorld) {
    delete dynamicsWorld;
    dynamicsWorld = nullptr;
  }
  if (collisionCfg) {
    delete collisionCfg;
    collisionCfg = nullptr;
  }
  if (dispatcher) {
    delete dispatcher;
    dispatcher = nullptr;
  }
  if (solver) {
    delete solver;
    solver = nullptr;
  }
  delete _mlcpInterface;
  _mlcpInterface = nullptr;
  if (broadphase) {
    delete broadphase;
    broadphase = nullptr;
  }

  // It's important that timeStep is always less than maxSubSteps*fixedTimeStep,
  // otherwise you are losing time. Mathematically,
  //
  //   timeStep < maxSubSteps * fixedTimeStep
  //
  _timeStep = 1 / 25.0; // 25fps
  //_timeStep = 1/120.0;    // 1/120th of a second
  _maxSubSteps = 7;
  _fixedTimeStep = 1 / 100.0; // 1/60th of a second

  collisionCfg = new btSoftBodyRigidBodyCollisionConfiguration();
  broadphase = new btDbvtBroadphase();
  dispatcher = new RestSkippingDispatcher(collisionCfg);
  solver = new btSequentialImpulseConstraintSolver();

  _aabbSeen.clear();
  dynamicsWorld = newBppWorld(dispatcher, broadphase,
                                               solver, collisionCfg);
  dynamicsWorld->setInternalTickCallback(bppGyroPreTick, nullptr, true);
  dynamicsWorld->setDebugDrawer(_debugDrawer);
  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));
  dynamicsWorld->getWorldInfo().m_broadphase = broadphase;
  dynamicsWorld->getWorldInfo().m_dispatcher = dispatcher;
  dynamicsWorld->getWorldInfo().m_gravity = dynamicsWorld->getGravity();
  dynamicsWorld->getWorldInfo().m_sparsesdf.Initialize();
  SoftBody::setWorldInfo(&dynamicsWorld->getWorldInfo());

  btCollisionDispatcher *dispatcher_ptr = dispatcher;
  GImpactPlaneAlgorithm::registerAlgorithm(dispatcher_ptr);

  _pov_settings_inc = "settings.inc";

  _povRadiosityEnabled = false;
  _povPhotonsEnabled = false;
  _povFogEnabled = false;
  _povAtmosphereEnabled = false;

  setPreSDL(QString());
  setPostSDL(QString());

  if (_cam != nullptr) {
    _cam->setPreSDL(QString());
    _cam->setPostSDL(QString());
    _cam->setUseFocalBlur(0);
    _cam->setUpVector(btVector3(0, 1, 0), true);
    _cam->setPivotPoint(_cam->sceneCenter());   // (following the scene again, till it's chosen)
  }

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);
  _light0Color = _light1Color = btVector4(1, 1, 1, 1);

  // (and its music; the shadows are the user's, see setShadowsFromScript())
  freeMusic();
  setShadows(_shadowsPref);
  _shadowsNoted = false;

  // (a script's culling and shadow-record settings go with it, as the
  // lights do)
  _culling = true;
  _shadowRecord.enabled = true;
  _merge.enabled = true;
  _shadowRecord.saveDepth = true;
  _drawTiming = false;

  _gl_ambient = btVector3(0.2f, 0.2f, 0.2f);
  _gl_diffuse = btVector4(0.7f, 0.7f, 0.7f, 1.0f);
  _gl_shininess = btScalar(100.0);
  _gl_specular_col = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_specular = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_model_ambient = btVector4(0.2f, 0.2f, 0.2f, 1.0f);
}
