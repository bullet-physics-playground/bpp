#ifndef VIEWER_H
#define VIEWER_H

/**
 * @file viewer.h
 * @brief The 3D view, the Bullet simulation and the Lua scripting host.
 */

#include <lua.hpp>

#include <QGLViewer/manipulatedCameraFrame.h>
#include <QGLViewer/manipulatedFrame.h>
#include <QGLViewer/qglviewer.h>

#include <btBulletDynamicsCommon.h>

#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QMutex>
#include <QMutexLocker>
#include <QRect>
#include <QSet>
#include <QSettings>
#include <QTextStream>
#include <QVector>
#include <QWheelEvent>
#include <QHash>
#include <QThreadPool>
#include <map>
#include <functional>
#include <luabind/object.hpp>

#include <SDL2/SDL_mixer.h>

#include "objects/cam.h"

#include "objects/sphere.h"

#include <unordered_map>
#include "joystick/joystickhandler.h"
#include "joystick/joystickinterfacesdl.h"

#include "spacenavigator/spacenavigator.h"

using namespace qglviewer;

class Object;
class Viewer;
class QTimer;
class ShadowMap;
class btSoftRigidDynamicsWorld;
#if USE_VFE
class BppVfeSession;
class BppVfeDisplay;
#endif // USE_VFE

/**
 * @brief A script parameter and everything the GUI needs to present it.
 *
 * Scripts register parameters with Viewer::addParam(); the Gui turns each one
 * into a slider, a check box or an editable cell depending on what is known
 * about it here.
 */
struct ParamInfo {
  QVariant value;        ///< The value the parameter was last given.
  btScalar min = 0.0;    ///< Lower bound; only meaningful if #hasRange.
  btScalar max = 100.0;  ///< Upper bound; only meaningful if #hasRange.
  btScalar step = 0.0;   ///< Step size for the slider; 0 means pick a default.
  QString comment;       ///< Description shown in the parameter's tooltip.
  bool hasRange = false; ///< True if the script declared a min and max, which
                         ///< is what makes the parameter a slider.
};

/**
 * @brief Writes a Viewer's description to a standard stream.
 * @param ostream The stream to write to.
 * @param v       The viewer to describe.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const Viewer &v);

/**
 * @brief The 3D view: it owns the Bullet world, the Lua state and the scene.
 *
 * Viewer is the centre of bpp. It embeds a Bullet btSoftRigidDynamicsWorld, so
 * rigid and soft bodies can be simulated together, and a Lua interpreter in
 * which the whole scene is built. parse() tears the previous world and
 * interpreter down and runs a fresh script; the script populates the world
 * through the global @c v, which is this object bound into Lua.
 *
 * A script can hook into the frame loop through the @c cb_ callbacks -
 * preStart, preDraw, preSim, postSim, postDraw, preStop - and can bind its own
 * keyboard shortcuts, expose live parameters for the Parameters dock, and
 * respond to the command line, a joystick or a 3D mouse.
 *
 * Alongside drawing with OpenGL the viewer can export each frame as a POV-Ray
 * scene, and render one directly either by launching @c povray as a separate
 * process or, where bpp was built with VFE support, in-process with a live
 * preview.
 *
 * @b Threading: @c mutex guards the simulation and the Lua state against the
 * animation, input and render paths. parse() holds it for the whole run of a
 * script, which is why the setters a script may call at top level - such as
 * setShowConstraints() - must not take it.
 */
class Viewer : public QGLViewer {
  Q_OBJECT;

public:
  /**
   * @brief Builds the viewer, the Bullet world and the input devices.
   *
   * Creates the collision configuration, broadphase, dispatcher, solver and
   * dynamics world, the three fixed orthographic cameras used by the quad
   * view, the default lighting, and the joystick and 3D mouse handlers. The
   * 3D mouse preferences are read from @p settings. Animation starts
   * immediately, though the simulation itself does not.
   *
   * @param parent   Parent widget. Unused; QGLViewer is constructed without it.
   * @param settings Settings store to read preferences from. Not owned.
   * @param savePOV  Whether to start with POV-Ray frame export enabled.
   */
  Viewer(QWidget *parent = nullptr, QSettings *settings = nullptr,
         bool savePOV = false);

  /**
   * @brief Tears everything down in an order that avoids dangling pointers.
   *
   * Any in-flight VFE render is stopped first, since it owns a worker thread
   * that can call back in. The input devices are then stopped, the Lua
   * callbacks and registry references released while the Lua state is still
   * valid, and the state closed - which is what frees the Bullet objects Lua
   * adopted, so the corresponding raw pointers are nulled before the C++
   * objects are deleted.
   */
  ~Viewer();

  /**
   * @brief Turns POV-Ray frame export on or off.
   *
   * Enabling it restarts the exported animation's clock at the current frame.
   *
   * @param pov True to write a POV-Ray scene for each simulated frame.
   */
  void setSavePOV(bool pov);

  /**
   * @brief Turns POV-Ray frame export on or off.
   *
   * Equivalent to setSavePOV(); provided as the slot the GUI's toggle uses.
   *
   * @param savePOV True to write a POV-Ray scene for each simulated frame.
   */
  void toggleSavePOV(bool savePOV);

  /**
   * @brief Allows or forbids Bullet putting resting bodies to sleep.
   *
   * Takes effect for bodies added afterwards; with deactivation off, bodies
   * are added with @c DISABLE_DEACTIVATION.
   *
   * @param deactivation True to let bodies deactivate.
   */
  void toggleDeactivation(bool deactivation);

  // http://bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
  /**
   * @brief Sets the wall-clock time one animation step advances the world by.
   *
   * For Bullet not to lose time, this must stay below
   * @c maxSubSteps * fixedTimeStep.
   *
   * @param ts The step in seconds. Defaults to 1/25.
   */
  void setTimeStep(btScalar ts);

  /**
   * @brief Returns the time one animation step advances the world by.
   * @return The step in seconds.
   */
  btScalar getTimeStep();

  /**
   * @brief Sets how many internal steps Bullet may take per animation step.
   * @param steps The maximum number of substeps. Defaults to 7.
   */
  void setMaxSubSteps(int steps);

  /**
   * @brief Returns the maximum number of internal steps per animation step.
   * @return The substep limit.
   */
  int getMaxSubSteps();

  /**
   * @brief Loads a short sound effect (WAV, or MP3 via mpg123) for later
   * playback with playSound(). Safe to call even if no audio device is
   * available (headless/CI runs, or a machine with no sound hardware) --
   * returns -1 in that case rather than throwing, and playSound() on an
   * invalid id is a silent no-op. Loading the same path twice returns the
   * same id rather than loading it again.
   * @param path Path to a sound file, relative to the script's working
   *             directory, same convention as Mesh() paths.
   * @return An id to pass to playSound(), or -1 if audio isn't available
   *         or the file failed to load.
   */
  int loadSound(const QString &path);

  /**
   * @brief Plays a sound previously loaded with loadSound(), starting
   * immediately (does not block). Intended to be called from a Lua
   * postSim callback at the exact frame an event (e.g. an escapement
   * beat) is detected. A no-op if id is invalid or no audio device is
   * available. While POV-Ray export is on, the sound is also mixed into the
   * exported scene's audio track, see saveWAV().
   * @param id The id returned by loadSound().
   */
  void playSound(int id);

  /**
   * @brief As playSound(id), at a volume from 0 (silent) to 1 (full).
   */
  void playSound(int id, double volume);

  /**
   * @brief Reports where the time went whenever a frame comes late.
   *
   * With a threshold above zero, bpp notes each step of its frame (the
   * animation step, the drawing, every Qt event it handles, the time its
   * event loop sits waiting) and, when the gap from one animation step to the
   * next exceeds the threshold, prints which steps took that time. 0 (the
   * default) turns it off. The environment variable BPP_FRAME_TIMING=<ms>
   * turns it on at start-up.
   *
   * @param ms Threshold in milliseconds; 0 turns frame timing off.
   */
  void setFrameTiming(double ms);

  /**
   * @brief The frame-timing threshold in milliseconds (0 when off).
   */
  double getFrameTiming() const;

  /**
   * @brief Sets the size of Bullet's internal fixed simulation step.
   * @param fts The internal step in seconds. Defaults to 1/100.
   */
  void setFixedTimeStep(btScalar fts);

  /**
   * @brief Returns the size of Bullet's internal fixed simulation step.
   * @return The internal step in seconds.
   */
  btScalar getFixedTimeStep();

  /**
   * @brief Starts stepping the simulation.
   */
  void startSim();

  /**
   * @brief Stops stepping the simulation; the scene stays as it is.
   */
  void stopSim();

  /**
   * @brief Re-runs the script from the beginning, keeping the current view.
   *
   * The camera and the values of any parameters that still exist afterwards
   * are saved and restored around the re-parse, so restarting does not throw
   * away where the user was looking or what they had dialled in.
   */
  void restartSim();

  /**
   * @brief Monotonic wall-clock seconds since the viewer was constructed.
   *
   * Lua's @c os.clock() reports CPU time, which barely advances while the
   * viewer idles between frames; this is what a script needs to pace itself
   * against real time.
   *
   * @return Seconds since construction.
   */
  /**
   * @brief Steps the physics world once more, from a script.
   *
   * The same as the step bpp takes every frame (stepSimulation() with these
   * settings, the moved objects' bounding boxes brought up to date first),
   * for a script that runs part of its scene at other settings: the rec
   * room steps its clock this way, at the clock's own step size, within the
   * frame the other games are stepped in. Call it from preSim or postSim.
   *
   * @param timeStep      Seconds of simulated time to advance.
   * @param maxSubSteps   The most substeps to take.
   * @param fixedTimeStep Length of each substep, in seconds.
   * @return The number of substeps taken.
   */
  int stepSimulation(btScalar timeStep, int maxSubSteps, btScalar fixedTimeStep);

  double getTime() const;

  /**
   * @brief Returns the camera to the view the script set up.
   *
   * The reference view is captured when the script runs and updated if the
   * script moved the camera itself, so this returns to the script's own view
   * rather than a fixed default.
   */
  void resetCamView();

  /**
   * @brief Sets the solver's constraint mixing factor.
   * @param tau The new @c m_tau.
   */
  void setTau(btScalar tau);

  /**
   * @brief Sets the solver's error reduction parameter.
   * @param erp The new @c m_erp.
   */
  void setErp(btScalar erp);

  /**
   * @brief Sets the solver's secondary error reduction parameter.
   * @param erp The new @c m_erp2.
   */
  void setErp2(btScalar erp);

  /**
   * @brief Sets the solver's global constraint force mixing.
   * @param cfm The new @c m_globalCfm.
   */
  void setCfm(btScalar cfm);

