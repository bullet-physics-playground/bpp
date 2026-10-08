#ifndef OBJECT_H
#define OBJECT_H

/**
 * @file object.h
 * @brief Base class for everything that can be put into a bpp scene.
 */

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QColor>
#include <QTextStream>
#include <iostream>

#include <btBulletDynamicsCommon.h>

#include <qgl.h>

class Object;

/**
 * @brief Writes an object's description and colour to a standard stream.
 * @param ostream The stream to write to.
 * @param obj     The object to describe.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const Object &obj);

/**
 * @brief Compares two objects by identity.
 *
 * Objects are unique bodies in the scene, not comparable by value; this
 * matches luabind's fallback for the Bullet classes registered in
 * @c lua_bullet.cpp.
 *
 * @param a First object.
 * @param b Second object.
 * @return True only if both are the same object.
 */
bool operator==(const Object &a, const Object &b);

/// Builds a single-bit collision mask value.
#define BIT(x) (1 << (x))

/**
 * @brief Collision filter groups an object can belong to and collide with.
 *
 * Bullet filters a pair out unless each body's group appears in the other's
 * mask, so these values are used for both roles.
 */
enum collisiontypes {
  COL_NOTHING = 0,     //<Collide with nothing
  COL_SHIP = BIT(1),   //<Collide with ships
  COL_WALL = BIT(2),   //<Collide with walls
  COL_POWERUP = BIT(3) //<Collide with powerups
};

#include "lua_converters.h" // for Lua QString => string mapping

/**
 * @brief A body in the scene: its physics, its appearance and its export.
 *
 * Object ties a Bullet rigid body and collision shape to the two ways bpp
 * shows it: drawn with OpenGL in the interactive view, and written out as
 * POV-Ray SDL when a frame is exported. Derived classes - Cube, Sphere,
 * Cylinder, Mesh and the rest - supply the shape, the OpenGL geometry and the
 * POV-Ray text; everything shared, including position, mass, friction, colour
 * and transparency, lives here.
 *
 * Almost every setter is a no-op until a rigid body has been attached, since
 * the state lives in Bullet rather than in this object.
 *
 * Both drawing and exporting can be overridden per object without subclassing:
 * setRenderFunction() installs a Lua function called while the object's
 * transform is on the OpenGL matrix stack, and the pre-, main and post-SDL
 * strings replace the corresponding parts of the exported text.
 *
 * @b Ownership is split: a body the object created is deleted with it, while
 * one handed in through setRigidBody() is not. Lua adds a third case: when the
 * Lua state closes it frees the Bullet objects it adopted, so #body and #shape
 * have to be cleared before the C++ destructors run. Viewer::parse() and the
 * Viewer destructor do that themselves, after lua_close(); preDestructor() is
 * called first, to drop this object's own references into the interpreter.
 */
class Object : public QObject {
  Q_OBJECT;

public:
  /**
   * @brief Constructs a grey, exportable object with no body or shape yet.
   * @param parent Parent object, passed through to QObject.
   * @param pmass  Mass. Accepted for the benefit of the Lua constructors but
   *               not used; a derived class sets the mass when it creates the
   *               body.
   */
  Object(QObject *parent = nullptr, btScalar pmass = 0);

  /**
   * @brief Destroys the object, and its rigid body if it owns one.
   */
  virtual ~Object();

  /**
   * @brief Sets the object's colour from its components.
   * @param r Red, 0 to 255.
   * @param g Green, 0 to 255.
   * @param b Blue, 0 to 255.
   */
  void setColor(int r, int g, int b);

  /**
   * @brief Sets the object's colour.
   * @param col The colour; its alpha is ignored, transparency being separate.
   */
  void setColor(const QColor &col);

  /**
   * @brief Sets the object's colour from a name or hex string.
   * @param c Anything QColor accepts, such as @c "red" or @c "#ff8800".
   */
  void setColor(const QString &c);

  /**
   * @brief Returns the object's colour.
   * @return The colour, fully opaque.
   */
  QColor getColor() const;

  /**
   * @brief Returns the object's colour as a hex string.
   * @return The colour in @c "#rrggbb" form.
   */
  QString getColorString() const;

