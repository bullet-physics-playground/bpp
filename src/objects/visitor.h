#ifndef VISITOR_H
#define VISITOR_H

/**
 * @file visitor.h
 * @brief Visitor pattern for scene graph traversal (Moray-style).
 *
 * Implements the visitor pattern as used in the Moray POV-Ray modeler:
 * a base Visitor class with a Visiting() method, concrete visitors for
 * statistics, search, collection, modification, and traversal of the
 * object scene graph.
 */

#include "object.h"

class Object;

/**
 * @brief Base class for scene graph visitors (Moray-style).
 *
 * Derive from this class and override Visiting() for the object types
 * you want to handle. Call accept() on an Object to start traversal.
 */
class Visitor {
public:
  virtual ~Visitor() = default;

  /**
   * @brief Called for each Object in the scene graph during traversal.
   * @param obj The object being visited.
   * @return True to continue traversal to children, false to stop.
   */
  virtual bool Visiting(Object * /*obj*/) { return true; }
};

/**
 * @brief Convenience visitor that applies a function to each object.
 */
template <typename Func>
class FunctionVisitor : public Visitor {
public:
  explicit FunctionVisitor(Func f) : func(std::move(f)) {}

  bool Visiting(Object *obj) override {
    return func(obj);
  }

private:
  Func func;
};

/**
 * @brief Visitor that counts objects matching a predicate.
 */
template <typename Pred>
class CountVisitor : public Visitor {
public:
  explicit CountVisitor(Pred p) : pred(std::move(p)) {}

  bool Visiting(Object *obj) override {
    if (pred(obj))
      ++count;
    return true;
  }

  int count = 0;

private:
  Pred pred;
};

/**
 * @brief Visitor that collects objects matching a predicate.
 */
template <typename Pred>
class CollectVisitor : public Visitor {
public:
  explicit CollectVisitor(Pred p) : pred(std::move(p)) {}

  bool Visiting(Object *obj) override {
    if (pred(obj))
      results.push_back(obj);
    return true;
  }

  std::vector<Object *> results;

private:
  Pred pred;
};

/**
 * @brief Visitor that finds the first object matching a predicate.
 */
template <typename Pred>
class FindVisitor : public Visitor {
public:
  explicit FindVisitor(Pred p) : pred(std::move(p)) {}

  bool Visiting(Object *obj) override {
    if (pred(obj)) {
      found = obj;
      return false;  // stop traversal
    }
    return true;
  }

  Object *found = nullptr;

private:
  Pred pred;
};

/**
 * @brief Statistics visitor (Moray CStatisticsVisitor).
 *
 * Counts objects by category: lights, primitives, groups, real objects,
 * and totals.
 */
class StatisticsVisitor : public Visitor {
public:
  StatisticsVisitor() = default;

  bool Visiting(Object *obj) override {
    ++total;
    const QString type = obj->toString();
    if (type.contains("Light", Qt::CaseInsensitive))
      ++lights;
    else if (type.contains("CSG", Qt::CaseInsensitive) ||
             type.contains("Group", Qt::CaseInsensitive))
      ++groups;
    else if (type.contains("Plane", Qt::CaseInsensitive) ||
             type.contains("Cube", Qt::CaseInsensitive) ||
             type.contains("Sphere", Qt::CaseInsensitive) ||
             type.contains("Cylinder", Qt::CaseInsensitive) ||
             type.contains("Cone", Qt::CaseInsensitive) ||
             type.contains("Torus", Qt::CaseInsensitive) ||
             type.contains("Disc", Qt::CaseInsensitive) ||
             type.contains("Mesh", Qt::CaseInsensitive) ||
             type.contains("BezierPatch", Qt::CaseInsensitive) ||
             type.contains("Heightfield", Qt::CaseInsensitive))
      ++primitives;
    else
      ++realObjects;
    return true;
  }

  int lights = 0;
  int primitives = 0;
  int groups = 0;
  int realObjects = 0;
  int total = 0;
};

/**
 * @brief FindObject visitor (Moray CFindObjectVisitor).
 *
 * Finds the first object whose name matches the given pattern.
 */
class FindObjectVisitor : public Visitor {
public:
  explicit FindObjectVisitor(const QString &namePattern) : namePattern(namePattern) {}

  bool Visiting(Object *obj) override {
    if (obj->toString().contains(namePattern, Qt::CaseInsensitive)) {
      found = obj;
      return false;  // stop traversal
    }
    return true;
  }

  Object *found = nullptr;

private:
  QString namePattern;
};

/**
 * @brief Layer visitor (Moray CLayerVisitor).
 *
 * Collects all objects assigned to a specific layer name.
 */
class LayerVisitor : public Visitor {
public:
  explicit LayerVisitor(const QString &layerName) : layerName(layerName) {}

  bool Visiting(Object *obj) override {
    // Objects don't carry layer info in this implementation;
    // we track layers via the LayerManager instead.
    // This visitor is a placeholder for future integration.
    Q_UNUSED(obj)
    Q_UNUSED(layerName)
    return true;
  }

  QString layerName;
};

/**
 * @brief Rename visitor (Moray CRenameTextureVisitor style).
 *
 * Renames objects whose toString() contains a given pattern.
 */
class RenameVisitor : public Visitor {
public:
  RenameVisitor(const QString &oldPattern, const QString &newName)
    : oldPattern(oldPattern), newName(newName) {}

  bool Visiting(Object *obj) override {
    Q_UNUSED(obj)
    Q_UNUSED(oldPattern)
    Q_UNUSED(newName)
    // Object doesn't expose a settable name in this version;
    // this visitor is a placeholder for future integration.
    return true;
  }

  QString oldPattern;
  QString newName;
};

/**
 * @brief Check references visitor (Moray CCheckReferencesVisitor).
 *
 * Finds objects that reference a given object (placeholder).
 */
class CheckReferencesVisitor : public Visitor {
public:
  explicit CheckReferencesVisitor(Object *target) : target(target) {}

  bool Visiting(Object *obj) override {
    Q_UNUSED(obj)
    Q_UNUSED(target)
    return true;
  }

  Object *target = nullptr;
  int found = 0;
};

/**
 * @brief Creates a function visitor from a lambda.
 */
template <typename Func>
FunctionVisitor<Func> makeVisitor(Func f) {
  return FunctionVisitor<Func>(std::move(f));
}

/**
 * @brief Creates a counting visitor from a lambda predicate.
 */
template <typename Pred>
CountVisitor<Pred> makeCountVisitor(Pred p) {
  return CountVisitor<Pred>(std::move(p));
}

/**
 * @brief Creates a collecting visitor from a lambda predicate.
 */
template <typename Pred>
CollectVisitor<Pred> makeCollectVisitor(Pred p) {
  return CollectVisitor<Pred>(std::move(p));
}

/**
 * @brief Creates a finding visitor from a lambda predicate.
 */
template <typename Pred>
FindVisitor<Pred> makeFindVisitor(Pred p) {
  return FindVisitor<Pred>(std::move(p));
}

#endif // VISITOR_H