  /**
   * @brief Sets how many iterations the constraint solver runs.
   * @param n The new @c m_numIterations.
   */
  void setSolverIterations(int n);

  /**
   * @brief Reports every live contact point to a Lua function.
   *
   * Walks the narrowphase's persistent manifolds and hands every live contact
   * point to @p fn, which is called as
   * @code
   *   fn(objA, objB, px, py, pz, nx, ny, nz, distance, impulse)
   * @endcode
   * with the position and normal in world space, @c distance negative when the
   * pair is interpenetrating, and @c impulse the magnitude the solver actually
   * applied on the previous step. @c objA and @c objB are the Objects the two
   * collision bodies belong to, or nil for a body the viewer does not own.
   * Read-only: it reports the current manifolds and changes nothing.
   *
   * @param fn The Lua function to call once per contact point.
   */
  void eachContact(const luabind::object &fn);
  
  /**
   * @brief Adds an object to the scene and the dynamics world.
   *
   * Also adds any constraints the object carries. When called from Lua, a
   * reference to the Lua-side object is stored in the registry so it survives
   * for as long as the viewer holds the C++ object.
   *
   * @param o The object to add. Null is ignored.
   */
  void addObject(Object *o);

  /**
   * @brief Adds every object in a Lua array or table.
   *
   * For example the table a module's constructor returns. Each element is
   * added through the same @c v:add() path as a single object, so it goes
   * through the normal adopt and registry bookkeeping.
   *
   * @param objs The Lua table to iterate.
   */
  void addObjectList(const luabind::object &objs);

  /**
   * @brief Removes an object from the scene and the dynamics world.
   *
   * The object itself is not deleted; ownership passes back to the caller.
   *
   * @param o The object to remove.
   * @return @p o, or null if @p o was null.
   */
  Object *removeObject(Object *o);

  /**
   * @brief What a script's v:remove(obj) calls: removes the object and gives
   *        it back to the script.
   *
   * v:add took the object from Lua; this hands it back. bpp keeps the
   * object until the script has let go of it (its Lua handle has been
   * collected), then frees it (see reapRemoved()), so removing objects
   * doesn't make memory grow.
   *
   * @param o The script's handle to the object.
   * @return The same handle, so obj = v:remove(obj) keeps working.
   */
  luabind::object removeObjectLua(const luabind::object &o);

  /**
   * @brief What a script's v:add(obj) (or v:add{...}) calls.
   *
   * The first time an object is added, bpp takes it from Lua: the script's
   * handle stops owning it (luabind's adopt). Only the first time: taking it
   * a second time would leave the handle pointing at nothing, so an object
   * the script removes and adds again stays usable.
   *
   * @param o An object, or a table of objects.
   */
  void addObjectLua(const luabind::object &o);

  /**
   * @brief Frees removed objects the script has let go of.
   *
   * One whose body a constraint in the world still uses is kept until that
   * constraint is removed too.
   */
  void reapRemoved();

  /**
   * @brief The Lua handle a script added an object with (a new one for an
   *        object that isn't in the scene).
   *
   * Everything that hands a scene object to Lua uses it, so a script never
   * holds two different handles to one object.
   *
   * @param o The object.
   * @return Its handle, or nil for null.
   */
  luabind::object handleOf(Object *o);

  /**
   * @brief Adds an object's rigid body to the dynamics world.
   * @param o The object whose body to add.
   */
  void addObjectBody(Object *o);

  /**
   * @brief Adopts a camera as the viewer's own.
   * @param cam The camera to use. The viewer takes ownership.
   */
  void setCamera(Cam *cam);

  /**
   * @brief Returns the viewer's camera.
   * @return The current camera.
   */
  Cam *getCamera();

  /**
   * @brief Registers the Viewer class and its Qt helpers with a Lua state.
   *
   * Exposes the scene, simulation, lighting, POV-Ray and 3D mouse API as the
   * @c Viewer class, plus the QColor, JoystickInfo and SpaceNavigatorAxes
   * helper types.
   *
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);
  // static void luabind_error(lua_State *s);

  /**
   * @brief Publishes this viewer to a Lua state as the global @c v.
   * @param s The Lua state; it is also remembered as the viewer's own.
   */
  void luaBindInstance(lua_State *s);

  /**
   * @brief Returns a short description of this object.
   * @return The literal @c "Viewer".
   */
  virtual QString toString() const;

  /**
   * @brief Sets the name used for exported scenes and rendered images.
   * @param sn The script name, usually its file name without extension.
   */
  void setScriptName(QString sn);

  /**
   * @brief Sets the directory the running script was loaded from.
   *
   * Used to build the Lua module search path, so a script can @c require a
   * module sitting next to it.
   *
   * @param sbp Absolute path of the script's directory.
   */
  void setScriptBasePath(QString sbp);

  /**
   * @brief Emits one line of script output.
   * @param out The text to emit through scriptHasOutput().
   */
  void emitScriptOutput(const QString &out);

  /**
   * @brief Asks the GUI to clear the debug pane.
   */
  void emitClearOutput();

  /**
   * @brief Replacement for Lua's @c print that routes output to the GUI.
   *
   * Installed as the global @c print with the Viewer as an upvalue. Each
   * argument is converted with Lua's own @c tostring and emitted through
   * emitScriptOutput().
   *
   * @param L The Lua state.
   * @return 0; the function returns no values to Lua.
   */
  static int lua_print(lua_State *L);

  /**
   * @brief Adds a list of constraints to the dynamics world.
   * @param cons The constraints to add. Null entries are skipped.
   */
  void addConstraints(QList<btTypedConstraint *> cons);

  /**
   * @brief Adds one constraint to the dynamics world.
   *
   * Collisions between the two connected bodies are disabled.
   *
   * @param con The constraint to add. Null is ignored.
   */
  void addConstraint(btTypedConstraint *con);

  /**
   * @brief Adds a raycast vehicle to the dynamics world.
   * @param veh The vehicle to add. The viewer takes ownership.
   */
  void addVehicle(btRaycastVehicle *veh);

  /**
   * @brief Removes a constraint from the dynamics world.
   *
   * The constraint itself is not deleted; ownership passes back to the caller.
   *
   * @param con The constraint to remove.
   * @return @p con.
   */
  btTypedConstraint *removeConstraint(btTypedConstraint *con);

  /**
   * @brief Binds a Lua function to a key sequence.
   *
   * The binding takes precedence over the viewer's own shortcut for that key.
   * The function is called with the current frame number.
   *
   * @param keys Key sequence in QKeySequence's native text form, e.g. @c "Ctrl+X".
   * @param fn   The Lua function to call. Ignored if it is not a function.
   */
  void addShortcut(const QString &keys, const luabind::object &fn);

  /**
   * @brief Removes a key binding added with addShortcut().
   * @param keys The key sequence to unbind.
   */
  void removeShortcut(const QString &keys);

  /**
   * @brief Creates a raycaster for a vehicle, bound to this dynamics world.
   *
   * btRaycastVehicle does not own or delete its raycaster, so the ones handed
   * out here are tracked and deleted by the viewer.
   *
   * @return The new raycaster; it stays owned by the viewer.
   */
  btVehicleRaycaster *createVehicleRaycaster();

  // OpenGL properties
  /**
   * @brief Sets the OpenGL material shininess exponent.
   * @param s The new shininess.
   */
  void setGLShininess(const btScalar &s);

  /**
   * @brief Returns the OpenGL material shininess exponent.
   * @return The shininess.
   */
  btScalar getGLShininess() const;

  /**
   * @brief Sets the specular colour as an RGBA vector.
   * @param col The new colour.
   */
  void setGLSpecularColor(const btVector4 &col);

  /**
   * @brief Returns the specular colour as an RGBA vector.
   * @return The colour.
   */
  btVector4 getGLSpecularColor() const;

  /**
   * @brief Sets the specular colour to a shade of grey.
   * @param col Intensity, applied to all four components.
   */
  void setGLSpecularCol(const btScalar col);

  /**
   * @brief Returns the magnitude of the specular colour.
   * @return The length of the specular colour vector.
   */
  btScalar getGLSpecularCol() const;

  /**
   * @brief Sets the position of the main light.
   *
   * The vector goes to @c glLightfv(GL_LIGHT0, GL_POSITION) as it stands, so
   * it is a homogeneous coordinate, not a position and a brightness: the
   * light sits at @c xyz/w, and a @p w of 0 makes it a direction rather than
   * a place. The default, @c <500,500,500,0.4>, therefore lights from
   * @c <1250,1250,1250>.
   *
   * A POV-Ray export writes this out for the settings include to light with,
   * so a render is lit the way the view is.
   *
   * @param pos The new homogeneous position.
   */
  void setGLLight0(const btVector4 &pos);

  /**
   * @brief Returns the homogeneous position of the main light.
   * @return The light vector.
   */
  btVector4 getGLLight0() const;

  /**
   * @brief Sets the position of the fill light.
   *
   * A homogeneous coordinate, the same as setGLLight0() describes.
   *
   * @param pos The new homogeneous position.
   */
  void setGLLight1(const btVector4 &pos);

  /**
   * @brief Returns the homogeneous position of the fill light.
   * @return The light vector.
   */
  btVector4 getGLLight1() const;

  /**
   * @brief Turns shadow casting in the interactive view on or off.
   *
   * With shadows on the scene is drawn twice: once as depth only from the main
   * light's point of view, into an off-screen map, and then normally through a
   * shader that looks each fragment up in that map. Only the main light,
   * setGLLight0(), casts; the fill light does not.
   *
   * Switching them on asks for an off-screen depth map and a shader, and a
   * context that will not provide either falls back to the plain
   * fixed-function draw with a warning. Shadows also change the lighting from
   * per-vertex to per-pixel, and light both sides of a surface rather than
   * only the front, so the shaded scene looks a little different from the
   * unshadowed one beyond the shadows themselves.
   *
   * Takes no mutex, for the reason setShowConstraints() gives.
   *
   * @param on True to cast shadows.
   */
  void setShadows(bool on);

  /**
   * @brief Returns whether shadows are being cast.
   * @return True if they are.
   */
  bool shadows() const;

  /**
   * @brief Turns culling on or off: skipping, each frame, the objects that
   *        can't be seen.
   *
   * On (the default), an object whose bounding box lies wholly outside the
   * camera's view isn't drawn, and, with shadows on, isn't drawn into the
   * shadow map either unless its shadow could fall into the view (its box,
   * swept along the light's direction, meets the view). Objects a script
   * draws for itself (setRenderFunction()), soft bodies and objects without
   * a shape are always drawn, as is everything in quad view.
   *
   * @param on True to cull.
   */
  void setCulling(bool on);

  /**
   * @brief Returns whether culling is on (see setCulling()).
   * @return True if it is.
   */
  bool culling() const;

