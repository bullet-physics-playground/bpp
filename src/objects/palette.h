#ifndef PALETTE_H
#define PALETTE_H

/**
 * @file palette.h
 * @brief A set of colours loaded from a file, sampled at random.
 */

#include "object.h"

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QColor>
#include <QList>
#include <QObject>
#include <QRandomGenerator>

class Palette;

/**
 * @brief Writes a palette's description to a standard stream.
 * @param ostream The stream to write to.
 * @param pal     The palette to describe.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const Palette &pal);

/**
 * @brief A list of colours read from a file, handed out at random.
 *
 * Lets a script colour a crowd of objects from a chosen scheme rather than at
 * random across the whole colour space. The file is read line by line and any
 * line containing exactly three integers is taken as one RGB colour, which
 * accepts the usual GIMP @c .gpl palette files as well as plain lists.
 *
 * The generator is seeded with a fixed value, so the same palette produces the
 * same sequence on every run unless setSeed() says otherwise; that is what
 * keeps a scene reproducible.
 */
class Palette : public QObject {
  Q_OBJECT;

public:
  /**
   * @brief Loads a palette from a file.
   *
   * A file that cannot be read leaves the palette empty.
   *
   * @param fileName Path of the palette file.
   */
  Palette(QString fileName);

  /**
   * @brief Destroys the palette.
   */
  ~Palette();

  /**
   * @brief Picks a colour from the palette at random.
   * @return One of the loaded colours.
   */
  QColor getRandomColor();

  /**
   * @brief Reseeds the random generator, restarting the sequence.
   * @param seed The new seed.
   */
  void setSeed(int seed);

  /**
   * @brief Registers the Palette class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Palette".
   */
  virtual QString toString() const;

protected:
  QList<unsigned char> colors[3]; ///< Red, green and blue components, one
                                  ///< list per channel and one entry per
                                  ///< colour.
  QRandomGenerator rg;            ///< Picks the colours; seeded so runs are
                                  ///< reproducible.
};

#endif // PALETTE_H
