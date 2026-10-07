#ifndef GLUTILS_H
#define GLUTILS_H

/**
 * @file glutils.h
 * @brief Immediate-mode OpenGL replacements for the GLUT solid primitives.
 *
 * bpp draws its debug/preview geometry with fixed-function OpenGL but does not
 * link against GLUT, so the handful of @c glutSolid* shapes it needs are
 * reimplemented here. Every function emits vertices, normals and texture
 * coordinates into the currently bound OpenGL context; none of them touch the
 * matrix stack or any render state, so the caller is responsible for
 * positioning and material setup.
 *
 * The texture coordinates follow POV-Ray's @c uv_mapping of the same shape, so
 * an object wearing a texture looks the same here as in an exported render.
 */

#include <QString>

/**
 * @brief Draws an axis-aligned solid cube centred on the origin.
 *
 * The cube is emitted as six textured quads with outward-facing normals.
 *
 * @param sz Edge length of the cube; it extends @c sz/2 along each axis in
 *           both directions.
 */
void solidCube(double sz);

/**
 * @brief The current GL context, for keeping display lists in.
 *
 * Returns nullptr when no context is current. The first time a context is
 * seen, a hook is set so that when it's destroyed glCacheEpoch() changes,
 * which tells anything holding display lists that they have gone with it.
 */
const void *glCacheContext();

/**
 * @brief A number that changes whenever a GL context is destroyed.
 *
 * A display list built when this had one value is only good while it still
 * has that value (and in the same context).
 */
unsigned glCacheEpoch();

/**
 * @brief Whether a display list is being recorded (set around recording one).
 *
 * OpenGL can't start a list while another is being recorded, so while this is
 * set, anything that would make a list of its own draws directly instead (into
 * the list being recorded).
 */
bool glRecordingList();
void glSetRecordingList(bool on);

/**
 * @brief Draws a solid sphere centred on the origin.
 *
 * The surface is tessellated into @p stacks quad strips running from the +Y
 * pole to the -Y pole, each strip subdivided into @p slices segments around
 * the Y axis. Unit-length normals are emitted per vertex.
 *
 * The poles are on Y, rather than on Z like the cylinder and cone, because
 * that is the axis POV-Ray wraps a sphere's texture around: it lets the same
 * image sit the same way up in the interactive view and in a render.
 *
 * @param radius Sphere radius.
 * @param slices Number of subdivisions around the Y axis (longitude).
 * @param stacks Number of subdivisions along the Y axis (latitude).
 */
void solidSphere(double radius, int slices, int stacks);

/**
 * @brief Draws a closed solid cylinder aligned with the Z axis.
 *
 * The cylinder stands on the XY plane and extends from @c z=0 to
 * @c z=height. Both end caps are emitted as triangle fans with outward-facing
 * normals, so the shape is watertight.
 *
 * @param radius Radius of the cylinder.
 * @param height Extent along the +Z axis.
 * @param slices Number of subdivisions around the Z axis.
 * @param stacks Number of segments the side wall is split into along Z.
 */
void solidCylinder(double radius, double height, int slices, int stacks);

/**
 * @brief Draws a closed solid cone aligned with the Z axis.
 *
 * The base sits on the XY plane at @c z=0 and the apex is at @c z=height. The
 * base is closed with a downward-facing triangle fan.
 *
 * @param radius Radius of the cone at its base.
 * @param height Extent along the +Z axis, from base to apex.
 * @param slices Number of subdivisions around the Z axis.
 * @param stacks Number of rings the side wall is split into along Z.
 */
void solidCone(double radius, double height, int slices, int stacks);

/**
 * @brief Loads an image file into an OpenGL texture, once per file.
 *
 * The image is flipped so that its bottom row is the texture's first, which is
 * how POV-Ray reads one too, and kept in a cache shared by every object using
 * the same file. A file that will not load is remembered as a failure, so a
 * missing image costs one attempt rather than one per frame.
 *
 * @param file Absolute path of the image.
 * @return The texture name to bind, or 0 when there is no current GL context
 *         or the image could not be read.
 */
unsigned glTextureFromFile(const QString &file);

#endif