  /**
   * @brief Sets how transparent the object is.
   *
   * 0.0 = fully opaque, 1.0 = fully transparent -- matches POV-Ray's own
   * rgbt transmit channel directly, so povPigment() can pass it straight
   * through with no remapping.
   *
   * @param t The transparency; values outside the range are clamped.
   */
  void setTransparency(btScalar t);

  /**
   * @brief Returns how transparent the object is.
   * @return The transparency, 0.0 for opaque.
   */
  btScalar getTransparency() const;

  /**
   * @brief Moves the object, keeping its orientation.
   * @param x New x position.
   * @param y New y position.
   * @param z New z position.
   */
  void setPosition(btScalar x, btScalar y, btScalar z);

  /**
   * @brief Moves the object, keeping its orientation.
   * @param v The new position.
   */
  void setPosition(const btVector3 &v);

  /**
   * @brief Returns where the object is.
   * @return Its world position, or the origin if it has no body yet.
   */
  btVector3 getPosition() const;

  /**
   * @brief Turns the object to a rotation about an axis.
   * @param axis  Axis to rotate about.
   * @param angle Rotation angle in radians.
   */
  void setRotation(const btVector3 &axis, btScalar angle);

  /**
   * @brief Turns the object to a given orientation.
   * @param rot The new orientation.
   */
  void setRotation(const btQuaternion &rot);

  /**
   * @brief Returns the object's orientation.
   * @return Its rotation, or the identity if it has no body yet.
   */
  btQuaternion getRotation() const;

  /**
   * @brief Places the object at a given position and orientation at once.
   * @param trans The new world transform.
   */
  void setTransform(const btTransform &trans);

  /**
   * @brief Returns the object's position and orientation.
   * @return Its world transform, or the identity if it has no body yet.
   */
  btTransform getTransform() const;

  /**
   * @brief Sets the object's mass and recomputes its inertia.
   *
   * A mass of 0 makes the body static, which is Bullet's convention. Needs
   * both a body and a shape to have any effect.
   *
   * @param mass The new mass.
   */
  virtual void setMass(btScalar mass);

  /**
   * @brief Returns the object's mass.
   *
   * The inverse of setMass(): what was set is what comes back.
   *
   * @return The mass, or 0 for a static body or one with no rigid body yet.
   *         0 is also what setMass() takes to make a body static, so the two
   *         agree on that value.
   */
  btScalar getMass() const;

  /**
   * @brief Sets the object's friction coefficient.
   * @param friction The new friction.
   */
  void setFriction(btScalar friction);

  /**
   * @brief Returns the object's friction coefficient.
   * @return The friction, or 0 if it has no body yet.
   */
  btScalar getFriction() const;

  /**
   * @brief Sets how bouncy the object is.
   * @param restitution The new restitution, 0 for no bounce.
   */
  void setRestitution(btScalar restitution);

  /**
   * @brief Returns how bouncy the object is.
   * @return The restitution, or 0 if it has no body yet.
   */
  btScalar getRestitution() const;

  /**
   * @brief Sets the damping applied to linear motion.
   * @param linearDamping The new linear damping.
   */
  void setLinearDamping(btScalar linearDamping);

  /**
   * @brief Sets the damping applied to rotation.
   * @param angularDamping The new angular damping.
   */
  void setAngularDamping(btScalar angularDamping);

  /**
   * @brief Sets both damping coefficients at once.
   * @param linearDamping  The new linear damping.
   * @param angularDamping The new angular damping.
   */
  void setDamping(btScalar linearDamping, btScalar angularDamping);

  /**
   * @brief Returns the damping applied to linear motion.
   * @return The linear damping, or 0 if the object has no body yet.
   */
  btScalar getLinearDamping() const;

  /**
   * @brief Returns the damping applied to rotation.
   * @return The angular damping, or 0 if the object has no body yet.
   */
  btScalar getAngularDamping() const;

  /**
   * @brief Sets the object's linear velocity outright.
   * @param vector The new velocity.
   */
  void setLinearVelocity(const btVector3 &vector);

  /**
   * @brief Returns the object's linear velocity.
   * @return The velocity, or a zero vector if it has no body yet.
   */
  btVector3 getLinearVelocity() const;

