#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "terrain.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

// Collects the world-space triangles of a static concave shape via
// btConcaveShape::processAllTriangles, exactly like Mesh's own
// POVSaveCallback -- kept as a separate, differently-named class so the two
// translation units don't define clashing same-named classes.
class TerrainPOVSaveCallback : public btTriangleCallback {
public:
  QList<btVector3> v1;
  QList<btVector3> v2;
  QList<btVector3> v3;

  virtual void processTriangle(btVector3 *triangle, int partId,
                               int triangleIndex) {
    (void)partId;
    (void)triangleIndex;
    v1.append(triangle[0]);
    v2.append(triangle[1]);
    v3.append(triangle[2]);
  }
};

class TerrainGlDrawCallback : public btTriangleCallback {
public:
  virtual void processTriangle(btVector3 *triangle, int partId,
                               int triangleIndex) {
    (void)partId;
    (void)triangleIndex;

    btVector3 n = (triangle[1] - triangle[0]).cross(triangle[2] - triangle[0]);
    n.normalize();

    glBegin(GL_TRIANGLES);
    glNormal3d(n.x(), n.y(), n.z());
    glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
    glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
    glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
    glNormal3d(-n.x(), -n.y(), -n.z());
    glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
    glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
    glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
    glEnd();
  }
};

Terrain::Terrain() {
  m_mesh = new btTriangleMesh();
  m_shape = nullptr;
  shape = nullptr;
  body = nullptr;

  setColor(127, 127, 127);
}

Terrain::~Terrain() {
  if (body && body->getMotionState())
    delete body->getMotionState();
  delete m_shape;
  delete m_mesh;
  shape = nullptr;
}

void Terrain::addTriangle(const btVector3 &v0, const btVector3 &v1,
                          const btVector3 &v2) {
  m_mesh->addTriangle(v0, v1, v2);
}

int Terrain::getNumTriangles() const { return m_mesh->getNumTriangles(); }

void Terrain::build() {
  if (body != nullptr) {
    if (body->getMotionState())
      delete body->getMotionState();
    delete body;
    body = nullptr;
  }
  delete m_shape;

  // true: use quantized AABB compression -- smaller BVH, and the standard
  // choice for a static (never-refit) terrain like this one.
  m_shape = new btBvhTriangleMeshShape(m_mesh, true, true);
  shape = m_shape;

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  // mass 0 -> static: btBvhTriangleMeshShape's BVH is built once and never
  // refit, so it can only ever back an immovable body.
  body = new btRigidBody(0.0, motionState, m_shape, btVector3(0, 0, 0));
}

void Terrain::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Terrain, Object>("Terrain")
                .def(constructor<>(), adopt(result))
                .def("addTriangle", &Terrain::addTriangle)
                .def("build", &Terrain::build)
                .def("getNumTriangles", &Terrain::getNumTriangles)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Terrain::toString() const { return QString("Terrain"); }

void Terrain::toMesh2(QTextStream *s, QString hash) const {
  if (s == nullptr || m_shape == nullptr)
    return;

  TerrainPOVSaveCallback pov;
  btVector3 aabbMin(-1e99, -1e99, -1e99);
  btVector3 aabbMax(1e99, 1e99, 1e99);
  m_shape->processAllTriangles(&pov, aabbMin, aabbMax);

  *s << "#ifndef (mesh_" << hash << "_included)" << "\n";
  *s << "#declare mesh_" << hash << "_included = 1;" << "\n\n";

  if (pov.v1.length() > 0) {
    *s << "#declare mesh_" << hash << " = ";
    *s << "mesh2 {" << "\n";
    *s << "  vertex_vectors {" << "\n";
    *s << "    " << pov.v1.length() * 3 << ", ";
    for (int i = 0; i < pov.v1.length(); ++i) {
      *s << "<" << pov.v1.at(i).x() << "," << pov.v1.at(i).y() << ","
         << -pov.v1.at(i).z() << ">";
      *s << "<" << pov.v2.at(i).x() << "," << pov.v2.at(i).y() << ","
         << -pov.v2.at(i).z() << ">";
      *s << "<" << pov.v3.at(i).x() << "," << pov.v3.at(i).y() << ","
         << -pov.v3.at(i).z() << ">";
      if (i != pov.v1.length() - 1)
        *s << ", \n";
    }
    *s << " }" << "\n";

    *s << "  face_indices {" << "\n";
    *s << "    " << pov.v1.length() << ", ";
    for (int i = 0; i < pov.v1.length(); ++i) {
      *s << "<" << i * 3 << "," << i * 3 + 1 << "," << i * 3 + 2 << ">";
      if (i != pov.v1.length() - 1)
        *s << ", \n";
    }
    *s << " }" << "\n";

    *s << "}" << "\n";
  } else {
    *s << "union {}" << "\n"; // empty object in case of an empty mesh
  }
  *s << "#end" << "\n";
}

