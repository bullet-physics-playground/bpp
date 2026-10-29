#ifndef LAYER_H
#define LAYER_H

/**
 * @file layer.h
 * @brief Layer system for scene organization (Moray-style).
 *
 * Provides layers with visibility, locking, and color coding
 * for organizing complex scenes.
 */

#include <QString>
#include <QColor>
#include <QVector>
#include <QHash>
#include <QObject>

class Object;

/**
 * @brief A single layer in the scene.
 */
class Layer : public QObject {
  Q_OBJECT

public:
  /**
   * @brief Layer flags.
   */
  enum Flag {
    Visible     = 0x01,  ///< Layer is visible in viewport
    Locked      = 0x02,  ///< Objects on layer cannot be selected/modified
    Renderable  = 0x04,  ///< Layer participates in POV-Ray export
    Selectable  = 0x08,  ///< Objects on layer can be selected
    Shaded      = 0x10,  ///< Show shaded in viewport (vs wireframe)
  };
  Q_DECLARE_FLAGS(Flags, Flag)

  /**
   * @brief Constructs a layer.
   * @param name Layer name.
   * @param parent Parent object.
   */
  explicit Layer(const QString &name = "Layer", QObject *parent = nullptr);

  /**
   * @brief Layer name.
   */
  QString name() const { return m_name; }
  void setName(const QString &name) { m_name = name; }

  /**
   * @brief Layer color (for wireframe display).
   */
  QColor color() const { return m_color; }
  void setColor(const QColor &color) { m_color = color; }

  /**
   * @brief Layer flags.
   */
  Flags flags() const { return m_flags; }
  void setFlags(Flags flags) { m_flags = flags; }

  bool testFlag(Flag flag) const { return m_flags & flag; }
  void setFlag(Flag flag, bool on = true) {
    if (on) m_flags |= flag;
    else m_flags &= ~flag;
  }

  /**
   * @brief Returns true if layer is visible.
   */
  bool isVisible() const { return testFlag(Visible); }
  void setVisible(bool v) { setFlag(Visible, v); }

  /**
   * @brief Returns true if layer is locked.
   */
  bool isLocked() const { return testFlag(Locked); }
  void setLocked(bool v) { setFlag(Locked, v); }

  /**
   * @brief Returns true if layer is renderable.
   */
  bool isRenderable() const { return testFlag(Renderable); }
  void setRenderable(bool v) { setFlag(Renderable, v); }

  /**
   * @brief Adds an object to this layer.
   */
  void addObject(Object *obj);

  /**
   * @brief Removes an object from this layer.
   */
  void removeObject(Object *obj);

  /**
   * @brief Returns all objects on this layer.
   */
  const QVector<Object *> &objects() const { return m_objects; }

  /**
   * @brief Returns the number of objects on this layer.
   */
  int objectCount() const { return m_objects.size(); }

  /**
   * @brief Clears all objects from this layer.
   */
  void clearObjects();

signals:
  void changed();
  void objectAdded(Object *);
  void objectRemoved(Object *);

private:
  QString m_name;
  QColor m_color;
  Flags m_flags;
  QVector<Object *> m_objects;
};
Q_DECLARE_OPERATORS_FOR_FLAGS(Layer::Flags)

/**
 * @brief Manages a collection of layers.
 */
class LayerManager : public QObject {
  Q_OBJECT

public:
  /**
   * @brief Constructs a layer manager.
   * @param parent Parent object.
   */
  explicit LayerManager(QObject *parent = nullptr);

  /**
   * @brief Creates a new layer.
   * @param name Layer name (auto-generated if empty).
   * @return The new layer.
   */
  Layer *createLayer(const QString &name = QString());

  /**
   * @brief Removes a layer.
   * @param layer Layer to remove.
   * @param reassignTo Layer to move objects to (default: first layer).
   */
  void removeLayer(Layer *layer, Layer *reassignTo = nullptr);

  /**
   * @brief Returns all layers.
   */
  const QVector<Layer *> &layers() const { return m_layers; }

  /**
   * @brief Returns a layer by name.
   */
  Layer *layerByName(const QString &name) const;

  /**
   * @brief Returns the active layer (for new objects).
   */
  Layer *activeLayer() const { return m_activeLayer; }
  void setActiveLayer(Layer *layer) { m_activeLayer = layer; }

  /**
   * @brief Returns the default layer (always exists).
   */
  Layer *defaultLayer() const { return m_layers.isEmpty() ? nullptr : m_layers.first(); }

  /**
   * @brief Assigns an object to a layer.
   */
  void assignObject(Object *obj, Layer *layer);

  /**
   * @brief Removes an object from its current layer.
   */
  void removeObject(Object *obj);

  /**
   * @brief Returns the layer an object belongs to.
   */
  Layer *objectLayer(Object *obj) const;

  /**
   * @brief Moves a layer up/down in the stack.
   */
  void moveLayer(Layer *layer, int delta);

  /**
   * @brief Returns number of layers.
   */
  int layerCount() const { return m_layers.size(); }

  /**
   * @brief Registers the Layer system with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

signals:
  void layerAdded(Layer *);
  void layerRemoved(Layer *);
  void layerChanged(Layer *);
  void activeLayerChanged(Layer *);

private:
  QVector<Layer *> m_layers;
  Layer *m_activeLayer = nullptr;
  QHash<Object *, Layer *> m_objectLayers;
};

#endif // LAYER_H