/*************************************************
*  LuaGL - an OpenGL binding for Lua
*  2003-2004(c) Fabio Guerra, Cleyde Marlyse
*  http://luagl.sourceforge.net
*-------------------------------------------------
*  Description: This file implements the OpenGL
*               binding for Lua 5
*-------------------------------------------------
* Mantained by Antonio Scuri since 2009
*-------------------------------------------------
*  See Copyright Notice in LuaGL.h
*************************************************/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#endif
#if defined (__APPLE__) || defined (OSX)
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

#include <lua.h>
#include <lauxlib.h>

#include "luagl.h"
#include "luagl_util.h"
#include "luagl_const.h"


#define LUAGL_VERSION "1.8"


/*Accum (op, value) -> none*/
static int luagl_accum(lua_State *L)
{
  glAccum(luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*AlphaFunc (func, ref) -> none*/
static int luagl_alpha_func(lua_State *L)
{
  glAlphaFunc(luagl_get_gl_enum(L, 1), (GLclampf)luaL_checknumber(L, 2));
  return 0;
}

/*AreTexturesResident (texturesArray) -> residences*/
static int luagl_are_textures_resident(lua_State *L)
{
  GLboolean *residences;
  GLuint *textures;
  int n;

  n = luagl_get_arrayui(L, 1, &textures);

  residences = LUAGL_NEW_ARRAY(GLboolean, n);

  glAreTexturesResident(n, textures, residences);

  luagl_push_arrayb(L, residences, n);

  LUAGL_DELETE_ARRAY(textures);
  LUAGL_DELETE_ARRAY(residences);
  return 1;
}

/*ArrayElement (i) -> none*/
static int luagl_array_element(lua_State *L)
{
  glArrayElement(luaL_checkinteger(L, 1));
  return 0;
}

/*Begin (mode) -> none*/
static int luagl_begin(lua_State *L)
{
  glBegin(luagl_get_gl_enum(L, 1));
  return 0;
}

/*BindTexture (target, texture) -> none*/
static int luagl_bind_texture(lua_State *L)
{
  glBindTexture(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2));
  return 0;
}

/*Bitmap (xorig, yorig, xmove, ymove, bitmapArray) -> none*/
static int luagl_bitmap(lua_State *L)
{
  int width = 0, height = 0;
  GLubyte *bitmap = NULL;

  /* if no bitmap passed usefull to move raster pos */
  if (lua_istable(L,5))
  {
    height = luagl_get_array2uc(L, 5, &bitmap, &width);
    if (height==-1)
      luaL_argerror(L, 5, "must be a table of tables");
  }

  glBitmap(width, height, (GLfloat)luaL_checknumber(L, 1), (GLfloat)luaL_checknumber(L, 2),
           (GLfloat)luaL_checknumber(L, 3), (GLfloat)luaL_checknumber(L, 4), bitmap);

  LUAGL_DELETE_ARRAY(bitmap);
  return 0;
}

/*BitmapRaw (width, height, xorig, yorig, xmove, ymove, bitmap) -> none*/
static int luagl_bitmap_raw(lua_State *L)
{
  glBitmap(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), (GLfloat)luaL_checknumber(L, 3), 
           (GLfloat)luaL_checknumber(L, 4), (GLfloat)luaL_checknumber(L, 5), 
           (GLfloat)luaL_checknumber(L, 6), luagl_checkuserdata(L, 7));
  return 0;
}

/*BlendFunc (sfactor, dfactor) -> none*/
static int luagl_blend_func(lua_State *L)
{
  glBlendFunc(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));
  return 0;
}

/*CallList (list) -> none*/
static int luagl_call_list(lua_State *L)
{
  glCallList(luaL_checkinteger(L, 1));
  return 0;
}

/*CallLists (listArray) -> none*/
static int luagl_call_lists(lua_State *L)
{
  GLsizei n;
  GLfloat *lists;

  n = luagl_get_arrayf(L, 1, &lists);

  glCallLists(n, GL_FLOAT, lists);

  LUAGL_DELETE_ARRAY(lists);
  return 0;
}

/*Clear (mask) -> none*/
static int luagl_clear(lua_State *L)
{
  glClear(luagl_get_gl_enum(L, 1));
  return 0;
}

/*ClearAccum (red, green, blue, alpha) -> none*/
static int luagl_clear_accum(lua_State *L)
{
  glClearAccum((GLfloat)luaL_checknumber(L, 1), (GLfloat)luaL_checknumber(L, 2),
               (GLfloat)luaL_checknumber(L, 3), (GLfloat)luaL_checknumber(L, 4));
  return 0;
}

/*ClearColor (red, green, blue, alpha) -> none*/
static int luagl_clear_color(lua_State *L)
{
  glClearColor((GLclampf)luaL_checknumber(L, 1), (GLclampf)luaL_checknumber(L, 2),
               (GLclampf)luaL_checknumber(L, 3), (GLclampf)luaL_checknumber(L, 4));
  return 0;
}

/*ClearDepth (depth) -> none*/
static int luagl_clear_depth(lua_State *L)
{
  glClearDepth((GLclampd)luaL_checknumber(L, 1));
  return 0;
}

/*ClearIndex (c) -> none*/
static int luagl_clear_index(lua_State *L)
{
  glClearIndex((GLfloat)luaL_checknumber(L, 1));
  return 0;
}

/*ClearStencil (s) -> none*/
static int luagl_clear_stencil(lua_State *L)
{
  glClearStencil(luaL_checkinteger(L, 1));
  return 0;
}

/*ClipPlane (plane, equationArray) -> none*/
static int luagl_clip_plane(lua_State *L)
{
  GLdouble *equation;

  luagl_get_arrayd(L, 2, &equation);

  glClipPlane(luagl_get_gl_enum(L, 1), equation);

  LUAGL_DELETE_ARRAY(equation);
  return 0;
}

/*Color (red, green, blue [, alpha]) -> none
  Color (color) -> none*/
static int luagl_color(lua_State *L)
{
  if (lua_istable(L, 1))
  {
    GLdouble *parray = NULL;
    int n;

    n = luagl_get_arrayd(L, 1, &parray);
    if (n < 3)
    {
      LUAGL_DELETE_ARRAY(parray);
      luaL_argerror(L, 1, "invalid number of items in table (n<3).");
    }

    switch(n)
    {
    case 3:  glColor3dv(parray); break;
    case 4:  glColor4dv(parray); break;
    }

    LUAGL_DELETE_ARRAY(parray);
  }
  else
  {
    switch(lua_gettop(L))
    {
    case 3:  glColor3d(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3));
      break;
    case 4:  glColor4d(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3), luaL_checknumber(L, 4));
      break;
    }
  }

  return 0;
}

/*ColorMask (red, green, blue, alpha) -> none*/
static int luagl_color_mask(lua_State *L)
{
  glColorMask((GLboolean)luagl_checkboolean(L, 1), (GLboolean)luagl_checkboolean(L, 2),
              (GLboolean)luagl_checkboolean(L, 3), (GLboolean)luagl_checkboolean(L, 4));
  return 0;
}

/*ColorMaterial (face, mode) -> none*/
static int luagl_color_material(lua_State *L)
{
  glColorMaterial(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));
  return 0;
}

/*ColorPointer (colorArray) -> none*/
static int luagl_color_pointer(lua_State *L)
{
  GLint size;
  static GLdouble *parray = NULL;

  LUAGL_DELETE_ARRAY(parray);

  if (lua_isnil(L,1))
    return 0;

  if (lua_isnumber(L, 2))
  {
    size = luaL_checkinteger(L, 2);
    luagl_get_arrayd(L, 1, &parray);
  }
  else 
  {
    int h = luagl_get_array2d(L, 1, &parray, &size);
    if (h==-1)
      luaL_argerror(L, 1, "must be a table of tables");
  }

  glColorPointer(size, GL_DOUBLE, 0, parray);
  return 0;
}

/*CopyPixels (x, y, width, height, type) -> none*/
static int luagl_copy_pixels(lua_State *L)
{
  glCopyPixels(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
               luaL_checkinteger(L, 3), luaL_checkinteger(L, 4), 
               luagl_get_gl_enum(L, 5));
  return 0;
}

/*CopyTexImage (level, internalFormat, border, x, y, width[, height]) -> none*/
static int luagl_copy_tex_image(lua_State *L)
{
  int num_args = lua_gettop(L);
  if (num_args > 6)
  {
    glCopyTexImage2D(GL_TEXTURE_2D, luaL_checkinteger(L, 1), luagl_get_gl_enum(L, 2),
      luaL_checkinteger(L, 4), luaL_checkinteger(L, 5),
      luaL_checkinteger(L, 6), luaL_checkinteger(L, 7),
      luaL_checkinteger(L, 3));
  }
  else
  {
    glCopyTexImage1D(GL_TEXTURE_1D, luaL_checkinteger(L, 1), luagl_get_gl_enum(L, 2),
      luaL_checkinteger(L, 4), luaL_checkinteger(L, 5),
      luaL_checkinteger(L, 6), luaL_checkinteger(L, 3));
  }
  return 0;
}

/*CopyTexSubImage (level, x, y, xoffset, width[, yoffset, height]) -> none*/
static int luagl_copy_tex_sub_image(lua_State *L)
{
  int num_args = lua_gettop(L);
  if (num_args >= 7)
  {
    glCopyTexSubImage2D(GL_TEXTURE_2D,
      luaL_checkinteger(L, 1), luaL_checkinteger(L, 4),
      luaL_checkinteger(L, 6), luaL_checkinteger(L, 2),
      luaL_checkinteger(L, 3), luaL_checkinteger(L, 5),
      luaL_checkinteger(L, 7));
  }
  else
  {
    glCopyTexSubImage1D(GL_TEXTURE_1D,
      luaL_checkinteger(L, 1), luaL_checkinteger(L, 4),
      luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
      luaL_checkinteger(L, 5));
  }
  return 0;
}