  /**
   * @brief Attaches a rigid body the object does not own.
   *
   * Clears the ownership flag, so the body is not deleted with the object.
   * Used when the body belongs to Lua or to some other structure. When the
   * object is in the dynamics world, the new body takes the old one's place
   * there. A replaced body the object made itself is kept until the object
   * goes (a constraint may still use it).
   *
   * @param b The body to attach.
   */
  void setRigidBody(btRigidBody *b);

  /**
   * @brief Tells the object which dynamics world it is in (null: none).
   *
   * The viewer sets it as it adds the object and clears it as it removes it.
   *
   * @param w The world.
   */
  void setWorld(btDynamicsWorld *w) { _world = w; }

  /**
   * @brief Bodies the object has had and since replaced (see setRigidBody()),
   *        whoever made them; one a constraint joins may still be in the
   *        world. (One the object made is freed with it; a script's is kept
   *        alive by the object until then, see retireLua().)
   * @return The bodies.
   */
  const std::vector<btRigidBody *> &formerBodies() const { return _formerBodies; }

  /**
   * @brief Returns the object's rigid body.
   * @return The body, or null if it has none.
   */
  btRigidBody *getRigidBody() const;

  /**
   * @brief Attaches a collision shape in place of the previous one.
   *
   * A previous shape that a script handed in (see keepLua()) belongs to Lua
   * and is not deleted here. One the object made itself is kept until the
   * object goes (its body may still use it; see retireShape()).
   *
   * @param s The shape to attach. The object takes ownership.
   */
  void setCollisionShape(btCollisionShape *s);

  /**
   * @brief Slots for the Lua objects an object keeps alive (see keepLua()).
   */
  enum LuaKeepSlot { KEEP_BODY = 0, KEEP_SHAPE = 1, KEEP_MESH = 2, KEEP_SLOTS = 3 };

  /**
   * @brief Keeps a script's Bullet object alive while this object uses it.
   *
   * A script can build its own body, shape or triangle mesh and hand it to an
   * object (obj.body = body, obj.shape = shape, mesh.mesh = triangles). Lua
   * still owns it, and only a raw pointer is kept here, so without a
   * reference from this object Lua's garbage collector could free it while
   * the scene still uses it. This holds that reference (replacing whatever
   * the slot held), until the object is torn down (preDestructor()).
   *
   * @param slot Which of the object's parts it is.
   * @param o The Lua value handed in (nil releases the slot).
   */
  void keepLua(LuaKeepSlot slot, const luabind::object &o);

  /**
   * @brief Keeps the Lua value in a slot alive until teardown, even after the
   * slot is reused.
   *
   * Called when a script hands in a replacement while the old value is still
   * in use: a body still in the dynamics world, or a shape the object's body
   * still uses. Without it, the replacement would release the last reference
   * and the collector could free what Bullet still points at.
   *
   * @param slot Which of the object's parts it is.
   */
  void retireLua(LuaKeepSlot slot);

  /**
   * @brief Records whether the current shape came from a script (Lua owns it).
   * @param fromLua True when a script handed the shape in.
   */
  void setShapeFromLua(bool fromLua) { _shapeFromLua = fromLua; }

  /**
   * @brief Returns the object's collision shape.
   * @return The shape, or null if it has none.
   */
  btCollisionShape *getCollisionShape() const;

  // POV-Ray properties

  /**
   * @brief Sets whether the object takes part in photon mapping.
   * @param _photons_enable     Whether to emit a photons block at all.
   * @param _photons_reflection Whether photons reflect off the object.
   * @param _photons_refraction Whether photons refract through it.
   */
  void setPovPhotons(bool _photons_enable = false,
                     bool _photons_reflection = false,
                     bool _photons_refraction = false);

  /**
   * @brief Builds the POV-Ray photons block for this object.
   * @return The SDL text, or an empty string when photons are disabled.
   */
  virtual QString getPovPhotons() const;

  /**
   * @brief Sets whether the object appears in exported POV-Ray scenes.
   * @param onoff True to export it. On by default.
   */
  void setPOVExport(bool onoff);

  /**
   * @brief Returns whether the object appears in exported POV-Ray scenes.
   * @return True if it is exported.
   */
  bool getPOVExport() const;