QString Terrain::toPOV(const QString &sceneDir) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  QByteArray data;
  QTextStream s(&data);

  if (m_shape != nullptr && body != nullptr &&
      body->getMotionState() != nullptr) {
    if (mPreSDL.isNull()) {
      // Terrain never moves and is typically large (thousands of
      // triangles), so -- exactly like Mesh -- the mesh2 data is written
      // once to a content-hashed .inc file and #include'd by every frame,
      // instead of being re-emitted inline into each frame's own .inc.
      QByteArray meshdata;
      QTextStream tmp(&meshdata);
      toMesh2(&tmp, QString());
      tmp.flush();

      QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
      hashAlgo.addData(meshdata);
      QString hash = hashAlgo.result().toHex();

      meshdata.clear();
      QTextStream tmp2(&meshdata);
      toMesh2(&tmp2, hash);
      tmp2.flush();

      QString incfile = sceneDir + QDir::separator() + "mesh_" + hash + ".inc";

      QFileInfo check_file(incfile);
      if (!check_file.exists() && !check_file.isFile()) {
        QFile file(incfile);
        if (file.open(QIODevice::ReadWrite)) {
          QTextStream stream(&file);
          toMesh2(&stream, hash);
          stream.flush();
          file.close();
        } else {
          qDebug() << "unable to create " << incfile;
        }
      }

      s << "#include \"" + check_file.fileName() + "\"" << "\n"
        << "\n";
      s << "object { mesh_" + hash << "\n";
    } else {
      s << mPreSDL << "\n";
    }

    if (!mSDL.isNull()) {
      s << mSDL << "\n";
    } else {
      s << "  pigment { rgb <" << color[0] / 255.0 << ", " << color[1] / 255.0
        << ", " << color[2] / 255.0 << "> }" << "\n";
    }

    s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2]
      << "," << "\n"
      << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6]
      << "," << "\n"
      << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10]
      << "," << "\n"
      << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14]
      << ">" << "\n";

    if (mPostSDL.isNull()) {
      s << "}" << "\n"
        << "\n";
    } else {
      s << mPostSDL << "\n"
        << "\n";
    }
  }

  s.flush();
  return QString::fromStdString(data.toStdString());
}

void Terrain::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  if (m_shape == nullptr)
    return;

  GLfloat mat_ambient[] = {(GLfloat)(color[0] / 255.0),
                           (GLfloat)(color[1] / 255.0),
                           (GLfloat)(color[2] / 255.0), 1.0};
  GLfloat mat_diffuse[] = {0.5, 0.5, 0.5, 1.0};
  GLfloat mat_specular[] = {0.0, 0.0, 0.0, 1.0};
  GLfloat high_shininess[] = {100.0};
  GLfloat no_mat[] = {0.0, 0.0, 0.0, 1.0};

  glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
  glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);
  glColor3ubv(color);

  TerrainGlDrawCallback drawCallback;
  btVector3 aabbMin(-1e99, -1e99, -1e99);
  btVector3 aabbMax(1e99, 1e99, 1e99);
  m_shape->processAllTriangles(&drawCallback, aabbMin, aabbMax);
}