/*CullFace (mode) -> none*/
static int luagl_cull_face(lua_State *L)
{
  glCullFace(luagl_get_gl_enum(L, 1));
  return 0;
}

/*DeleteLists (list, range) -> none*/
static int luagl_delete_lists(lua_State *L)
{
  glDeleteLists(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2));
  return 0;
}

/*DeleteTextures (texturesArray) -> none*/
static int luagl_delete_textures(lua_State *L)
{
  int n;
  GLuint *textures;

  n = luagl_get_arrayui(L, 1, &textures);

  glDeleteTextures((GLsizei)n, (GLuint *)textures);

  LUAGL_DELETE_ARRAY(textures);

  return 0;
}

/*DepthFunc (func) -> none*/
static int luagl_depth_func(lua_State *L)
{
  glDepthFunc(luagl_get_gl_enum(L, 1));
  return 0;
}

/*DepthMask (flag) -> none*/
static int luagl_depth_mask(lua_State *L)
{
  glDepthMask((GLboolean)luagl_checkboolean(L, 1));
  return 0;
}

/*DepthRange (zNear, zFar) -> none*/
static int luagl_depth_range(lua_State *L)
{
  glDepthRange((GLclampd)luaL_checknumber(L, 1), (GLclampd)luaL_checknumber(L, 2));
  return 0;
}

/*Disable (cap) -> none*/
static int luagl_disable(lua_State *L)
{
  glDisable(luagl_get_gl_enum(L, 1));
  return 0;
}

/*DisableClientState (parray) -> none*/
static int luagl_disable_client_state(lua_State *L)
{
  glDisableClientState(luagl_get_gl_enum(L, 1));
  return 0;
}

/*DrawArrays (mode, first, count) -> none*/
static int luagl_draw_arrays(lua_State *L)
{
  glDrawArrays(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luaL_checkinteger(L, 3));
  return 0;
}

/*DrawBuffer (mode) -> none*/
static int luagl_draw_buffer(lua_State *L)
{
  glDrawBuffer(luagl_get_gl_enum(L, 1));
  return 0;
}

/*DrawElements (mode, indicesArray) -> none*/
static int luagl_draw_elements(lua_State *L)
{
  int n;
  GLuint *indices;

  n = luagl_get_arrayui(L, 2, &indices);

  glDrawElements(luagl_get_gl_enum(L, 1), n, GL_UNSIGNED_INT, indices);

  LUAGL_DELETE_ARRAY(indices);
  return 0;
}

/*DrawPixels (width, height, format, pixels) -> none*/
static int luagl_draw_pixels(lua_State *L)
{
  GLfloat *pixels;

  luagl_get_arrayf(L, 4, &pixels);

  glDrawPixels(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), 
               luagl_get_gl_enum(L, 3), GL_FLOAT, pixels);

  LUAGL_DELETE_ARRAY(pixels);
  return 0;
}

/*DrawPixelsRaw (width, height, format, type, pixels) -> none*/
static int luagl_draw_pixels_raw(lua_State *L)
{
  glDrawPixels(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), 
               luagl_get_gl_enum(L, 3), luagl_get_gl_enum(L, 4), luagl_checkuserdata(L, 5));
  return 0;
}

/*EdgeFlag (flag) -> none*/
static int luagl_edge_flag(lua_State *L)
{
  if (lua_istable(L, 1))
  {
    GLboolean *flag;
    luagl_get_arrayb(L, 1, &flag);

    glEdgeFlagv((GLboolean *)flag);

    LUAGL_DELETE_ARRAY(flag);
  }
  else 
    glEdgeFlag((GLboolean)luagl_checkboolean(L, 1));

  return 0;
}

/*EdgeFlagPointer (flagsArray) -> none*/
static int luagl_edge_flag_pointer(lua_State *L)
{
  static GLboolean *flags = 0;

  LUAGL_DELETE_ARRAY(flags);

  if(lua_isnil(L,1))
    return 0;

  luagl_get_arrayb(L, 1, &flags);

  glEdgeFlagPointer(0, flags);

  return 0;
}

/*Enable (cap) -> none*/
static int luagl_enable(lua_State *L)
{
  glEnable(luagl_get_gl_enum(L, 1));
  return 0;
}

/*EnableClientState (parray) -> none*/
static int luagl_enable_client_state(lua_State *L)
{
  glEnableClientState(luagl_get_gl_enum(L, 1));
  return 0;
}

/*End () -> none*/
static int luagl_end(lua_State *L)
{
  glEnd();
  return 0;
}

/*EndList () -> none*/
static int luagl_end_list(lua_State *L)
{
  glEndList();
  return 0;
}

/*EvalCoord (u[, v]) -> none
  EvalCoord (coordArray) -> none*/
static int luagl_eval_coord(lua_State *L)
{
  if (lua_istable(L, 1))
  {
    GLdouble *parray;
    if(luagl_get_arrayd(L, 1, &parray) == 1)
      glEvalCoord1dv(parray);
    else
      glEvalCoord2dv(parray);

    LUAGL_DELETE_ARRAY(parray);

    return 0;
  }
  else
  {
    int num_args = lua_gettop(L);
    switch(num_args)
    {
    case 1:  glEvalCoord1d(luaL_checknumber(L, 1));
      break;
    case 2:  glEvalCoord2d(luaL_checknumber(L, 1), luaL_checknumber(L, 2));
      break;
    }
  }
  return 0;
}

/*EvalMesh (mode, i1, i2[,j1, j2]) -> none*/
static int luagl_eval_mesh(lua_State *L)
{
  int num_args = lua_gettop(L);
  if(num_args < 5)
    glEvalMesh1(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luaL_checkinteger(L, 3));
  else
    glEvalMesh2(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
                luaL_checkinteger(L, 4), luaL_checkinteger(L, 5));
  return 0;
}

/*EvalPoint (i[, j]) -> none*/
static int luagl_eval_point(lua_State *L)
{
  int num_args = lua_gettop(L);
  if(num_args == 1)
    glEvalPoint1(luaL_checkinteger(L, 1));
  else
    glEvalPoint2(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2));
  return 0;
}

/*FeedbackBuffer (size, type) -> dataArray*/
static int luagl_feedback_buffer(lua_State *L)
{
  GLfloat *buffer;
  GLsizei size;

  size = luaL_checkinteger(L, 1);

  buffer = LUAGL_NEW_ARRAY(GLfloat, size);

  glFeedbackBuffer (size, luagl_get_gl_enum(L, 2), buffer);

  luagl_push_arrayf(L, buffer, size);

  LUAGL_DELETE_ARRAY(buffer);

  return 1;
}

/*Finish () -> none*/
static int luagl_finish(lua_State *L)
{
  glFinish();
  return 0;
}

/*Flush () -> none*/
static int luagl_flush(lua_State *L)
{
  glFlush();
  return 0;
}

/*Fog (pname, param) -> none
  Fog (pname, paramsArray) -> none*/
static int luagl_fog(lua_State *L)
{
  GLfloat *param;

  if(lua_istable(L, 2))
  {
    luagl_get_arrayf(L, 2, &param);

    glFogfv(luagl_get_gl_enum(L, 1), (GLfloat*)param);

    LUAGL_DELETE_ARRAY(param);
    return 0;
  }
  else if(lua_isnumber(L, 2))
    glFogf(luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  else 
    glFogi(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));

  return 0;
}

/*FrontFace (mode) -> none*/
static int luagl_front_face(lua_State *L)
{
  glFrontFace(luagl_get_gl_enum(L, 1));
  return 0;
}

/*Frustum (left, right, bottom, top, zNear, zFar) -> none*/
static int luagl_frustum(lua_State *L)
{
  glFrustum(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
            luaL_checknumber(L, 3), luaL_checknumber(L, 4),
            luaL_checknumber(L, 5), luaL_checknumber(L, 6));
  return 0;
}

/*GenLists (range) -> num*/
static int luagl_gen_lists(lua_State *L)
{
  lua_pushnumber(L, glGenLists(luaL_checkinteger(L, 1)) );
  return 1;
}

/*GenTextures (n) -> texturesArray*/
static int luagl_gen_textures(lua_State *L)
{
  GLsizei size;
  GLuint *textures;

  size = luaL_checkinteger(L, 1);
  textures = LUAGL_NEW_ARRAY(GLuint, size);

  glGenTextures(size, textures);

  luagl_push_arrayui(L, textures, size);

  LUAGL_DELETE_ARRAY(textures);

  return 1;
}