  /**
   * @brief How many objects the last frame drew for the screen (in quad view,
   *        counting each pane).
   * @return The count.
   */
  int drawnObjects() const;

  /**
   * @brief How many objects the last frame drew into the shadow map one by
   *        one (0 with shadows off; those replayed from its record are
   *        shadowCached()).
   * @return The count.
   */
  int shadowCasters() const;

  /**
   * @brief Turns the shadow map's record of fixed objects on or off.
   *
   * On (the default), the fixed objects (mass 0) that have stayed where they
   * are for a while are drawn into the shadow map once, recorded as OpenGL
   * lists (one for each patch of the scene), and each frame replays the lists
   * of the patches it needs and draws only the rest one by one. A fixed object a script moves leaves the record (which is
   * made again without it) and comes back once it has stayed put again.
   * Objects a script draws for itself (setRenderFunction()) are always drawn
   * one by one.
   *
   * @param on True to record the fixed objects.
   */
  void setShadowCache(bool on);

  /**
   * @brief Returns whether the fixed objects' shadows are recorded (see
   *        setShadowCache()).
   * @return True if they are.
   */
  bool shadowCache() const;

  /**
   * @brief How many fixed objects the last frame's shadow map took from its
   *        record or its saved depth (0 when it drew them all one by one).
   *        From the saved depth that is all of them; replaying the record,
   *        only those in the patches culling kept.
   * @return The count.
   */
  int shadowCached() const;

  /**
   * @brief Turns the screen's record of still objects on or off.
   *
   * On (the default), the fixed objects that have stayed the same for a
   * while (where they are, their shape, colour and transparency) and have no
   * image wrapped round them and nothing of a script's drawing are drawn for
   * the screen from recorded OpenGL lists, one per patch of the scene, each
   * replayed when culling keeps any of its objects; the rest are drawn one by
   * one. The lists are made again when those objects change. A fixed object
   * that changes after being recorded (a lamp that blinks) stays out for ten
   * seconds after it last changed, so it doesn't have them made again and
   * again.
   *
   * @param on True to record them.
   */
  void setScreenCache(bool on);

  /**
   * @brief Returns whether the screen's record is on (see setScreenCache()).
   * @return True if it is.
   */
  bool screenCache() const;

  /**
   * @brief How many objects the last frame drew for the screen from its
   *        record (drawnObjects() counts those drawn one by one).
   * @return The count.
   */
  int screenCached() const;

  /**
   * @brief Turns the saved shadow depth on or off.
   *
   * On (the default), with the record on (setShadowCache()), the still
   * objects' depth is drawn into the shadow map once and saved, and each
   * frame after that puts the saved depth back with one copy on the graphics
   * card, then draws only the rest. It is drawn and saved again when the
   * record changes, or the light, or the scene's extent (which the shadow map
   * is fitted to), once that has stayed the same for ten frames; until then,
   * and with this off, each frame replays the record instead.
   *
   * @param on True to save the depth.
   */
  void setShadowSaved(bool on);

  /**
   * @brief Returns whether the shadow depth is saved (see setShadowSaved()).
   * @return True if it is.
   */
  bool shadowSaved() const;

  /**
   * @brief Whether the last frame's shadow map started from the saved depth
   *        (or saved it).
   * @return True if it did.
   */
  bool shadowFromSaved() const;

  /**
   * @brief Turns the drawing timer on or off (off by default, and each time
   *        a script starts).
   *
   * On, each frame times the parts of drawing the scene -- deciding what to
   * skip, the shadow map, the screen pass, and the whole of draw() -- on the
   * processor, and the shadow map and the screen pass on the graphics card
   * too (with its own timers, read a few frames later so as not to wait for
   * it). drawTimingReport() gives the averages.
   *
   * @param on True to time.
   */
  void setDrawTiming(bool on);

  /**
   * @brief Returns whether the drawing timer is on (see setDrawTiming()).
   * @return True if it is.
   */
  bool drawTiming() const;

  /**
   * @brief The drawing timer's averages since the last call, one line, in
   *        milliseconds a frame, and starts again.
   * @return The line, or an empty string if nothing was timed.
   */
  QString drawTimingReport();

  /**
   * @brief Sets the resolution of the square shadow depth map, in pixels.
   *
   * Larger is sharper and slower, and is clamped to between 256 and 8192. The
   * default, 2048, puts a shadow edge within about a thousandth of the scene's
   * width.
   *
   * @param px The new edge length in pixels.
   */
  void setShadowMapSize(int px);

  /**
   * @brief Returns the resolution of the shadow depth map.
   * @return Its edge length in pixels.
   */
  int shadowMapSize() const;

  /**
   * @brief Sets how far a shadow edge is blurred, in depth-map texels.
   *
   * 0 gives a hard, stair-stepped edge; the default 1 spreads the nine shadow
   * taps one texel apart, which is roughly a pixel of blur on screen at the
   * default map size.
   *
   * @param texels The tap spacing.
   */
  void setShadowSoftness(btScalar texels);

  /**
   * @brief Returns how far a shadow edge is blurred.
   * @return The tap spacing in depth-map texels.
   */
  btScalar shadowSoftness() const;

  /**
   * @brief Sets how much of the main light a shadow takes away, from 0 to 1.
   *
   * The default, 1, removes all of it, which is what a blocked light means: a
   * shadow is then lit by the ambient terms and the unshadowed fill light
   * alone. Lower it to lift the shadows in a scene whose lighting leaves them
   * too heavy.
   *
   * @param d The fraction removed.
   */
  void setShadowDarkness(btScalar d);

  /**
   * @brief Returns how much of the main light a shadow takes away.
   * @return The fraction removed, from 0 to 1.
   */
  btScalar shadowDarkness() const;

  /**
   * @brief Sets the ambient light and material colour.
   * @param am The new RGB ambient colour.
   */
  void setGLAmbient(const btVector3 &am);

  /**
   * @brief Returns the ambient light and material colour.
   * @return The RGB ambient colour.
   */
  btVector3 getGLAmbient() const;

  /**
   * @brief Sets the diffuse light and material colour.
   * @param col The new RGBA diffuse colour.
   */
  void setGLDiffuse(const btVector4 &col);

  /**
   * @brief Returns the diffuse light and material colour.
   * @return The RGBA diffuse colour.
   */
  btVector4 getGLDiffuse() const;

  /**
   * @brief Sets the specular light and material colour.
   * @param col The new RGBA specular colour.
   */
  void setGLSpecular(const btVector4 &col);

  /**
   * @brief Returns the specular light and material colour.
   * @return The RGBA specular colour.
   */
  btVector4 getGLSpecular() const;

  /**
   * @brief Sets the global ambient term of the OpenGL lighting model.
   * @param am The new RGBA model ambient colour.
   */
  void setGLModelAmbient(const btVector4 &am);

  /**
   * @brief Returns the global ambient term of the OpenGL lighting model.
   * @return The RGBA model ambient colour.
   */
  btVector4 getGLModelAmbient() const;

  /**
   * @brief Sets the global ambient term to a shade of grey.
   * @param am Intensity, applied to the RGB components.
   */
  void setGLModelAmbientPercent(const btScalar am);

  /**
   * @brief Returns the magnitude of the global ambient colour.
   * @return The length of the model ambient vector.
   */
  btScalar getGLModelAmbientPercent() const;

  /**
   * @brief Sets the ambient colour to a shade of grey.
   * @param am Intensity, applied to the RGB components.
   */
  void setGLAmbientPercent(const btScalar am);

  /**
   * @brief Returns the magnitude of the ambient colour.
   * @return The length of the ambient vector.
   */
  btScalar getGLAmbientPercent() const;

  /**
   * @brief Sets the diffuse colour to a shade of grey.
   * @param col Intensity, applied to the RGB components.
   */
  void setGLDiffusePercent(const btScalar col);

  /**
   * @brief Returns the magnitude of the diffuse colour.
   * @return The length of the diffuse vector.
   */
  btScalar getGLDiffusePercent() const;

  /**
   * @brief Sets the specular colour to a shade of grey.
   * @param col Intensity, applied to the RGB components.
   */
  void setGLSpecularPercent(const btScalar col);

  /**
   * @brief Returns the magnitude of the specular colour.
   * @return The length of the specular vector.
   */
  btScalar getGLSpecularPercent() const;

#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
  /**
   * @brief Sets the colour the view is cleared to.
   * @param color The new background colour.
   */
  void setBackgroundColor(const QColor &color) {
    glClearColor(color.redF(), color.greenF(), color.blueF(), color.alphaF());
  }
#else
  /**
   * @brief Sets the colour the view is cleared to.
   * @param color The new background colour.
   */
  void setBackgroundColor(const QColor &color) { qglClearColor(color); }
#endif

  // POV-Ray properties
  /**
   * @brief Sets scene description text emitted before the objects.
   * @param preSDL POV-Ray SDL written near the top of each exported frame.
   */
  void setPreSDL(const QString &preSDL);

  /**
   * @brief Returns the scene description text emitted before the objects.
   * @return The prologue SDL.
   */
  QString getPreSDL() const;

  /**
   * @brief Sets scene description text emitted after the objects.
   * @param postSDL POV-Ray SDL written at the end of each exported frame.
   */
  void setPostSDL(const QString &postSDL);

  /**
   * @brief Returns the scene description text emitted after the objects.
   * @return The epilogue SDL.
   */
  QString getPostSDL() const;

  /**
   * @brief Sets the include file the exported main scene pulls in.
   * Each export copies the file of this name from @c includes/ into the
   * scene's export directory, so a scene with its own lighting and globals
   * names its own file here instead of overwriting @c settings.inc.
   * @param pov_settings_inc File name, @c "settings.inc" by default. An empty
   *                         string emits no include at all.
   */
  void setPOVSettingsInc(QString pov_settings_inc);

  /**
   * @brief Returns the include file the exported main scene pulls in.
   * @return The include file name.
   */
  QString getPOVSettingsInc();

  /**
   * @brief Sets the settings store the viewer reads its preferences from.
   * @param settings The store. Not owned.
   */
  void setSettings(QSettings *settings);

  /**
   * @brief Stores a value a script wants to keep between runs.
   *
   * Written under the @c lua group of the application settings -- on a
   * background thread (see PrefsWriter in viewer.cpp): writing the settings
   * file can take hundreds of milliseconds (Qt locks it and forces it to
   * disk), and done on the main thread that froze the whole scene each time
   * a script saved a score. getPrefs() sees the new value at once.
   *
   * @param key   Name to store it under.
   * @param value The value.
   */
  void setPrefs(QString key, QString value);

  /**
   * @brief Reads back a value stored with setPrefs().
   * @param key          Name to read.
   * @param defaultValue Returned if the key was never written.
   * @return The stored value, or @p defaultValue.
   */
  QString getPrefs(QString key, QString defaultValue) const;