  /**
   * @brief Replaces the opening line of the object's exported SDL.
   *
   * Lets a script substitute its own POV-Ray object for the shape bpp would
   * otherwise emit, while still getting the transform matrix written for it.
   *
   * @param pre_sdl The SDL to emit in place of the default opening.
   */
  void setPreSDL(const QString &pre_sdl);

  /**
   * @brief Returns the replacement opening SDL.
   * @return The text, or a null string when the default is used.
   */
  QString getPreSDL() const;

  /**
   * @brief Wraps an image file round the object.
   *
   * The image is drawn on the object in the interactive view, and exported as
   * a POV-Ray @c image_map so that a render shows the same picture in the same
   * place. It replaces the object's colour rather than tinting it, as an
   * @c image_map replaces a pigment; #setSDL() still overrides both.
   *
   * The file is looked for beside the script first and then in bpp's own
   * @c includes directory, which is also where POV-Ray looks, so a bare name
   * such as @c "ball8.jpeg" finds the same image in the view and in a render.
   *
   * @param file Image file to use, or an empty string to go back to the
   *             object's colour.
   */
  void setTexture(const QString &file);

  /**
   * @brief Returns the image file wrapped round the object.
   * @return The file, as it was given to setTexture(), or an empty string when
   *         the object has no texture.
   */
  QString getTexture() const;

  /**
   * @brief Replaces the object's exported surface description.
   *
   * Used instead of the pigment line povPigment() would otherwise write, so a
   * script can give the object a texture or finish of its own.
   *
   * @param sdl The SDL to emit in place of the default pigment.
   */
  void setSDL(const QString &sdl);

  /**
   * @brief Returns the replacement surface SDL.
   * @return The text, or a null string when the default is used.
   */
  QString getSDL() const;

  /**
   * @brief Replaces the closing line of the object's exported SDL.
   * @param post_sdl The SDL to emit in place of the closing brace.
   */
  void setPostSDL(const QString &post_sdl);

  /**
   * @brief Returns the replacement closing SDL.
   * @return The text, or a null string when the default is used.
   */
  QString getPostSDL() const;

  btRigidBody *body;      ///< The Bullet body, or null. Public because the
                          ///< viewer adds and removes it from the world.
  btCollisionShape *shape; ///< The Bullet collision shape, or null.
  bool _ownsBody;         ///< True when #body is deleted with this object.

  /**
   * @brief Registers the Object class with a Lua state.
   *
   * Exposes the colour, transform, physics and POV-Ray properties, so a script
   * can build and adjust objects directly.
   *
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Object"; derived classes return their own name,
   *         which is also how a few places recognise a particular type.
   */
  virtual QString toString() const;

  /**
   * @brief Writes the object to a POV-Ray scene as SDL.
   *
   * Emits the opening shape, the surface description and the object's current
   * transform as a POV-Ray matrix. Each of the three parts is replaced by the
   * corresponding pre-, main or post-SDL string when one was set. The base
   * class emits a unit sphere, so a derived class that does not override this
   * still exports as something visible.
   *
   * @param s The stream to write to. A null stream writes nothing, but the
   *          transform is still refreshed.
   */
  virtual void toPOV(QTextStream *s) const;

  /**
   * @brief Returns the object's POV-Ray SDL as a string.
   * @return The same text toPOV(QTextStream*) would write.
   */
  virtual QString toPOV() const;

  /**
   * @brief Draws the object in the interactive view.
   *
   * Sets up the object's transform and render state, draws it, and restores
   * what it changed. Does nothing for an object with no rigid body.
   *
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void render(btVector3 &minaabb, btVector3 &maxaabb);

  /**
   * @brief Installs a Lua function that draws alongside the object.
   *
   * Called with the object while its transform is on the matrix stack, so a
   * script can draw in the object's own frame.
   *
   * @param fn The Lua function. Ignored if it is not a function.
   */
  void setRenderFunction(const luabind::object &fn);

  /**
   * @brief Returns the Lua draw function, if one was installed.
   * @return The function, or an invalid object.
   */
  luabind::object getRenderFunction() const;

  /**
   * @brief Whether a script draws something of its own with the object (see
   *        setRenderFunction()), which may reach beyond the object's shape.
   * @return True if it does.
   */
  bool hasRenderFunction() const { return bool(_cb_render); }

