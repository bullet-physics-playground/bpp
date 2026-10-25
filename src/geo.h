#ifndef GEO_H
#define GEO_H

/**
 * @file geo.h
 * @brief geo: compiled helpers for the ArtificialPhysics world generator
 * (demo/WyomingWill/ArtificialPhysics/lib), for Lua.
 *
 * A Lua table `geo` of plain functions doing what the generator's hottest
 * Lua does -- its noise, its zone lookup and the drawing of its biggest
 * meshes -- with the same arithmetic in the same order, so a world is the
 * same, bit for bit, with or without them. The generator uses them when
 * they are there (inside bpp) and its own Lua otherwise (plain lua).
 */

struct lua_State;

class Geo {
public:
  /**
   * @brief Registers the global table `geo` in a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);
};

#endif // GEO_H