  /**
   * @brief Starts the animation loop, after calling the script's preStart hook.
   */
  void startAnimation() override;

  /**
   * @brief Stops the animation loop, after calling the script's preStop hook.
   */
  void stopAnimation() override;

  /**
   * @brief Advances one animation frame.
   *
   * Calls the script's preDraw hook, exports a POV-Ray frame if that is
   * enabled and, while the simulation is running, steps the Bullet world
   * between the preSim and postSim hooks and advances the frame counter.
   * Does nothing while a script is being parsed or after one raised an
   * exception.
   */
  void animate() override;

  /**
   * @brief Renders the scene.
   *
   * Sets up the lights and material state, then draws either the single
   * perspective view or, when quad view is on, the four panes. Skipped while
   * a script is being parsed or the widget is hidden. The script's preDraw
   * hook runs first.
   */
  void draw() override;

  /**
   * @brief Draws the screen-space overlays on top of the scene.
   *
   * Calls the script's postDraw hook, then paints the status dots in the top
   * right corner - red while animating, green while simulating, cyan while
   * exporting POV-Ray frames, yellow while deactivation is allowed - and the
   * VFE render preview when one is showing.
   */
  void postDraw() override;

public slots:
  /**
   * @brief Closes the viewer widget.
   */
  void close();

  /**
   * @brief Runs a Lua script, replacing whatever was running before.
   *
   * Calls the script's preStop hook, releases the callbacks and registry
   * references, closes the old Lua state - which is what frees the Bullet
   * objects Lua adopted - and rebuilds the world from scratch. A new state is
   * then opened, the module search path set up, every bpp class registered and
   * the script run. A leading @c \#! line is stripped so a script can be made
   * executable. If the script moved the camera, that view becomes the one
   * resetCamView() returns to. Errors are reported through scriptHasOutput()
   * with a Lua stack trace.
   *
   * @param txt The script source.
   * @return True if the script loaded and ran without error.
   */
  bool parse(QString txt);

  /**
   * @brief Empties the scene and rebuilds an empty dynamics world.
   *
   * Removes and deletes every object, constraint, vehicle and raycaster, then
   * recreates the Bullet world and resets the simulation, lighting and
   * POV-Ray settings to their defaults.
   */
  void clear();

  /**
   * @brief Sets the hook called just before the animation loop starts.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPreStart(const luabind::object &fn);

  /**
   * @brief Sets the hook called before each frame is drawn.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPreDraw(const luabind::object &fn);

  /**
   * @brief Sets the hook called after each frame is drawn.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPostDraw(const luabind::object &fn);

  /**
   * @brief Sets the hook called before each simulation step.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPreSim(const luabind::object &fn);

  /**
   * @brief Sets the hook called after each simulation step.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPostSim(const luabind::object &fn);

  /**
   * @brief Sets the hook called when the script is about to be replaced.
   * @param fn A Lua function taking the frame number. Ignored if not a
   *           function.
   */
  void setCBPreStop(const luabind::object &fn);

  /**
   * @brief Sets the hook called for a line typed at the command line.
   * @param fn A Lua function taking the frame number and the command text.
   *           Ignored if not a function.
   */
  void setCBOnCommand(const luabind::object &fn);

  /**
   * @brief Sets the hook called for each joystick report.
   * @param fn A Lua function taking the frame number and a JoystickInfo.
   *           Ignored if not a function.
   */
  void setCBOnJoystick(const luabind::object &fn);

  /**
   * @brief Sets the hook called when a key is pressed or released.
   *
   * The function receives the frame number, the key's name (the Qt key
   * sequence text, e.g. "Return", "Z", "1"; the two Shift keys are reported
   * as "LShift" and "RShift") and true for a press, false for a release.
   * Auto-repeat presses are not reported. If the function returns true for a
   * press, that key is consumed: it and its auto-repeats skip the built-in
   * key bindings until it is released.
   *
   * @param fn A Lua function as described. Ignored if not a function.
   */
  void setCBOnKey(const luabind::object &fn);

  /** @brief Milliseconds between animation frames (QGLViewer's period). */
  int getAnimationPeriod() const;
  /** @brief Sets the milliseconds between animation frames. */
  void setAnimationPeriodMs(int ms);

  /**
   * @brief Sets the hook called for each 3D mouse report.
   *
   * Setting this takes the 3D mouse away from the built-in camera control, so
   * a script can use the device for its own purposes.
   *
   * @param fn A Lua function taking the frame number and the axes. Ignored if
   *           not a function.
   */
  void setCBOnSpaceNavigator(const luabind::object &fn);

  /**
   * @brief Sets the hook called when F1 or F2 is pressed.
   * @param fn A Lua function taking -1 for F1 or 1 for F2. Ignored if not a
   *           function.
   */
  void setCBCycleObject(const luabind::object &fn);

  /**
   * @brief Sets the hook called whenever a parameter changes.
   * @param fn A Lua function taking the frame number, the name and the new
   *           value. Ignored if not a function.
   */
  void setCBOnParamChanged(const luabind::object &fn);

  /**
   * @brief Registers or updates a script parameter.
   * @param name  Parameter name; it also becomes a Lua global.
   * @param value The value.
   */
  void addParam(const QString &name, const QVariant &value);

  /**
   * @brief Registers or updates a script parameter with a description.
   *
   * The value is mirrored into a Lua global of the same name, so the script
   * can simply read it, and the onParamChanged hook is called.
   *
   * @param name    Parameter name.
   * @param value   The value.
   * @param comment Description shown in the parameter's tooltip.
   */
  void addParam(const QString &name, const QVariant &value, const QString &comment);