  /**
   * @brief How far what the object draws is shifted from its collision shape,
   *        in its own frame (see Mesh: it draws its file's vertices, while its
   *        shape is moved to put the centre of mass at the origin).
   * @return The shift.
   */
  virtual btVector3 drawnOffset() const { return btVector3(0, 0, 0); }

  bool drawOnScreen = true;  ///< Set each frame by Viewer::cullObjects().
  bool drawInShadow = true;  ///< Set each frame by Viewer::cullObjects().
  bool shadowListed = false; ///< In the shadow map's record of still objects
                             ///< (set each frame by Viewer::renderShadowDepth()).
  quint64 shadowHash = 0;    ///< Where and what it was last frame (the same).
  unsigned shadowStill = 0;  ///< Frames it has stayed so (the same).

  /**
   * @brief Draws the object's geometry in its own frame.
   *
   * This is what a derived class overrides to draw its shape. The base class
   * draws a unit sphere.
   *
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  virtual void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb);

  /**
   * @brief Sets up the matrix stack and render state before drawing.
   *
   * Pushes the object's world transform, enables normal rescaling, turns on
   * alpha blending for a transparent object - with depth writes off, so it
   * does not occlude what is behind it - and runs the Lua draw function.
   * Skipped entirely if the scene bounding box is not finite.
   *
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  virtual void renderInLocalFramePre(btVector3 &minaabb, btVector3 &maxaabb);

  /**
   * @brief Restores the matrix stack and render state after drawing.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  virtual void renderInLocalFramePost(btVector3 &minaabb, btVector3 &maxaabb);

  /**
   * @brief Returns the constraints this object brought with it.
   *
   * The viewer adds them to the dynamics world when the object is added.
   *
   * @return The constraints; empty for most objects.
   */
  QList<btTypedConstraint *> getConstraints() const;

  /**
   * @brief Sets which collision groups the object is in and collides with.
   * @param col1 The group the object belongs to.
   * @param col2 The groups it collides with.
   */
  void setCollisionTypes(collisiontypes col1, collisiontypes col2);

  /**
   * @brief Returns the collision group the object belongs to.
   * @return Its group.
   */
  collisiontypes getCol1() const;

  /**
   * @brief Whether the object takes part in collision detection at all.
   * Setting false (before the object is added to the world) puts it in no
   * collision group, so nothing is ever tested against it -- for objects
   * that are only for show. Lua property: collides.
   */
  void setCollides(bool on);
  bool getCollides() const;

  /**
   * @brief Returns the collision groups the object collides with.
   * @return Its mask.
   */
  collisiontypes getCol2() const;

  /**
   * @brief Converts an OpenGL transform matrix to POV-Ray's convention.
   *
   * POV-Ray is left-handed where OpenGL is right-handed, so the z axis is
   * negated. The two may be the same array, which is how the callers use it.
   *
   * @param[in]  gl  The 4x4 OpenGL matrix, column-major.
   * @param[out] pov Receives the POV-Ray matrix.
   */
  static void povMatrixFromGL(const float *gl, float *pov);

protected:
  // Shared by every derived object's toPOV()/renderInLocalFrame(): writes
  // the standard "pigment { rgbt <r,g,b,t> }" line (used whenever there's
  // no custom .sdl override) and applies color+alpha as the current GL
  // color, respectively -- centralizing these means transparency support
  // doesn't have to be re-implemented in each of the ~10 primitive types.
  /**
   * @brief Writes the object's colour as a POV-Ray pigment line.
   *
   * Emits @c "pigment { rgbt <r,g,b,t> }" with the components scaled to 0..1.
   *
   * @param s The stream to write to; a null stream writes nothing.
   */
  virtual void povPigment(QTextStream *s) const;

  /**
   * @brief Writes the object's texture as a POV-Ray @c image_map pigment.
   *
   * The shapes differ only in how the image is laid on them, so each passes
   * its own mapping in and this writes the rest: the file name, the
   * interpolation, and the object's transparency as a transmit value.
   *
   * @param s          The stream to write to.
   * @param pigmentPre Text inside the pigment, before the @c image_map:
   *                   @c "uv_mapping" for a shape POV-Ray can unwrap by
   *                   itself, empty otherwise.
   * @param mapOpts    Options inside the @c image_map, such as
   *                   @c "map_type 2" for a cylindrical wrap.
   * @param xform      A transformation applied to the pigment, or empty.
   */
  void povImageMap(QTextStream *s, const QString &pigmentPre,
                   const QString &mapOpts, const QString &xform) const;