/*Get (pname) -> params*/
static int luagl_get(lua_State *L)
{
  int i, size=1;
  GLenum e;
  GLdouble *params;
  int mask;

  e = luagl_get_gl_enum(L, 1);

  switch(e)
  {
  case GL_STENCIL_VALUE_MASK:
  case GL_LINE_STIPPLE_PATTERN:
  case GL_STENCIL_WRITEMASK:
  case GL_INDEX_WRITEMASK:
    mask = 0;
    glGetIntegerv(e, &mask);
    lua_pushstring(L, luagl_mask2str(mask));
    return 1;

  case GL_DEPTH_RANGE:
  case GL_MAP1_GRID_DOMAIN:
  case GL_MAP2_GRID_SEGMENTS:
  case GL_MAX_VIEWPORT_DIMS:
  case GL_POINT_SIZE_RANGE:
  case GL_POLYGON_MODE:
    size = 2;
    break;

  case GL_CURRENT_NORMAL:
    size = 3;
    break;

  case GL_ACCUM_CLEAR_VALUE:
  case GL_COLOR_CLEAR_VALUE:
  case GL_COLOR_WRITEMASK:
  case GL_CURRENT_COLOR:
  case GL_CURRENT_RASTER_COLOR:
  case GL_CURRENT_RASTER_POSITION:
  case GL_CURRENT_RASTER_TEXTURE_COORDS:
  case GL_CURRENT_TEXTURE_COORDS:
  case GL_FOG_COLOR:
  case GL_LIGHT_MODEL_AMBIENT:
  case GL_MAP2_GRID_DOMAIN:
  case GL_SCISSOR_BOX:
  case GL_TEXTURE_ENV_COLOR:
  case GL_VIEWPORT:
    size = 4;
    break;

  case GL_MODELVIEW_MATRIX:
  case GL_PROJECTION_MATRIX:
  case GL_TEXTURE_MATRIX:
    size = 16;
    break;

  default:
    luaL_argerror(L, 1, "unknown enumeration.");
    break;
  }

  params = LUAGL_NEW_ARRAY(GLdouble, size);

  glGetDoublev(e, params);

  for(i = 0; i < size; i++)
    lua_pushnumber(L, params[i]);

  LUAGL_DELETE_ARRAY(params);

  return size;
}

/*GetConst (pname) -> constant string*/
static int luagl_get_const(lua_State *L)
{
  int i, size=1;
  GLenum e;
  GLenum *params;

  e = luagl_get_gl_enum(L, 1);

  switch(e)
  {
  case GL_DEPTH_RANGE:
  case GL_MAP1_GRID_DOMAIN:
  case GL_MAP2_GRID_SEGMENTS:
  case GL_MAX_VIEWPORT_DIMS:
  case GL_POINT_SIZE_RANGE:
  case GL_POLYGON_MODE:
    size = 2;
    break;

  case GL_CURRENT_NORMAL:
    size = 3;
    break;

  case GL_ACCUM_CLEAR_VALUE:
  case GL_COLOR_CLEAR_VALUE:
  case GL_COLOR_WRITEMASK:
  case GL_CURRENT_COLOR:
  case GL_CURRENT_RASTER_COLOR:
  case GL_CURRENT_RASTER_POSITION:
  case GL_CURRENT_RASTER_TEXTURE_COORDS:
  case GL_CURRENT_TEXTURE_COORDS:
  case GL_FOG_COLOR:
  case GL_LIGHT_MODEL_AMBIENT:
  case GL_MAP2_GRID_DOMAIN:
  case GL_SCISSOR_BOX:
  case GL_TEXTURE_ENV_COLOR:
  case GL_VIEWPORT:
    size = 4;
    break;

  case GL_MODELVIEW_MATRIX:
  case GL_PROJECTION_MATRIX:
  case GL_TEXTURE_MATRIX:
    size = 16;
    break;
  }

  params = LUAGL_NEW_ARRAY(GLenum, size);

  glGetIntegerv(e, (GLint*)params);

  for(i = 0; i < size; i++)
    luagl_pushenum(L, params[i]);

  LUAGL_DELETE_ARRAY(params);

  return size;
}

/*GetArray (pname) -> paramsArray*/
static int luagl_get_array(lua_State *L)
{
  int size = 1;
  GLenum e;
  GLdouble *params;

  e = luagl_get_gl_enum(L, 1);

  switch(e)
  {
  case GL_DEPTH_RANGE:
  case GL_MAP1_GRID_DOMAIN:
  case GL_MAP2_GRID_SEGMENTS:
  case GL_MAX_VIEWPORT_DIMS:
  case GL_POINT_SIZE_RANGE:
  case GL_POLYGON_MODE:
    size = 2;
    break;

  case GL_CURRENT_NORMAL:
    size = 3;
    break;

  case GL_ACCUM_CLEAR_VALUE:
  case GL_COLOR_CLEAR_VALUE:
  case GL_COLOR_WRITEMASK:
  case GL_CURRENT_COLOR:
  case GL_CURRENT_RASTER_COLOR:
  case GL_CURRENT_RASTER_POSITION:
  case GL_CURRENT_RASTER_TEXTURE_COORDS:
  case GL_CURRENT_TEXTURE_COORDS:
  case GL_FOG_COLOR:
  case GL_LIGHT_MODEL_AMBIENT:
  case GL_MAP2_GRID_DOMAIN:
  case GL_SCISSOR_BOX:
  case GL_TEXTURE_ENV_COLOR:
  case GL_VIEWPORT:
    size = 4;
    break;

  case GL_MODELVIEW_MATRIX:
  case GL_PROJECTION_MATRIX:
  case GL_TEXTURE_MATRIX:
    size = 16;
    break;
  }

  params = LUAGL_NEW_ARRAY(GLdouble, size);

  glGetDoublev(e, params);

  luagl_push_arrayd(L, params, size);

  LUAGL_DELETE_ARRAY(params);

  return 1;
}

/*GetClipPlane (plane) -> equationArray*/
static int luagl_get_clip_plane(lua_State *L)
{
  GLdouble *equation;

  equation = LUAGL_NEW_ARRAY(GLdouble, 4);

  glGetClipPlane(luagl_get_gl_enum(L, 1), equation);

  luagl_push_arrayd(L, equation, 4);

  LUAGL_DELETE_ARRAY(equation);

  return 1;
}

/*GetError () -> error flag*/
static int luagl_get_error(lua_State *L)
{
  GLenum error = glGetError();
  if(error == GL_NO_ERROR)
    lua_pushnil(L);
  else
    luagl_pushenum(L, error);
  return 1;
}

/*GetLight (light, pname) -> paramsArray*/
static int luagl_get_light(lua_State *L)
{
  int size = 1;
  GLenum e1, e2;
  GLfloat *params;

  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  switch(e2)
  {
  case GL_AMBIENT:
  case GL_DIFFUSE:
  case GL_SPECULAR:
  case GL_POSITION:
    size = 4;
    break;
  case GL_SPOT_DIRECTION :
    size = 3;
    break;
  case GL_SPOT_EXPONENT:
  case GL_SPOT_CUTOFF:
  case GL_CONSTANT_ATTENUATION:
  case GL_LINEAR_ATTENUATION:
  case GL_QUADRATIC_ATTENUATION:
    size = 1;
    break;
  }

  params = LUAGL_NEW_ARRAY(GLfloat, size);

  glGetLightfv(e1, e2, params);

  luagl_push_arrayf(L, params, size);

  LUAGL_DELETE_ARRAY(params);

  return 1;
}

/*GetMap (target, query) -> vArray*/
static int luagl_get_map(lua_State *L)
{
  int size = 1;
  GLenum e1, e2;
  GLdouble *params;
  GLint *order;

  order = LUAGL_NEW_ARRAY(GLint, 2);
  order[0] = order[1] = 1;

  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  switch(e1)
  {
  case GL_MAP1_INDEX:
  case GL_MAP2_INDEX:
  case GL_MAP1_TEXTURE_COORD_1:
  case GL_MAP2_TEXTURE_COORD_1:
    size = 1;
    break;
  case GL_MAP1_TEXTURE_COORD_2:
  case GL_MAP2_TEXTURE_COORD_2:
    size = 2;
    break;
  case GL_MAP1_VERTEX_3:
  case GL_MAP2_VERTEX_3:
  case GL_MAP1_NORMAL:
  case GL_MAP2_NORMAL:
  case GL_MAP1_TEXTURE_COORD_3:
  case GL_MAP2_TEXTURE_COORD_3:
    size = 3;
    break;
  case GL_MAP1_VERTEX_4:
  case GL_MAP2_VERTEX_4:
  case GL_MAP1_COLOR_4:
  case GL_MAP2_COLOR_4:
  case GL_MAP1_TEXTURE_COORD_4:
  case GL_MAP2_TEXTURE_COORD_4:
    size = 4;
    break;
  }

  glGetMapiv(e1, GL_ORDER, order);

  size *= order[0] * order[1];

  params = LUAGL_NEW_ARRAY(GLdouble, size);

  glGetMapdv(e1, e2, params);

  luagl_push_arrayd(L, params, size);

  LUAGL_DELETE_ARRAY(params);
  LUAGL_DELETE_ARRAY(order);

  return 1;
}

/*GetMaterial (face, pname) -> paramsArray*/
static int luagl_get_material(lua_State *L)
{
  int size = 1;
  GLenum e1, e2;
  GLfloat *params;

  /* get string parameters */
  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  switch(e2)
  {
  case GL_AMBIENT:
  case GL_DIFFUSE:
  case GL_SPECULAR:
  case GL_EMISSION:
    size = 4;
    break;
  case GL_COLOR_INDEXES:
    size = 3;
    break;
  case GL_SHININESS:
    size = 1;
    break;
  }

  params = LUAGL_NEW_ARRAY(GLfloat, size);

  glGetMaterialfv(e1, e2, params);

  luagl_push_arrayf(L, params, size);

  LUAGL_DELETE_ARRAY(params);

  return 1;
}