  /**
   * @brief Registers or updates a numeric parameter with a range.
   *
   * Giving a range is what makes the Gui present the parameter as a slider.
   *
   * @param name  Parameter name.
   * @param value The value.
   * @param min   Lower bound.
   * @param max   Upper bound.
   */
  void addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max);

  /**
   * @brief Registers or updates a numeric parameter with a range and step.
   * @param name  Parameter name.
   * @param value The value.
   * @param min   Lower bound.
   * @param max   Upper bound.
   * @param step  Slider step size.
   */
  void addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step);

  /**
   * @brief Registers or updates a numeric parameter with range, step and text.
   * @param name    Parameter name.
   * @param value   The value.
   * @param min     Lower bound.
   * @param max     Upper bound.
   * @param step    Slider step size.
   * @param comment Description shown in the parameter's tooltip.
   */
  void addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step, const QString &comment);

  /**
   * @brief Reads a parameter's current value.
   *
   * The Lua global is consulted first, so a value the script assigned to it
   * directly is seen here too.
   *
   * @param name Parameter name.
   * @return The value, or an invalid QVariant if there is no such parameter.
   */
  QVariant getParam(const QString &name) const;

  /**
   * @brief Returns every registered parameter.
   * @return Parameter names mapped to their values.
   */
  QHash<QString, QVariant> getParams() const;

  /**
   * @brief Forgets every registered parameter.
   */
  void clearParams();

  /**
   * @brief Sets the text shown in the "Shortcuts" dock panel.
   *
   * See helpTextChanged(). Scripts call this once, typically near the top,
   * listing their own addShortcut() bindings, so the panel always reflects
   * whatever script is actually loaded, rather than something hardcoded in
   * the GUI itself and liable to drift out of sync.
   *
   * @param text The text to show.
   */
  void setHelpText(const QString &text);
	
  /**
   * @brief Returns everything known about one parameter.
   * @param name Parameter name.
   * @return Its metadata, or a default-constructed ParamInfo if there is no
   *         such parameter.
   */
  ParamInfo getParamInfo(const QString &name) const;

  /**
   * @brief Handles a key press in the 3D view.
   *
   * A shortcut a script bound with addShortcut() wins over the built-in keys,
   * which are: @c S start/stop simulation, @c P toggle POV-Ray export, @c D
   * toggle deactivation, @c R re-run the script, @c C reset the camera,
   * @c F1/@c F2 cycle objects, and Tab toggle the quad view. With VFE
   * support, Escape cancels and Space pauses an in-progress render. Anything
   * else goes to QGLViewer.
   *
   * @param e The key event.
   */
  void keyPressEvent(QKeyEvent *e) override;

  /**
   * @brief Reports key releases to the onKey() hook, if one is set.
   * @param e The key event.
   */
  void keyReleaseEvent(QKeyEvent *e) override;

  /**
   * @brief Stops Tab and Backtab being eaten by focus traversal.
   *
   * Qt intercepts Tab/Backtab for focus-chain traversal in QWidget::event(),
   * before keyPressEvent() ever runs. Disabling that lets Tab reach
   * keyPressEvent() and toggle the quad view instead.
   *
   * Qt passes the direction focus would move in; it is ignored, and the
   * parameter is left unnamed so the body draws no unused-parameter warning.
   *
   * @return Always false, so focus never moves.
   */
  bool focusNextPrevChild(bool) override { return false; }

  /**
   * @brief Starts a pan drag, or dismisses the VFE preview.
   *
   * A click while the render preview is showing dismisses it and is consumed,
   * so the view is not nudged at the same time. Otherwise, a press over one of
   * the orthographic quad-view panes begins a pan of that pane; everywhere
   * else, including the perspective pane, falls through to QGLViewer's own
   * camera handling.
   *
   * @param e The mouse event.
   */
  void mousePressEvent(QMouseEvent *e) override;

  /**
   * @brief Pans the orthographic pane a drag started in.
   *
   * Screen movement is converted to world units at the pane's current zoom.
   *
   * @param e The mouse event.
   */
  void mouseMoveEvent(QMouseEvent *e) override;

  /**
   * @brief Ends a pan drag on an orthographic pane.
   * @param e The mouse event.
   */
  void mouseReleaseEvent(QMouseEvent *e) override;

  /**
   * @brief Zooms the orthographic pane under the pointer.
   *
   * Each wheel notch moves the camera 10% closer to or further from its pivot
   * along its own view direction. Over the perspective pane, QGLViewer's own
   * handling applies.
   *
   * @param e The wheel event.
   */
  void wheelEvent(QWheelEvent *e) override;

  /**
   * @brief Passes a command line entry to the script's onCommand hook.
   * @param cmd The command text.
   */
  void command(QString cmd);

  /**
   * @brief Reports an exception raised by Lua and stops the simulation.
   *
   * Emits the exception text together with whatever Lua error message and
   * source line are available, and latches the viewer so animate() stops
   * stepping until the next parse().
   *
   * @param e       The exception.
   * @param context Name of the hook or call it came from, used in the message.
   */
  void showLuaException(const std::exception &e, const QString &context = "");

  /**
   * @brief Renders the current frame with POV-Ray, using the default options.
   */
  void onQuickRender();

  /**
   * @brief Renders the current frame with POV-Ray.
   *
   * Exports the frame, then renders it at the resolution chosen in the GUI,
   * writing a timestamped PNG to the desktop. The render either runs in a
   * separate @c povray process or, if the @c povray/useVFE setting is on and
   * bpp was built with VFE support, in-process with a live preview.
   *
   * @param povargs Extra POV-Ray command line options, appended to those from
   *                the preferences.
   */
  void onQuickRender(QString povargs);

  /**
   * @brief Passes a joystick report to the script's onJoystick hook.
   * @param ji The report.
   */
  void onJoystickData(const JoystickInfo &ji);

  /**
   * @brief Passes raw 3D mouse axes to the script's onSpaceNavigator hook.
   * @param axes The raw device axes.
   */
  void onSpaceNavigatorAxes(const SpaceNavigator::Axes &axes);

  /**
   * @brief Turns a normalised 3D mouse report into a camera target velocity.
   *
   * Integrates whatever was already commanded over the time since the previous
   * report, then shapes this report into a new target: deflections inside the
   * dead band are treated as rest, a cubic response gives fine control near
   * the centre and fast travel at full deflection, and a low-pass filter
   * smooths out packet jitter and the cap's spring-back. The first movement
   * also starts the sustaining timer. Does nothing to the camera if a script
   * has taken the device over.
   *
   * @param axes The normalised device axes.
   */
  void onSpaceNavigatorNorm(const SpaceNavigator::AxesNorm &axes);

  /**
   * @brief Handles a 3D mouse button press.
   *
   * Button 0 resets the camera; buttons 1 and 2 switch between Object and Fly
   * navigation.
   *
   * @param button  Button index.
   * @param pressed True on press, false on release.
   */
  void onSpaceNavigatorButton(int button, bool pressed);

  /**
   * @brief Keeps the camera moving while a 3D mouse deflection is held.
   *
   * The SpaceNavigator is an absolute device that reports nothing while the
   * cap is held still, so this timer keeps integrating the last target and
   * eases it back to rest once the cap returns to centre.
   */
  void onSpaceNavigatorTick();

  /**
   * @brief Moves the camera by the current 3D mouse target velocity.
   *
   * Integrates over the time since the previous report or tick, which is
   * measured and restarted here so the event-driven and sustaining paths
   * never double-count or skip an interval. In Fly mode the camera turns and
   * moves about itself; in Object mode it orbits the view-centre pivot. With
   * the horizon locked, rotation is a turntable yaw and pitch and the camera
   * is re-rolled level afterwards. The caller must hold @c mutex.
   *
   * @param sustained True when called from the sustaining timer, which is what
   *                  enables easing resting axes back to zero.
   */
  void integrateSpaceNavigator(bool sustained = false);

  // SpaceNavigator navigation settings
  /**
   * @brief Chooses the 3D mouse navigation style.
   * @param mode 1 for Object (orbit), anything else for Fly (first person).
   */
  void setSpaceNavigatorMode(int mode);

  /**
   * @brief Returns the 3D mouse navigation style.
   * @return 1 for Object, 0 for Fly.
   */
  int spaceNavigatorMode() const;

  /**
   * @brief Sets whether 3D mouse rotation keeps the horizon level.
   * @param on True to lock the horizon.
   */
  void setSpaceNavigatorLockHorizon(bool on);

  /**
   * @brief Returns whether 3D mouse rotation keeps the horizon level.
   * @return True if the horizon is locked.
   */
  bool spaceNavigatorLockHorizon() const;

  /**
   * @brief Sets whether fly speed scales with the distance to the scene.
   * @param on True to scale automatically.
   */
  void setSpaceNavigatorAutoFlySpeed(bool on);

  /**
   * @brief Returns whether fly speed scales with the distance to the scene.
   * @return True if it scales automatically.
   */
  bool spaceNavigatorAutoFlySpeed() const;

  /**
   * @brief Sets whether the orbit centre is drawn as an axis marker.
   * @param on True to draw it.
   */
  void setSpaceNavigatorShowOrbitAxis(bool on);

  /**
   * @brief Returns whether the orbit centre is drawn as an axis marker.
   * @return True if it is drawn.
   */
  bool spaceNavigatorShowOrbitAxis() const;

  /**
   * @brief Sets which way pushing the cap moves the camera.
   * @param forward True to move along the view direction, false to invert it.
   */
  void setSpaceNavigatorZoomDirection(bool forward);

  /**
   * @brief Returns which way pushing the cap moves the camera.
   * @return True if it moves along the view direction.
   */
  bool spaceNavigatorZoomForward() const;

  /**
   * @brief Sets whether the 3D mouse translates the camera at all.
   * @param on True to allow translation; false leaves only rotation.
   */
  void setSpaceNavigatorPanZoom(bool on);

  /**
   * @brief Returns whether the 3D mouse translates the camera.
   * @return True if translation is enabled.
   */
  bool spaceNavigatorPanZoom() const;

  /**
   * @brief Turns the drawing of constraint markers on or off.
   *
   * Deliberately takes no mutex, unlike the input-event setters above:
   * parse() already holds @c mutex for a script's entire run, so a script
   * setting @c v.showConstraints at top level - the natural place to do it -
   * would deadlock against itself on a plain, non-recursive QMutex. The flag
   * is a single bool only ever read from the render thread in
   * drawConstraints(), the same as the unlocked setTau(), setErp() and
   * setCfm() above.
   *
   * @param on True to draw the markers.
   */
  void setShowConstraints(bool on);

  /**
   * @brief Returns whether constraint markers are drawn.
   * @return True if they are.
   */
  bool showConstraints() const;

  /**
   * @brief Requests a repaint, using whichever call this QGLViewer provides.
   */
  void updateGLViewer() {
#if QGLVIEWER_VERSION < 0x020700
    this->updateGL();
#else
    this->update();
#endif
  };

signals:
  /**
   * @brief Emitted when the user asks to step through the scene's objects.
   * @param direction -1 for the previous object, 1 for the next.
   */
  void cycleObject(int direction);

  /**
   * @brief Emitted once per simulated frame.
   * @param frameNum The frame that was just simulated.
   */
  void frameUpdate(int frameNum);

  /**
   * @brief Emitted for a message belonging in the status bar.
   * @param msg The message.
   */
  void statusEvent(const QString &msg);

  /**
   * @brief Emitted when a script has finished loading and running.
   */
  void scriptFinished();

  /**
   * @brief Emitted when a script is about to be loaded.
   */
  void scriptStarts();

  /**
   * @brief Emitted when the running script is about to be replaced.
   */
  void scriptStopped();

  /**
   * @brief Emitted for a line of script output or an error message.
   * @param out The text.
   */
  void scriptHasOutput(const QString &out);

  /**
   * @brief Emitted after a frame has been simulated and drawn.
   *
   * The Gui uses it to refresh the camera readout. Suppressed for the first
   * ten frames.
   *
   * @param frameNum The frame number.
   */
  void postDrawShot(int frameNum);

  /**
   * @brief Emitted when the simulation starts or stops.
   * @param running True if it is now running.
   */
  void simulationStateChanged(bool running);

  /**
   * @brief Emitted when POV-Ray frame export is turned on or off.
   * @param enabled True if export is now on.
   */
  void POVStateChanged(bool enabled);

  /**
   * @brief Emitted when PNG frame export is turned on or off.
   * @param enabled True if export is now on.
   */
  void PNGStateChanged(bool enabled);

  /**
   * @brief Emitted when body deactivation is allowed or forbidden.
   * @param enabled True if bodies may now deactivate.
   */
  void deactivationStateChanged(bool enabled);

  /**
   * @brief Emitted to ask the GUI to empty the debug pane.
   */
  void clearDebugText();

  /**
   * @brief Emitted whenever the set or values of the parameters change.
   */
  void paramsChanged();

  /**
   * @brief Emitted to set the text of the "Shortcuts" dock panel.
   * @param text The text to show.
   */
  void helpTextChanged(const QString &text);

