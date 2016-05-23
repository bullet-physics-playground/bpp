#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#ifdef HAS_LIB_ASSIMP

#include "mesh.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

// assimp include files. These three are usually needed.
#include <assimp/cimport.h>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Mesh::Mesh(QString filename, btScalar mass) : Object() {

    setColor(0.75, 0.75, 0.75);

    if (filename != NULL)
        loadFile(filename, mass);
}

Mesh::~Mesh() {
    if (m_scene != NULL) {
        aiReleaseImport(m_scene);
    }
}

void Mesh::loadFile(QString filename, btScalar mass) {
    m_scene = aiImportFile(filename.toUtf8(), aiProcessPreset_TargetRealtime_Fast);

    if (!m_scene) {

        // qDebug() << "Unable to load " << filename << ": using empty shape.";

        btEmptyShape *shape = new btEmptyShape();
        btQuaternion qtn;
        btTransform trans;
        btDefaultMotionState *motionState;

        trans.setIdentity();
        qtn.setEuler(0.0, 0.0, 0.0);
        trans.setRotation(qtn);
        trans.setOrigin(btVector3(0, 0, 0));
        motionState = new btDefaultMotionState(trans);

        btVector3 inertia;
        shape->calculateLocalInertia(mass,inertia);
        body = new btRigidBody(mass, motionState, shape, inertia);

    } else {
        assert(m_scene->mNumMeshes > 0);

        const struct aiMesh* mesh = m_scene->mMeshes[0];

        unsigned int t;

        btTriangleMesh* trimesh = new btTriangleMesh();

        for (t = 0; t < mesh->mNumFaces; ++t) {
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

            trimesh->addTriangle(btVector3(mesh->mVertices[i0].x,
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

        btGImpactMeshShape *shape = new btGImpactMeshShape(trimesh);
        shape->updateBound();

        btQuaternion qtn;
        btTransform trans;
        btDefaultMotionState *motionState;

        trans.setIdentity();
        qtn.setEuler(0.0, 0.0, 0.0);
        trans.setRotation(qtn);
        trans.setOrigin(btVector3(0, 0, 0));
        motionState = new btDefaultMotionState(trans);

        btVector3 inertia;
        shape->calculateLocalInertia(mass,inertia);
        body = new btRigidBody(mass, motionState, shape, inertia);

    }
}

void Mesh::luaBind(lua_State *s) {
    using namespace luabind;

    open(s);

    module(s)
            [
            class_<Mesh,Object>("Mesh")
            .def(constructor<QString, btScalar>(), adopt(result))
            .def(tostring(const_self))
            ];
}

QString Mesh::toString() const {
    return QString("Mesh");
}

void Mesh::renderInLocalFrame(QTextStream *s) {

    GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
    GLfloat mat_ambient[] = { color[0] / 255.0f, color[1] / 255.0f, color[2] / 255.0f, 1.0 };
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

    if (m_scene) {
        const struct aiMesh* mesh = m_scene->mMeshes[0];

        unsigned int i,t;

        for (t = 0; t < mesh->mNumFaces; ++t) {
            const struct aiFace* face = &mesh->mFaces[t];
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

    if (s != NULL && m_scene != NULL && m_scene->mNumMeshes > 0) {
        if (mPreSDL == NULL) {
            const struct aiMesh* mesh = m_scene->mMeshes[0];

            *s << "mesh2 {" << endl;
            *s << "  vertex_vectors {" << endl;
            *s << "    " << mesh->mNumVertices << ", ";
            for (unsigned int i = 0; i < mesh->mNumVertices; ++i) {
                *s << "<"
                   << mesh->mVertices[i].x
                   << ","
                   << mesh->mVertices[i].y
                   << ","
                   << mesh->mVertices[i].z
                   << ">";
            }
            *s << " }" << endl;

            if (mesh->HasNormals()) {
                *s << "  normal_vectors {" << endl;
                *s << "    " << mesh->mNumVertices << ", ";
                for (unsigned int i = 0; i < mesh->mNumVertices; ++i) {
                    *s << "<"
                       << mesh->mNormals[i].x
                       << ","
                       << mesh->mNormals[i].y
                       << ","
                       << mesh->mNormals[i].z
                       << ">";
                }
                *s << " }"
                   << endl;
            }

            *s << "  face_indices {"  << endl;
            *s << "    " << mesh->mNumFaces << ", ";
            for (unsigned int t = 0; t < mesh->mNumFaces; ++t) {
                const struct aiFace* face = &mesh->mFaces[t];
                // only trimeshes for now! assert(face->mNumIndices == 3);
                *s << "<"
                   << face->mIndices[0]
                   << ","
                   << face->mIndices[1]
                   << ","
                   << face->mIndices[2]
                   << ">";
            }
            *s << " }"
               << endl;

            if (mesh->HasNormals()) {
                *s << "  normal_indices {"  << endl;
                *s << "    " << mesh->mNumFaces << ", ";
                for (unsigned int t = 0; t < mesh->mNumFaces; ++t) {
                    const struct aiFace* face = &mesh->mFaces[t];
                    // only trimeshes for now! assert(face->mNumIndices == 3);
                    *s << "<"
                       << face->mIndices[0]
                       << ","
                       << face->mIndices[1]
                       << ","
                       << face->mIndices[2]
                       << ">";
                }
                *s << " }"
                   << endl;
            }
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

#endif