/*GetPixelMap (map) -> valuesArray*/
static int luagl_get_pixel_map(lua_State *L)
{
  int size;
  int s = GL_PIXEL_MAP_R_TO_R_SIZE;
  GLenum e;
  GLfloat *values;

  e = luagl_get_gl_enum(L, 1);

  switch(e)
  {
  case GL_PIXEL_MAP_I_TO_I: s = GL_PIXEL_MAP_I_TO_I_SIZE; break;
  case GL_PIXEL_MAP_S_TO_S: s = GL_PIXEL_MAP_S_TO_S_SIZE; break;
  case GL_PIXEL_MAP_I_TO_R: s = GL_PIXEL_MAP_I_TO_R_SIZE; break;
  case GL_PIXEL_MAP_I_TO_G: s = GL_PIXEL_MAP_I_TO_G_SIZE; break;
  case GL_PIXEL_MAP_I_TO_B: s = GL_PIXEL_MAP_I_TO_B_SIZE; break;
  case GL_PIXEL_MAP_I_TO_A: s = GL_PIXEL_MAP_I_TO_A_SIZE; break;
  case GL_PIXEL_MAP_R_TO_R: s = GL_PIXEL_MAP_R_TO_R_SIZE; break;
  case GL_PIXEL_MAP_G_TO_G: s = GL_PIXEL_MAP_G_TO_G_SIZE; break;
  case GL_PIXEL_MAP_B_TO_B: s = GL_PIXEL_MAP_B_TO_B_SIZE; break;
  case GL_PIXEL_MAP_A_TO_A: s = GL_PIXEL_MAP_A_TO_A_SIZE; break;
  }

  glGetIntegerv(s, &size);

  values = LUAGL_NEW_ARRAY(GLfloat, size);

  glGetPixelMapfv(e, values);

  luagl_push_arrayf(L, values, size);

  LUAGL_DELETE_ARRAY(values);

  return 1;
}

/*GetPointer (pname, n) -> valuesArray*/
static int luagl_get_pointer(lua_State *L)
{
  int n;
  GLenum e;

  e = luagl_get_gl_enum(L, 1);
  n = luaL_checkinteger(L, 2);

  if(e == GL_EDGE_FLAG_ARRAY_POINTER)
  {
    GLboolean *flags;
    glGetPointerv(e, (void *)&flags);
    if(flags == 0)
      return 0;

    luagl_push_arrayb(L, flags, n);
  }
  else
  {
    GLdouble *params;
    glGetPointerv(e, (void *)&params);
    if(params == 0)
      return 0;

    luagl_push_arrayd(L, params, n);
  }

  return 1;
}

/*GetPolygonStipple () -> maskArray*/
static int luagl_get_polygon_stipple(lua_State *L)
{
  GLubyte *mask = LUAGL_NEW_ARRAY(GLubyte, 1024);

  glGetPolygonStipple(mask);

  luagl_push_arrayuc(L, mask, 1024);

  LUAGL_DELETE_ARRAY(mask);

  return 1;
}

/*GetString (name) -> string*/
static int luagl_get_string(lua_State *L)
{
  lua_pushstring(L, (const char*)glGetString(luagl_get_gl_enum(L, 1)));
  return 1;
}

/*GetTexEnv (pname) -> paramsArray*/
static int luagl_get_tex_env(lua_State *L)
{
  GLenum e1;

  e1 = luagl_get_gl_enum(L, 1);

  if (e1 != GL_TEXTURE_ENV_MODE)
  {
    GLfloat *params;

    params = LUAGL_NEW_ARRAY(GLfloat, 4);

    glGetTexEnvfv(GL_TEXTURE_ENV, e1, params);

    luagl_push_arrayf(L, params, 4);

    LUAGL_DELETE_ARRAY(params);
  }
  else 
  {
    GLint e2;
    glGetTexEnviv(GL_TEXTURE_ENV, e1, &e2);
    luagl_pushenum(L, e2);
  }

  return 1;
}

/*GetTexGen (coord, pname) -> paramsArray*/
static int luagl_get_tex_gen(lua_State *L)
{
  GLenum e2;

  e2 = luagl_get_gl_enum(L, 2);

  if (e2 != GL_TEXTURE_GEN_MODE)
  {
    GLdouble *params;

    params = LUAGL_NEW_ARRAY(GLdouble, 4);

    glGetTexGendv(luagl_get_gl_enum(L, 1), e2, params);

    luagl_push_arrayd(L, params, 4);

    LUAGL_DELETE_ARRAY(params);
  }
  else
  {
    GLint e3;
    glGetTexGeniv(luagl_get_gl_enum(L, 1), e2, &e3);
    luagl_pushenum(L, e3);
  }
  return 1;
}

static int luagl_get_depth(GLenum format)
{
  int depth = 0;
  switch(format)
  {
  case GL_DEPTH_COMPONENT:
  case GL_STENCIL_INDEX:
  case GL_COLOR_INDEX:
  case GL_RED:
  case GL_GREEN:
  case GL_BLUE:
  case GL_ALPHA:
  case GL_LUMINANCE:
    depth = 1;
    break;

  case GL_LUMINANCE_ALPHA:
    depth = 2;
    break;

  case GL_RGB:
#ifdef GL_BGR_EXT
  case GL_BGR_EXT:
#endif
    depth = 3;
    break;

  case GL_RGBA:
#ifdef GL_BGRA_EXT
  case GL_BGRA_EXT:
#endif
    depth = 4;
    break;
  }

  return depth;
}

/*GetTexImage (target, level, format) -> pixelsArray*/
static int luagl_get_tex_image(lua_State *L)
{
  int depth, size;
  int width, height, level;
  GLenum target, format;
  GLfloat *pixels;

  target = luagl_get_gl_enum(L, 1);
  level = luaL_checkinteger(L, 2);
  format = luagl_get_gl_enum(L, 3);

  /* get width and height of image */
  glGetTexLevelParameteriv(target, level, GL_TEXTURE_WIDTH, &width);
  glGetTexLevelParameteriv(target, level, GL_TEXTURE_HEIGHT, &height);

  depth = luagl_get_depth(format);
  if (depth == 0)
    luaL_argerror(L, 3, "unknown format");

  size = depth * width * height;
  pixels = LUAGL_NEW_ARRAY(GLfloat, size);

  glGetTexImage(target, level, format, GL_FLOAT, pixels);

  if (target == GL_TEXTURE_1D)
    luagl_push_arrayf(L, pixels, size);
  else
    luagl_push_array2f(L, pixels, height, width*depth);

  LUAGL_DELETE_ARRAY(pixels);

  return 1;
}

/*GetTexImageRaw (target, level, format, type, pixels) -> none*/
static int luagl_get_tex_image_raw(lua_State *L)
{
  glGetTexImage(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luagl_get_gl_enum(L, 3), 
                luagl_get_gl_enum(L, 4), luagl_checkuserdata(L, 5));
  return 0;
}

/*GetTexLevelParameter (target, level, pname) -> param*/
static int luagl_get_tex_level_parameter(lua_State *L)
{
  GLfloat param;
  glGetTexLevelParameterfv(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luagl_get_gl_enum(L, 3), &param);
  lua_pushnumber(L, param);
  return 1;
}

/*GetTexParameter (target, pname) -> paramsArray*/
static int luagl_get_tex_parameter(lua_State *L)
{
  GLenum target, pname;

  target = luagl_get_gl_enum(L, 1);
  pname = luagl_get_gl_enum(L, 2);

  if(pname == GL_TEXTURE_BORDER_COLOR)
  {
    GLfloat *params;

    params = LUAGL_NEW_ARRAY(GLfloat, 4);

    glGetTexParameterfv(target, pname, params);

    luagl_push_arrayf(L, params, 4);

    LUAGL_DELETE_ARRAY(params);
  }
  else if(pname == GL_TEXTURE_PRIORITY)
  {
    GLfloat param;
    glGetTexParameterfv(target, pname, &param);
    lua_pushnumber(L, param);
  }
  else
  {
    GLint e;
    glGetTexParameteriv(target, pname, &e);
    luagl_pushenum(L, e);
  }
  return 1;
}

/*Hint (target, mode) -> none*/
static int luagl_hint(lua_State *L)
{
  glHint(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));
  return 0;
}

/*Index (c) -> none*/
static int luagl_index(lua_State *L)
{
  if (lua_istable(L, 1))
  {
    GLdouble *c;

    luagl_get_arrayd(L, 1, &c);

    glIndexdv((GLdouble *)c);

    LUAGL_DELETE_ARRAY(c);
  }
  else 
    glIndexd(luaL_checknumber(L, 1));

  return 0;
}

/*IndexMask (mask) -> none*/
static int luagl_index_mask(lua_State *L)
{
  if(lua_type(L,1) == LUA_TSTRING)
    glIndexMask(luagl_str2mask(luaL_checkstring(L, 1)));
  else 
    glIndexMask(luaL_checkinteger(L, 1));
  return 0;
}

/*IndexPointer (indexArray) -> none*/
static int luagl_index_pointer(lua_State *L)
{
  static GLdouble *parray = NULL;

  LUAGL_DELETE_ARRAY(parray);

  /* Used to release the static memory */
  if(lua_isnil(L,1))
    return 0;

  luagl_get_arrayd(L, 1, &parray);

  glIndexPointer(GL_DOUBLE, 0, parray);

  return 0;
}

/*InitNames () -> none*/
static int luagl_init_names(lua_State *L)
{
  glInitNames();
  return 0;
}

/*IsEnabled (cap) -> true/false*/
static int luagl_is_enabled(lua_State *L)
{
  lua_pushboolean(L, glIsEnabled(luagl_get_gl_enum(L, 1)));
  return 1;
}