protected:
  /**
   * @brief Sets up OpenGL state and the initial camera once the context exists.
   *
   * Enables depth testing and smooth shading, frames the scene, installs the
   * default lighting, records the camera as the one resetCamView() returns to
   * and puts the mouse orbit into turntable mode so the camera never rolls.
   */
  void init() override;

  /**
   * @brief Sets the world's gravity.
   *
   * Set on the world info as well as the world itself, because
   * btDiscreteDynamicsWorld::setGravity() only updates rigid bodies while soft
   * bodies read gravity from the world info.
   *
   * @param gravity The new gravity vector.
   */
  void setGravity(btVector3 gravity);

  /**
   * @brief Returns the world's gravity.
   * @return The gravity vector.
   */
  btVector3 getGravity();

  /**
   * @brief Hook for subclasses to populate the scene. Does nothing here.
   */
  virtual void addObjects();

  /**
   * @brief Adds an object with explicit collision filtering.
   *
   * Adds both the rigid body and, for a SoftBody, the soft body. With
   * deactivation off the body is added with @c DISABLE_DEACTIVATION.
   *
   * @param o    The object to add.
   * @param type Collision filter group.
   * @param mask Collision filter mask.
   */
  void addObject(Object *o, int type, int mask);

  /**
   * @brief Adds several objects with the same collision filtering.
   * @param ol   The objects to add.
   * @param type Collision filter group.
   * @param mask Collision filter mask.
   */
  void addObjects(QList<Object *> ol, int type, int mask);

  /**
   * @brief Renders every object and the constraint markers.
   *
   * With shadows on, the objects are drawn through the shadow map's shader and
   * the constraint markers after it is released, so the markers keep the flat,
   * unlit colours they are drawn with.
   *
   * @param pass Index of the quad-view pane being drawn. Unused.
   */
  void drawSceneInternal(int pass);

  /**
   * @brief Renders every object in the scene, and nothing else.
   *
   * A SoftBody has no rigid body or motion state, so Object::render() would
   * silently skip it; those are rendered directly instead.
   *
   * Called once per visible pass and, with shadows on, once more for the
   * depth-only pass from the light, which is why it sets no render state of
   * its own: each caller has already set what it needs.
   */
  void drawObjects(bool shadowPass = false, bool skipFixed = false);

  /**
   * @brief Whether an object goes into the shadow map's record of fixed
   *        objects (see setShadowCache()).
   * @param o The object.
   * @return True for a fixed object none of a script's drawing goes with.
   */
  static bool isFixedCaster(const Object *o);

  /**
   * @brief Marks which fixed objects go into the shadow map's record (those
   *        that have stayed put; see setShadowCache()).
   * @param count Set to how many do.
   * @return A fingerprint of them: which they are, where, and their shapes.
   */
  quint64 markStillCasters(int *count);

  /**
   * @brief Once a frame: marks the still objects (markStillCasters()) when
   *        either record wants them, and makes the screen's record again if
   *        they have changed (see setScreenCache()).
   */
  void markStill();

  /**
   * @brief Which patch of the scene an object is in, for the records' lists.
   * @param o The object (a fixed one).
   * @return The patch.
   */
  static std::tuple<int, int, int> patchOf(const Object *o);

  /**
   * @brief Sets the surface an object that doesn't set its own is drawn
   *        with: matte (as a Mesh leaves it) or the viewer's own (shiny).
   *
   * Which is fixed, not left to what happened to be drawn before (the
   * objects come in no particular order): matte whenever the scene has a
   * Mesh or a Terrain, as drawing the shadow map always left it, and the
   * viewer's own otherwise. Drawing one by one and from the screen's record
   * then look the same.
   *
   * @param matte True for matte.
   */
  void applySurface(bool matte);

  /**
   * @brief Decides, once a frame, which objects are drawn for the screen and
   *        which into the shadow map (see setCulling()).
   *
   * Must be called with the camera's own projection and modelview matrices
   * loaded, before renderShadowDepth().
   */
  void cullObjects();

  /**
   * @brief Renders the scene's depth from the main light, into the shadow map.
   *
   * A no-op when shadows are off, and gives up quietly when the GL context
   * cannot provide the off-screen depth map or the shader, in which case
   * drawSceneInternal() draws the scene the fixed-function way.
   *
   * Must be called with the camera's own modelview matrix loaded and after the
   * lights have been positioned, since it leans on
   * @c glLightfv(GL_POSITION) having already put light 0 into eye space.
   */
  void renderShadowDepth();

  /**
   * @brief Renders the scene once into each of the four quad-view panes.
   *
   * Each pane gets its own viewport and camera. The full-window viewport and
   * the main camera's screen size are restored afterwards, because postDraw()'s
   * screen-space overlays and the next frame's mouse handling both assume the
   * whole widget.
   */
  void drawQuadView();

  /**
   * @brief Re-frames the three fixed orthographic cameras on the scene.
   *
   * Keeps their view direction and up vector, set once in the constructor, and
   * just slides them along that direction so the whole scene is in frame.
   * Called when quad view is first switched on and on a camera reset, not
   * every frame, so it does not fight the user's own pan and zoom afterwards.
   */
  void updateOrthoCameras();

  /**
   * @brief Fits the scene bounding box around everything in the world.
   *
   * Also invalidates the 3D mouse orbit distance, which the new scene size
   * makes stale.
   */
  void computeBoundingBox();

  /**
   * @brief Writes the current frame out as a POV-Ray scene.
   *
   * Creates a per-script directory under the export path holding a copy of
   * the settings include (@c settings.inc unless the script names another,
   * see setPOVSettingsInc()), a main @c .pov that includes the per-frame file, an
   * animation @c .ini with the usual output resolutions, a @c GNUmakefile and
   * one numbered @c .inc per frame carrying the camera and every object that
   * opted into export. The copy of the settings include keeps the directory
   * self-contained, so the scene still renders elsewhere without the original
   * include path. Sounds the scene plays go to a @c .wav, see saveWAV().
   *
   * @param force Write the frame even when POV-Ray export is turned off, as a
   *              quick render does.
   */
  void savePOV(bool force = false);

  /**
   * @brief Queues a sound just played for the exported audio track.
   *
   * Only while POV-Ray export is on. A sound played after the current frame
   * was exported (from postSim, say) is first seen in the next exported frame
   * and is queued for that one.
   *
   * @param chunk  The sound played.
   * @param volume Its volume from 0 to 1.
   */
  void recordSound(Mix_Chunk *chunk, double volume);

  /**
   * @brief Writes the exported frame's audio to the scene's @c .wav.
   *
   * Mixes the sounds recordSound() queued into the track and appends the
   * frame's share of it, 1/25 s -- the rate export.mk encodes the frames at --
   * so the file on disk is always a complete WAV as long as the video. The
   * track is started by the first sound, padded with silence back to the
   * export's first frame, so a scene that plays nothing gets no @c .wav. A new
   * export starts the track over.
   *
   * @param fileWAV Path of the scene's @c .wav.
   */
  void saveWAV(const QString &fileWAV);

public:
  //  QList<Object*> l[13];

