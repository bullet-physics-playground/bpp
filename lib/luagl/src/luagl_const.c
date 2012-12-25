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

/* includes OpenGL, but do NOT use their functions, so no need to link */
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

#include "luagl_const.h"


static const luaglConst luagl_const[] = {
  { "VERSION_1_1"                     , GL_VERSION_1_1                    },
#ifdef GL_VERSION_1_2
  { "VERSION_1_2"                     , GL_VERSION_1_2                    },
#endif
#ifdef GL_VERSION_1_3
  { "VERSION_1_3"                     , GL_VERSION_1_3                    },
#endif
  { "ACCUM"                           , GL_ACCUM                          },
  { "LOAD"                            , GL_LOAD                           },
  { "RETURN"                          , GL_RETURN                         },
  { "MULT"                            , GL_MULT                           },
  { "ADD"                             , GL_ADD                            },
  { "NEVER"                           , GL_NEVER                          },
  { "LESS"                            , GL_LESS                           },
  { "EQUAL"                           , GL_EQUAL                          },
  { "LEQUAL"                          , GL_LEQUAL                         },
  { "GREATER"                         , GL_GREATER                        },
  { "NOTEQUAL"                        , GL_NOTEQUAL                       },
  { "GEQUAL"                          , GL_GEQUAL                         },
  { "ALWAYS"                          , GL_ALWAYS                         },
  { "POINTS"                          , GL_POINTS                         },
  { "LINES"                           , GL_LINES                          },
  { "LINE_LOOP"                       , GL_LINE_LOOP                      },
  { "LINE_STRIP"                      , GL_LINE_STRIP                     },
  { "TRIANGLES"                       , GL_TRIANGLES                      },
  { "TRIANGLE_STRIP"                  , GL_TRIANGLE_STRIP                 },
  { "TRIANGLE_FAN"                    , GL_TRIANGLE_FAN                   },
  { "QUADS"                           , GL_QUADS                          },
  { "QUAD_STRIP"                      , GL_QUAD_STRIP                     },
  { "POLYGON"                         , GL_POLYGON                        },
  { "ZERO"                            , GL_ZERO                           },
  { "ONE"                             , GL_ONE                            },
  { "SRC_COLOR"                       , GL_SRC_COLOR                      },
  { "ONE_MINUS_SRC_COLOR"             , GL_ONE_MINUS_SRC_COLOR            },
  { "SRC_ALPHA"                       , GL_SRC_ALPHA                      },
  { "ONE_MINUS_SRC_ALPHA"             , GL_ONE_MINUS_SRC_ALPHA            },
  { "DST_ALPHA"                       , GL_DST_ALPHA                      },
  { "ONE_MINUS_DST_ALPHA"             , GL_ONE_MINUS_DST_ALPHA            },
  { "DST_COLOR"                       , GL_DST_COLOR                      },
  { "ONE_MINUS_DST_COLOR"             , GL_ONE_MINUS_DST_COLOR            },
  { "SRC_ALPHA_SATURATE"              , GL_SRC_ALPHA_SATURATE             },
  { "TRUE"                            , GL_TRUE                           },
  { "FALSE"                           , GL_FALSE                          },
  { "CLIP_PLANE0"                     , GL_CLIP_PLANE0                    },
  { "CLIP_PLANE1"                     , GL_CLIP_PLANE1                    },
  { "CLIP_PLANE2"                     , GL_CLIP_PLANE2                    },
  { "CLIP_PLANE3"                     , GL_CLIP_PLANE3                    },
  { "CLIP_PLANE4"                     , GL_CLIP_PLANE4                    },
  { "CLIP_PLANE5"                     , GL_CLIP_PLANE5                    },
  { "BYTE"                            , GL_BYTE                           },
  { "UNSIGNED_BYTE"                   , GL_UNSIGNED_BYTE                  },
  { "SHORT"                           , GL_SHORT                          },
  { "UNSIGNED_SHORT"                  , GL_UNSIGNED_SHORT                 },
  { "INT"                             , GL_INT                            },
  { "UNSIGNED_INT"                    , GL_UNSIGNED_INT                   },
  { "FLOAT"                           , GL_FLOAT                          },
  { "2_BYTES"                         , GL_2_BYTES                        },
  { "3_BYTES"                         , GL_3_BYTES                        },
  { "4_BYTES"                         , GL_4_BYTES                        },
  { "DOUBLE"                          , GL_DOUBLE                         },
  { "NONE"                            , GL_NONE                           },
  { "FRONT_LEFT"                      , GL_FRONT_LEFT                     },
  { "FRONT_RIGHT"                     , GL_FRONT_RIGHT                    },
  { "BACK_LEFT"                       , GL_BACK_LEFT                      },
  { "BACK_RIGHT"                      , GL_BACK_RIGHT                     },
  { "FRONT"                           , GL_FRONT                          },
  { "BACK"                            , GL_BACK                           },
  { "LEFT"                            , GL_LEFT                           },
  { "RIGHT"                           , GL_RIGHT                          },
  { "FRONT_AND_BACK"                  , GL_FRONT_AND_BACK                 },
  { "AUX0"                            , GL_AUX0                           },
  { "AUX1"                            , GL_AUX1                           },
  { "AUX2"                            , GL_AUX2                           },
  { "AUX3"                            , GL_AUX3                           },
  { "NO_ERROR"                        , GL_NO_ERROR                       },
  { "INVALID_ENUM"                    , GL_INVALID_ENUM                   },
  { "INVALID_VALUE"                   , GL_INVALID_VALUE                  },
  { "INVALID_OPERATION"               , GL_INVALID_OPERATION              },
  { "STACK_OVERFLOW"                  , GL_STACK_OVERFLOW                 },
  { "STACK_UNDERFLOW"                 , GL_STACK_UNDERFLOW                },
  { "OUT_OF_MEMORY"                   , GL_OUT_OF_MEMORY                  },
  { "2D"                              , GL_2D                             },
  { "3D"                              , GL_3D                             },
  { "3D_COLOR"                        , GL_3D_COLOR                       },
  { "3D_COLOR_TEXTURE"                , GL_3D_COLOR_TEXTURE               },
  { "4D_COLOR_TEXTURE"                , GL_4D_COLOR_TEXTURE               },
  { "PASS_THROUGH_TOKEN"              , GL_PASS_THROUGH_TOKEN             },
  { "POINT_TOKEN"                     , GL_POINT_TOKEN                    },
  { "LINE_TOKEN"                      , GL_LINE_TOKEN                     },
  { "POLYGON_TOKEN"                   , GL_POLYGON_TOKEN                  },
  { "BITMAP_TOKEN"                    , GL_BITMAP_TOKEN                   },
  { "DRAW_PIXEL_TOKEN"                , GL_DRAW_PIXEL_TOKEN               },
  { "COPY_PIXEL_TOKEN"                , GL_COPY_PIXEL_TOKEN               },
  { "LINE_RESET_TOKEN"                , GL_LINE_RESET_TOKEN               },
  { "EXP"                             , GL_EXP                            },
  { "EXP2"                            , GL_EXP2                           },
  { "CW"                              , GL_CW                             },
  { "CCW"                             , GL_CCW                            },
  { "COEFF"                           , GL_COEFF                          },
  { "ORDER"                           , GL_ORDER                          },
  { "DOMAIN"                          , GL_DOMAIN                         },
  { "CURRENT_COLOR"                   , GL_CURRENT_COLOR                  },
  { "CURRENT_INDEX"                   , GL_CURRENT_INDEX                  },
  { "CURRENT_NORMAL"                  , GL_CURRENT_NORMAL                 },
  { "CURRENT_TEXTURE_COORDS"          , GL_CURRENT_TEXTURE_COORDS         },
  { "CURRENT_RASTER_COLOR"            , GL_CURRENT_RASTER_COLOR           },
  { "CURRENT_RASTER_INDEX"            , GL_CURRENT_RASTER_INDEX           },
  { "CURRENT_RASTER_TEXTURE_COORDS"   , GL_CURRENT_RASTER_TEXTURE_COORDS  },
  { "CURRENT_RASTER_POSITION"         , GL_CURRENT_RASTER_POSITION        },
  { "CURRENT_RASTER_POSITION_VALID"   , GL_CURRENT_RASTER_POSITION_VALID  },
  { "CURRENT_RASTER_DISTANCE"         , GL_CURRENT_RASTER_DISTANCE        },
  { "POINT_SMOOTH"                    , GL_POINT_SMOOTH                   },
  { "POINT_SIZE"                      , GL_POINT_SIZE                     },
  { "POINT_SIZE_RANGE"                , GL_POINT_SIZE_RANGE               },
  { "POINT_SIZE_GRANULARITY"          , GL_POINT_SIZE_GRANULARITY         },
  { "LINE_SMOOTH"                     , GL_LINE_SMOOTH                    },
  { "LINE_WIDTH"                      , GL_LINE_WIDTH                     },
  { "LINE_WIDTH_RANGE"                , GL_LINE_WIDTH_RANGE               },
  { "LINE_WIDTH_GRANULARITY"          , GL_LINE_WIDTH_GRANULARITY         },
  { "LINE_STIPPLE"                    , GL_LINE_STIPPLE                   },
  { "LINE_STIPPLE_PATTERN"            , GL_LINE_STIPPLE_PATTERN           },
  { "LINE_STIPPLE_REPEAT"             , GL_LINE_STIPPLE_REPEAT            },
  { "LIST_MODE"                       , GL_LIST_MODE                      },
  { "MAX_LIST_NESTING"                , GL_MAX_LIST_NESTING               },
  { "LIST_BASE"                       , GL_LIST_BASE                      },
  { "LIST_INDEX"                      , GL_LIST_INDEX                     },
  { "POLYGON_MODE"                    , GL_POLYGON_MODE                   },
  { "POLYGON_SMOOTH"                  , GL_POLYGON_SMOOTH                 },
  { "POLYGON_STIPPLE"                 , GL_POLYGON_STIPPLE                },
  { "EDGE_FLAG"                       , GL_EDGE_FLAG                      },
  { "CULL_FACE"                       , GL_CULL_FACE                      },
  { "CULL_FACE_MODE"                  , GL_CULL_FACE_MODE                 },
  { "FRONT_FACE"                      , GL_FRONT_FACE                     },
  { "LIGHTING"                        , GL_LIGHTING                       },
  { "LIGHT_MODEL_LOCAL_VIEWER"        , GL_LIGHT_MODEL_LOCAL_VIEWER       },
  { "LIGHT_MODEL_TWO_SIDE"            , GL_LIGHT_MODEL_TWO_SIDE           },
  { "LIGHT_MODEL_AMBIENT"             , GL_LIGHT_MODEL_AMBIENT            },
  { "SHADE_MODEL"                     , GL_SHADE_MODEL                    },
  { "COLOR_MATERIAL_FACE"             , GL_COLOR_MATERIAL_FACE            },
  { "COLOR_MATERIAL_PARAMETER"        , GL_COLOR_MATERIAL_PARAMETER       },
  { "COLOR_MATERIAL"                  , GL_COLOR_MATERIAL                 },
  { "FOG"                             , GL_FOG                            },
  { "FOG_INDEX"                       , GL_FOG_INDEX                      },
  { "FOG_DENSITY"                     , GL_FOG_DENSITY                    },
  { "FOG_START"                       , GL_FOG_START                      },
  { "FOG_END"                         , GL_FOG_END                        },
  { "FOG_MODE"                        , GL_FOG_MODE                       },
  { "FOG_COLOR"                       , GL_FOG_COLOR                      },
  { "DEPTH_RANGE"                     , GL_DEPTH_RANGE                    },
  { "DEPTH_TEST"                      , GL_DEPTH_TEST                     },
  { "DEPTH_WRITEMASK"                 , GL_DEPTH_WRITEMASK                },
  { "DEPTH_CLEAR_VALUE"               , GL_DEPTH_CLEAR_VALUE              },
  { "DEPTH_FUNC"                      , GL_DEPTH_FUNC                     },
  { "ACCUM_CLEAR_VALUE"               , GL_ACCUM_CLEAR_VALUE              },
  { "STENCIL_TEST"                    , GL_STENCIL_TEST                   },
  { "STENCIL_CLEAR_VALUE"             , GL_STENCIL_CLEAR_VALUE            },
  { "STENCIL_FUNC"                    , GL_STENCIL_FUNC                   },
  { "STENCIL_VALUE_MASK"              , GL_STENCIL_VALUE_MASK             },
  { "STENCIL_FAIL"                    , GL_STENCIL_FAIL                   },
  { "STENCIL_PASS_DEPTH_FAIL"         , GL_STENCIL_PASS_DEPTH_FAIL        },
  { "STENCIL_PASS_DEPTH_PASS"         , GL_STENCIL_PASS_DEPTH_PASS        },
  { "STENCIL_REF"                     , GL_STENCIL_REF                    },
  { "STENCIL_WRITEMASK"               , GL_STENCIL_WRITEMASK              },
  { "MATRIX_MODE"                     , GL_MATRIX_MODE                    },
  { "NORMALIZE"                       , GL_NORMALIZE                      },
  { "VIEWPORT"                        , GL_VIEWPORT                       },
  { "MODELVIEW_STACK_DEPTH"           , GL_MODELVIEW_STACK_DEPTH          },
  { "PROJECTION_STACK_DEPTH"          , GL_PROJECTION_STACK_DEPTH         },
  { "TEXTURE_STACK_DEPTH"             , GL_TEXTURE_STACK_DEPTH            },
  { "MODELVIEW_MATRIX"                , GL_MODELVIEW_MATRIX               },
  { "PROJECTION_MATRIX"               , GL_PROJECTION_MATRIX              },
  { "TEXTURE_MATRIX"                  , GL_TEXTURE_MATRIX                 },
  { "ATTRIB_STACK_DEPTH"              , GL_ATTRIB_STACK_DEPTH             },
  { "CLIENT_ATTRIB_STACK_DEPTH"       , GL_CLIENT_ATTRIB_STACK_DEPTH      },
  { "ALPHA_TEST"                      , GL_ALPHA_TEST                     },
  { "ALPHA_TEST_FUNC"                 , GL_ALPHA_TEST_FUNC                },
  { "ALPHA_TEST_REF"                  , GL_ALPHA_TEST_REF                 },
  { "DITHER"                          , GL_DITHER                         },
  { "BLEND_DST"                       , GL_BLEND_DST                      },
  { "BLEND_SRC"                       , GL_BLEND_SRC                      },
  { "BLEND"                           , GL_BLEND                          },
  { "LOGIC_OP_MODE"                   , GL_LOGIC_OP_MODE                  },
  { "LOGIC_OP"                        , GL_LOGIC_OP                       },
  { "INDEX_LOGIC_OP"                  , GL_INDEX_LOGIC_OP                 },
  { "COLOR_LOGIC_OP"                  , GL_COLOR_LOGIC_OP                 },
  { "AUX_BUFFERS"                     , GL_AUX_BUFFERS                    },
  { "DRAW_BUFFER"                     , GL_DRAW_BUFFER                    },
  { "READ_BUFFER"                     , GL_READ_BUFFER                    },
  { "SCISSOR_BOX"                     , GL_SCISSOR_BOX                    },
  { "SCISSOR_TEST"                    , GL_SCISSOR_TEST                   },
  { "INDEX_CLEAR_VALUE"               , GL_INDEX_CLEAR_VALUE              },
  { "INDEX_WRITEMASK"                 , GL_INDEX_WRITEMASK                },
  { "COLOR_CLEAR_VALUE"               , GL_COLOR_CLEAR_VALUE              },
  { "COLOR_WRITEMASK"                 , GL_COLOR_WRITEMASK                },
  { "INDEX_MODE"                      , GL_INDEX_MODE                     },
  { "RGBA_MODE"                       , GL_RGBA_MODE                      },
  { "DOUBLEBUFFER"                    , GL_DOUBLEBUFFER                   },
  { "STEREO"                          , GL_STEREO                         },
  { "RENDER_MODE"                     , GL_RENDER_MODE                    },
  { "PERSPECTIVE_CORRECTION_HINT"     , GL_PERSPECTIVE_CORRECTION_HINT    },
  { "POINT_SMOOTH_HINT"               , GL_POINT_SMOOTH_HINT              },
  { "LINE_SMOOTH_HINT"                , GL_LINE_SMOOTH_HINT               },
  { "POLYGON_SMOOTH_HINT"             , GL_POLYGON_SMOOTH_HINT            },
  { "FOG_HINT"                        , GL_FOG_HINT                       },
  { "TEXTURE_GEN_S"                   , GL_TEXTURE_GEN_S                  },
  { "TEXTURE_GEN_T"                   , GL_TEXTURE_GEN_T                  },
  { "TEXTURE_GEN_R"                   , GL_TEXTURE_GEN_R                  },
  { "TEXTURE_GEN_Q"                   , GL_TEXTURE_GEN_Q                  },
  { "PIXEL_MAP_I_TO_I"                , GL_PIXEL_MAP_I_TO_I               },
  { "PIXEL_MAP_S_TO_S"                , GL_PIXEL_MAP_S_TO_S               },
  { "PIXEL_MAP_I_TO_R"                , GL_PIXEL_MAP_I_TO_R               },
  { "PIXEL_MAP_I_TO_G"                , GL_PIXEL_MAP_I_TO_G               },
  { "PIXEL_MAP_I_TO_B"                , GL_PIXEL_MAP_I_TO_B               },
  { "PIXEL_MAP_I_TO_A"                , GL_PIXEL_MAP_I_TO_A               },
  { "PIXEL_MAP_R_TO_R"                , GL_PIXEL_MAP_R_TO_R               },
  { "PIXEL_MAP_G_TO_G"                , GL_PIXEL_MAP_G_TO_G               },
  { "PIXEL_MAP_B_TO_B"                , GL_PIXEL_MAP_B_TO_B               },
  { "PIXEL_MAP_A_TO_A"                , GL_PIXEL_MAP_A_TO_A               },
  { "PIXEL_MAP_I_TO_I_SIZE"           , GL_PIXEL_MAP_I_TO_I_SIZE          },
  { "PIXEL_MAP_S_TO_S_SIZE"           , GL_PIXEL_MAP_S_TO_S_SIZE          },
  { "PIXEL_MAP_I_TO_R_SIZE"           , GL_PIXEL_MAP_I_TO_R_SIZE          },
  { "PIXEL_MAP_I_TO_G_SIZE"           , GL_PIXEL_MAP_I_TO_G_SIZE          },
  { "PIXEL_MAP_I_TO_B_SIZE"           , GL_PIXEL_MAP_I_TO_B_SIZE          },
  { "PIXEL_MAP_I_TO_A_SIZE"           , GL_PIXEL_MAP_I_TO_A_SIZE          },
  { "PIXEL_MAP_R_TO_R_SIZE"           , GL_PIXEL_MAP_R_TO_R_SIZE          },
  { "PIXEL_MAP_G_TO_G_SIZE"           , GL_PIXEL_MAP_G_TO_G_SIZE          },
  { "PIXEL_MAP_B_TO_B_SIZE"           , GL_PIXEL_MAP_B_TO_B_SIZE          },
  { "PIXEL_MAP_A_TO_A_SIZE"           , GL_PIXEL_MAP_A_TO_A_SIZE          },
  { "UNPACK_SWAP_BYTES"               , GL_UNPACK_SWAP_BYTES              },
  { "UNPACK_LSB_FIRST"                , GL_UNPACK_LSB_FIRST               },
  { "UNPACK_ROW_LENGTH"               , GL_UNPACK_ROW_LENGTH              },
  { "UNPACK_SKIP_ROWS"                , GL_UNPACK_SKIP_ROWS               },
  { "UNPACK_SKIP_PIXELS"              , GL_UNPACK_SKIP_PIXELS             },
  { "UNPACK_ALIGNMENT"                , GL_UNPACK_ALIGNMENT               },
  { "PACK_SWAP_BYTES"                 , GL_PACK_SWAP_BYTES                },
  { "PACK_LSB_FIRST"                  , GL_PACK_LSB_FIRST                 },
  { "PACK_ROW_LENGTH"                 , GL_PACK_ROW_LENGTH                },
  { "PACK_SKIP_ROWS"                  , GL_PACK_SKIP_ROWS                 },
  { "PACK_SKIP_PIXELS"                , GL_PACK_SKIP_PIXELS               },
  { "PACK_ALIGNMENT"                  , GL_PACK_ALIGNMENT                 },
  { "MAP_COLOR"                       , GL_MAP_COLOR                      },
  { "MAP_STENCIL"                     , GL_MAP_STENCIL                    },
  { "INDEX_SHIFT"                     , GL_INDEX_SHIFT                    },
  { "INDEX_OFFSET"                    , GL_INDEX_OFFSET                   },
  { "RED_SCALE"                       , GL_RED_SCALE                      },
  { "RED_BIAS"                        , GL_RED_BIAS                       },
  { "ZOOM_X"                          , GL_ZOOM_X                         },
  { "ZOOM_Y"                          , GL_ZOOM_Y                         },
  { "GREEN_SCALE"                     , GL_GREEN_SCALE                    },
  { "GREEN_BIAS"                      , GL_GREEN_BIAS                     },
  { "BLUE_SCALE"                      , GL_BLUE_SCALE                     },
  { "BLUE_BIAS"                       , GL_BLUE_BIAS                      },
  { "ALPHA_SCALE"                     , GL_ALPHA_SCALE                    },
  { "ALPHA_BIAS"                      , GL_ALPHA_BIAS                     },
  { "DEPTH_SCALE"                     , GL_DEPTH_SCALE                    },
  { "DEPTH_BIAS"                      , GL_DEPTH_BIAS                     },
  { "MAX_EVAL_ORDER"                  , GL_MAX_EVAL_ORDER                 },
  { "MAX_LIGHTS"                      , GL_MAX_LIGHTS                     },
  { "MAX_CLIP_PLANES"                 , GL_MAX_CLIP_PLANES                },
  { "MAX_TEXTURE_SIZE"                , GL_MAX_TEXTURE_SIZE               },
  { "MAX_PIXEL_MAP_TABLE"             , GL_MAX_PIXEL_MAP_TABLE            },
  { "MAX_ATTRIB_STACK_DEPTH"          , GL_MAX_ATTRIB_STACK_DEPTH         },
  { "MAX_MODELVIEW_STACK_DEPTH"       , GL_MAX_MODELVIEW_STACK_DEPTH      },
  { "MAX_NAME_STACK_DEPTH"            , GL_MAX_NAME_STACK_DEPTH           },
  { "MAX_PROJECTION_STACK_DEPTH"      , GL_MAX_PROJECTION_STACK_DEPTH     },
  { "MAX_TEXTURE_STACK_DEPTH"         , GL_MAX_TEXTURE_STACK_DEPTH        },
  { "MAX_VIEWPORT_DIMS"               , GL_MAX_VIEWPORT_DIMS              },
  { "MAX_CLIENT_ATTRIB_STACK_DEPTH"   , GL_MAX_CLIENT_ATTRIB_STACK_DEPTH  },
  { "SUBPIXEL_BITS"                   , GL_SUBPIXEL_BITS                  },
  { "INDEX_BITS"                      , GL_INDEX_BITS                     },
  { "RED_BITS"                        , GL_RED_BITS                       },
  { "GREEN_BITS"                      , GL_GREEN_BITS                     },
  { "BLUE_BITS"                       , GL_BLUE_BITS                      },
  { "ALPHA_BITS"                      , GL_ALPHA_BITS                     },
  { "DEPTH_BITS"                      , GL_DEPTH_BITS                     },
  { "STENCIL_BITS"                    , GL_STENCIL_BITS                   },
  { "ACCUM_RED_BITS"                  , GL_ACCUM_RED_BITS                 },
  { "ACCUM_GREEN_BITS"                , GL_ACCUM_GREEN_BITS               },
  { "ACCUM_BLUE_BITS"                 , GL_ACCUM_BLUE_BITS                },
  { "ACCUM_ALPHA_BITS"                , GL_ACCUM_ALPHA_BITS               },
  { "NAME_STACK_DEPTH"                , GL_NAME_STACK_DEPTH               },
  { "AUTO_NORMAL"                     , GL_AUTO_NORMAL                    },
  { "MAP1_COLOR_4"                    , GL_MAP1_COLOR_4                   },
  { "MAP1_INDEX"                      , GL_MAP1_INDEX                     },
  { "MAP1_NORMAL"                     , GL_MAP1_NORMAL                    },
  { "MAP1_TEXTURE_COORD_1"            , GL_MAP1_TEXTURE_COORD_1           },
  { "MAP1_TEXTURE_COORD_2"            , GL_MAP1_TEXTURE_COORD_2           },
  { "MAP1_TEXTURE_COORD_3"            , GL_MAP1_TEXTURE_COORD_3           },
  { "MAP1_TEXTURE_COORD_4"            , GL_MAP1_TEXTURE_COORD_4           },
  { "MAP1_VERTEX_3"                   , GL_MAP1_VERTEX_3                  },
  { "MAP1_VERTEX_4"                   , GL_MAP1_VERTEX_4                  },
  { "MAP2_COLOR_4"                    , GL_MAP2_COLOR_4                   },
  { "MAP2_INDEX"                      , GL_MAP2_INDEX                     },
  { "MAP2_NORMAL"                     , GL_MAP2_NORMAL                    },
  { "MAP2_TEXTURE_COORD_1"            , GL_MAP2_TEXTURE_COORD_1           },
  { "MAP2_TEXTURE_COORD_2"            , GL_MAP2_TEXTURE_COORD_2           },
  { "MAP2_TEXTURE_COORD_3"            , GL_MAP2_TEXTURE_COORD_3           },
  { "MAP2_TEXTURE_COORD_4"            , GL_MAP2_TEXTURE_COORD_4           },
  { "MAP2_VERTEX_3"                   , GL_MAP2_VERTEX_3                  },
  { "MAP2_VERTEX_4"                   , GL_MAP2_VERTEX_4                  },
  { "MAP1_GRID_DOMAIN"                , GL_MAP1_GRID_DOMAIN               },
  { "MAP1_GRID_SEGMENTS"              , GL_MAP1_GRID_SEGMENTS             },
  { "MAP2_GRID_DOMAIN"                , GL_MAP2_GRID_DOMAIN               },
  { "MAP2_GRID_SEGMENTS"              , GL_MAP2_GRID_SEGMENTS             },
  { "TEXTURE_1D"                      , GL_TEXTURE_1D                     },
  { "TEXTURE_2D"                      , GL_TEXTURE_2D                     },
  { "FEEDBACK_BUFFER_POINTER"         , GL_FEEDBACK_BUFFER_POINTER        },
  { "FEEDBACK_BUFFER_SIZE"            , GL_FEEDBACK_BUFFER_SIZE           },
  { "FEEDBACK_BUFFER_TYPE"            , GL_FEEDBACK_BUFFER_TYPE           },
  { "SELECTION_BUFFER_POINTER"        , GL_SELECTION_BUFFER_POINTER       },
  { "SELECTION_BUFFER_SIZE"           , GL_SELECTION_BUFFER_SIZE          },
  { "TEXTURE_WIDTH"                   , GL_TEXTURE_WIDTH                  },
  { "TEXTURE_HEIGHT"                  , GL_TEXTURE_HEIGHT                 },
  { "TEXTURE_COMPONENTS"              , GL_TEXTURE_COMPONENTS             },
  { "TEXTURE_INTERNAL_FORMAT"         , GL_TEXTURE_INTERNAL_FORMAT        },
  { "TEXTURE_BORDER_COLOR"            , GL_TEXTURE_BORDER_COLOR           },
  { "TEXTURE_BORDER"                  , GL_TEXTURE_BORDER                 },
  { "DONT_CARE"                       , GL_DONT_CARE                      },
  { "FASTEST"                         , GL_FASTEST                        },
  { "NICEST"                          , GL_NICEST                         },
  { "LIGHT0"                          , GL_LIGHT0                         },
  { "LIGHT1"                          , GL_LIGHT1                         },
  { "LIGHT2"                          , GL_LIGHT2                         },
  { "LIGHT3"                          , GL_LIGHT3                         },
  { "LIGHT4"                          , GL_LIGHT4                         },
  { "LIGHT5"                          , GL_LIGHT5                         },
  { "LIGHT6"                          , GL_LIGHT6                         },
  { "LIGHT7"                          , GL_LIGHT7                         },
  { "AMBIENT"                         , GL_AMBIENT                        },
  { "DIFFUSE"                         , GL_DIFFUSE                        },
  { "SPECULAR"                        , GL_SPECULAR                       },
  { "POSITION"                        , GL_POSITION                       },
  { "SPOT_DIRECTION"                  , GL_SPOT_DIRECTION                 },
  { "SPOT_EXPONENT"                   , GL_SPOT_EXPONENT                  },
  { "SPOT_CUTOFF"                     , GL_SPOT_CUTOFF                    },
  { "CONSTANT_ATTENUATION"            , GL_CONSTANT_ATTENUATION           },
  { "LINEAR_ATTENUATION"              , GL_LINEAR_ATTENUATION             },
  { "QUADRATIC_ATTENUATION"           , GL_QUADRATIC_ATTENUATION          },
  { "COMPILE"                         , GL_COMPILE                        },
  { "COMPILE_AND_EXECUTE"             , GL_COMPILE_AND_EXECUTE            },
  { "CLEAR"                           , GL_CLEAR                          },
  { "AND"                             , GL_AND                            },
  { "AND_REVERSE"                     , GL_AND_REVERSE                    },
  { "COPY"                            , GL_COPY                           },
  { "AND_INVERTED"                    , GL_AND_INVERTED                   },
  { "NOOP"                            , GL_NOOP                           },
  { "XOR"                             , GL_XOR                            },
  { "OR"                              , GL_OR                             },
  { "NOR"                             , GL_NOR                            },
  { "EQUIV"                           , GL_EQUIV                          },
  { "INVERT"                          , GL_INVERT                         },
  { "OR_REVERSE"                      , GL_OR_REVERSE                     },
  { "COPY_INVERTED"                   , GL_COPY_INVERTED                  },
  { "OR_INVERTED"                     , GL_OR_INVERTED                    },
  { "NAND"                            , GL_NAND                           },
  { "SET"                             , GL_SET                            },
  { "EMISSION"                        , GL_EMISSION                       },
  { "SHININESS"                       , GL_SHININESS                      },
  { "AMBIENT_AND_DIFFUSE"             , GL_AMBIENT_AND_DIFFUSE            },
  { "COLOR_INDEXES"                   , GL_COLOR_INDEXES                  },
  { "MODELVIEW"                       , GL_MODELVIEW                      },
  { "PROJECTION"                      , GL_PROJECTION                     },
  { "TEXTURE"                         , GL_TEXTURE                        },
  { "COLOR"                           , GL_COLOR                          },
  { "DEPTH"                           , GL_DEPTH                          },
  { "STENCIL"                         , GL_STENCIL                        },
  { "COLOR_INDEX"                     , GL_COLOR_INDEX                    },
  { "STENCIL_INDEX"                   , GL_STENCIL_INDEX                  },
  { "DEPTH_COMPONENT"                 , GL_DEPTH_COMPONENT                },
  { "RED"                             , GL_RED                            },
  { "GREEN"                           , GL_GREEN                          },
  { "BLUE"                            , GL_BLUE                           },
  { "ALPHA"                           , GL_ALPHA                          },
  { "RGB"                             , GL_RGB                            },
  { "RGBA"                            , GL_RGBA                           },
  { "LUMINANCE"                       , GL_LUMINANCE                      },
  { "LUMINANCE_ALPHA"                 , GL_LUMINANCE_ALPHA                },
  { "BITMAP"                          , GL_BITMAP                         },
  { "POINT"                           , GL_POINT                          },
  { "LINE"                            , GL_LINE                           },
  { "FILL"                            , GL_FILL                           },
  { "RENDER"                          , GL_RENDER                         },
  { "FEEDBACK"                        , GL_FEEDBACK                       },
  { "SELECT"                          , GL_SELECT                         },
  { "FLAT"                            , GL_FLAT                           },
  { "SMOOTH"                          , GL_SMOOTH                         },
  { "KEEP"                            , GL_KEEP                           },
  { "REPLACE"                         , GL_REPLACE                        },
  { "INCR"                            , GL_INCR                           },
  { "DECR"                            , GL_DECR                           },
  { "VENDOR"                          , GL_VENDOR                         },
  { "RENDERER"                        , GL_RENDERER                       },
  { "VERSION"                         , GL_VERSION                        },
  { "EXTENSIONS"                      , GL_EXTENSIONS                     },
  { "S"                               , GL_S                              },
  { "T"                               , GL_T                              },
  { "R"                               , GL_R                              },
  { "Q"                               , GL_Q                              },
  { "MODULATE"                        , GL_MODULATE                       },
  { "DECAL"                           , GL_DECAL                          },
  { "TEXTURE_ENV_MODE"                , GL_TEXTURE_ENV_MODE               },
  { "TEXTURE_ENV_COLOR"               , GL_TEXTURE_ENV_COLOR              },
  { "TEXTURE_ENV"                     , GL_TEXTURE_ENV                    },
  { "EYE_LINEAR"                      , GL_EYE_LINEAR                     },
  { "OBJECT_LINEAR"                   , GL_OBJECT_LINEAR                  },
  { "SPHERE_MAP"                      , GL_SPHERE_MAP                     },
  { "TEXTURE_GEN_MODE"                , GL_TEXTURE_GEN_MODE               },
  { "OBJECT_PLANE"                    , GL_OBJECT_PLANE                   },
  { "EYE_PLANE"                       , GL_EYE_PLANE                      },
  { "NEAREST"                         , GL_NEAREST                        },
  { "LINEAR"                          , GL_LINEAR                         },
  { "NEAREST_MIPMAP_NEAREST"          , GL_NEAREST_MIPMAP_NEAREST         },
  { "LINEAR_MIPMAP_NEAREST"           , GL_LINEAR_MIPMAP_NEAREST          },
  { "NEAREST_MIPMAP_LINEAR"           , GL_NEAREST_MIPMAP_LINEAR          },
  { "LINEAR_MIPMAP_LINEAR"            , GL_LINEAR_MIPMAP_LINEAR           },
  { "TEXTURE_MAG_FILTER"              , GL_TEXTURE_MAG_FILTER             },
  { "TEXTURE_MIN_FILTER"              , GL_TEXTURE_MIN_FILTER             },
  { "TEXTURE_WRAP_S"                  , GL_TEXTURE_WRAP_S                 },
  { "TEXTURE_WRAP_T"                  , GL_TEXTURE_WRAP_T                 },
  { "CLAMP"                           , GL_CLAMP                          },
  { "REPEAT"                          , GL_REPEAT                         },
#ifdef GL_MIRRORED_REPEAT
  { "MIRRORED_REPEAT"                 , GL_MIRRORED_REPEAT                },
#endif
#ifdef GL_VERSION_1_2
  { "CLAMP_TO_EDGE"                   , GL_CLAMP_TO_EDGE                  },
#endif
  { "POLYGON_OFFSET_FACTOR"           , GL_POLYGON_OFFSET_FACTOR          },
  { "POLYGON_OFFSET_UNITS"            , GL_POLYGON_OFFSET_UNITS           },
  { "POLYGON_OFFSET_POINT"            , GL_POLYGON_OFFSET_POINT           },
  { "POLYGON_OFFSET_LINE"             , GL_POLYGON_OFFSET_LINE            },
  { "POLYGON_OFFSET_FILL"             , GL_POLYGON_OFFSET_FILL            },
  { "ALPHA4"                          , GL_ALPHA4                         },
  { "ALPHA8"                          , GL_ALPHA8                         },
  { "ALPHA12"                         , GL_ALPHA12                        },
  { "ALPHA16"                         , GL_ALPHA16                        },
  { "LUMINANCE4"                      , GL_LUMINANCE4                     },
  { "LUMINANCE8"                      , GL_LUMINANCE8                     },
  { "LUMINANCE12"                     , GL_LUMINANCE12                    },
  { "LUMINANCE16"                     , GL_LUMINANCE16                    },
  { "LUMINANCE4_ALPHA4"               , GL_LUMINANCE4_ALPHA4              },
  { "LUMINANCE6_ALPHA2"               , GL_LUMINANCE6_ALPHA2              },
  { "LUMINANCE8_ALPHA8"               , GL_LUMINANCE8_ALPHA8              },
  { "LUMINANCE12_ALPHA4"              , GL_LUMINANCE12_ALPHA4             },
  { "LUMINANCE12_ALPHA12"             , GL_LUMINANCE12_ALPHA12            },
  { "LUMINANCE16_ALPHA16"             , GL_LUMINANCE16_ALPHA16            },
  { "INTENSITY"                       , GL_INTENSITY                      },
  { "INTENSITY4"                      , GL_INTENSITY4                     },
  { "INTENSITY8"                      , GL_INTENSITY8                     },
  { "INTENSITY12"                     , GL_INTENSITY12                    },
  { "INTENSITY16"                     , GL_INTENSITY16                    },
  { "R3_G3_B2"                        , GL_R3_G3_B2                       },
  { "RGB4"                            , GL_RGB4                           },
  { "RGB5"                            , GL_RGB5                           },
  { "RGB8"                            , GL_RGB8                           },
  { "RGB10"                           , GL_RGB10                          },
  { "RGB12"                           , GL_RGB12                          },
  { "RGB16"                           , GL_RGB16                          },
  { "RGBA2"                           , GL_RGBA2                          },
  { "RGBA4"                           , GL_RGBA4                          },
  { "RGB5_A1"                         , GL_RGB5_A1                        },
  { "RGBA8"                           , GL_RGBA8                          },
  { "RGB10_A2"                        , GL_RGB10_A2                       },
  { "RGBA12"                          , GL_RGBA12                         },
  { "RGBA16"                          , GL_RGBA16                         },
  { "TEXTURE_RED_SIZE"                , GL_TEXTURE_RED_SIZE               },
  { "TEXTURE_GREEN_SIZE"              , GL_TEXTURE_GREEN_SIZE             },
  { "TEXTURE_BLUE_SIZE"               , GL_TEXTURE_BLUE_SIZE              },
  { "TEXTURE_ALPHA_SIZE"              , GL_TEXTURE_ALPHA_SIZE             },
  { "TEXTURE_LUMINANCE_SIZE"          , GL_TEXTURE_LUMINANCE_SIZE         },
  { "TEXTURE_INTENSITY_SIZE"          , GL_TEXTURE_INTENSITY_SIZE         },
  { "PROXY_TEXTURE_1D"                , GL_PROXY_TEXTURE_1D               },
  { "PROXY_TEXTURE_2D"                , GL_PROXY_TEXTURE_2D               },
  { "TEXTURE_PRIORITY"                , GL_TEXTURE_PRIORITY               },
  { "TEXTURE_RESIDENT"                , GL_TEXTURE_RESIDENT               },
  { "TEXTURE_BINDING_1D"              , GL_TEXTURE_BINDING_1D             },
  { "TEXTURE_BINDING_2D"              , GL_TEXTURE_BINDING_2D             },
  { "VERTEX_ARRAY"                    , GL_VERTEX_ARRAY                   },
  { "NORMAL_ARRAY"                    , GL_NORMAL_ARRAY                   },
  { "COLOR_ARRAY"                     , GL_COLOR_ARRAY                    },
  { "INDEX_ARRAY"                     , GL_INDEX_ARRAY                    },
  { "TEXTURE_COORD_ARRAY"             , GL_TEXTURE_COORD_ARRAY            },
  { "EDGE_FLAG_ARRAY"                 , GL_EDGE_FLAG_ARRAY                },
  { "VERTEX_ARRAY_SIZE"               , GL_VERTEX_ARRAY_SIZE              },
  { "VERTEX_ARRAY_TYPE"               , GL_VERTEX_ARRAY_TYPE              },
  { "VERTEX_ARRAY_STRIDE"             , GL_VERTEX_ARRAY_STRIDE            },
  { "NORMAL_ARRAY_TYPE"               , GL_NORMAL_ARRAY_TYPE              },
  { "NORMAL_ARRAY_STRIDE"             , GL_NORMAL_ARRAY_STRIDE            },
  { "COLOR_ARRAY_SIZE"                , GL_COLOR_ARRAY_SIZE               },
  { "COLOR_ARRAY_TYPE"                , GL_COLOR_ARRAY_TYPE               },
  { "COLOR_ARRAY_STRIDE"              , GL_COLOR_ARRAY_STRIDE             },
  { "INDEX_ARRAY_TYPE"                , GL_INDEX_ARRAY_TYPE               },
  { "INDEX_ARRAY_STRIDE"              , GL_INDEX_ARRAY_STRIDE             },
  { "TEXTURE_COORD_ARRAY_SIZE"        , GL_TEXTURE_COORD_ARRAY_SIZE       },
  { "TEXTURE_COORD_ARRAY_TYPE"        , GL_TEXTURE_COORD_ARRAY_TYPE       },
  { "TEXTURE_COORD_ARRAY_STRIDE"      , GL_TEXTURE_COORD_ARRAY_STRIDE     },
  { "EDGE_FLAG_ARRAY_STRIDE"          , GL_EDGE_FLAG_ARRAY_STRIDE         },
  { "VERTEX_ARRAY_POINTER"            , GL_VERTEX_ARRAY_POINTER           },
  { "NORMAL_ARRAY_POINTER"            , GL_NORMAL_ARRAY_POINTER           },
  { "COLOR_ARRAY_POINTER"             , GL_COLOR_ARRAY_POINTER            },
  { "INDEX_ARRAY_POINTER"             , GL_INDEX_ARRAY_POINTER            },
  { "TEXTURE_COORD_ARRAY_POINTER"     , GL_TEXTURE_COORD_ARRAY_POINTER    },
  { "EDGE_FLAG_ARRAY_POINTER"         , GL_EDGE_FLAG_ARRAY_POINTER        },
  { "V2F"                             , GL_V2F                            },
  { "V3F"                             , GL_V3F                            },
  { "C4UB_V2F"                        , GL_C4UB_V2F                       },
  { "C4UB_V3F"                        , GL_C4UB_V3F                       },
  { "C3F_V3F"                         , GL_C3F_V3F                        },
  { "N3F_V3F"                         , GL_N3F_V3F                        },
  { "C4F_N3F_V3F"                     , GL_C4F_N3F_V3F                    },
  { "T2F_V3F"                         , GL_T2F_V3F                        },
  { "T4F_V4F"                         , GL_T4F_V4F                        },
  { "T2F_C4UB_V3F"                    , GL_T2F_C4UB_V3F                   },
  { "T2F_C3F_V3F"                     , GL_T2F_C3F_V3F                    },
  { "T2F_N3F_V3F"                     , GL_T2F_N3F_V3F                    },
  { "T2F_C4F_N3F_V3F"                 , GL_T2F_C4F_N3F_V3F                },
  { "T4F_C4F_N3F_V4F"                 , GL_T4F_C4F_N3F_V4F                },
#ifdef GL_EXT_vertex_array
  { "EXT_vertex_array"                , GL_EXT_vertex_array               },
#endif
#ifdef GL_EXT_bgra
  { "EXT_bgra"                        , GL_EXT_bgra                       },
#endif
#ifdef GL_EXT_paletted_texture
  { "EXT_paletted_texture"            , GL_EXT_paletted_texture           },
#endif
#ifdef GL_WIN_swap_hint
  { "WIN_swap_hint"                   , GL_WIN_swap_hint                  },
  { "WIN_draw_range_elements"         , GL_WIN_draw_range_elements        },
#endif
#ifdef GL_VERTEX_ARRAY_EXT
  { "VERTEX_ARRAY_EXT"                , GL_VERTEX_ARRAY_EXT               },
  { "NORMAL_ARRAY_EXT"                , GL_NORMAL_ARRAY_EXT               },
  { "COLOR_ARRAY_EXT"                 , GL_COLOR_ARRAY_EXT                },
  { "INDEX_ARRAY_EXT"                 , GL_INDEX_ARRAY_EXT                },
  { "TEXTURE_COORD_ARRAY_EXT"         , GL_TEXTURE_COORD_ARRAY_EXT        },
  { "EDGE_FLAG_ARRAY_EXT"             , GL_EDGE_FLAG_ARRAY_EXT            },
  { "VERTEX_ARRAY_SIZE_EXT"           , GL_VERTEX_ARRAY_SIZE_EXT          },
  { "VERTEX_ARRAY_TYPE_EXT"           , GL_VERTEX_ARRAY_TYPE_EXT          },
  { "VERTEX_ARRAY_STRIDE_EXT"         , GL_VERTEX_ARRAY_STRIDE_EXT        },
  { "VERTEX_ARRAY_COUNT_EXT"          , GL_VERTEX_ARRAY_COUNT_EXT         },
  { "NORMAL_ARRAY_TYPE_EXT"           , GL_NORMAL_ARRAY_TYPE_EXT          },
  { "NORMAL_ARRAY_STRIDE_EXT"         , GL_NORMAL_ARRAY_STRIDE_EXT        },
  { "NORMAL_ARRAY_COUNT_EXT"          , GL_NORMAL_ARRAY_COUNT_EXT         },
  { "COLOR_ARRAY_SIZE_EXT"            , GL_COLOR_ARRAY_SIZE_EXT           },
  { "COLOR_ARRAY_TYPE_EXT"            , GL_COLOR_ARRAY_TYPE_EXT           },
  { "COLOR_ARRAY_STRIDE_EXT"          , GL_COLOR_ARRAY_STRIDE_EXT         },
  { "COLOR_ARRAY_COUNT_EXT"           , GL_COLOR_ARRAY_COUNT_EXT          },
  { "INDEX_ARRAY_TYPE_EXT"            , GL_INDEX_ARRAY_TYPE_EXT           },
  { "INDEX_ARRAY_STRIDE_EXT"          , GL_INDEX_ARRAY_STRIDE_EXT         },
  { "INDEX_ARRAY_COUNT_EXT"           , GL_INDEX_ARRAY_COUNT_EXT          },
  { "TEXTURE_COORD_ARRAY_SIZE_EXT"    , GL_TEXTURE_COORD_ARRAY_SIZE_EXT   },
  { "TEXTURE_COORD_ARRAY_TYPE_EXT"    , GL_TEXTURE_COORD_ARRAY_TYPE_EXT   },
  { "TEXTURE_COORD_ARRAY_STRIDE_EXT"  , GL_TEXTURE_COORD_ARRAY_STRIDE_EXT },
  { "TEXTURE_COORD_ARRAY_COUNT_EXT"   , GL_TEXTURE_COORD_ARRAY_COUNT_EXT  },
  { "EDGE_FLAG_ARRAY_STRIDE_EXT"      , GL_EDGE_FLAG_ARRAY_STRIDE_EXT     },
  { "EDGE_FLAG_ARRAY_COUNT_EXT"       , GL_EDGE_FLAG_ARRAY_COUNT_EXT      },
  { "VERTEX_ARRAY_POINTER_EXT"        , GL_VERTEX_ARRAY_POINTER_EXT       },
  { "NORMAL_ARRAY_POINTER_EXT"        , GL_NORMAL_ARRAY_POINTER_EXT       },
  { "COLOR_ARRAY_POINTER_EXT"         , GL_COLOR_ARRAY_POINTER_EXT        },
  { "INDEX_ARRAY_POINTER_EXT"         , GL_INDEX_ARRAY_POINTER_EXT        },
  { "TEXTURE_COORD_ARRAY_POINTER_EXT" , GL_TEXTURE_COORD_ARRAY_POINTER_EXT},
  { "EDGE_FLAG_ARRAY_POINTER_EXT"     , GL_EDGE_FLAG_ARRAY_POINTER_EXT    },
#endif
#ifdef GL_BGR_EXT
  { "BGR_EXT"                         , GL_BGR_EXT                        },
  { "BGRA_EXT"                        , GL_BGRA_EXT                       },
#endif
#ifdef GL_COLOR_TABLE_FORMAT_EXT
  { "COLOR_TABLE_FORMAT_EXT"          , GL_COLOR_TABLE_FORMAT_EXT         },
  { "COLOR_TABLE_WIDTH_EXT"           , GL_COLOR_TABLE_WIDTH_EXT          },
  { "COLOR_TABLE_RED_SIZE_EXT"        , GL_COLOR_TABLE_RED_SIZE_EXT       },
  { "COLOR_TABLE_GREEN_SIZE_EXT"      , GL_COLOR_TABLE_GREEN_SIZE_EXT     },
  { "COLOR_TABLE_BLUE_SIZE_EXT"       , GL_COLOR_TABLE_BLUE_SIZE_EXT      },
  { "COLOR_TABLE_ALPHA_SIZE_EXT"      , GL_COLOR_TABLE_ALPHA_SIZE_EXT     },
  { "COLOR_TABLE_LUMINANCE_SIZE_EXT"  , GL_COLOR_TABLE_LUMINANCE_SIZE_EXT },
  { "COLOR_TABLE_INTENSITY_SIZE_EXT"  , GL_COLOR_TABLE_INTENSITY_SIZE_EXT },
#endif
#ifdef GL_COLOR_INDEX1_EXT
  { "COLOR_INDEX1_EXT"                , GL_COLOR_INDEX1_EXT               },
  { "COLOR_INDEX2_EXT"                , GL_COLOR_INDEX2_EXT               },
  { "COLOR_INDEX4_EXT"                , GL_COLOR_INDEX4_EXT               },
  { "COLOR_INDEX8_EXT"                , GL_COLOR_INDEX8_EXT               },
  { "COLOR_INDEX12_EXT"               , GL_COLOR_INDEX12_EXT              },
  { "COLOR_INDEX16_EXT"               , GL_COLOR_INDEX16_EXT              },
#endif
#ifdef GL_MAX_ELEMENTS_VERTICES_WIN
  { "MAX_ELEMENTS_VERTICES_WIN"       , GL_MAX_ELEMENTS_VERTICES_WIN      },
  { "MAX_ELEMENTS_INDICES_WIN"        , GL_MAX_ELEMENTS_INDICES_WIN       },
#endif
#ifdef GL_PHONG_WIN
  { "PHONG_WIN"                       , GL_PHONG_WIN                      },
  { "PHONG_HINT_WIN"                  , GL_PHONG_HINT_WIN                 },
#endif
#ifdef GL_FOG_SPECULAR_TEXTURE_WIN
  { "FOG_SPECULAR_TEXTURE_WIN"        , GL_FOG_SPECULAR_TEXTURE_WIN       },
#endif
  { "CURRENT_BIT"                     , GL_CURRENT_BIT                    },
  { "POINT_BIT"                       , GL_POINT_BIT                      },
  { "LINE_BIT"                        , GL_LINE_BIT                       },
  { "POLYGON_BIT"                     , GL_POLYGON_BIT                    },
  { "POLYGON_STIPPLE_BIT"             , GL_POLYGON_STIPPLE_BIT            },
  { "PIXEL_MODE_BIT"                  , GL_PIXEL_MODE_BIT                 },
  { "LIGHTING_BIT"                    , GL_LIGHTING_BIT                   },
  { "FOG_BIT"                         , GL_FOG_BIT                        },
  { "DEPTH_BUFFER_BIT"                , GL_DEPTH_BUFFER_BIT               },
  { "ACCUM_BUFFER_BIT"                , GL_ACCUM_BUFFER_BIT               },
  { "STENCIL_BUFFER_BIT"              , GL_STENCIL_BUFFER_BIT             },
  { "VIEWPORT_BIT"                    , GL_VIEWPORT_BIT                   },
  { "TRANSFORM_BIT"                   , GL_TRANSFORM_BIT                  },
  { "ENABLE_BIT"                      , GL_ENABLE_BIT                     },
  { "COLOR_BUFFER_BIT"                , GL_COLOR_BUFFER_BIT               },
  { "HINT_BIT"                        , GL_HINT_BIT                       },
  { "EVAL_BIT"                        , GL_EVAL_BIT                       },
  { "LIST_BIT"                        , GL_LIST_BIT                       },
  { "TEXTURE_BIT"                     , GL_TEXTURE_BIT                    },
  { "SCISSOR_BIT"                     , GL_SCISSOR_BIT                    },
  { "ALL_ATTRIB_BITS"                 , GL_ALL_ATTRIB_BITS                },
  { "CLIENT_PIXEL_STORE_BIT"          , GL_CLIENT_PIXEL_STORE_BIT         },
  { "CLIENT_VERTEX_ARRAY_BIT"         , GL_CLIENT_VERTEX_ARRAY_BIT        },
#ifdef GL_CLIENT_ALL_ATTRIB_BITS
  { "CLIENT_ALL_ATTRIB_BITS"          , GL_CLIENT_ALL_ATTRIB_BITS         },
#endif
  { 0, 0}
};

