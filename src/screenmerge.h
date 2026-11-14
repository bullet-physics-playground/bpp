#ifndef SCREENMERGE_H
#define SCREENMERGE_H

#include <QMap>
#include "orderedset.h"
#include <QVector>

#include <tuple>
#include <utility>
#include <vector>

class Object;

/**
 * @brief The screen's merge (v.screenMerge): fixed boxes and cylinders that
 * stay put are drawn from a few big vertex buffers instead of one by one.
 *
 * Once a second, what has stayed put for five looks running (and is
 * opaque, without an image, a glow or a script's drawing) goes into the
 * batch of its patch of the scene (a cube 60 across). What then moves
 * comes out again, its triangles blanked where they are; what only changes
 * colour gets its new colour in its batch. The batches live in the current
 * OpenGL context; one that goes takes them along, and they are made again.
 *
 * Viewer calls update() once a frame before drawing, draw() for the screen,
 * and skips the objects whose mergeDrawn is set while ready().
 */
class ScreenMerge {
public:
  /// What one update() did, for the drawing timer (v.drawTiming).
  struct Counts {
    int batches = 0;    ///< Batches made.
    int recoloured = 0; ///< Objects recoloured in their batch.
    int blanked = 0;    ///< Batches with triangles blanked.
  };

  bool enabled = true; ///< Merge at all (v.screenMerge).

  /// Once a frame: takes out what has changed, looks for more now and then,
  /// and makes the batches again if need be.
  Counts update(const ObjectSet &objects);
  /// Draws the batches (for the screen); with @p culled, only those with
  /// an object culling keeps on screen.
  void draw(bool culled);
  /// Forgets them all (deleting them if their context is current).
  void clear();
  /// An object leaves the scene: out of its batch, if it is merged.
  void remove(Object *o);
  /// The batches no longer stand for the scene until the next update()
  /// (its objects were moved elsewhere: a world placed).
  void invalidate() { _ready = false; }

  /// The batches are made and up to date: what they hold is drawn by draw().
  bool ready() const { return _ready; }
  /// Objects drawn from the batches last frame (v.screenMerged).
  int drawn() const { return _drawn; }
  /// Times batches were made since resetMade().
  int made() const { return _made; }
  void resetMade() { _made = 0; }

private:
  struct Batch {
    QVector<Object *> objs;        ///< What's in it.
    unsigned vbo = 0;              ///< Its vertices, on the graphics card,
    unsigned cvbo = 0;             ///< and their colours (apart: changed alone).
    int verts = 0;                 ///< How many.
    bool dirty = true;             ///< To be made again.
    int holes = 0;                 ///< Vertices blanked (objects that left it).
    std::vector<std::pair<int, int>> blank; ///< To blank next frame: first, count.
  };

  /// Makes the batches that need it again.
  void build(Counts &counts);
  /// Takes an object out of its batch (which is made again).
  void unmerge(Object *o);

  /// One batch for each patch of the scene that has merged objects.
  QMap<std::tuple<int, int, int, int>, Batch> _batches;  ///< (patch, generation)
  QMap<std::tuple<int, int, int>, int> _openGen;  ///< Each patch's batch taking newcomers.
  int _genCount = 0;
  QVector<Object *> _objs;    ///< Everything merged.
  const void *_ctx = nullptr; ///< The context the batches live in.
  unsigned _epoch = 0;
  bool _ready = false;        ///< They're made, and up to date.
  long _frame = 0;
  int _drawn = 0;             ///< Drawn from them last frame.
  int _made = 0;              ///< Times made since resetMade().
};

#endif // SCREENMERGE_H
