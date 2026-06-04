#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#ifdef HAS_LIB_ASSIMP

#include "mesh.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

// assimp include files. These three are usually needed.
#include <assimp/cimport.h>
#include <assimp/postprocess.h>
#include <assimp/scene.h>

#include "BulletCollision/CollisionShapes/btConvexTriangleMeshShape.h"

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

QHash<QString, std::shared_ptr<MeshCacheEntry>> Mesh::_meshCache;

class GlDrawcallback : public btTriangleCallback {

public:
  bool m_wireframe;

  GlDrawcallback() : m_wireframe(false) {}

  virtual void processTriangle(btVector3 *triangle, int partId,
                               int triangleIndex) {

    (void)triangleIndex;
    (void)partId;

    glBegin(GL_TRIANGLES);
    glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
    glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
    glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
    glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
    glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
    glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
    glEnd();
  }
};

class POVSaveCallback : public btTriangleCallback {

public:
  QList<btVector3> v1;
  QList<btVector3> v2;
  QList<btVector3> v3;
  QList<int> idx;

  POVSaveCallback() {}

  virtual void processTriangle(btVector3 *triangle, int partId,
                               int triangleIndex) {
    (void)partId;

    v1.append(triangle[0]);
    v2.append(triangle[1]);
    v3.append(triangle[2]);
    idx.append(triangleIndex);
  }
};

Mesh::Mesh(const QString &filename, btScalar mass) {
  m_filename = filename;
  m_mass = mass;
  m_mesh = nullptr;
  m_shape = nullptr;
  m_scene = nullptr;

  setColor(127, 127, 127);

  if (!filename.isNull())
    loadFile(filename, mass);
}

Mesh::Mesh(const QString &filename) {
  m_filename = filename;
  m_mass = 0;
  m_mesh = nullptr;
  m_shape = nullptr;
  m_scene = nullptr;

  setColor(127, 127, 127);

  if (!filename.isNull())
    loadFile(filename, 0);
}

Mesh::Mesh() {
  m_filename = QString();
  m_mass = 0;
  m_mesh = new btTriangleMesh();
  m_shape = new btGImpactMeshShape(m_mesh);
  m_scene = nullptr;
  shape = m_shape;

  setColor(127, 127, 127);
  setMass(0);
}

Mesh::~Mesh() {
  m_shape = nullptr;
  m_mesh = nullptr;
  m_scene = nullptr;
  if (body && body->getMotionState()) {
    delete body->getMotionState();
  }
}

void Mesh::loadFile(const QString &filename, btScalar mass) {
  m_filename = filename;
  m_mass = mass;

  QString cacheKey = QFileInfo(filename).absoluteFilePath();

  if (_meshCache.contains(cacheKey)) {
    auto entry = _meshCache.value(cacheKey);
    m_shape = entry->m_shape;
    m_mesh = entry->m_mesh;
    m_scene = entry->m_scene;
    shape = m_shape;
  } else {
    const aiScene *scene =
        aiImportFile(cacheKey.toUtf8().constData(), aiProcessPreset_TargetRealtime_Fast);

    if (!scene) {
      return;
    }

    assert(scene->mNumMeshes > 0);

    btTriangleMesh *triMesh = new btTriangleMesh();
    const struct aiMesh *amesh = scene->mMeshes[0];

    for (unsigned int t = 0; t < amesh->mNumFaces; ++t) {
      const struct aiFace *face = &amesh->mFaces[t];

      GLenum face_mode;

      switch (face->mNumIndices) {
      case 1:
        face_mode = GL_POINTS;
        break;
      case 2:
        face_mode = GL_LINES;
        break;
      case 3:
        face_mode = GL_TRIANGLES;
        break;
      default:
        face_mode = GL_POLYGON;
        break;
      }

      assert(face_mode == GL_TRIANGLES);

      int i0 = face->mIndices[0];
      int i1 = face->mIndices[1];
      int i2 = face->mIndices[2];

      triMesh->addTriangle(
          btVector3(amesh->mVertices[i0].x, amesh->mVertices[i0].y,
                    amesh->mVertices[i0].z),
          btVector3(amesh->mVertices[i1].x, amesh->mVertices[i1].y,
                    amesh->mVertices[i1].z),
          btVector3(amesh->mVertices[i2].x, amesh->mVertices[i2].y,
                    amesh->mVertices[i2].z));
    }

    auto entry = std::make_shared<MeshCacheEntry>();
    entry->m_scene = scene;
    entry->m_mesh = triMesh;
    entry->m_shape = new btGImpactMeshShape(triMesh);
    entry->m_shape->updateBound();

    _meshCache.insert(cacheKey, entry);

    m_shape = entry->m_shape;
    m_mesh = entry->m_mesh;
    m_scene = entry->m_scene;
  }

  shape = m_shape;

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  m_shape->calculateLocalInertia(mass, inertia);
  body = new btRigidBody(mass, motionState, m_shape, inertia);
}