private:
  lua_State *L;       ///< The interpreter the current script runs in, or null.
  QString lua_error;  ///< Result of the last parse: an error message, or "ok".

  Cam *_cam; ///< The viewer's camera; also reachable as camera().
  Vec _initialCameraPosition;    ///< Camera position resetCamView() returns to.
  Quaternion _initialCameraOrientation; ///< Orientation it returns to.
  btScalar _initialCameraHorizontalFieldOfView; ///< Field of view it
                                                ///< returns to.
  Vec _initialCameraUpVector; ///< Up vector it returns to; also the reference
                              ///< up used to keep the horizon level.

  /**
   * @brief True while the 4-pane quad view is shown instead of one view.
   *
   * Tab toggles between the single perspective view and a 4-pane CAD-style
   * layout (perspective, top, front, right), matching AutoCAD/Maya. The
   * perspective quadrant reuses camera(); the other three are fixed,
   * auto-framed orthographic views.
   */
  bool _quadView;

  /**
   * @brief Whether the ortho cameras have been framed on the scene yet.
   *
   * Set once updateOrthoCameras() has auto-framed the ortho cameras for
   * the first time, so later Tab toggles remember the user's own pan/zoom
   * in those views instead of re-framing every time.
   */
  bool _orthoCamerasFitted;
  qglviewer::Camera *_camTop;   ///< Fixed orthographic view from above.
  qglviewer::Camera *_camFront; ///< Fixed orthographic view from the front.
  qglviewer::Camera *_camRight; ///< Fixed orthographic view from the right.

  /**
   * @brief One quad-view pane: which camera renders it, and where.
   */
  struct Pane {
    qglviewer::Camera *cam; ///< Camera that renders this pane.
    QRect rect; ///< The pane's rectangle in widget coordinates, that is Qt's
                ///< convention with the origin top-left.
  };

  /**
   * @brief Returns the current quad-view pane layout.
   *
   * Perspective top-left (the interactive camera()), top top-right, front
   * bottom-left, right bottom-right - the classic AutoCAD/Maya four-view
   * layout. Rectangles are in widget coordinates, that is Qt's convention with
   * the origin top-left and y down, shared by drawQuadView(), which flips to
   * OpenGL's bottom-left-origin viewport, and orthoCameraAt(), which hit-tests
   * mouse events directly against these.
   *
   * @return The four panes, in that order.
   */
  QVector<Pane> computePanes() const;

  /**
   * @brief Returns the orthographic camera under a widget position.
   * @param pos Position in widget coordinates.
   * @return The camera, or null when quad view is off or @p pos is over the
   *         perspective pane, where camera()'s own default mouse handling
   *         already applies.
   */
  qglviewer::Camera *orthoCameraAt(const QPoint &pos) const;

  /// Active pan drag on one of the ortho panes (nullptr when not panning).
  qglviewer::Camera *_orthoPanCamera;
  QPoint _orthoPanLastPos; ///< Pointer position at the last pan step.

  bool _simulate; ///< True while the simulation is being stepped.

  Sphere *mioSphere; ///< Unused.

  //  ManipulatedFrame** keyFrame_;
  //  KeyFrameInterpolator kfi_;
  //  int nbKeyFrames;
  //  int currentKF_;

  QSet<Object *> *_objects;                  ///< Every object in the scene.
  QSet<Object *> _takenFromLua;              ///< Objects v:add took from Lua.
  QSet<btTypedConstraint *> _detached;       ///< Constraints taken out of the
                                             ///< world with an object they
                                             ///< join (see removeObject()).
  QSet<Object *> _removed;                   ///< Removed objects bpp still owns,
                                             ///< until their script lets go
                                             ///< (see reapRemoved()).
  QSet<btTypedConstraint *> *_constraints;   ///< Every constraint in the world.
  QSet<btRaycastVehicle *> *_raycast_vehicles; ///< Every raycast vehicle.

  /**
   * @brief The raycasters handed out by createVehicleRaycaster().
   *
   * btRaycastVehicle doesn't own/delete its raycaster, so track the ones we
   * hand out from createVehicleRaycaster() ourselves.
   */
  QSet<btVehicleRaycaster *> *_vehicle_raycasters;

  /**
   * @brief Lua references keeping each object's Lua-side value alive.
   *
   * Store raw Lua registry references (not luabind::object) to avoid
   * use-after-free when Lua state is destroyed.
   */
  std::map<Object*, int> _luabindRegistry;

  btScalar _aabb[6]; ///< Scene bounding box: minimum x, y, z then maximum.

  /**
   * @brief The collision configuration the world was built with.
   *
   * Actually a btSoftBodyRigidBodyCollisionConfiguration (see viewer.cpp);
   * the base pointer type is enough for everything this header needs.
   */
  btDefaultCollisionConfiguration *collisionCfg;

  /**
   * @brief The Bullet world the scene is simulated in.
   *
   * A btSoftRigidDynamicsWorld so soft bodies (SoftBody objects) can be
   * simulated alongside rigid bodies. It IS-A btDiscreteDynamicsWorld, so
   * all the rigid-body-oriented calls elsewhere keep working unchanged.
   */
  btSoftRigidDynamicsWorld *dynamicsWorld;

  /// Where each sleeping or fixed object was when its bounding box was last
  /// brought up to date (see updateMovedAabbs()).
  std::unordered_map<const btCollisionObject *, std::pair<btTransform, const btCollisionShape *>> _aabbSeen;
  /// Brings the bounding boxes of sleeping and fixed objects that scripts
  /// have moved up to date, so Bullet needn't recompute every box on every
  /// substep.
  void updateMovedAabbs();

  // Keep ownership of Bullet subcomponents so we can delete them explicitly
  btBroadphaseInterface *broadphase;  ///< Broadphase collision detection.
  btCollisionDispatcher *dispatcher;  ///< Narrowphase algorithm dispatcher.
  btConstraintSolver *solver;         ///< The constraint solver.

  /**
   * @brief Renders the constraint markers.
   *
   * Draws constraints (hinge axes, slider axes, pivots, ...), modelled on
   * btDiscreteDynamicsWorld::debugDrawConstraint() but implemented directly
   * so we control size/color per constraint type.
   */
  btIDebugDraw *_debugDrawer;
  bool _showConstraints; ///< Whether those markers are drawn.

  bool _shadows;         ///< Whether the main light casts shadows.
  bool _culling = true;  ///< Whether unseen objects are skipped (setCulling()).
  bool _culled = false;  ///< Whether this frame's culling applies (each
                         ///< object's drawOnScreen and drawInShadow).
  int _drawnObjects = 0;   ///< Objects drawn for the screen last frame.
  int _shadowCasters = 0;  ///< Objects drawn into the shadow map last frame.
  bool _shadowCache = true;        ///< See setShadowCache().
  bool _screenCache = true;        ///< See setScreenCache().
  quint64 _stillSig = 0;           ///< markStill()'s fingerprint this frame
  int _stillCount = 0;             ///< (and how many objects are still).
  bool _stillMarked = false;       ///< Whether markStill() marked them.
  GLuint _screenLists = 0;         ///< The screen's record: a list per patch.
  QVector<QVector<Object *>> _screenCells; ///< Each list's objects.
  const void *_screenCtx = nullptr; ///< The context the lists live in.
  unsigned _screenEpoch = 0;       ///< glCacheEpoch() when they were made.
  quint64 _screenSig = 0;          ///< The still objects they were made from
  int _screenCount = -1;           ///< (and how many those were).
  bool _anyMesh = false;           ///< The scene has a Mesh or a Terrain.
  bool _screenMatte = false;       ///< The surface they were made with
  btVector4 _screenSpecular;       ///< (applySurface()).
  btScalar _screenShininess = 0;
  int _screenCached = 0;           ///< Taken from it last frame.
  int _recordsMade = 0;            ///< Records made since the timer's report.
  GLuint _fixedShadowLists = 0;    ///< The still objects' recorded depth: one
                                   ///< list per patch of the room, from here.
  QVector<QVector<Object *>> _fixedShadowCells; ///< Each list's objects.
  const void *_fixedShadowCtx = nullptr; ///< GL context the lists live in.
  unsigned _fixedShadowEpoch = 0;  ///< glCacheEpoch() when they were made.
  quint64 _fixedShadowSig = 0;     ///< The objects they were made from.
  int _fixedShadowCount = 0;       ///< How many objects they hold.
  int _shadowCached = 0;           ///< Taken from it last frame.
  bool _shadowSaved = true;        ///< See setShadowSaved().
  bool _shadowFromSaved = false;   ///< See shadowFromSaved().
  quint64 _savedDepthSig = 0;      ///< The record the saved depth was made from
  int _savedDepthCount = -1;       ///< (and how many objects it held).

  // The drawing timer (see setDrawTiming()): totals since the last report.
  bool _drawTiming = false;
  double _dtCull = 0, _dtShadow = 0, _dtScreen = 0, _dtDraw = 0;
  double _dtBox = 0, _dtStill = 0;
  int _dtFrames = 0;
  double _dtShadowGpu = 0, _dtScreenGpu = 0;
  int _dtGpuFrames = 0;
  unsigned _dtQueries[4][2] = {};  ///< Timer queries, a ring of four frames.
  bool _dtPending[4] = {};         ///< Which of them wait to be read.
  int _dtSlot = 0;
  const void *_dtCtx = nullptr;    ///< The context the queries belong to.
  unsigned _dtEpoch = 0;
  bool _dtNoGpu = false;           ///< The context has no timer queries.
  void dtGpuBegin(int which);
  void dtGpuEnd();
  void dtGpuCollect();
  ShadowMap *_shadowMap; ///< Off-screen depth map and the shader that reads
                         ///< it; built on the first shadowed frame, since it
                         ///< needs a current GL context.

  /**
   * @brief Draws a marker for every constraint in the scene.
   *
   * Each constraint's markers are sized relative to the parts it connects
   * rather than to the whole scene, so one far-away or oversized object - a
   * ground plane, a long road - does not blow up every marker elsewhere.
   */
  void drawConstraints();

  /**
   * @brief Draws the marker for one constraint.
   *
   * Modelled on btDiscreteDynamicsWorld::debugDrawConstraint() but implemented
   * directly, so the size and colour can be chosen per type instead of using
   * Bullet's often too-small internal defaults. Point constraints get a cross
   * at each pivot, hinge, slider and cone-twist constraints a cylinder along
   * their axis, six-degree-of-freedom and fixed constraints a three-axis
   * frame, a gear constraint one cylinder per body axis, and a
   * btHinge2Constraint its two joint axes through its anchor.
   *
   * @param c    The constraint to draw.
   * @param size Marker size, from constraintDrawSize().
   */
  void drawConstraint(btTypedConstraint *c, btScalar size);

  /**
   * @brief Chooses a marker size that suits the bodies a constraint joins.
   *
   * Half the average bounding-sphere radius of the two connected bodies, so
   * markers scale with the parts a constraint actually joins rather than the
   * whole scene.
   *
   * @param c The constraint.
   * @return The marker size; 0.5 if neither body has a collision shape.
   */
  btScalar constraintDrawSize(btTypedConstraint *c);

  /**
   * @brief Draws a three-axis cross along a transform's own axes.
   *
   * For constraints that pin a full frame - generic six-degree-of-freedom,
   * fixed - rather than a single axis or point.
   *
   * @param t    The frame to draw.
   * @param size Half-length of each arm.
   */
  void drawConstraintFrame(const btTransform &t, btScalar size);

  /**
   * @brief Draws a cylinder through a transform's origin along one of its axes.
   *
   * For constraints defined by a single axis: a hinge, a slider, or a
   * cone-twist's twist axis.
   *
   * @param t     The constraint frame.
   * @param axis  Which local axis to draw along: 0 for X, 1 for Y, 2 for Z.
   * @param size  Half-length of the cylinder.
   * @param color RGB colour.
   */
  void drawConstraintAxis(const btTransform &t, int axis, btScalar size,
                          const btVector3 &color);

  /**
   * @brief Draws a small three-axis cross at a world point.
   *
   * For point constraints, such as a point-to-point pivot.
   *
   * @param p     The world position.
   * @param size  Half-length of each arm.
   * @param color RGB colour.
   */
  void drawConstraintPoint(const btVector3 &p, btScalar size,
                           const btVector3 &color);

  /**
   * @brief Draws a solid cylinder between two world points.
   *
   * Builds a rotation via @c btPlaneSpace1, the same way btHingeConstraint
   * itself derives a frame from a single axis, mapping the cylinder's local Z
   * onto the direction from @p from to @p to.
   *
   * @param from   Start point.
   * @param to     End point; a degenerate segment draws nothing.
   * @param radius Cylinder radius.
   * @param color  RGB colour.
   */
  void drawConstraintCylinder(const btVector3 &from, const btVector3 &to,
                              btScalar radius, const btVector3 &color);

  QElapsedTimer _timer; ///< Restarted each animation step; measures the
                        ///< interval between frames.
  QElapsedTimer _wallTimer; ///< Never restarted; backs getTime().

  /// One step of a frame noted by frame timing (see setFrameTiming()).
  struct FrameMark {
    qint64 ns;        ///< When, on _wallTimer.
    int kind;         ///< FrameMarkKind.
    int eventType;    ///< QEvent::Type, for an event.
    const char *cls;  ///< Receiver's class, for an event.
    const char *pcls; ///< Receiver's parent's class, for an event.
  };
  /// What a FrameMark marks the start of.
  enum FrameMarkKind {
    FM_ANIMATE, FM_AFTER_ANIMATE, FM_PAINT, FM_AFTER_PAINT, FM_EVENT,
    FM_WAITING, FM_AWAKE
  };
  void frameMark(int kind, int eventType = 0, const char *cls = nullptr,
                 const char *pcls = nullptr);
  void frameTimingReport(qint64 now);
  bool eventFilter(QObject *obj, QEvent *ev) override;
  /// Takes everything still in the dynamics world out of it, before the Lua
  /// state that may own some of it is closed.
  void removeLeftoverBodies();
  double _frameTimingMs = 0;       ///< Threshold; 0 when off.
  bool _frameTimingHooked = false; ///< Event filter and dispatcher hooked up.
  QVector<FrameMark> _frameMarks;  ///< Steps since the last animation step.
  qint64 _frameTimingLast = -1;    ///< Start of the last animation step.
  int _frameTimingReports = 0;     ///< Reports printed so far.

  QTextStream *_stream; ///< Stream writing the current frame's POV-Ray include.

  int _frameNum;   ///< The frame about to be simulated, counting from 1.
  int _firstFrame; ///< Frame the current POV-Ray export started at, which
                   ///< becomes the exported animation's initial clock.

  QFile *_file;         ///< This frame's POV-Ray include file.
  QFile *_fileMain;     ///< The exported scene's main @c .pov file.
  QFile *_fileINI;      ///< The exported animation's @c .ini file.
  QFile *_fileMakefile; ///< The @c GNUmakefile written beside the scene.

  bool _savePOV;      ///< Whether each simulated frame is exported.
  bool _deactivation; ///< Whether bodies are allowed to sleep.
  QString _scriptName;     ///< Base name used for exports and renders.
  QString _scriptBasePath; ///< Directory the running script came from.
  QString _scriptContent;  ///< Source of the running script, kept so it can
                           ///< be re-run.

  QMutex mutex;    ///< Guards the simulation and the Lua state; see the class
                   ///< description.
  QMutex cammutex; ///< Unused.

  // Lua callback functions
  luabind::object _cb_preStart;  ///< Called before the animation loop starts.
  luabind::object _cb_preDraw,  /**< Called before each frame is drawn. */
                  _cb_postDraw; /**< Called after each frame is drawn. */
  luabind::object _cb_preSim,    /**< Called before each simulation step. */
                  _cb_postSim;   /**< Called after each simulation step. */
  luabind::object _cb_preStop;   ///< Called before the script is replaced.
  luabind::object _cb_onCommand; ///< Called for a command line entry.
  luabind::object _cb_onJoystick; ///< Called for each joystick report.
  luabind::object _cb_onKey; ///< Called for each key press and release.
  QSet<int> _luaHeldKeys;    ///< Keys the onKey() hook consumed on press.
  luabind::object _cb_onSpaceNavigator; ///< Called for each 3D mouse report;
                                        ///< when set it also takes the device
                                        ///< away from the built-in camera
                                        ///< control.
  luabind::object _cb_cycleObject;   ///< Called when F1 or F2 is pressed.
  luabind::object _cb_onParamChanged; ///< Called when a parameter changes.

  #include <memory>

  QHash<QString, std::shared_ptr<luabind::object>> *_cb_shortcuts; ///< Lua
                          ///< functions bound to key sequences, keyed by the
                          ///< sequence's native text form.

  bool _parsing;       ///< True while a script is being loaded, which stops
                       ///< the draw and animation paths touching the world.
  bool _has_exception; ///< Latched when a Lua callback threw; stops the
                       ///< simulation until the next parse().

  // OpenGL properties
  btScalar _gl_shininess;      ///< Material shininess exponent.
  btVector4 _gl_specular_col;  ///< Specular colour as RGBA.

  btVector4 _light0; ///< Main light, as a homogeneous GL_POSITION: the light
                     ///< is at xyz/w, @see setGLLight0().
  btVector4 _light1; ///< Fill light, the same way. @see setGLLight1().

  btVector3 _gl_ambient;       ///< Ambient light and material colour.
  btVector4 _gl_diffuse,  /**< Diffuse light and material colour. */
            _gl_specular; /**< Specular light and material colour. */

  btVector4 _gl_model_ambient; ///< Global ambient term of the lighting model.

  // POV-Ray properties
  QString mPreSDL;  ///< SDL emitted before the objects in each frame.
  QString mPostSDL; ///< SDL emitted after them.

  QString _pov_settings_inc; ///< Include file the exported main scene pulls
                             ///< in; @c "settings.inc" by default.

