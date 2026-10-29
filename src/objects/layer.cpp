/**
 * @file layer.cpp
 * @brief Implementation of the Layer system.
 */

#include "layer.h"

#include "object.h"

#include <QDebug>

Layer::Layer(const QString &name, QObject *parent)
  : QObject(parent), m_name(name), m_color(Qt::white), m_flags(Visible | Renderable | Selectable | Shaded) {
}

void Layer::addObject(Object *obj) {
  if (obj && !m_objects.contains(obj)) {
    m_objects.append(obj);
    emit objectAdded(obj);
    emit changed();
  }
}

void Layer::removeObject(Object *obj) {
  if (obj && m_objects.removeOne(obj)) {
    emit objectRemoved(obj);
    emit changed();
  }
}

void Layer::clearObjects() {
  while (!m_objects.isEmpty()) {
    Object *obj = m_objects.takeLast();
    emit objectRemoved(obj);
  }
  emit changed();
}

LayerManager::LayerManager(QObject *parent) : QObject(parent) {
  // Create default layer
  Layer *defaultLayer = new Layer("Default", this);
  m_layers.append(defaultLayer);
  m_activeLayer = defaultLayer;
}

Layer *LayerManager::createLayer(const QString &name) {
  QString layerName = name;
  if (layerName.isEmpty()) {
    layerName = QString("Layer %1").arg(m_layers.size() + 1);
  }

  // Ensure unique name
  int suffix = 1;
  QString baseName = layerName;
  while (layerByName(layerName)) {
    layerName = QString("%1 %2").arg(baseName).arg(suffix++);
  }

  Layer *layer = new Layer(layerName, this);
  m_layers.append(layer);
  if (!m_activeLayer) m_activeLayer = layer;

  emit layerAdded(layer);
  return layer;
}

void LayerManager::removeLayer(Layer *layer, Layer *reassignTo) {
  if (!layer || m_layers.size() <= 1) return; // Keep at least one layer

  // Reassign objects
  Layer *target = reassignTo ? reassignTo : defaultLayer();
  for (Object *obj : layer->objects()) {
    assignObject(obj, target);
  }

  if (m_activeLayer == layer) {
    m_activeLayer = target;
    emit activeLayerChanged(m_activeLayer);
  }

  m_layers.removeOne(layer);
  layer->deleteLater();

  emit layerRemoved(layer);
}

Layer *LayerManager::layerByName(const QString &name) const {
  for (Layer *layer : m_layers) {
    if (layer->name() == name) return layer;
  }
  return nullptr;
}

void LayerManager::assignObject(Object *obj, Layer *layer) {
  if (!obj || !layer) return;

  // Remove from current layer
  Layer *current = objectLayer(obj);
  if (current) {
    current->removeObject(obj);
    m_objectLayers.remove(obj);
  }

  // Add to new layer
  layer->addObject(obj);
  m_objectLayers[obj] = layer;
  obj->setLayer(layer);
}

void LayerManager::removeObject(Object *obj) {
  if (!obj) return;

  Layer *current = objectLayer(obj);
  if (current) {
    current->removeObject(obj);
    m_objectLayers.remove(obj);
  }
  obj->setLayer(nullptr);
}

Layer *LayerManager::objectLayer(Object *obj) const {
  return m_objectLayers.value(obj, nullptr);
}

void LayerManager::moveLayer(Layer *layer, int delta) {
  if (!layer) return;
  int idx = m_layers.indexOf(layer);
  if (idx < 0) return;

  int newIdx = idx + delta;
  if (newIdx < 0) newIdx = 0;
  if (newIdx >= m_layers.size()) newIdx = m_layers.size() - 1;

  if (newIdx != idx) {
    m_layers.move(idx, newIdx);
    emit layerChanged(layer);
  }
}

void LayerManager::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[
    class_<Layer>("Layer")
      .def(constructor<>())
      .def(constructor<const QString &>())
      .def("getName", &Layer::name)
      .def("setName", &Layer::setName)
      .def("getColor", &Layer::color)
      .def("setColor", &Layer::setColor)
      .def("getFlags", &Layer::flags)
      .def("setFlags", &Layer::setFlags)
      .def("isVisible", &Layer::isVisible)
      .def("setVisible", &Layer::setVisible)
      .def("isLocked", &Layer::isLocked)
      .def("setLocked", &Layer::setLocked)
      .def("isRenderable", &Layer::isRenderable)
      .def("setRenderable", &Layer::setRenderable)
      .def("objectCount", &Layer::objectCount),

    class_<LayerManager>("LayerManager")
      .def(constructor<>())
      .def("createLayer", &LayerManager::createLayer)
      .def("removeLayer", &LayerManager::removeLayer)
      .def("layerByName", &LayerManager::layerByName)
      .def("layers", &LayerManager::layers)
      .def("activeLayer", &LayerManager::activeLayer)
      .def("setActiveLayer", &LayerManager::setActiveLayer)
      .def("defaultLayer", &LayerManager::defaultLayer)
      .def("assignObject", &LayerManager::assignObject)
      .def("removeObject", &LayerManager::removeObject)
      .def("objectLayer", &LayerManager::objectLayer)
      .def("layerCount", &LayerManager::layerCount)
      .def("moveLayer", &LayerManager::moveLayer)
  ];
}