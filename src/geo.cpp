/**
 * @file geo.cpp
 * @brief geo: compiled helpers for the ArtificialPhysics world generator.
 *
 * Each function repeats a piece of the generator's Lua
 * (demo/WyomingWill/ArtificialPhysics/lib) operation for operation, in the
 * same order and in doubles, so its results are the Lua's to the last bit;
 * the generator's check demo/WyomingWill/ArtificialPhysics/checks/geo.lua
 * compares the two. What it repeats:
 *
 *   geo.noise(n)          a packed copy of a noise lattice (Land.newNoise)
 *   geo.fbm(c, x, y)      Land.fbm on that copy
 *   geo.zones(town)       a packed copy of a town's zoning (Town.build)
 *   geo.zone(z, x, y)     Town:entry's land rules on that copy, as a code:
 *                         k = district k, #districts + l = ladder step l,
 *                         0 = open land, -1 = woods (water stays in Lua)
 *   geo.grid(mesh, h, nx, ny, x0, y0, cell, S, base)
 *                         the terrain's ground triangles (T:toBPP)
 *   geo.colors(mesh, r, g, b, n)
 *                         its triangle colours, rounded as T:toBPP rounds
 *   geo.woods(trees, m1, m2, m3, trunks, S, base, crownBase, C6, S6, C3, S3)
 *                         the woods' trees (V.toBPP); returns the four
 *                         meshes' triangle counts
 *   geo.meshHash(mesh)    a hash of a built mesh's corners, in order, and
 *                         its triangle count (for the checks)
 *
 * Lua's arithmetic is one rounding per operation, so this file must not
 * fuse a multiply and an add into one (an FMA, which some compilers do by
 * default on ARM): contraction is turned off below.
 */

#if defined(__clang__)
#pragma clang fp contract(off)
#elif defined(__GNUC__)
#pragma GCC optimize("fp-contract=off")
#endif

#include "geo.h"

#include "objects/terrain.h"

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <btBulletDynamicsCommon.h>

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <new>
#include <vector>