/*IsList (list) -> true/false*/
static int luagl_is_list(lua_State *L)
{
  lua_pushboolean(L, glIsList(luaL_checkinteger(L, 1)));
  return 1;
}

/*IsTexture (texture) -> true/false*/
static int luagl_is_texture(lua_State *L)
{
  lua_pushboolean(L, glIsTexture(luaL_checkinteger(L, 1)));
  return 1;
}

/*Light (light, pname, param) -> none
  Light (light, pname, paramsArray) -> none*/
static int luagl_light(lua_State *L)
{
  if(lua_istable(L, 3))
  {
    GLfloat *params;
    luagl_get_arrayf(L, 3, &params);

    glLightfv(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2), (GLfloat *)params);

    LUAGL_DELETE_ARRAY(params);
  }
  else 
    glLightf(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2), (GLfloat)luaL_checknumber(L, 3));
  return 0;
}

/*LightModel (pname, param) -> none
  LightModel (pname, paramsArray) -> none*/
static int luagl_light_model(lua_State *L)
{
  if (lua_istable(L, 2))
  {
    GLfloat *params;
    luagl_get_arrayf(L, 2, &params);

    glLightModelfv(luagl_get_gl_enum(L, 1), (GLfloat *)params);

    LUAGL_DELETE_ARRAY(params);
  }
  else 
    glLightModelf(luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*LineStipple (factor, pattern) -> none*/
static int luagl_line_stipple(lua_State *L)
{
  if (lua_type(L,2) == LUA_TSTRING)
    glLineStipple(luaL_checkinteger(L, 1), (GLushort)luagl_str2mask(luaL_checkstring(L, 2)));
  else 
    glLineStipple(luaL_checkinteger(L, 1), (GLushort)luaL_checkinteger(L, 2));
  return 0;
}

/*LineWidth (width) -> none*/
static int luagl_line_width(lua_State *L)
{
  glLineWidth((GLfloat)luaL_checknumber(L, 1));
  return 0;
}

/*ListBase (base) -> none*/
static int luagl_list_base(lua_State *L)
{
  glListBase(luaL_checkinteger(L, 1));
  return 0;
}

/*LoadIdentity () -> none*/
static int luagl_load_identity(lua_State *L)
{
  glLoadIdentity();
  return 0;
}

/*LoadMatrix (mArray) -> none*/
static int luagl_load_matrix(lua_State *L)
{
  GLdouble *m;
  int n;

  n = luagl_get_arrayd(L, 1, &m);
  if (n < 16)
  {
    LUAGL_DELETE_ARRAY(m);
    luaL_argerror(L, 1, "invalid number of elements in the matrix table (n<16).");
  }

  glLoadMatrixd(m);

  LUAGL_DELETE_ARRAY(m);

  return 0;
}

/*LoadName (name) -> none*/
static int luagl_load_name(lua_State *L)
{
  glLoadName(luaL_checkinteger(L, 1));
  return 0;
}

/*LogicOp (opcode) -> none*/
static int luagl_logic_op(lua_State *L)
{
  glLogicOp(luagl_get_gl_enum(L, 1));
  return 0;
}

/*Map (target, u1, u2, ustride, pointsArray) -> none
  Map (target, u1, u2, ustride, v1, v2, vstride, pointsArray) -> none*/
static int luagl_map(lua_State *L)
{
  int size=1;
  GLenum target;
  GLdouble *points;
  GLint uorder, vorder;

  target = luagl_get_gl_enum(L, 1);

  switch(target)
  {
  case GL_MAP1_INDEX:
  case GL_MAP2_INDEX:
  case GL_MAP1_TEXTURE_COORD_1:
  case GL_MAP2_TEXTURE_COORD_1:
    size = 1;
    break;
  case GL_MAP1_TEXTURE_COORD_2:
  case GL_MAP2_TEXTURE_COORD_2:
    size = 2;
    break;
  case GL_MAP1_VERTEX_3:
  case GL_MAP2_VERTEX_3:
  case GL_MAP1_NORMAL:
  case GL_MAP2_NORMAL:
  case GL_MAP1_TEXTURE_COORD_3:
  case GL_MAP2_TEXTURE_COORD_3:
    size = 3;
    break;
  case GL_MAP1_VERTEX_4:
  case GL_MAP2_VERTEX_4:
  case GL_MAP1_COLOR_4:
  case GL_MAP2_COLOR_4:
  case GL_MAP1_TEXTURE_COORD_4:
  case GL_MAP2_TEXTURE_COORD_4:
    size = 4;
    break;
  }

  if (lua_gettop(L) < 6)
  {
    uorder = luagl_get_arrayd(L, 4, &points) / size;

    glMap1d(target, luaL_checknumber(L, 2),
      luaL_checknumber(L, 3),
      size, uorder, points);

    LUAGL_DELETE_ARRAY(points);
  }
  else
  {
    vorder = luagl_get_array2d(L, 6, &points, &uorder);
    uorder /= size;

    if (vorder==-1)
      luaL_argerror(L, 6, "must be a table of tables");

    glMap2d(target, luaL_checknumber(L, 2), luaL_checknumber(L, 3),
            size, uorder, luaL_checknumber(L, 4), luaL_checknumber(L, 5),
            size * uorder, vorder, points);

    LUAGL_DELETE_ARRAY(points);
  }
  return 0;
}

/*MapGrid (un, u1, u2[, vn, v1, v2]) -> none*/
static int luagl_map_grid(lua_State *L)
{
  if (lua_gettop(L) < 6)
    glMapGrid1d(luaL_checkinteger(L, 1),
                luaL_checknumber(L, 2),
                luaL_checknumber(L, 3));
  else
    glMapGrid2d(luaL_checkinteger(L, 1),
                luaL_checknumber(L, 2),
                luaL_checknumber(L, 3),
                luaL_checkinteger(L, 4),
                luaL_checknumber(L, 5),
                luaL_checknumber(L, 6));
  return 0;
}

/*Material (face, pname, param) -> none*/
static int luagl_material(lua_State *L)
{
  GLenum e1, e2;
  GLfloat *params;

  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  if (lua_istable(L, 3))
  {
    luagl_get_arrayf(L, 3, &params);

    glMaterialfv(e1, e2, (GLfloat *)params);

    LUAGL_DELETE_ARRAY(params);
  }
  else 
    glMaterialf(e1, e2, (GLfloat)luaL_checknumber(L, 3));
  return 0;
}

/*MatrixMode (mode) -> none*/
static int luagl_matrix_mode(lua_State *L)
{
  glMatrixMode(luagl_get_gl_enum(L, 1));
  return 0;
}

/*MultMatrix (mArray) -> none*/
static int luagl_mult_matrix(lua_State *L)
{
  GLdouble *m;
  int n;

  n = luagl_get_arrayd(L, 1, &m);
  if (n < 16)
  {
    LUAGL_DELETE_ARRAY(m);
    luaL_argerror(L, 1, "invalid number of elements in the matrix table (n<16).");
  }

  glMultMatrixd(m);

  LUAGL_DELETE_ARRAY(m);

  return 0;
}

/*NewList (list, mode) -> none*/
static int luagl_new_list(lua_State *L)
{
  glNewList(luaL_checkinteger(L, 1), luagl_get_gl_enum(L, 2));
  return 0;
}

/*Normal (nx, ny, nz) -> none
  Normal (nArray) -> none*/
static int luagl_normal(lua_State *L)
{
  if(lua_istable(L, 1))
  {
    GLdouble *parray;
    int n;

    n = luagl_get_arrayd(L, 1, &parray);
    if (n < 3)
      luaL_argerror(L, 1, "invalid number of elements in the table (n<3)");

    glNormal3dv(parray);

    LUAGL_DELETE_ARRAY(parray);
  }
  else
    glNormal3d(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3));

  return 0;
}

/*NormalPointer (normalArray) -> none*/
static int luagl_normal_pointer(lua_State *L)
{
  GLint size;
  static GLdouble *parray = NULL;

  LUAGL_DELETE_ARRAY(parray);

  if(lua_isnil(L,1))
    return 0;

  if (lua_isnumber(L, 2))
  {
    size = luaL_checkinteger(L, 2);
    luagl_get_arrayd(L, 1, &parray);
  }
  else 
  {
    int h = luagl_get_array2d(L, 1, &parray, &size);
    if (h==-1)
      luaL_argerror(L, 1, "must be a table of tables");
  }

  glNormalPointer(GL_DOUBLE, 0, parray);

  return 0;
}

/*Ortho (left, right, bottom, top, zNear, zFar) -> none*/
static int luagl_ortho(lua_State *L)
{
  glOrtho(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
          luaL_checknumber(L, 3), luaL_checknumber(L, 4),
          luaL_checknumber(L, 5), luaL_checknumber(L, 6));
  return 0;
}

/*PassThrough (token) -> none*/
static int luagl_pass_through(lua_State *L)
{
  glPassThrough((GLfloat)luaL_checknumber(L, 1));
  return 0;
}

/*PixelMap (map, valuesArray) -> none*/
static int luagl_pixel_map(lua_State *L)
{
  GLfloat *values;
  int mapsize;

  mapsize = luagl_get_arrayf(L, 2, &values);

  glPixelMapfv(luagl_get_gl_enum(L, 1), mapsize, values);

  LUAGL_DELETE_ARRAY(values);

  return 0;
}

/*PixelStore (pname, param) -> none*/
static int luagl_pixel_store(lua_State *L)
{
  if (lua_isboolean(L,2))
    glPixelStoref(luagl_get_gl_enum(L, 1), (GLfloat)luagl_checkboolean(L, 2));
  else 
    glPixelStoref(luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*PixelTransfer (pname, param) -> none*/
static int luagl_pixel_transfer(lua_State *L)
{
  if(lua_isboolean(L,2))
    glPixelTransferf(luagl_get_gl_enum(L, 1), (GLfloat)luagl_checkboolean(L, 2));
  else 
    glPixelTransferf(luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*PixelZoom (xfactor, yfactor) -> none*/
static int luagl_pixel_zoom(lua_State *L)
{
  glPixelZoom((GLfloat)luaL_checknumber(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*PointSize (size) -> none*/
static int luagl_point_size(lua_State *L)
{
  glPointSize((GLfloat)luaL_checknumber(L, 1));
  return 0;
}

/*PolygonMode (face, mode) -> none*/
static int luagl_polygon_mode(lua_State *L)
{
  glPolygonMode(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));
  return 0;
}

/*PolygonOffset (factor, units) -> none*/
static int luagl_polygon_offset(lua_State *L)
{
  glPolygonOffset((GLfloat)luaL_checknumber(L, 1), (GLfloat)luaL_checknumber(L, 2));
  return 0;
}

/*PolygonStipple (maskArray) -> none*/
static int luagl_polygon_stipple(lua_State *L)
{
  GLubyte *parray;
  int width, height = 32;

  height = luagl_get_array2uc(L, 1, &parray, &width);
  if (height == -1)  /* if not 2D, get 1D */
    width = luagl_get_arrayuc(L, 1, &parray);

  if (width != 32 && height != 32)
  {
    LUAGL_DELETE_ARRAY(parray);
    luaL_argerror(L, 1, "invalid stipple size (width != 32 && height != 32)");
  }

  glPolygonStipple(parray);
  LUAGL_DELETE_ARRAY(parray);

  return 0;
}

/*PopAttrib () -> none*/
static int luagl_pop_attrib(lua_State *L)
{
  glPopAttrib();
  return 0;
}

/*PopClientAttrib () -> none*/
static int luagl_pop_client_attrib(lua_State *L)
{
  glPopClientAttrib();
  return 0;
}

/*PopMatrix () -> none*/
static int luagl_pop_matrix(lua_State *L)
{
  glPopMatrix();
  return 0;
}

/*PopName () -> none*/
static int luagl_pop_name(lua_State *L)
{
  glPopName();
  return 0;
}

/*PrioritizeTextures (texturesArray, prioritiesArray) -> none*/
static int luagl_prioritize_textures(lua_State *L)
{
  GLsizei n1, n2;
  GLuint *array1;
  GLclampf *array2;

  n1 = luagl_get_arrayui(L, 1, &array1);
  n2 = luagl_get_arrayf(L, 2, &array2);

  if (n1 > n2) n1 =  n2;

  glPrioritizeTextures(n1, array1, array2);

  LUAGL_DELETE_ARRAY(array1);
  LUAGL_DELETE_ARRAY(array2);

  return 0;
}

/*PushAttrib (mask) -> none*/
static int luagl_push_attrib(lua_State *L)
{
  glPushAttrib(luagl_get_gl_enum(L, 1));
  return 0;
}

/*PushClientAttrib (mask) -> none*/
static int luagl_push_client_attrib(lua_State *L)
{
  glPushClientAttrib(luagl_get_gl_enum(L, 1));
  return 0;
}

/*PushMatrix () -> none*/
static int luagl_push_matrix(lua_State *L)
{
  glPushMatrix();
  return 0;
}

/*PushName (GLuint name) -> none*/
static int luagl_push_name(lua_State *L)
{
  glPushName(luaL_checkinteger(L, 1));
  return 0;
}

/*RasterPos (x, y[, z, w]) -> none
  RasterPos (vArray) -> none*/
static int luagl_raster_pos(lua_State *L)
{
  if(lua_istable(L, 1))
  {
    GLdouble *parray;
    int n = luagl_get_arrayd(L, 1, &parray);
    if (n < 2)
    {
      LUAGL_DELETE_ARRAY(parray);
      luaL_argerror(L, 1, "invalid number of items in table (n<2).");
    }

    switch(n)
    {
    case 2:  glRasterPos2dv(parray); break;
    case 3:  glRasterPos3dv(parray); break;
    case 4:  glRasterPos4dv(parray); break;
    }

    LUAGL_DELETE_ARRAY(parray);
  }
  else
  {
    int num_args = lua_gettop(L);
    switch(num_args)
    {
    case 2:  
      glRasterPos2d(luaL_checknumber(L, 1), luaL_checknumber(L, 2));
      break;
    case 3:  
      glRasterPos3d(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3));
      break;
    case 4:  
      glRasterPos4d(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3), luaL_checknumber(L, 4));
      break;
    }
  }
  return 0;
}

/*ReadBuffer (mode) -> none*/
static int luagl_read_buffer(lua_State *L)
{
  glReadBuffer(luagl_get_gl_enum(L, 1));
  return 0;
}

/*ReadPixels (x, y, width, height, format) -> pixelsArray */
static int luagl_read_pixels(lua_State *L)
{
  GLenum format;
  GLfloat *pixels;
  int width, height, size, depth=1;

  format = luagl_get_gl_enum(L, 5);
  depth = luagl_get_depth(format);
  if (depth == 0)
    luaL_argerror(L, 5, "unknown format");

  width = luaL_checkinteger(L, 3);
  height = luaL_checkinteger(L, 4);
  size = width*height*depth;

  pixels = LUAGL_NEW_ARRAY(GLfloat, size);

  glReadPixels(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
               width, height, format, GL_FLOAT, pixels);

  luagl_push_arrayf(L, pixels, size);

  LUAGL_DELETE_ARRAY(pixels);

  return 1;
}

/*ReadPixelsRaw (x, y, width, height, format, type, pixels) -> none*/
static int luagl_read_pixels_raw(lua_State *L)
{
  glReadPixels(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
               luaL_checkinteger(L, 3), luaL_checkinteger(L, 4), 
               luagl_get_gl_enum(L, 5), luagl_get_gl_enum(L, 6), luagl_checkuserdata(L, 7));
  return 0;
}

/*Rect (x1, y1, x2, y2) -> none
  Rect (v1, v2) -> none*/
static int luagl_rect(lua_State *L)
{
  GLdouble *v1, *v2;

  if (lua_istable(L, 1) && lua_istable(L, 2))
  {
    luagl_get_arrayd(L, 1, &v1);
    luagl_get_arrayd(L, 2, &v2);

    glRectdv(v1, v2);

    LUAGL_DELETE_ARRAY(v1);
    LUAGL_DELETE_ARRAY(v2);
  }
  else 
    glRectd(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3), luaL_checknumber(L, 4));
  return 0;
}

/*RenderMode (mode) -> none*/
static int luagl_render_mode(lua_State *L)
{
  lua_pushnumber(L, glRenderMode(luagl_get_gl_enum(L, 1)));
  return 1;
}

/*Rotate (angle, x, y, z) -> none*/
static int luagl_rotate(lua_State *L)
{
  glRotated(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3), luaL_checknumber(L, 4));
  return 0;
}

/*Scale (x, y, z) -> none*/
static int luagl_scale(lua_State *L)
{
  glScaled(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3));
  return 0;
}

/*Scissor (x, y, width, height) -> none*/
static int luagl_scissor(lua_State *L)
{
  glScissor(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), luaL_checkinteger(L, 3), luaL_checkinteger(L, 4));
  return 0;
}

/*SelectBuffer (size) -> SelectArray*/
static int luagl_select_buffer(lua_State *L)
{
  int size;
  GLuint *buffer;

  size = luaL_checkinteger(L, 1);

  buffer = LUAGL_NEW_ARRAY(GLuint, size+1); /*first index is size*/
  buffer[0]=(GLuint)size;

  glSelectBuffer(size, buffer+1);

  lua_pushlightuserdata(L,buffer);
  return 1;
}

static int luagl_get_select_buffer(lua_State *L)
{
  GLuint* buffer = (GLuint*)luagl_checkuserdata(L, 1);
  int i = luaL_checkinteger(L,2);
  if (buffer) 
  { 
    int size = (int)buffer[0];
    if ((i<=size) && (i>0)) 
    {
      lua_pushnumber(L,buffer[i]); /*select buffer data begin at index i */
      return 1;
     }
  }
  return 0;
}

static int luagl_free_select_buffer(lua_State *L)
{
  GLuint* buffer = (GLuint*)luagl_checkuserdata(L, 1);
  LUAGL_DELETE_ARRAY(buffer);
  return 0;
}

static int luagl_new_data(lua_State *L)
{
  int size = luaL_checkinteger(L, 1);
  void* buffer = LUAGL_NEW_ARRAY(unsigned char, size);
  lua_pushlightuserdata(L, buffer);
  return 1;
}

static int luagl_free_data(lua_State *L)
{
  void* buffer = luagl_checkuserdata(L, 1);
  LUAGL_DELETE_ARRAY(buffer);
  return 0;
}

/*ShadeModel (mode) -> none*/
static int luagl_shade_model(lua_State *L)
{
  glShadeModel(luagl_get_gl_enum(L, 1));
  return 0;
}

/*StencilFunc (func, ref, mask) -> none*/
static int luagl_stencil_func(lua_State *L)
{
  if (lua_type(L,3) == LUA_TSTRING)
    glStencilFunc(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luagl_str2mask(luaL_checkstring(L, 3)));
  else 
    glStencilFunc(luagl_get_gl_enum(L, 1), luaL_checkinteger(L, 2), luaL_checkinteger(L, 3));
  return 0;
}

/*StencilMask (mask) -> none*/
static int luagl_stencil_mask(lua_State *L)
{
  if(lua_type(L,1) == LUA_TSTRING)
    glStencilMask(luagl_str2mask(luaL_checkstring(L, 1)));
  else 
    glStencilMask(luaL_checkinteger(L, 1));
  return 0;
}

/*StencilOp (fail, zfail, zpass) -> none*/
static int luagl_stencil_op(lua_State *L)
{
  glStencilOp(luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2), luagl_get_gl_enum(L, 3));
  return 0;
}