  /**
   * @brief Writes the object's texture wrapped round its Z axis.
   *
   * For the shapes POV-Ray cannot unwrap by itself. Its cylindrical
   * @c map_type goes once round the Y axis and spans Y from 0 to 1, so the
   * image is stretched to the shape's length, centred on the origin the way
   * the exported geometry is, and turned onto the Z axis the shape stands on.
   * That makes it go round once and along once, as the interactive view's
   * texture coordinates do.
   *
   * @param s      The stream to write to.
   * @param length Extent of the shape along its axis.
   */
  void povAxialImageMap(QTextStream *s, btScalar length) const;

  /**
   * @brief Makes the object's colour and opacity the current OpenGL colour.
   */
  void glApplyColor() const;

  unsigned char color[3];  ///< The object's colour, as red, green and blue.
  btScalar transparency;   ///< 0.0 for opaque, 1.0 for fully transparent.

  bool photons_enable;     ///< Whether to emit a POV-Ray photons block.
  bool photons_reflection; ///< Whether photons reflect off the object.
  bool photons_refraction; ///< Whether photons refract through it.

  QString mTexture;     ///< Image file wrapped round the object, as given to
                        ///< setTexture(), and as written into exported SDL.
  QString mTextureFile; ///< #mTexture resolved to a path on disk, for the
                        ///< interactive view. Empty when it was not found.
  mutable bool mTextureBound; ///< True between renderInLocalFramePre() and
                        ///< renderInLocalFramePost() while the texture is
                        ///< actually bound, so the colour and the teardown
                        ///< agree about whether there is one.
  bool mPOVExport;   ///< Whether the object appears in exported scenes.
  QString mPreSDL;   ///< Replacement opening SDL, or null.
  QString mSDL;      ///< Replacement surface SDL, or null.
  QString mPostSDL;  ///< Replacement closing SDL, or null.

  QList<btTypedConstraint *> _constraints; ///< Constraints handed to the
                                           ///< viewer when the object is added.

  collisiontypes col1; ///< The collision group the object belongs to.
  collisiontypes col2; ///< The collision groups it collides with.

  luabind::object _cb_render; ///< Lua function drawn alongside the object.

  mutable GLfloat matrix[16]; ///< Scratch transform, reused by the draw and
                              ///< export paths.

  luabind::object _luaKeep[KEEP_SLOTS]; ///< Script-made Bullet objects this
                                        ///< object uses (see keepLua()).
  std::vector<luabind::object> _luaRetired; ///< Replaced ones still in use
                                            ///< (see retireLua()).
  bool _shapeFromLua = false;           ///< True when #shape belongs to Lua.
  btDynamicsWorld *_world = nullptr;    ///< The world it is in (see setWorld()).
  std::vector<btRigidBody *> _retiredBodies; ///< Replaced bodies it made itself.
  std::vector<btRigidBody *> _formerBodies;  ///< Every body it has replaced.
  std::vector<btCollisionShape *> _retiredShapes; ///< Replaced shapes it made
                                                  ///< itself.

  /**
   * @brief Keeps a replaced shape the object made itself until the object
   *        goes, instead of deleting it while a body may still use it.
   * @param s The shape.
   */
  void retireShape(btCollisionShape *s) { _retiredShapes.push_back(s); }

  /**
   * @brief Deletes the shape and motion state a built-in object made itself.
   *
   * For the destructors and shape setters of Cube, Sphere and the rest: a
   * shape a script handed in belongs to Lua, and so does the motion state of
   * a body a script handed in, so neither is deleted here.
   *
   * @param motionStateToo Also delete the body's motion state (destructors).
   */
  void deleteOwnShape(bool motionStateToo);

public:
  /**
   * @brief Releases the object's reference to the Lua draw function.
   *
   * Called before the Lua state is closed, so that no destructor afterwards
   * touches the closed interpreter.
   */
  void preDestructor();
};

#endif // OBJECT_H
