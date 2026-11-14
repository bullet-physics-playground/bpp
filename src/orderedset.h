#pragma once

/**
 * @file orderedset.h
 * @brief A set that iterates in the order its items were inserted.
 *
 * The Viewer keeps its objects and constraints in these rather than in a
 * QSet, whose order follows the pointers' hashes: that changes from run to
 * run (Qt seeds its hash per process), and the order is what the POV-Ray
 * export writes objects in, what they are drawn in, and the order an
 * object's constraints leave the Bullet world, which decides the order of
 * the rest (Bullet fills a gap with its last constraint).
 *
 * Insert, remove and contains are as quick as a QSet's (a hash, plus a map
 * kept in insertion order). An item inserted again keeps its place; one
 * removed and inserted again goes last. Copies are cheap (implicitly
 * shared), so Q_FOREACH over one is safe while the set changes.
 */

#include <QHash>
#include <QList>
#include <QMap>

class Object;

template <typename T> class OrderedSet {
public:
  typedef typename QMap<quint64, T>::const_iterator const_iterator;

  void insert(const T &item) {
    if (!_index.contains(item)) {
      _index.insert(item, _next);
      _order.insert(_next++, item);
    }
  }

  bool remove(const T &item) {
    auto it = _index.find(item);
    if (it == _index.end())
      return false;
    _order.remove(it.value());
    _index.erase(it);
    return true;
  }

  bool contains(const T &item) const { return _index.contains(item); }
  int size() const { return _index.size(); }
  bool isEmpty() const { return _index.isEmpty(); }
  void clear() {
    _index.clear();
    _order.clear();
  }

  /// The items, in insertion order.
  QList<T> values() const { return _order.values(); }

  const_iterator begin() const { return _order.constBegin(); }
  const_iterator end() const { return _order.constEnd(); }

private:
  QHash<T, quint64> _index; ///< Each item's place in _order.
  QMap<quint64, T> _order;  ///< The items, by when they were inserted.
  quint64 _next = 0;        ///< The next item's place.
};

/// The scene's objects (Viewer::_objects), in the order they were added.
typedef OrderedSet<Object *> ObjectSet;