unsigned int luagl_get_gl_enum(lua_State *L, int index)
{
  return luagl_get_enum(L, index, luagl_const);
}

const char *luagl_get_str_gl_enum(unsigned int num)
{
  unsigned int i = 0;

  /* works only for simple enums */
  while(luagl_const[i].str != 0)
  {
    if(num == luagl_const[i].value)
      return luagl_const[i].str;

    i++;
  }
  return NULL;
}

void luagl_pushenum(lua_State *L, GLenum num)
{
  const char* str = luagl_get_str_gl_enum(num);
  if (str)
    lua_pushstring(L, str);
  else
    lua_pushinteger(L, num);
}

static unsigned int luagl_find_enum(const luaglConst* gl_const, const char *str, int n)
{
  int i = 0;

  while(gl_const[i].str != 0)
  {
    if(strncmp(str, gl_const[i].str, n) == 0 && gl_const[i].str[n] == 0)
      return gl_const[i].value;
    i++;
  }
  return LUAGL_ENUM_ERROR;
}

unsigned int luagl_get_enum(lua_State *L, int index, const luaglConst* gl_const)
{
  if (lua_isnumber(L, index))
  {
    return (unsigned int)luaL_checkinteger(L, index);
  }
  else
  {
    unsigned int i;
    const char *str = luaL_checkstring(L, index);
    unsigned int len = (unsigned int)strlen(str);
    unsigned int temp = 0, ret = 0, found = 0;

    for(i = 0; i < len; i++)
    {
      if(str[i] == ',')
      {
        temp = luagl_find_enum(gl_const, str, i);
        if (temp != LUAGL_ENUM_ERROR)
        {
          ret |= temp;
          found = 1;
        }

        str += i+1;
        len -= i+1;
        i = 0;
      }
    }
    temp = luagl_find_enum(gl_const, str, len);

    if (temp == LUAGL_ENUM_ERROR)
    {
      if (!found)
      {
        luaL_argerror(L, index, "unknown or invalid enumeration");
        return LUAGL_ENUM_ERROR;
      }

      return ret;
    }

    return ret | temp;
  }
}

void luagl_initconst(lua_State *L, const luaglConst *gl_const)
{
  for (; gl_const->str; gl_const++) 
  {
    if (gl_const->value == LUAGL_ENUM_ERROR)
      luaL_error(L, "WARNING: INVALID CONSTANT=LUAGL_ENUM_ERROR");

    lua_pushstring(L, gl_const->str);
    lua_pushinteger(L, gl_const->value);
    lua_settable(L, -3);
  }
}

void luagl_open_const(lua_State *L) 
{
  luagl_initconst(L, luagl_const);
}