void Mesh::luaBind(lua_State *s) {
  using namespace luabind;

module(s)[class_<Mesh, Object>("Mesh")
                 .def(constructor<>(), adopt(result))
                 .def(constructor<QString>(), adopt(result))
                 .def(constructor<QString, btScalar>(), adopt(result))
                 .def(tostring(const_self))

                 .property("shape", &Mesh::getShape, &Mesh::setShape)
                 .property("mesh", &Mesh::getTriangleMesh,
                           &Mesh::setTriangleMesh)

  ];
}

QString Mesh::toString() const { return QString("Mesh"); }

void Mesh::toMesh2(QTextStream *s, QString hash) const {
  if (s != nullptr && m_shape != nullptr) {
    POVSaveCallback pov;
    btVector3 pminaabb = btVector3(-1e99, -1e99, -1e99); // XXX
    btVector3 pmaxaabb = btVector3(1e99, 1e99, 1e99);    // XXX
    btConcaveShape *concaveMesh = (btConcaveShape *)m_shape;
    concaveMesh->processAllTriangles(&pov, pminaabb, pmaxaabb);

    *s << "#ifndef (mesh_" << hash << "_included)" << "\n";
    *s << "#declare mesh_" << hash << "_included = 1;" << "\n\n";

    if (pov.idx.length() > 0) {
      *s << "#declare mesh_" << hash << " = ";
      *s << "mesh2 {" << "\n";
      *s << "  vertex_vectors {" << "\n";
      *s << "    " << pov.idx.length() * 3 << ", ";
      for (int i = 0; i < pov.idx.length(); ++i) {
        *s << "<" << pov.v1.at(i).x() << "," << pov.v1.at(i).y() << ","
           << pov.v1.at(i).z() << ">";
        *s << "<" << pov.v2.at(i).x() << "," << pov.v2.at(i).y() << ","
           << pov.v2.at(i).z() << ">";
        *s << "<" << pov.v3.at(i).x() << "," << pov.v3.at(i).y() << ","
           << pov.v3.at(i).z() << ">";
        if (i != pov.idx.length() - 1)
          *s << ", \n";
      }
      *s << " }" << "\n";

      /*
      *s << "  normal_vectors {\n";
      *s << "    " << pov.idx.length() << ", ";
      for (int i = 0; i < pov.idx.length(); i++) {
          btVector3 normal = (pov.v3.at(i) - pov.v1.at(i)).cross(pov.v2.at(i) -
      pov.v1.at(i)); normal.normalize(); *s << "<"
           << normal.getX()
           << ","
           << normal.getY()
           << ","
           << normal.getZ()
           << ">";
          if (i != pov.idx.length() - 1) *s << ", \n";
      }
      *s << " }" << "\n";
      */

      *s << "  face_indices {" << "\n";
      *s << "    " << pov.idx.length() << ", ";
      for (int i = 0; i < pov.idx.length(); ++i) {
        *s << "<" << i * 3 << "," << i * 3 + 1 << "," << i * 3 + 2 << ">";
        if (i != pov.idx.length() - 1)
          *s << ", \n";
      }
      *s << " }" << "\n";

      *s << "}" << "\n";
    } else {
      *s << "union {}" << "\n"; // empty object in case of empty mesh
    }
    *s << "#end" << "\n";
  }
}

