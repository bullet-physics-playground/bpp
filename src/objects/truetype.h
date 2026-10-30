#ifndef TRUETYPE_H
#define TRUETYPE_H

/**
 * @file truetype.h
 * @brief TrueType text primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <QString>

/**
 * @brief Text rendered with a TrueType font.
 *
 * Backed by a Bullet btBoxShape approximation for collision. Exports as a
 * POV-Ray @c text with a @c ttf font.
 */
class TrueType : public Object {
public:
  /**
   * @brief Constructs TrueType text.
   * @param font  Path to a TrueType font file.
   * @param text  The text string.
   * @param size  Character height.
   * @param mass  Mass; 0 makes it static.
   */
  TrueType(const QString &font = "", const QString &text = "Text",
           btScalar size = 1.0, btScalar mass = 1.0);

  /** @brief Destroys the TrueType object. */
  ~TrueType();

  /** @brief Sets the font file path. */
  void setFont(const QString &font) { m_font = font; }

  /** @brief Returns the font file path. */
  QString getFont() const { return m_font; }

  /** @brief Sets the text string. */
  void setText(const QString &text) { m_text = text; }

  /** @brief Returns the text string. */
  QString getText() const { return m_text; }

  /** @brief Sets the character height. */
  void setSize(btScalar size) { m_size = size; }

  /** @brief Returns the character height. */
  btScalar getSize() const { return m_size; }

  /**
   * @brief Registers the TrueType class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the text to a POV-Ray scene as a @c text. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the text as a solid box. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  QString m_font;   ///< Font file path.
  QString m_text;   ///< Text string.
  btScalar m_size;  ///< Character height.
};

#endif // TRUETYPE_H