namespace {

// Lua's math.max(a, b) and math.min(a, b): the first argument unless the
// second is strictly greater (smaller)
inline double luaMax(double a, double b) { return b > a ? b : a; }
inline double luaMin(double a, double b) { return b < a ? b : a; }

// Lua 5.1 and 5.2 compute a ^ 2 with pow(); a compiler would turn a
// literal pow(a, 2.0) into a * a, so the exponent is kept out of its sight
volatile double kTwo = 2.0;
inline double sq(double a) { return std::pow(a, kTwo); }

// a table's field as a number (dflt if it is nil)
double num(lua_State *L, int t, const char *k, double dflt) {
  lua_getfield(L, t, k);
  double v = lua_isnil(L, -1) ? dflt : lua_tonumber(L, -1);
  lua_pop(L, 1);
  return v;
}

// a sequence of numbers t[1], t[2], ... up to the first nil
std::vector<double> nums(lua_State *L, int t) {
  std::vector<double> v;
  for (int k = 1;; k++) {
    lua_rawgeti(L, t, k);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    v.push_back(lua_tonumber(L, -1));
    lua_pop(L, 1);
  }
  return v;
}

// a C++ value in a full userdata, freed by the collector
template <class T> T *newBox(lua_State *L, const char *meta) {
  void *p = lua_newuserdata(L, sizeof(T));
  T *o = new (p) T();
  if (luaL_newmetatable(L, meta)) {
    lua_pushcfunction(L, [](lua_State *L) -> int {
      static_cast<T *>(lua_touserdata(L, 1))->~T();
      return 0;
    });
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
  return o;
}

Terrain *meshArg(lua_State *L, int i, const char *fn) {
  Terrain *m = nullptr;
  try {
    m = luabind::object_cast<Terrain *>(luabind::object(luabind::from_stack(L, i)));
  } catch (...) {
    m = nullptr;
  }
  if (m == nullptr) luaL_error(L, "geo.%s: argument %d is not a Terrain", fn, i);
  return m;
}

//--------------------------------------------------------------------------
// Noise (lib/terrain.lua newNoise / fbm)
//--------------------------------------------------------------------------

struct Octave {
  std::vector<double> L;
  double nu, lam, amp, du, dv;
};
struct Noise {
  std::vector<Octave> oc;
  double total = 1;
};

void readNoise(lua_State *L, int n, Noise &out) {
  out.total = num(L, n, "total", 1);
  lua_getfield(L, n, "octaves");
  int os = lua_gettop(L);
  for (int q = 1;; q++) {
    lua_rawgeti(L, os, q);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    int o = lua_gettop(L);
    Octave oc;
    oc.nu = num(L, o, "nu", 0);
    oc.lam = num(L, o, "lam", 1);
    oc.amp = num(L, o, "amp", 0);
    oc.du = num(L, o, "du", 0);
    oc.dv = num(L, o, "dv", 0);
    lua_getfield(L, o, "L");
    oc.L = nums(L, lua_gettop(L));
    lua_pop(L, 2);
    out.oc.push_back(oc);
  }
  lua_pop(L, 1);
}

// false if (x, y) is off the lattice (where the Lua would fail on a nil)
bool fbm(const Noise &n, double x, double y, double &out) {
  double sum = 0;
  for (const Octave &o : n.oc) {
    double u = x / o.lam + o.du, v = y / o.lam + o.dv;
    double i = std::floor(u), j = std::floor(v);
    double tu = u - i, tv = v - j;
    double fu = tu * tu * tu * (tu * (tu * 6 - 15) + 10);
    double fv = tv * tv * tv * (tv * (tv * 6 - 15) + 10);
    double k = j * o.nu + i;      // (the Lua's k - 1)
    double size = (double)o.L.size();
    if (!(k >= 0 && k + o.nu + 1 < size)) return false;
    size_t K = (size_t)k, N = (size_t)o.nu;
    double a = o.L[K], b = o.L[K + 1], c = o.L[K + N], d = o.L[K + N + 1];
    sum = sum + o.amp * (a + (b - a) * fu + (c - a) * fv + (a - b - c + d) * fu * fv);
  }
  out = sum / n.total;
  return true;
}

int lNoise(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  Noise *n = newBox<Noise>(L, "geo.noise");
  readNoise(L, 1, *n);
  return 1;
}

int lFbm(lua_State *L) {
  Noise *n = static_cast<Noise *>(luaL_checkudata(L, 1, "geo.noise"));
  double v;
  if (!fbm(*n, luaL_checknumber(L, 2), luaL_checknumber(L, 3), v))
    return luaL_error(L, "geo.fbm: (%f, %f) is off the noise", lua_tonumber(L, 2), lua_tonumber(L, 3));
  lua_pushnumber(L, v);
  return 1;
}

//--------------------------------------------------------------------------
// Zones (lib/town.lua Town:entry, lib/terrain.lua shapeDist / segDist)
//--------------------------------------------------------------------------

enum { DISC, RECT, STRIP };
struct Shape {
  int kind = STRIP;
  double x = 0, y = 0, r = 0, sx = 0, sy = 0, a = 0, w = 0;
  std::vector<double> pts;
};
struct Centre { double x, y, r, peak; };
struct Zones {
  std::vector<Shape> districts;
  std::vector<Centre> centres;
  std::vector<double> ladderU;
  std::vector<char> ladderD;      // the step's zone is "D"
  bool openD = false;
  bool hasCut = false;
  double cut = 0, x0 = 0, y0 = 0;
  Noise woods;
};

double segDist(double px, double py, double ax, double ay, double bx, double by) {
  double dx = bx - ax, dy = by - ay;
  double L2 = dx * dx + dy * dy;
  double t = L2 > 0 ? luaMax(0, luaMin(1, ((px - ax) * dx + (py - ay) * dy) / L2)) : 0;
  double qx = ax + t * dx - px, qy = ay + t * dy - py;
  return std::sqrt(qx * qx + qy * qy);
}

double shapeDist(const Shape &sh, double x, double y) {
  if (sh.kind == DISC) {
    double dx = x - sh.x, dy = y - sh.y;
    return std::sqrt(dx * dx + dy * dy) - sh.r;
  } else if (sh.kind == RECT) {
    double c = std::cos(sh.a), s = std::sin(sh.a);
    double dx = x - sh.x, dy = y - sh.y;
    double qx = std::fabs(dx * c + dy * s) - sh.sx / 2;
    double qy = std::fabs(-dx * s + dy * c) - sh.sy / 2;
    double ox = luaMax(qx, 0), oy = luaMax(qy, 0);
    return std::sqrt(ox * ox + oy * oy) + luaMin(luaMax(qx, qy), 0);
  }
  const std::vector<double> &p = sh.pts;
  double best = HUGE_VAL;
  for (size_t k = 0; k + 3 < p.size(); k += 2)
    best = luaMin(best, segDist(x, y, p[k], p[k + 1], p[k + 2], p[k + 3]));
  return best - sh.w / 2;
}

bool isD(lua_State *L, int e) {
  lua_getfield(L, e, "lcz");
  const char *s = lua_tostring(L, -1);
  bool d = s != nullptr && std::strcmp(s, "D") == 0;
  lua_pop(L, 1);
  return d;
}

int lZones(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  Zones *z = newBox<Zones>(L, "geo.zones");
  z->x0 = num(L, 1, "x0", 0);
  z->y0 = num(L, 1, "y0", 0);
  lua_getfield(L, 1, "districts");
  int ds = lua_gettop(L);
  for (int k = 1;; k++) {
    lua_rawgeti(L, ds, k);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    lua_getfield(L, -1, "shape");
    int s = lua_gettop(L);
    Shape sh;
    lua_getfield(L, s, "kind");
    const char *kind = lua_tostring(L, -1);
    sh.kind = kind && !std::strcmp(kind, "disc") ? DISC : kind && !std::strcmp(kind, "rect") ? RECT : STRIP;
    lua_pop(L, 1);
    sh.x = num(L, s, "x", 0);
    sh.y = num(L, s, "y", 0);
    sh.r = num(L, s, "r", 0);
    sh.sx = num(L, s, "sx", 0);
    sh.sy = num(L, s, "sy", 0);
    sh.a = num(L, s, "a", 0);
    sh.w = num(L, s, "w", 0);
    if (sh.kind == STRIP) {
      lua_getfield(L, s, "pts");
      sh.pts = nums(L, lua_gettop(L));
      lua_pop(L, 1);
    }
    lua_pop(L, 2);
    z->districts.push_back(sh);
  }
  lua_pop(L, 1);
  lua_getfield(L, 1, "centres");
  int cs = lua_gettop(L);
  for (int k = 1;; k++) {
    lua_rawgeti(L, cs, k);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    int c = lua_gettop(L);
    z->centres.push_back({num(L, c, "x", 0), num(L, c, "y", 0), num(L, c, "r", 1), num(L, c, "peak", 1)});
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_getfield(L, 1, "ladder");
  int ls = lua_gettop(L);
  for (int k = 1;; k++) {
    lua_rawgeti(L, ls, k);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    z->ladderU.push_back(num(L, -1, "u", 0));
    z->ladderD.push_back(isD(L, lua_gettop(L)));
    lua_pop(L, 1);
  }
  lua_pop(L, 1);
  lua_getfield(L, 1, "openEntry");
  z->openD = isD(L, lua_gettop(L));
  lua_pop(L, 1);
  lua_getfield(L, 1, "woodsCut");
  z->hasCut = !lua_isnil(L, -1);
  z->cut = lua_tonumber(L, -1);
  lua_pop(L, 1);
  if (z->hasCut) {
    lua_getfield(L, 1, "woodsNoise");
    readNoise(L, lua_gettop(L), z->woods);
    lua_pop(L, 1);
  }
  return 1;
}

int lZone(lua_State *L) {
  Zones *z = static_cast<Zones *>(luaL_checkudata(L, 1, "geo.zones"));
  double x = luaL_checknumber(L, 2), y = luaL_checknumber(L, 3);
  int nd = (int)z->districts.size();
  for (int k = nd - 1; k >= 0; k--)
    if (shapeDist(z->districts[k], x, y) <= 0) { lua_pushinteger(L, k + 1); return 1; }
  double u = 0;
  for (const Centre &c : z->centres) {
    double d = std::sqrt(sq(x - c.x) + sq(y - c.y));
    u = luaMax(u, c.peak * std::exp(-d / c.r));
  }
  int code = 0;
  bool d = z->openD;
  for (size_t l = 0; l < z->ladderU.size(); l++)
    if (u >= z->ladderU[l]) { code = nd + (int)l + 1; d = z->ladderD[l]; break; }
  if (d && z->hasCut) {
    double f;
    if (!fbm(z->woods, x - z->x0, y - z->y0, f)) return luaL_error(L, "geo.zone: (%f, %f) is off the woods' noise", x, y);
    if (f > z->cut) code = -1;
  }
  lua_pushinteger(L, code);
  return 1;
}

//--------------------------------------------------------------------------
// Meshes (lib/terrain.lua T:toBPP, lib/vegetation.lua V.toBPP)
//--------------------------------------------------------------------------

int lGrid(lua_State *L) {
  Terrain *m = meshArg(L, 1, "grid");
  luaL_checktype(L, 2, LUA_TTABLE);
  int nx = (int)luaL_checknumber(L, 3), ny = (int)luaL_checknumber(L, 4);
  double x0 = luaL_checknumber(L, 5), y0 = luaL_checknumber(L, 6), cell = luaL_checknumber(L, 7);
  double S = luaL_checknumber(L, 8), base = luaL_checknumber(L, 9);
  int s = nx + 1;
  std::vector<btVector3> VX((size_t)s * (ny + 1));
  for (int k = 1; k <= s * (ny + 1); k++) {
    lua_rawgeti(L, 2, k);
    double h = lua_tonumber(L, -1);
    lua_pop(L, 1);
    double i = (k - 1) % s, j = (k - 1) / s;
    double x = x0 + i * cell, y = y0 + j * cell;
    VX[k - 1] = btVector3(btScalar(x * S), btScalar(base + h * S), btScalar(-y * S));
  }
  for (int j = 0; j < ny; j++)
    for (int i = 0; i < nx; i++) {
      int k = j * s + i;           // (the Lua's k - 1)
      m->addTriangle(VX[k], VX[k + 1], VX[k + s + 1]);
      m->addTriangle(VX[k], VX[k + s + 1], VX[k + s]);
    }
  return 0;
}

int lColors(lua_State *L) {
  Terrain *m = meshArg(L, 1, "colors");
  int n = (int)luaL_checknumber(L, 5);
  for (int i = 0; i < n; i++) {
    int c[3];
    for (int q = 0; q < 3; q++) {
      lua_rawgeti(L, 2 + q, i);
      c[q] = (int)std::floor(lua_tonumber(L, -1) + 0.5);
      lua_pop(L, 1);
    }
    m->setTriangleColor(i, c[0], c[1], c[2]);
  }
  return 0;
}

int lWoods(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  Terrain *crowns[3] = {meshArg(L, 2, "woods"), meshArg(L, 3, "woods"), meshArg(L, 4, "woods")};
  Terrain *trunks = meshArg(L, 5, "woods");
  double S = luaL_checknumber(L, 6), base = luaL_checknumber(L, 7), WB = luaL_checknumber(L, 8);
  double C6[6], S6[6], C3[3], S3[3];
  for (int k = 0; k < 6; k++) {
    lua_rawgeti(L, 9, k); C6[k] = lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, 10, k); S6[k] = lua_tonumber(L, -1); lua_pop(L, 1);
  }
  for (int k = 0; k < 3; k++) {
    lua_rawgeti(L, 11, k); C3[k] = lua_tonumber(L, -1); lua_pop(L, 1);
    lua_rawgeti(L, 12, k); S3[k] = lua_tonumber(L, -1); lua_pop(L, 1);
  }
  auto P = [&](double x, double y, double h) {
    return btVector3(btScalar(x * S), btScalar(base + h * S), btScalar(-y * S));
  };
  lua_Integer nc[3] = {0, 0, 0}, nt = 0;
  btVector3 ring[6], lo[3], hi[3];
  for (int i = 1;; i++) {
    lua_rawgeti(L, 1, i);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    int t = lua_gettop(L);
    lua_getfield(L, t, "kind");
    const char *kind = lua_tostring(L, -1);
    bool wood = kind != nullptr && std::strcmp(kind, "wood") == 0;
    lua_pop(L, 1);
    if (wood) {
      int which = i % 3;
      Terrain *cm = crowns[which];
      double x = num(L, t, "x", 0), y = num(L, t, "y", 0), g = num(L, t, "g", 0);
      double h = num(L, t, "h", 0), r = num(L, t, "r", 0);
      double z0 = g + WB * h;
      double zm = z0 + (1 - WB) * h / 3, z1 = g + h;
      for (int k = 0; k < 6; k++) ring[k] = P(x + r * C6[k], y + r * S6[k], zm);
      btVector3 top = P(x, y, z1), bot = P(x, y, z0);
      for (int k = 0; k < 6; k++) {
        int k1 = k < 5 ? k + 1 : 0;
        cm->addTriangle(ring[k], ring[k1], top);
        cm->addTriangle(ring[k1], ring[k], bot);
      }
      nc[which] += 12;
      for (int k = 0; k < 3; k++) {
        lo[k] = P(x + 0.3 * C3[k], y + 0.3 * S3[k], g - 0.3);
        hi[k] = P(x + 0.3 * C3[k], y + 0.3 * S3[k], z0);
      }
      for (int k = 0; k < 3; k++) {
        int k1 = k < 2 ? k + 1 : 0;
        trunks->addTriangle(lo[k], lo[k1], hi[k1]);
        trunks->addTriangle(lo[k], hi[k1], hi[k]);
      }
      nt += 6;
    }
    lua_pop(L, 1);
  }
  // (counted in the Lua's order: crown mesh 1 holds the trees i % 3 == 0)
  for (int q = 0; q < 3; q++) lua_pushinteger(L, nc[q]);
  lua_pushinteger(L, nt);
  return 4;
}

int lMeshHash(lua_State *L) {
  Terrain *m = meshArg(L, 1, "meshHash");
  btBvhTriangleMeshShape *sh =
      m->body ? dynamic_cast<btBvhTriangleMeshShape *>(m->body->getCollisionShape()) : nullptr;
  if (sh == nullptr) return luaL_error(L, "geo.meshHash: the mesh is not built");
  const btStridingMeshInterface *mi = sh->getMeshInterface();
  uint64_t hsh = 1469598103934665603ULL;
  auto mix = [&](const void *p, size_t n) {
    const unsigned char *b = static_cast<const unsigned char *>(p);
    for (size_t q = 0; q < n; q++) { hsh ^= b[q]; hsh *= 1099511628211ULL; }
  };
  long count = 0;
  for (int part = 0; part < mi->getNumSubParts(); part++) {
    const unsigned char *verts, *idx;
    int nv, vstride, istride, ntri;
    PHY_ScalarType vtype, itype;
    mi->getLockedReadOnlyVertexIndexBase(&verts, nv, vtype, vstride, &idx, istride, ntri, itype, part);
    for (int t = 0; t < ntri; t++) {
      const unsigned char *ip = idx + (size_t)t * istride;
      for (int c = 0; c < 3; c++) {
        unsigned int v = itype == PHY_SHORT ? ((const unsigned short *)ip)[c] : ((const unsigned int *)ip)[c];
        const unsigned char *vp = verts + (size_t)v * vstride;
        float f[3];
        for (int q = 0; q < 3; q++)
          f[q] = vtype == PHY_DOUBLE ? (float)((const double *)vp)[q] : ((const float *)vp)[q];
        mix(f, sizeof f);
      }
      count++;
    }
    mi->unLockReadOnlyVertexBase(part);
  }
  char s[17];
  std::snprintf(s, sizeof s, "%016llx", (unsigned long long)hsh);
  lua_pushstring(L, s);
  lua_pushinteger(L, (lua_Integer)count);
  return 2;
}

} // namespace

void Geo::luaBind(lua_State *L) {
  static const struct { const char *name; lua_CFunction f; } fns[] = {
      {"noise", lNoise}, {"fbm", lFbm}, {"zones", lZones}, {"zone", lZone},
      {"grid", lGrid}, {"colors", lColors}, {"woods", lWoods}, {"meshHash", lMeshHash}};
  lua_newtable(L);
  for (const auto &e : fns) {
    lua_pushcfunction(L, e.f);
    lua_setfield(L, -2, e.name);
  }
  lua_setglobal(L, "geo");
}
