#ifndef GLUTILS_H
#define GLUTILS_H

/**
 * @file glutils.h
 * @brief Immediate-mode OpenGL replacements for the GLUT solid primitives.
 *
 * bpp draws its debug/preview geometry with fixed-function OpenGL but does not
 * link against GLUT, so the handful of @c glutSolid* shapes it needs are
 * reimplemented here. Every function emits vertices, normals and (for the cube)
 * texture coordinates into the currently bound OpenGL context; none of them
 * touch the matrix stack or any render state, so the caller is responsible for
 * positioning and material setup.
 */

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
 * @brief Draws a solid sphere centred on the origin.
 *
 * The surface is tessellated into @p stacks quad strips running from the +Z
 * pole to the -Z pole, each strip subdivided into @p slices segments around
 * the Z axis. Unit-length normals are emitted per vertex.
 *
 * @param radius Sphere radius.
 * @param slices Number of subdivisions around the Z axis (longitude).
 * @param stacks Number of subdivisions along the Z axis (latitude).
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

#endif