#if USE_VFE
  // POV-Ray VFE quick-render preview (F6, gated by the povray/useVFE
  // setting). See src/povray/bppvfesession.h and bppvfedisplay.h.

  /**
   * @brief Starts an in-process POV-Ray render of an exported scene.
   *
   * Creates the VFE session on first use, clears the previous render's state -
   * which vfeSession documents as the client's job - and adds the library
   * paths the embedded renderer needs but a real install would resolve for
   * itself: POV-Ray's own standard include directory and the scene directory,
   * without which the per-frame include cannot be found. A render already in
   * flight is cancelled and this one queued, because CancelRender() is
   * asynchronous and the options cannot be set again until it has finished.
   *
   * @param sceneName Base name of the exported scene.
   * @param sceneDir  Directory holding the exported @c .pov and its includes.
   * @param args      POV-Ray command line options and the scene file.
   */
  void startVfeQuickRender(const QString &sceneName, const QString &sceneDir,
                            const QStringList &args);

  /**
   * @brief Polls the VFE session and drives the preview.
   *
   * Drains the renderer's messages, lazily acquires the display once vfe has
   * created it on its own thread, repaints while new pixels arrive, and on
   * shutdown reports the result and starts any queued render. A critical error
   * tears the session down rather than retrying.
   */
  void pollVfeRender();

  /**
   * @brief Forwards any pending POV-Ray messages to the script output.
   */
  void drainVfeMessages();

  /**
   * @brief Draws the VFE render preview over the whole view.
   *
   * Uploads the renderer's latest pixels into a texture and draws it as a
   * full-window quad. The texture is recreated here rather than where a new
   * render starts, because this runs from postDraw() with a current GL
   * context. Once vfe has torn the render down the last frame simply stays on
   * screen.
   */
  void drawVfePreview();

  /**
   * @brief Stops an in-flight render and optionally shuts the session down.
   * @param shutdownSession True to also shut down and release the VFE session.
   */
  void teardownVfeRender(bool shutdownSession);

  std::unique_ptr<BppVfeSession> _vfeSession; ///< The embedded POV-Ray
                                              ///< session, created on first
                                              ///< use.
  /**
   * @brief The display collecting the rendered pixels, while one exists.
   *
   * vfe destroys the Display (via VirtualFrontEnd::Process()'s CloseView()
   * call, vfe/vfe.cpp) as soon as a render reaches a terminal state, on its
   * own worker thread, with no notification to us -- a raw pointer captured
   * once at creation would dangle the moment that happens. weak_ptr, backed
   * by vfeSession::GetDisplay()'s shared_ptr, lets lock() safely detect that
   * instead of touching freed memory.
   */
  std::weak_ptr<BppVfeDisplay> _vfeDisplay;
  QTimer *_vfePollTimer;  ///< Drives pollVfeRender() while a render runs.
  bool _vfeRenderActive;  ///< True between starting a render and its shutdown.
  /**
   * @brief Whether a render is queued behind the one being cancelled.
   *
   * F6 while a render is already active cancels it and restarts with the
   * new scene/options once vfe has actually torn the old one down --
   * CancelRender() is asynchronous, so SetOptions()/StartRender() can't be
   * called again immediately (per vfeSession::CancelRender()'s own docs).
   * pollVfeRender() consumes this on the next stRenderShutdown.
   */
  bool _vfeRestartPending;
  QString _vfePendingSceneName; ///< Scene name for the queued render.
  QString _vfePendingSceneDir;  ///< Scene directory for the queued render.
  QStringList _vfePendingArgs;  ///< POV-Ray options for the queued render.
  /**
   * @brief Whether the render preview is currently shown over the scene.
   *
   * Clicking the 3D view while the VFE preview is showing (rendering or
   * finished) dismisses it back to the normal OpenGL scene; a fresh F6
   * brings it back. Does not cancel an in-progress render, only its display.
   */
  bool _vfePreviewVisible;
  /**
   * @brief Whether the preview texture must be thrown away and rebuilt.
   *
   * Set when a new render starts; drawVfePreview() deletes and recreates
   * _vfePreviewTexture on its next call. All GL work for this happens
   * inside drawVfePreview() (called from postDraw(), always within a
   * current GL context) rather than from startVfeQuickRender() itself,
   * which runs from a keypress/action handler with no GL context current --
   * calling makeCurrent() there was the cause of a crash on the second
   * render (the first render never takes this path, since no texture
   * exists yet to delete, so it was untested until the second F6 press).
   */
  bool _vfePreviewNeedsReset;
  unsigned int _vfePreviewTexture; ///< GL texture holding the rendered pixels,
                                   ///< 0 before one has been created.
  int _vfePreviewWidth;  ///< Width of the render, and of the texture.
  int _vfePreviewHeight; ///< Height of the render, and of the texture.
#endif // USE_VFE

  QSettings *_settings; ///< The settings store; not owned.

  // Lua preferences (setPrefs()): written on a background thread.
  QHash<QString, QString> _luaPrefs;      ///< Every value set this run (main
                                          ///< thread only), for getPrefs().
  QMutex _prefsMutex;                     ///< Guards the two below.
  QHash<QString, QString> _prefsToWrite;  ///< Set, not yet written.
  bool _prefsWriteQueued = false;         ///< A write is waiting to run.
  QThreadPool _prefsPool;                 ///< One thread: writes run in order.
  friend class PrefsWriter;
  void writePendingPrefs(QSettings &s);   ///< Runs on that thread.

  // bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
  btScalar _timeStep;      ///< Time one animation step advances the world by.
  int _maxSubSteps;        ///< Internal steps Bullet may take per animation
                           ///< step.
  btScalar _fixedTimeStep; ///< Size of Bullet's internal fixed step.

  // joystick handler
  JoystickInterfaceSDL *_joystickInterface; ///< SDL joystick backend.
  JoystickHandler _joystickHandler;         ///< Polls it and emits the reports.

  // audio: short sound effects (ticks, tocks, bells, ...), triggered from
  // Lua postSim callbacks. Deliberately minimal -- one-shot chunk playback
  // only, no music/streaming, since that's all a beat sound needs.
  bool _audioAvailable; ///< False if SDL audio / Mix_OpenAudio failed to
                        ///< init (no device, headless env, etc.) -- every
                        ///< audio method becomes a safe no-op in that case
                        ///< rather than crashing the sim.
  std::map<QString, int> _soundIdByPath; ///< Path -> id, so loading the same
                                         ///< file twice is free.
  std::map<int, Mix_Chunk *> _soundChunks; ///< id -> loaded chunk.
  int _nextSoundId; ///< Monotonically increasing; never reused.

  // exported audio: the sounds played while exporting, mixed by saveWAV()
  // into a track that keeps in step with the exported frames
  struct WavEvent {
    int frame;        ///< Exported frame the sound starts at.
    Mix_Chunk *chunk; ///< The sound; loaded chunks live as long as the Viewer.
    double volume;    ///< Volume from 0 to 1.
  };
  std::vector<WavEvent> _wavEvents; ///< Sounds played since the last frame.
  std::vector<int> _wavMix; ///< Mixed samples not written yet, the first one
                            ///< at _wavWritten.
  QString _wavFile;   ///< The track being written.
  int _wavFirstFrame; ///< Export start the track was begun for.
  int _wavFrame;      ///< Last frame whose audio was written.
  qint64 _wavWritten; ///< Sample frames in the file, -1 before the first sound.

  // SpaceNavigator 3D mouse
  SpaceNavigator *_spaceNavigator; ///< The 3D mouse, open or not.

  /**
   * @brief How the 3D mouse drives the camera.
   *
   * Object mode orbits the view-centre pivot; Fly mode navigates in first
   * person around the camera's own position.
   */
  enum SpaceNavigatorMode {
    SN_MODE_OBJECT, ///< Orbit the view-centre pivot.
    SN_MODE_FLY     ///< First-person navigation.
  };
  SpaceNavigatorMode _snMode; ///< The mode currently in use.

  // SpaceNavigator navigation settings (editable from the Preferences
  // dialog and via the Lua sn* properties).
  bool _snLockHorizon;   ///< Keep the horizon level while rotating.
  bool _snAutoFlySpeed;  ///< Scale fly speed with the distance to the scene.
  bool _snShowOrbitAxis; ///< Draw the orbit centre as an axis marker.
  bool _snZoomForward;   ///< Push the cap to move along the view direction.
  bool _snPanZoom;       ///< Let the device translate the camera at all.

  /**
   * @brief Distance from the camera to the point the 3D mouse orbits around.
   *
   * Blender-style orbit distance: the distance from the camera to the
   * view-centre pivot the SpaceNavigator orbits around.  Reinitialised from
   * the scene when the camera is reset or the scene changes.
   */
  qreal _snOrbitDist;

  // 3D mouse integration: the current shaped deflection is held in _snTarget
  // (a target velocity in units of full deflection).  Each device report
  // integrates the target over the time elapsed since the previous report
  // (event-driven, like Blender's NDOF), so navigation responds immediately.
  // _snTimer is a sustaining timer only: the SpaceNavigator is an absolute
  // device that reports nothing while a deflection is held still, so the
  // timer keeps integrating the last target at a fixed rate and the camera
  // keeps moving for as long as the cap is held.  Motion stops when the cap
  // returns to rest: the last report's deflection is remembered in
  // _snLastInput, the sustaining path eases resting axes back to zero (the
  // event path has already shaped them through the dead band and low-pass),
  // and the eased target is stopped once it falls back into the target dead
  // band.  _snTickTimer is shared by both paths so the integrated time
  // intervals never overlap.
  QTimer *_snTimer;           ///< The sustaining timer described above.
  QElapsedTimer _snTickTimer; ///< Measures the interval each integration step
                              ///< covers; shared by both paths.
  SpaceNavigator::AxesNorm _snTarget;    ///< Current shaped target velocity.
  SpaceNavigator::AxesNorm _snLastInput; ///< Raw deflection of the last report,
                                         ///< used to tell held axes from
                                         ///< resting ones.

   // parameter storage for Lua scripts
   QHash<QString, QVariant> _params;      ///< Current value of each parameter.
   QHash<QString, ParamInfo> _paramInfo;  ///< Range, step and comment for each.
};

#endif // VIEWER_H