/*TexCoord (s[, t, r, q]) -> none
  TexCoord (vArray) -> none*/
static int luagl_tex_coord(lua_State *L)
{
  int index;
  int num_args = lua_gettop(L);

  GLdouble *v = 0;

  if (lua_istable(L, 1))
    num_args = luagl_get_arrayd(L, 1, &v);
  else
  {
    v = LUAGL_NEW_ARRAY(GLdouble, num_args);

    for(index = 0; index < num_args; index++)
    {
      v[index] = luaL_checknumber(L, index+1);
    }
  }

  switch(num_args)
  {
  case 1:  glTexCoord1dv((GLdouble *)v);  break;
  case 2:  glTexCoord2dv((GLdouble *)v);  break;
  case 3:  glTexCoord3dv((GLdouble *)v);  break;
  case 4:  glTexCoord4dv((GLdouble *)v);  break;
  }

  LUAGL_DELETE_ARRAY(v);

  return 0;
}

/*TexCoordPointer(vArray) -> none*/
static int luagl_tex_coord_pointer(lua_State *L)
{
  GLint size;
  static GLdouble *parray = NULL;

  LUAGL_DELETE_ARRAY(parray);

  if(lua_isnil(L,1))
    return 0;

  if (lua_isnumber(L, 2))
  {
    size = luaL_checkinteger(L, 2);
    luagl_get_arrayd(L, 1, &parray);
  }
  else
  {
    int h = luagl_get_array2d(L, 1, &parray, &size);
    if (h==-1)
      luaL_argerror(L, 1, "must be a table of tables");
  }

  glTexCoordPointer(size, GL_DOUBLE, 0, parray);

  return 0;
}

