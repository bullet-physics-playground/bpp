/**
 * @file heightfield.cpp
 * @brief Implementation of the general heightfield primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "heightfield.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>
#include <QImage>
#include <QFile>
#include <QTextStream>

#include <algorithm>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Heightfield::Heightfield(int w, int d, btScalar mass) : width(w), depth(d) {
  m_heights.resize(width * depth, 0.0f);
  buildShape(mass);
}

Heightfield::Heightfield(const QImage &image, const btVector3 &scl, btScalar mass) : scale(scl) {
  QImage gray = image.convertToFormat(QImage::Format_Grayscale8);
  width = gray.width();
  depth = gray.height();
  m_heights.resize(width * depth);

  for (int z = 0; z < depth; ++z) {
    for (int x = 0; x < width; ++x) {
      float h = gray.pixelColor(x, z).redF(); // 0.0 to 1.0
      m_heights[z * width + x] = h;
    }
  }
  buildShape(mass);
}

Heightfield::Heightfield(int w, int d, const function<float(float, float)> &heightFn,
                         const btVector3 &scl, btScalar mass) : width(w), depth(d), scale(scl) {
  m_heights.resize(width * depth);
  setFromFunction(heightFn, 0.0f, 1.0f);
  buildShape(mass);
}

Heightfield::~Heightfield() {
  if (m_hfShape) {
    delete m_hfShape;
    m_hfShape = nullptr;
  }
  deleteOwnShape(true);
}

void Heightfield::setHeight(int x, int z, float height) {
  if (x >= 0 && x < width && z >= 0 && z < depth) {
    m_heights[z * width + x] = height;
  }
}

float Heightfield::getHeight(int x, int z) const {
  if (x >= 0 && x < width && z >= 0 && z < depth) {
    return m_heights[z * width + x];
  }
  return 0.0f;
}

void Heightfield::setFromImage(const QImage &image, float minH, float maxH) {
  QImage gray = image.convertToFormat(QImage::Format_Grayscale8);
  QImage scaled = gray.scaled(width, depth, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

  minHeight = minH;
  maxHeight = maxH;
  float range = maxH - minH;

  for (int z = 0; z < depth; ++z) {
    for (int x = 0; x < width; ++x) {
      float h = scaled.pixelColor(x, z).redF(); // 0.0 to 1.0
      m_heights[z * width + x] = minH + h * range;
    }
  }
  rebuild();
}

void Heightfield::setFromFunction(const function<float(float, float)> &fn, float minH, float maxH) {
  minHeight = minH;
  maxHeight = maxH;

  for (int z = 0; z < depth; ++z) {
    for (int x = 0; x < width; ++x) {
      float u = (width > 1) ? float(x) / (width - 1) : 0.5f;
      float v = (depth > 1) ? float(z) / (depth - 1) : 0.5f;
      float h = fn(u, v);
      m_heights[z * width + x] = h;
    }
  }
  rebuild();
}

void Heightfield::rebuild() {
  if (m_hfShape) {
    delete m_hfShape;
    m_hfShape = nullptr;
  }
  if (body) {
    delete body;
    body = nullptr;
  }
  if (shape) {
    shape = nullptr;
  }
  buildShape(getMass());
  generateMesh();
  generateNormals();
}

bool Heightfield::exportHeightmap(const QString &file) const {
  QImage img(width, depth, QImage::Format_Grayscale8);
  float range = maxHeight - minHeight;
  if (range <= 0) range = 1.0f;

  for (int z = 0; z < depth; ++z) {
    for (int x = 0; x < width; ++x) {
      float h = m_heights[z * width + x];
      float normalized = (h - minHeight) / range;
      normalized = std::max(0.0f, std::min(1.0f, normalized));
      img.setPixelColor(x, z, QColor::fromRgbF(normalized, normalized, normalized));
    }
  }
  return img.save(file);
}

void Heightfield::buildShape(btScalar mass) {
  // Find min/max for heightfield shape
  float minH = m_heights[0];
  float maxH = m_heights[0];
  for (float h : m_heights) {
    if (h < minH) minH = h;
    if (h > maxH) maxH = h;
  }
  minHeight = minH;
  maxHeight = maxH;

  // btHeightfieldTerrainShape expects heights in a flat array
  // It uses X for width, Z for depth (Y is up)
  m_hfShape = new btHeightfieldTerrainShape(
    width, depth,
    m_heights.data(),
    1.0f, // height scale
    minH, maxH,
    1, // upAxis = Y (1)
    PHY_FLOAT, // height data type
    false // flipQuadEdges
  );

  // Set local scaling
  m_hfShape->setLocalScaling(btVector3(scale.x() / (width - 1), scale.y(), scale.z() / (depth - 1)));

  shape = m_hfShape;

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  shape->calculateLocalInertia(mass, inertia);
  body = new btRigidBody(mass, motionState, shape, inertia);
  _ownsBody = true;
}

void Heightfield::generateMesh() {
  m_vertices.clear();
  m_vertices.reserve(width * depth);
  m_normals.clear();
  m_normals.reserve(width * depth);
  m_indices.clear();
  m_indices.reserve((width - 1) * (depth - 1) * 6);

  float wx = scale.x() / (width - 1);
  float wz = scale.z() / (depth - 1);
  float originX = -scale.x() * 0.5f;
  float originZ = -scale.z() * 0.5f;

  // Generate vertices
  for (int z = 0; z < depth; ++z) {
    for (int x = 0; x < width; ++x) {
      float h = m_heights[z * width + x];
      btVector3 v(originX + x * wx, h * scale.y(), originZ + z * wz);
      m_vertices.push_back(v);
    }
  }

  // Generate normals (simple averaging)
  m_normals.assign(m_vertices.size(), btVector3(0, 1, 0));
  for (int z = 0; z < depth - 1; ++z) {
    for (int x = 0; x < width - 1; ++x) {
      int i0 = z * width + x;
      int i1 = z * width + x + 1;
      int i2 = (z + 1) * width + x;
      int i3 = (z + 1) * width + x + 1;

      btVector3 n1 = (m_vertices[i1] - m_vertices[i0]).cross(m_vertices[i2] - m_vertices[i0]);
      btVector3 n2 = (m_vertices[i2] - m_vertices[i1]).cross(m_vertices[i3] - m_vertices[i1]);

      n1.normalize();
      n2.normalize();

      m_normals[i0] += n1;
      m_normals[i1] += n1 + n2;
      m_normals[i2] += n1 + n2;
      m_normals[i3] += n2;
    }
  }
  for (auto &n : m_normals) n.normalize();

  // Generate triangle indices (two triangles per quad)
  for (int z = 0; z < depth - 1; ++z) {
    for (int x = 0; x < width - 1; ++x) {
      int i0 = z * width + x;
      int i1 = z * width + x + 1;
      int i2 = (z + 1) * width + x;
      int i3 = (z + 1) * width + x + 1;

      // Triangle 1
      m_indices.push_back(i0);
      m_indices.push_back(i2);
      m_indices.push_back(i1);

      // Triangle 2
      m_indices.push_back(i1);
      m_indices.push_back(i2);
      m_indices.push_back(i3);
    }
  }
}

void Heightfield::generateNormals() {
  // Already done in generateMesh
}

void Heightfield::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Heightfield, Object>("Heightfield")
                 .def(constructor<>(), adopt(result))
                 .def(constructor<int, int>(), adopt(result))
                 .def(constructor<int, int, btScalar>(), adopt(result))
                 .def("setHeight", &Heightfield::setHeight)
                 .def("getHeight", &Heightfield::getHeight)
                 .def("setFromImage", &Heightfield::setFromImage)
                 .def("setFromFunction", &Heightfield::setFromFunction)
                 .def("rebuild", &Heightfield::rebuild)
                 .def("exportHeightmap", &Heightfield::exportHeightmap)
                 .def_readwrite("width", &Heightfield::width)
                 .def_readwrite("depth", &Heightfield::depth)
                 .def_readwrite("scale", &Heightfield::scale)
                 .def(tostring(const_self))
                 .def(const_self == const_self)];
}

QString Heightfield::toString() const { return QString("Heightfield"); }

void Heightfield::toPOV(QTextStream *s) const {
  if (!s) return;

  // Get world transform
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    if (placed)
      trans = place * trans;
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (mPreSDL.isNull()) {
    // POV-Ray height_field from a function or image
    // We'll export as a mesh2 for simplicity
    *s << "#declare HFMesh = mesh2 {\n";
    *s << "  vertex_vectors {\n";
    *s << "    " << m_vertices.size() << ",\n";
    for (const auto &v : m_vertices) {
      *s << "    <" << v.x() << ", " << v.y() << ", " << v.z() << ">,\n";
    }
    *s << "  }\n";
    *s << "  normal_vectors {\n";
    *s << "    " << m_normals.size() << ",\n";
    for (const auto &n : m_normals) {
      *s << "    <" << n.x() << ", " << n.y() << ", " << n.z() << ">,\n";
    }
    *s << "  }\n";
    *s << "  face_indices {\n";
    *s << "    " << m_indices.size() / 3 << ",\n";
    for (size_t i = 0; i < m_indices.size(); i += 3) {
      *s << "    <" << m_indices[i] << ", " << m_indices[i+1] << ", " << m_indices[i+2] << ">,\n";
    }
    *s << "  }\n";
    *s << "}\n";
    *s << "object { HFMesh\n";
  } else {
    *s << mPreSDL << "\n";
  }

  if (!mSDL.isNull()) {
    *s << mSDL << "\n";
  } else {
    povPigment(s);
  }

  *s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2]
     << "," << "\n"
     << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6]
     << "," << "\n"
     << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10]
     << "," << "\n"
     << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14]
     << ">" << "\n";

  if (mPostSDL.isNull()) {
    *s << "}" << "\n" << "\n";
  } else {
    *s << mPostSDL << "\n";
  }
}

void Heightfield::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  if (m_vertices.empty()) {
    generateMesh();
    generateNormals();
  }

  glApplyColor();

  glBegin(GL_TRIANGLES);
  for (size_t i = 0; i < m_indices.size(); ++i) {
    int idx = m_indices[i];
    const btVector3 &v = m_vertices[idx];
    const btVector3 &n = m_normals[idx];
    glNormal3f(n.x(), n.y(), n.z());
    glVertex3f(v.x(), v.y(), v.z());
  }
  glEnd();
}