#ifndef SHADOWMAP_H
#define SHADOWMAP_H

/**
 * @file shadowmap.h
 * @brief Shadow mapping for the interactive OpenGL view.
 *
 * The scene is drawn with fixed-function OpenGL (see glutils.h), which has no
 * way of telling a lit surface from a shadowed one. ShadowMap adds that in two
 * extra steps around the normal draw:
 *
 *  1. renderDepthBegin() / renderDepthEnd() render the scene's depth, and
 *     nothing else, from the light's point of view into an off-screen depth
 *     texture.
 *  2. bind() / release() wrap the real draw in a small GLSL program that
 *     reproduces what the fixed-function pipeline was doing -- two lights,
 *     @c glColorMaterial colours, a modulated texture on unit 0 -- and looks
 *     the fragment up in that depth texture to decide whether light 0 reaches
 *     it.
 *
 * Everything the shader needs about the scene's materials it reads from
 * fixed-function state (@c gl_LightSource, @c gl_FrontMaterial, @c gl_Color),
 * so the objects themselves still draw exactly as they always did. The one
 * thing GLSL cannot see is whether @c GL_TEXTURE_2D is enabled, so an object
 * binding a texture says so through glSceneShaderTextured().
 *
 * All of the GL resources are created on first use in whatever context is
 * current, and dropped again when that context goes away (tracked through
 * glCacheEpoch(), the same way glutils.h's display lists are).
 */

#include <QMatrix4x4>

#include <LinearMath/btVector3.h>

class QOpenGLShaderProgram;

/**
 * @brief Tells the scene shader whether texture unit 0 holds a texture.
 *
 * The shader modulates its lit colour by that texture when told to, which is
 * what the fixed-function @c GL_MODULATE texture environment did. A no-op
 * while no ShadowMap shader is bound, so object code can call it
 * unconditionally.
 *
 * @param on True once a texture is bound and @c GL_TEXTURE_2D enabled, false
 *           once it is unbound again.
 */
void glSceneShaderTextured(bool on);

/**
 * @brief An off-screen depth map of the scene as the light sees it.
 *
 * One instance belongs to the Viewer and lives as long as it does; the GL
 * objects inside come and go with the GL context.
 */
class ShadowMap {
public:
  ShadowMap();
  ~ShadowMap();

  /**
   * @brief Creates the depth texture, framebuffer and shader if needed.
   *
   * Safe to call every frame: the work happens once per GL context. A context
   * that cannot provide one of the three (no framebuffer objects, no depth
   * textures, a shader that will not compile) is remembered as unusable, so
   * the failure costs one attempt rather than one per frame.
   *
   * @return True when shadows can be drawn in the current context.
   */
  bool isAvailable();

  /**
   * @brief Resolution of the (square) depth texture, in pixels.
   *
   * Bigger is sharper and slower; the default is 2048. Changing it drops the
   * old texture, which is rebuilt on the next isAvailable().
   */
  void setMapSize(int px);
  int mapSize() const; ///< @see setMapSize()

  /**
   * @brief How far outside its own texel a shadow test looks, in texels.
   *
   * The shadow lookup is averaged over a 3x3 pattern this many texels apart,
   * which is what softens the shadow edge. 0 gives a hard, aliased edge.
   */
  void setSoftness(double texels);
  double softness() const; ///< @see setSoftness()

  /**
   * @brief How much of light 0 a shadow takes away, from 0 to 1.
   *
   * The default, 1, removes all of its diffuse and specular contribution,
   * which is what a blocked light means; the ambient terms and the unshadowed
   * fill light are what keep a shadow from being black. Lower it to lift the
   * shadows in a scene whose lighting leaves them too heavy.
   */
  void setDarkness(double d);
  double darkness() const; ///< @see setDarkness()

  /**
   * @brief Points the light at the scene and starts the depth-only pass.
   *
   * Replaces the projection and modelview matrices with the light's and binds
   * the off-screen framebuffer, so whatever the caller draws next lands in the
   * depth texture. The caller must draw its shadow casters with no model
   * matrix of its own on the stack beyond the per-object ones, and must call
   * renderDepthEnd() afterwards even if it draws nothing.
   *
   * The light is treated as directional -- only the direction from the scene
   * centre towards @p lightPos matters -- and the depth map covers a box
   * fitted to the scene's bounding sphere, so every object casts and receives
   * at the same resolution wherever it is.
   *
   * @param lightPos    The light's homogeneous position, as handed to
   *                    @c glLightfv(GL_POSITION): @c w of 0 means a direction.
   * @param sceneCenter Centre of the scene's bounding sphere, in world space.
   * @param sceneRadius Radius of that sphere. A radius of 0 or less has
   *                    nothing to fit around, and the pass is skipped.
   * @return True when the pass started; false when shadows are unavailable or
   *         the scene is empty, in which case renderDepthEnd() must not be
   *         called.
   */
  bool renderDepthBegin(const btVector4 &lightPos, const btVector3 &sceneCenter,
                        double sceneRadius);