/*TexEnv (pname, param) -> none
  TexEnv (pname, paramsArray) -> none*/
static int luagl_tex_env(lua_State *L)
{
  if(lua_istable(L, 2))
  {
    GLfloat *param;
    luagl_get_arrayf(L, 2, &param);

    glTexEnvfv(GL_TEXTURE_ENV, luagl_get_gl_enum(L, 1), (GLfloat *)param);

    LUAGL_DELETE_ARRAY(param);
  }
  else if(lua_isnumber(L, 2))
    glTexEnvf(GL_TEXTURE_ENV, luagl_get_gl_enum(L, 1), (GLfloat)luaL_checknumber(L, 2));
  else 
    glTexEnvi(GL_TEXTURE_ENV, luagl_get_gl_enum(L, 1), luagl_get_gl_enum(L, 2));

  return 0;
}

/*TexGen (coord, pname, param) -> none
  TexGen (coord, pname, paramsArray) -> none*/
static int luagl_tex_gen(lua_State *L)
{
  GLenum e1, e2;

  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  if (lua_istable(L, 3))
  {
    GLdouble *param;
    luagl_get_arrayd(L, 3, &param);

    glTexGendv(e1, e2, (GLdouble *)param);

    LUAGL_DELETE_ARRAY(param);
  }
  else 
    glTexGeni(e1, e2, luagl_get_gl_enum(L, 3));

  return 0;
}

/*TexImage(level, internalformat, format, pixels) -> none*/
static int luagl_tex_image(lua_State *L)
{
  GLenum e;
  GLubyte *pixels;
  GLsizei width, height;
  int iformat;
  int index;

  if(lua_isnumber(L, 1) && lua_istable(L, 2))
  {
    /* undocumented parameter passing, 
       so it can be compatible with a texture created for glu.Build2DMipmaps */
    lua_getfield(L, 2, "components");
    iformat = luaL_checkinteger(L, -1);
    lua_remove(L, -1);

    lua_getfield(L, 2, "format");
    e = luagl_get_gl_enum(L, -1);
    lua_remove(L, -1);

    index = 2;
  }
  else
  {
    e = luagl_get_gl_enum(L, 3);
    iformat = luaL_checkinteger(L, 2);
    index = 4;
  }

  height = luagl_get_array2uc(L, index, &pixels, &width);
  if (height != -1)
  {
    glTexImage2D(GL_TEXTURE_2D, luaL_checkinteger(L, 1),
                 iformat, width/iformat, height, 0, e, GL_UNSIGNED_BYTE, pixels);
  }
  else  /* if not 2D, get 1D */
  {
    width = luagl_get_arrayuc(L, index, &pixels);
    glTexImage1D(GL_TEXTURE_1D, luaL_checkinteger(L, 1),
                 iformat, width/iformat, 0, e, GL_UNSIGNED_BYTE, pixels);
  }
  LUAGL_DELETE_ARRAY(pixels);
  return 0;
}

/* TexImage2D(level, depth, width, height, border, format, type, pixels) -> none*/
static int luagl_tex_image_2d(lua_State *L)
{
  glTexImage2D(GL_TEXTURE_2D, luaL_checkinteger(L, 1),
              luaL_checkinteger(L, 2), (GLsizei)luaL_checkinteger(L, 3), 
              (GLsizei)luaL_checkinteger(L, 4), luaL_checkinteger(L, 5), 
              luagl_get_gl_enum(L, 6), luagl_get_gl_enum(L, 7), luagl_checkuserdata(L, 8));
  return 0;
}

/* TexImage1D(level, depth, width, border, format, type, pixels) -> none*/
static int luagl_tex_image_1d(lua_State *L)
{
  glTexImage1D(GL_TEXTURE_1D, luaL_checkinteger(L, 1),
               luaL_checkinteger(L, 2), (GLsizei)luaL_checkinteger(L, 3), 
               luaL_checkinteger(L, 4), luagl_get_gl_enum(L, 5), 
               luagl_get_gl_enum(L, 6), luagl_checkuserdata(L, 7));
  return 0;
}

/*TexSubImage (level, format, pixels, xoffset) -> none
  TexSubImage (level, format, pixels, xoffset, yoffset) -> none*/
static int luagl_tex_sub_image(lua_State *L)
{
  GLenum format;
  GLfloat *pixels;
  GLsizei width, height;
  int depth;

  format = luagl_get_gl_enum(L, 2);
  depth = luagl_get_depth(format);
  if (depth == 0)
    luaL_argerror(L, 2, "unknown format");

  height = luagl_get_array2f(L, 3, &pixels, &width);
  if(height != -1)
  {
    glTexSubImage2D(GL_TEXTURE_2D, luaL_checkinteger(L, 1), luaL_checkinteger(L, 4),
                    luaL_checkinteger(L, 5), width/depth, height, format, GL_FLOAT, pixels);
  }
  else  /* if not 2D, get 1D */
  {
    width = luagl_get_arrayf(L, 3, &pixels);
    glTexSubImage1D(GL_TEXTURE_1D, luaL_checkinteger(L, 1), luaL_checkinteger(L, 4),
                    width/depth, format, GL_FLOAT, pixels);
  }

  LUAGL_DELETE_ARRAY(pixels);
  return 0;
}

/* TexSubImage2D (level, xoffset, yoffset, width, height, format, type, pixels) -> none*/
static int luagl_tex_sub_image_2d(lua_State *L)
{
  glTexSubImage2D(GL_TEXTURE_2D, luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), 
                  luaL_checkinteger(L, 3), luaL_checkinteger(L, 4), luaL_checkinteger(L, 5), 
                  luagl_get_gl_enum(L, 6), luagl_get_gl_enum(L, 7), luagl_checkuserdata(L, 8));
  return 0;
}

/* TexSubImage1D (level, xoffset, width, format, type, pixels) -> none*/
static int luagl_tex_sub_image_1d(lua_State *L)
{
  glTexSubImage1D(GL_TEXTURE_1D, luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), 
                  luaL_checkinteger(L, 3), luagl_get_gl_enum(L, 4), 
                  luagl_get_gl_enum(L, 5), luagl_checkuserdata(L, 6));
  return 0;
}

/*TexParameter (target, pname, param) -> none
TexParameter (target, pname, paramsArray) -> none*/
static int luagl_tex_parameter(lua_State *L)
{
  GLenum e1, e2;

  e1 = luagl_get_gl_enum(L, 1);
  e2 = luagl_get_gl_enum(L, 2);

  if(lua_istable(L, 3))
  {
    GLfloat *param;
    luagl_get_arrayf(L, 3, &param);

    glTexParameterfv(e1, e2, (GLfloat *)param);

    LUAGL_DELETE_ARRAY(param);
  }
  else if(lua_isnumber(L, 3))
    glTexParameterf(e1, e2, (GLfloat)luaL_checknumber(L, 3));
  else 
    glTexParameteri(e1, e2, luagl_get_gl_enum(L, 3));

  return 0;
}

/*Translate (x, y, z) -> none*/
static int luagl_translate(lua_State *L)
{
  glTranslated(luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3));
  return 0;
}

/*Vertex (x, y, [z, w]) -> none
  Vertex (v) -> none*/
