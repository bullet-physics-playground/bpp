#ifndef SHADOWRECORD_H
#define SHADOWRECORD_H

#include <QMap>
#include "orderedset.h"
#include <QVector>

#include <tuple>

#include <qopengl.h>

class btBroadphaseInterface;
class Object;
class ShadowMap;

/**
 * @brief The shadow record (v.shadowCache, v.shadowSaved): the fixed objects
 * that stay put are drawn into the shadow map from recorded OpenGL lists.
 *
 * A fixed object that has stayed put 30 frames is recorded with the others
 * in its patch of the scene (a cube 60 across), and the patch's list is
 * replayed each frame instead of drawing them one by one. When what is in a
 * patch changes, only that patch is recorded again; an object that moves
 * after being recorded, twice over, is kept out for good. With the light and
 * the scene's extent steady, the record's depth is saved once and put back
 * each frame in one copy, until the record or the light changes.
 *
 * Viewer calls fill() between the shadow map's renderDepthBegin() and
 * renderDepthEnd(), then draws the objects fill() leaves to it.
 */
class ShadowRecord {
public:
  /// What one fill() did, for the drawing timer (v.drawTiming).
  struct Counts {
    int recorded = 0;        ///< Objects recorded into lists.
    bool depthSaved = false; ///< The depth was saved.
  };

  bool enabled = true;   ///< Record at all (v.shadowCache).
  bool saveDepth = true; ///< Save the record's depth (v.shadowSaved).

  /**
   * @brief Fills the shadow map with what the record holds, making it again
   * where it has changed.
   * @param objects    The scene's objects.
   * @param map        The shadow map, between renderDepthBegin() and
   *                   renderDepthEnd().
   * @param broadphase The world's broadphase (the scene's extent).
   * @param culled     Culling is on: a patch is replayed only if it holds
   *                   an object culling keeps in the shadow.
   * @param counts     What it did.
   * @return True if the record was drawn: the caller then draws only the
   *         objects not in it (shadowListed); false: every object.
   */
  bool fill(const ObjectSet &objects, ShadowMap *map,
            btBroadphaseInterface *broadphase, bool culled, Counts &counts);

  /// Objects taken from the record last frame (v.shadowCached).
  int cached() const { return _cached; }
  /// The depth was put back from the saved copy last frame.
  bool fromSaved() const { return _fromSaved; }

  /// Whether an object can go into the record at all: fixed, casting a
  /// shadow, with a shape, drawn by bpp itself, in the world it is drawn in.
  static bool isFixedCaster(const Object *o);

private:
  /// Marks the fixed objects that have stayed put long enough (shadowListed)
  /// and returns their hashes summed; @p count gets how many.
  quint64 markStillCasters(const ObjectSet &objects, int *count);

  /// The still objects' recorded depth: a list for each patch of the room,
  /// made again only when what's in that patch changes.
  struct Patch {
    GLuint list = 0;
    QVector<Object *> objs;         ///< (in the order they're drawn)
    quint64 sum = 0;                ///< Their hashes, summed.
    int count = 0;
  };
  QMap<std::tuple<int, int, int>, Patch> _patches;
  const void *_ctx = nullptr;       ///< GL context the lists live in.
  unsigned _epoch = 0;              ///< glCacheEpoch() when they were made.
  quint64 _sig = 0;                 ///< The objects they were made from.
  int _count = 0;                   ///< How many objects they hold.
  int _cached = 0;                  ///< Taken from it last frame.
  bool _fromSaved = false;          ///< See fromSaved().
  quint64 _savedDepthSig = 0;       ///< The record the saved depth was made from
  int _savedDepthCount = -1;        ///< (and how many objects it held).
};

#endif // SHADOWRECORD_H