  /**
   * @brief Ends the depth pass and restores the previous GL state.
   *
   * Puts back the framebuffer binding, viewport and both matrices that
   * renderDepthBegin() took over.
   */
  void renderDepthEnd();

  /**
   * @brief Whether a saved depth map (saveDepth()) can stand in for this
   *        pass's: there is one, and it was made from the same light and the
   *        same fit around the scene as the pass just begun.
   * @return True if restoreDepth() would give the right depths.
   */
  bool savedDepthFits() const;

  /**
   * @brief Whether this pass's light and fit around the scene are the same
   *        as the last ten passes' (worth saving the depth for: one that
   *        keeps changing would have it saved and never used).
   * @return True if they are.
   */
  bool lightSteady() const;

  /**
   * @brief Whether saveDepth() can work here (false once the GL context has
   *        refused the second depth map it needs).
   * @return True if it can.
   */
  bool canSaveDepth() const;

  /**
   * @brief Saves the depth drawn so far in this pass, for restoreDepth() to
   *        put back on a later frame. Call between renderDepthBegin() and
   *        renderDepthEnd().
   * @return True if it was saved.
   */
  bool saveDepth();

  /**
   * @brief Puts back the depth saved by saveDepth() in place of this pass's
   *        (call between renderDepthBegin() and renderDepthEnd(), before
   *        drawing anything more into it; only when savedDepthFits()).
   */
  void restoreDepth();

  /**
   * @brief Binds the lighting shader and the depth map for the visible pass.
   *
   * @param cameraModelView The camera's own view matrix, column-major as
   *                        OpenGL stores it, without any object transform.
   *                        The shader needs it to get from the eye space the
   *                        vertex shader works in back out to the light's.
   * @return True when the shader is bound, in which case release() must be
   *         called once the objects are drawn.
   */
  bool bind(const double cameraModelView[16]);

  /**
   * @brief Unbinds the shader and the depth map bound by bind().
   */
  void release();

private:
  /// Builds the GL objects in the current context. @return True on success.
  bool create();
  /// Deletes them again, if the context they live in is still current.
  void destroy();

  int _size;         ///< Depth texture resolution, @see setMapSize().
  double _softness;  ///< PCF radius in texels, @see setSoftness().
  double _darkness;  ///< Shadow strength, @see setDarkness().

  unsigned _tex;     ///< The depth texture, or 0 when there is none.
  unsigned _fbo;     ///< Framebuffer the depth texture is attached to.
  QOpenGLShaderProgram *_prog; ///< The lighting plus shadow shader.

  const void *_ctx;  ///< Context the objects above belong to, @see create().
  unsigned _epoch;   ///< glCacheEpoch() when they were made.
  bool _failed;      ///< Set once creation failed, so it is not retried.

  /// bias * lightProjection * lightView, filled in by renderDepthBegin().
  QMatrix4x4 _lightMatrix;
  /// Whether the last renderDepthBegin() produced a usable depth map.
  bool _haveDepth;
  /// Set by setMapSize() when the texture needs rebuilding at the new size,
  /// which only the render thread can do; cleared by isAvailable().
  bool _sizeDirty;

  unsigned _savedTex;  ///< A copy of a depth map, @see saveDepth().
  unsigned _savedTexFbo; ///< Framebuffer it is attached to (to copy from).
  bool _haveSaved;     ///< Whether _savedTex holds a saved depth map.
  QMatrix4x4 _savedMatrix; ///< The light matrix it was made with.
  QMatrix4x4 _lastMatrix;  ///< The light matrix of the pass before this one.
  int _steadyFrames = 0;   ///< Passes the light matrix has stayed the same.
  bool _saveFailed = false; ///< @see canSaveDepth().

  int _savedViewport[4]; ///< Viewport renderDepthBegin() replaced.
  int _savedFbo;         ///< Framebuffer binding it replaced.
};

#endif