static int luagl_vertex(lua_State *L)
{
  int index;
  int num_args = lua_gettop(L);

  GLdouble *v;

  if(lua_istable(L, 1))
    num_args = luagl_get_arrayd(L, 1, &v);
  else
  {
    v = LUAGL_NEW_ARRAY(GLdouble, num_args);

    for(index = 0; index < num_args; index++)
    {
      v[index] = luaL_checknumber(L, index+1);
    }
  }

  if (num_args < 2)
    luaL_error(L, "invalid number of arguments");

  switch(num_args)
  {
  case 2:  glVertex2dv((GLdouble *)v);  break;
  case 3:  glVertex3dv((GLdouble *)v);  break;
  case 4:  glVertex4dv((GLdouble *)v);  break;
  }

  LUAGL_DELETE_ARRAY(v);

  return 0;
}

/*VertexPointer (vertexArray) -> none*/
static int luagl_vertex_pointer(lua_State *L)
{
  GLint size;
  static GLdouble *parray = NULL;

  LUAGL_DELETE_ARRAY(parray);

  if(lua_isnil(L,1))
    return 0;

  if (lua_isnumber(L, 2))
  {
    size = luaL_checkinteger(L, 2);
    luagl_get_arrayd(L, 1, &parray);
  }
  else 
  {
    int h = luagl_get_array2d(L, 1, &parray, &size);
    if (h==-1)
      luaL_argerror(L, 1, "must be a table of tables");
  }

  glVertexPointer(size, GL_DOUBLE, 0, parray);

  return 0;
}

/*Viewport (x, y, width, height) -> none*/
static int luagl_viewport(lua_State *L)
{
  glViewport(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), 
             luaL_checkinteger(L, 3), luaL_checkinteger(L, 4));
  return 0;
}

static const luaL_Reg luagl_lib[] = {
  {"Accum", luagl_accum},
  {"AlphaFunc", luagl_alpha_func},
  {"AreTexturesResident", luagl_are_textures_resident},
  {"ArrayElement", luagl_array_element},
  {"Begin", luagl_begin},
  {"BindTexture", luagl_bind_texture},
  {"Bitmap", luagl_bitmap},
  {"BitmapRaw", luagl_bitmap_raw},
  {"BlendFunc", luagl_blend_func},
  {"CallList", luagl_call_list},
  {"CallLists", luagl_call_lists},
  {"Clear", luagl_clear},
  {"ClearAccum", luagl_clear_accum},
  {"ClearColor", luagl_clear_color},
  {"ClearDepth", luagl_clear_depth},
  {"ClearIndex", luagl_clear_index},
  {"ClearStencil", luagl_clear_stencil},
  {"ClipPlane", luagl_clip_plane},
  {"Color", luagl_color},
  {"ColorMask", luagl_color_mask},
  {"ColorMaterial", luagl_color_material},
  {"ColorPointer", luagl_color_pointer},
  {"CopyPixels", luagl_copy_pixels},
  {"CopyTexImage", luagl_copy_tex_image},
  {"CopyTexSubImage", luagl_copy_tex_sub_image},
  {"CullFace",luagl_cull_face},
  {"DeleteLists",luagl_delete_lists},
  {"DeleteTextures",luagl_delete_textures},
  {"DepthFunc",luagl_depth_func},
  {"DepthMask",luagl_depth_mask},
  {"DepthRange",luagl_depth_range},
  {"Disable",luagl_disable},
  {"DisableClientState",luagl_disable_client_state},
  {"DrawArrays",luagl_draw_arrays},
  {"DrawBuffer",luagl_draw_buffer},
  {"DrawElements", luagl_draw_elements},
  {"DrawPixels", luagl_draw_pixels},
  {"DrawPixelsRaw", luagl_draw_pixels_raw},
  {"EdgeFlag", luagl_edge_flag},
  {"EdgeFlagPointer", luagl_edge_flag_pointer},
  {"Enable", luagl_enable},
  {"EnableClientState", luagl_enable_client_state},
  {"End", luagl_end},
  {"EndList", luagl_end_list},
  {"EvalCoord", luagl_eval_coord},
  {"EvalMesh", luagl_eval_mesh},
  {"EvalPoint", luagl_eval_point},
  {"FeedbackBuffer", luagl_feedback_buffer},
  {"Finish", luagl_finish},
  {"Flush", luagl_flush},
  {"Fog", luagl_fog},
  {"FrontFace", luagl_front_face},
  {"Frustum", luagl_frustum},
  {"GenLists", luagl_gen_lists},
  {"GenTextures", luagl_gen_textures},
  {"Get", luagl_get},
  {"GetArray", luagl_get_array},
  {"GetConst", luagl_get_const},
  {"GetClipPlane", luagl_get_clip_plane},
  {"GetError", luagl_get_error},
  {"GetLight", luagl_get_light},
  {"GetMap", luagl_get_map},
  {"GetMaterial", luagl_get_material},
  {"GetPixelMap", luagl_get_pixel_map},
  {"GetPointer", luagl_get_pointer},
  {"GetPolygonStipple", luagl_get_polygon_stipple},
  {"GetString", luagl_get_string},
  {"GetTexEnv", luagl_get_tex_env},
  {"GetTexGen", luagl_get_tex_gen},
  {"GetTexImage", luagl_get_tex_image},
  {"GetTexImageRaw", luagl_get_tex_image_raw},
  {"GetTexLevelParameter", luagl_get_tex_level_parameter},
  {"GetTexParameter", luagl_get_tex_parameter},
  {"Hint", luagl_hint},
  {"Index", luagl_index},
  {"IndexMask", luagl_index_mask},
  {"IndexPointer", luagl_index_pointer},
  {"InitNames", luagl_init_names},
  {"IsEnabled", luagl_is_enabled},
  {"IsList", luagl_is_list},
  {"IsTexture", luagl_is_texture},
  {"Light", luagl_light},
  {"LightModel", luagl_light_model},
  {"LineStipple", luagl_line_stipple},
  {"LineWidth", luagl_line_width},
  {"ListBase", luagl_list_base},
  {"LoadIdentity", luagl_load_identity},
  {"LoadMatrix", luagl_load_matrix},
  {"LoadName", luagl_load_name},
  {"LogicOp", luagl_logic_op},
  {"Map", luagl_map},
  {"MapGrid", luagl_map_grid},
  {"Material", luagl_material},
  {"MatrixMode", luagl_matrix_mode},
  {"MultMatrix", luagl_mult_matrix},
  {"NewList", luagl_new_list},
  {"Normal", luagl_normal},
  {"NormalPointer", luagl_normal_pointer},
  {"Ortho", luagl_ortho},
  {"PassThrough", luagl_pass_through},
  {"PixelMap", luagl_pixel_map},
  {"PixelStore", luagl_pixel_store},
  {"PixelTransfer", luagl_pixel_transfer},
  {"PixelZoom", luagl_pixel_zoom},
  {"PointSize", luagl_point_size},
  {"PolygonMode", luagl_polygon_mode},
  {"PolygonOffset", luagl_polygon_offset},
  {"PolygonStipple", luagl_polygon_stipple},
  {"PopAttrib", luagl_pop_attrib},
  {"PopClientAttrib", luagl_pop_client_attrib},
  {"PopMatrix", luagl_pop_matrix},
  {"PopName", luagl_pop_name},
  {"PrioritizeTextures", luagl_prioritize_textures},
  {"PushAttrib", luagl_push_attrib},
  {"PushClientAttrib", luagl_push_client_attrib},
  {"PushMatrix", luagl_push_matrix},
  {"PushName", luagl_push_name},
  {"RasterPos", luagl_raster_pos},
  {"ReadBuffer", luagl_read_buffer},
  {"ReadPixels", luagl_read_pixels},
  {"ReadPixelsRaw", luagl_read_pixels_raw},
  {"Rect", luagl_rect},
  {"RenderMode", luagl_render_mode},
  {"Rotate", luagl_rotate},
  {"Scale", luagl_scale},
  {"Scissor", luagl_scissor},
  {"SelectBuffer", luagl_select_buffer},
  {"GetSelectBuffer", luagl_get_select_buffer},
  {"FreeSelectBuffer", luagl_free_select_buffer},
  {"NewData", luagl_new_data},
  {"FreeData", luagl_free_data},
  {"ShadeModel", luagl_shade_model},
  {"StencilFunc", luagl_stencil_func},
  {"StencilMask", luagl_stencil_mask},
  {"StencilOp", luagl_stencil_op},
  {"TexCoord", luagl_tex_coord},
  {"TexCoordPointer", luagl_tex_coord_pointer},
  {"TexEnv", luagl_tex_env},
  {"TexGen", luagl_tex_gen},
  {"TexImage", luagl_tex_image},
  {"TexImage1D", luagl_tex_image_1d},
  {"TexImage2D", luagl_tex_image_2d},
  {"TexSubImage", luagl_tex_sub_image},
  {"TexSubImage1D", luagl_tex_sub_image_1d},
  {"TexSubImage2D", luagl_tex_sub_image_2d},
  {"TexParameter", luagl_tex_parameter},
  {"Translate", luagl_translate},
  {"Vertex", luagl_vertex},
  {"VertexPointer", luagl_vertex_pointer},
  {"Viewport", luagl_viewport},
  {NULL, NULL}
};

int luaopen_luagl(lua_State *L) 
{
  luaL_register(L, "gl", luagl_lib);

  luagl_open_const(L);

  lua_pushstring(L, "_VERSION");
  lua_pushstring(L, LUAGL_VERSION);
  lua_settable(L,-3);

  return 1;
}
