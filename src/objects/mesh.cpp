#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#ifdef HAS_LIB_ASSIMP

#include "mesh.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QStandardPaths>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

// assimp include files. These three are usually needed.
#include <assimp/cimport.h>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

#include "BulletCollision/CollisionShapes/btConvexTriangleMeshShape.h"

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

class GlDrawcallback : public btTriangleCallback
{

public:

    bool m_wireframe;

    GlDrawcallback()
        :m_wireframe(false)
    {
    }

    virtual void processTriangle(btVector3* triangle,int partId, int triangleIndex)
    {

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

class POVSaveCallback : public btTriangleCallback
{

public:

    QList<btVector3> v1;
    QList<btVector3> v2;
    QList<btVector3> v3;
    QList<int> idx;

    POVSaveCallback()
    {
    }

    virtual void processTriangle(btVector3* triangle,int partId, int triangleIndex)
    {
        (void)partId;

        v1.append(triangle[0]);
        v2.append(triangle[1]);
        v3.append(triangle[2]);
        idx.append(triangleIndex);
    }
};


Mesh::Mesh(QString filename, btScalar mass) : Object() {
    m_mesh = new btTriangleMesh();
    m_shape = new btGImpactMeshShape(m_mesh);
    m_scene = NULL;

    setColor(127, 127, 127);

    if (filename != NULL)
        loadFile(filename, mass);
}

Mesh::Mesh(QString filename) : Object() {
    m_mesh = new btTriangleMesh();
    m_shape = new btGImpactMeshShape(m_mesh);
    m_scene = NULL;

    setColor(127, 127, 127);

    if (filename != NULL)
        loadFile(filename, 0);
}

Mesh::Mesh() : Object() {
    m_mesh = new btTriangleMesh();
    m_shape = new btGImpactMeshShape(m_mesh);
    m_scene = NULL;

    setColor(127, 127, 127);
    setMass(0);
}

Mesh::~Mesh() {
    aiReleaseImport(m_scene);
}

void Mesh::loadFile(QString filename, btScalar mass) {
    m_scene = aiImportFile(filename.toUtf8(), aiProcessPreset_TargetRealtime_Fast);

    if (!m_scene) {
        // qDebug() << "Unable to load " << filename << ": using empty shape.";
        btQuaternion qtn;
        btTransform trans;
        btDefaultMotionState *motionState;

        trans.setIdentity();
        qtn.setEuler(0.0, 0.0, 0.0);
        trans.setRotation(qtn);
        trans.setOrigin(btVector3(0, 0, 0));
        motionState = new btDefaultMotionState(trans);

        btVector3 inertia;
        m_shape->calculateLocalInertia(mass,inertia);
        body = new btRigidBody(mass, motionState, m_shape, inertia);
    } else {
        assert(m_scene->mNumMeshes > 0);

        const struct aiMesh* mesh = m_scene->mMeshes[0];

        for (unsigned int t = 0; t < mesh->mNumFaces; ++t) {
            const struct aiFace* face = &mesh->mFaces[t];

            GLenum face_mode;

            switch(face->mNumIndices) {
            case 1:  face_mode = GL_POINTS; break;
            case 2:  face_mode = GL_LINES; break;
            case 3:  face_mode = GL_TRIANGLES; break;
            default: face_mode = GL_POLYGON; break;
            }

            assert(face_mode == GL_TRIANGLES);

            int i0 = face->mIndices[0];
            int i1 = face->mIndices[1];
            int i2 = face->mIndices[2];

            m_mesh->addTriangle(btVector3(mesh->mVertices[i0].x,
                                          mesh->mVertices[i0].y,
                                          mesh->mVertices[i0].z),
                                btVector3(mesh->mVertices[i1].x,
                                          mesh->mVertices[i1].y,
                                          mesh->mVertices[i1].z),
                                btVector3(mesh->mVertices[i2].x,
                                          mesh->mVertices[i2].y,
                                          mesh->mVertices[i2].z)
                                );

        }

        // qDebug() << m_mesh->getNumTriangles();

        m_shape->updateBound();

        btQuaternion qtn;
        btTransform trans;
        btDefaultMotionState *motionState;

        trans.setIdentity();
        qtn.setEuler(0.0, 0.0, 0.0);
        trans.setRotation(qtn);
        trans.setOrigin(btVector3(0, 0, 0));
        motionState = new btDefaultMotionState(trans);

        btVector3 inertia;
        m_shape->calculateLocalInertia(mass,inertia);
        body = new btRigidBody(mass, motionState, m_shape, inertia);
    }
}

void Mesh::luaBind(lua_State *s) {
    using namespace luabind;

    module(s)
            [
            class_<Mesh, Object>("Mesh")
            .def(constructor<>(), adopt(result))
            .def(constructor<QString>(), adopt(result))
            .def(constructor<QString, btScalar>(), adopt(result))
            .def(tostring(const_self))

            .property("shape", &Mesh::getShape, &Mesh::setShape)

            ];
}

QString Mesh::toString() const {
    return QString("Mesh");
}

void Mesh::toMesh2(QTextStream *s) const {
    if (s != NULL && m_shape != NULL) {
        POVSaveCallback pov;
        btVector3 pminaabb = btVector3(-1e99, -1e99, -1e99); // XXX
        btVector3 pmaxaabb = btVector3( 1e99,  1e99,  1e99); // XXX
        btConcaveShape* concaveMesh = (btConcaveShape*) m_shape;
        concaveMesh->processAllTriangles(&pov, pminaabb, pmaxaabb);

        if (pov.idx.length() > 0) {
            *s << "mesh2 {" << endl;
            *s << "  vertex_vectors {" << endl;
            *s << "    " << pov.idx.length()*3 << ", ";
            for (int i = 0; i < pov.idx.length(); ++i) {
                *s << "<"
                   << pov.v1.at(i).x()
                   << ","
                   << pov.v1.at(i).y()
                   << ","
                   << pov.v1.at(i).z()
                   << ">";
                *s << "<"
                   << pov.v2.at(i).x()
                   << ","
                   << pov.v2.at(i).y()
                   << ","
                   << pov.v2.at(i).z()
                   << ">";
                *s << "<"
                   << pov.v3.at(i).x()
                   << ","
                   << pov.v3.at(i).y()
                   << ","
                   << pov.v3.at(i).z()
                   << ">";
                if (i != pov.idx.length() - 1) *s << ", \n";
            }
            *s << " }" << endl;

            /*
            *s << "  normal_vectors {\n";
            *s << "    " << pov.idx.length() << ", ";
            for (int i = 0; i < pov.idx.length(); i++) {
                btVector3 normal = (pov.v3.at(i) - pov.v1.at(i)).cross(pov.v2.at(i) - pov.v1.at(i));
                normal.normalize();
              *s << "<"
                 << normal.getX()
                 << ","
                 << normal.getY()
                 << ","
                 << normal.getZ()
                 << ">";
                if (i != pov.idx.length() - 1) *s << ", \n";
            }
            *s << " }" << endl;
            */

            *s << "  face_indices {"  << endl;
            *s << "    " << pov.idx.length() << ", ";
            for (int i = 0; i < pov.idx.length(); ++i) {
                *s << "<"
                   << i*3
                   << ","
                   << i*3+1
                   << ","
                   << i*3+2
                   << ">";
                if (i != pov.idx.length() - 1) *s << ", \n";
            }
            *s << " }"
               << endl;

            *s << "}" << endl;
        } else {
            *s << "union {}" << endl; // empty object in case of empty mesh
        }
    }
}

void Mesh::toPOV(QTextStream *s) const {
    if (body != NULL && body->getMotionState() != NULL) {
        btTransform trans;

        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    if (s != NULL && m_shape != NULL && body != NULL && body->getMotionState() != NULL) {
        if (mPreSDL == NULL) {

            QByteArray *data = new QByteArray();
            QTextStream *tmp = new QTextStream(data);
            toMesh2(tmp);
            tmp->flush();
            QString str = QString::fromStdString(data->toStdString());
            delete data;

            QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
            hashAlgo.addData(str.toUtf8());
            QString hash = hashAlgo.result().toHex();

            QFileInfo cacheInfo(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
            if (!cacheInfo.exists()) {
                QDir p(".");
                if (!p.mkpath(cacheInfo.absoluteFilePath())) {
                    qDebug() << "unable to create " << cacheInfo.absoluteFilePath();
                }
            }

            // check, if the inc file exists in the cache. If not, create it
            QString incfile = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +
                    QDir::separator() + "mesh_" + hash + ".inc";

            QFileInfo check_file(incfile);
            if (!check_file.exists() && !check_file.isFile() && m_shape != NULL) {
                QFile file(incfile);
                if (file.open(QIODevice::ReadWrite) )
                {
                    QTextStream stream( &file );
                    stream << "#declare mesh_" + hash + " = ";
                    toMesh2(&stream);
                    stream.flush();
                    file.close();
                } else {
                    qDebug() << "unable to create " << incfile;
                }
            } else {
                // qDebug() << "mesh already exists " << incfile;
            }

            *s << "#include \"" + check_file.fileName() + "\"" << endl << endl;

            *s << "object { mesh_" + hash << endl;

        } else {
            *s << mPreSDL
               << endl;
        }

        if (mSDL != NULL) {
            *s << mSDL
               << endl;
        } else {
            *s << "  pigment { rgb <"
               << color[0]/255.0 << ", "
               << color[1]/255.0 << ", "
               << color[2]/255.0 << "> }"
               << endl;
        }

        *s << "  matrix <" <<  matrix[0] << "," <<  matrix[1] << "," <<  matrix[2] << "," << endl
           << "          " <<  matrix[4] << "," <<  matrix[5] << "," <<  matrix[6] << "," << endl
           << "          " <<  matrix[8] << "," <<  matrix[9] << "," << matrix[10] << "," << endl
           << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << endl;

        if (mPostSDL == NULL) {
            *s << "}"
               << endl
               << endl;
        } else {
            *s << mPostSDL
               << endl
               << endl;
        }
    }
}

void Mesh::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    (void)minaabb;
    (void)maxaabb;

    GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
    GLfloat mat_ambient[] = { (GLfloat)(color[0] / 255.0), (GLfloat)(color[1] / 255.0), (GLfloat)(color[2] / 255.0), 1.0 };
    GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
    GLfloat mat_specular[] = { 0.0, 0.0, 0.0, 1.0 };
    // GLfloat no_shininess[] = { 0.0 };
    // GLfloat low_shininess[] = { 5.0 };
    GLfloat high_shininess[] = { 100.0 };
    // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

    glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
    glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);
    glColor3ubv(color);

    if (m_scene != NULL && m_scene->mMeshes != NULL) {
      const struct aiMesh* mesh = m_scene->mMeshes[0];

      unsigned int i,t;

      for (t = 0; t < mesh->mNumFaces; ++t) {
        const struct aiFace* face = &mesh->mFaces[t];
        if (face != NULL) {
            GLenum face_mode;

            switch(face->mNumIndices) {
              case 1:  face_mode = GL_POINTS; break;
              case 2:  face_mode = GL_LINES; break;
              case 3:  face_mode = GL_TRIANGLES; break;
              default: face_mode = GL_POLYGON; break;
            }

            glBegin(face_mode);

            for (i = 0; i < face->mNumIndices; i++) {
              int index = face->mIndices[i];

              if (mesh->mColors[0] != NULL)
                glColor4fv((GLfloat*)&mesh->mColors[0][index]);

              if (mesh->mNormals != NULL)
                glNormal3fv(&mesh->mNormals[index].x);
              glVertex3fv(&mesh->mVertices[index].x);
            }
            glEnd();
        }
      }
    }
}

btGImpactMeshShape* Mesh::getShape() const {
    return m_shape;
}

void Mesh::setShape(btGImpactMeshShape *shape) {
    if (m_shape != NULL)
        delete m_shape;

    m_shape = shape;
}

void Mesh::setMass(btScalar _mass) {
    if (body != NULL && m_shape != NULL) {
        btVector3 inertia;
        m_shape->calculateLocalInertia(_mass,inertia);
        body->setMassProps(_mass, inertia);
    }
}

#endif