QString Mesh::toPOV(const QString &sceneDir) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
  }

  QByteArray data;
  QTextStream s(&data);

  if (m_shape != nullptr && body != nullptr &&
      body->getMotionState() != nullptr) {
    if (mPreSDL.isNull()) {
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
      if (!check_file.exists() && !check_file.isFile() && m_shape != nullptr) {
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

void Mesh::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  (void)minaabb;
  (void)maxaabb;

  GLfloat no_mat[] = {0.0, 0.0, 0.0, 1.0};
  GLfloat mat_ambient[] = {(GLfloat)(color[0] / 255.0),
                           (GLfloat)(color[1] / 255.0),
                           (GLfloat)(color[2] / 255.0), 1.0};
  GLfloat mat_diffuse[] = {0.5, 0.5, 0.5, 1.0};
  GLfloat mat_specular[] = {0.0, 0.0, 0.0, 1.0};
  // GLfloat no_shininess[] = { 0.0 };
  // GLfloat low_shininess[] = { 5.0 };
  GLfloat high_shininess[] = {100.0};
  // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

  glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
  glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);
  glColor3ubv(color);

  if (m_scene != nullptr && m_scene->mMeshes != nullptr) {
    const struct aiMesh *mesh = m_scene->mMeshes[0];

    unsigned int i, t;

    for (t = 0; t < mesh->mNumFaces; ++t) {
      const struct aiFace *face = &mesh->mFaces[t];
      if (face != nullptr) {
        GLenum face_mode;

        switch (face->mNumIndices) {
        case 1:
          face_mode = GL_POINTS;
          break;
        case 2:
          face_mode = GL_LINES;
          break;
        case 3:
          face_mode = GL_TRIANGLES;
          break;
        default:
          face_mode = GL_POLYGON;
          break;
        }

        glBegin(face_mode);

        for (i = 0; i < face->mNumIndices; i++) {
          int index = face->mIndices[i];

          if (mesh->mColors[0] != nullptr)
            glColor4fv((GLfloat *)&mesh->mColors[0][index]);

          if (mesh->mNormals != nullptr)
            glNormal3fv(&mesh->mNormals[index].x);
          glVertex3fv(&mesh->mVertices[index].x);
        }
        glEnd();
      }
    }
  } else if (m_shape != nullptr) {
    GlDrawcallback drawCallback;
    btVector3 aabbMin(-1e99, -1e99, -1e99);
    btVector3 aabbMax(1e99, 1e99, 1e99);
    btConcaveShape *concaveMesh = (btConcaveShape *)m_shape;
    concaveMesh->processAllTriangles(&drawCallback, aabbMin, aabbMax);
  }
}

btGImpactMeshShape *Mesh::getShape() const { return m_shape; }

void Mesh::setShape(btGImpactMeshShape *shape) {
  if (m_shape != nullptr)
    delete m_shape;

  m_shape = shape;
}

btTriangleMesh *Mesh::getTriangleMesh() const { return m_mesh; }

void Mesh::setTriangleMesh(btTriangleMesh *mesh) {
  if (m_mesh != nullptr)
    delete m_mesh;

  m_mesh = mesh;
}

void Mesh::setMass(btScalar _mass) {
  if (body != nullptr && m_shape != nullptr) {
    btVector3 inertia;
    m_shape->calculateLocalInertia(_mass, inertia);
    body->setMassProps(_mass, inertia);
  }
}

void Mesh::recreate(btDiscreteDynamicsWorld *world) {
  if (!m_filename.isNull() && body != nullptr && m_shape != nullptr) {
    if (world) {
      world->removeRigidBody(body);
    }
    if (body->getMotionState()) {
      delete body->getMotionState();
    }
    delete body;
    body = nullptr;

    btQuaternion qtn;
    btTransform trans;
    btDefaultMotionState *motionState = nullptr;

    trans.setIdentity();
    qtn.setEuler(0.0, 0.0, 0.0);
    trans.setRotation(qtn);
    trans.setOrigin(btVector3(0, 0, 0));
    motionState = new btDefaultMotionState(trans);

    btVector3 inertia;
    m_shape->calculateLocalInertia(m_mass, inertia);
    body = new btRigidBody(m_mass, motionState, m_shape, inertia);
    if (world) {
      world->addRigidBody(body);
    }
  }
}

#endif
