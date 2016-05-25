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


        if (m_wireframe)
        {
            glBegin(GL_LINES);
            glColor3f(1, 0, 0);
            glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
            glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
            glColor3f(0, 1, 0);
            glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
            glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
            glColor3f(0, 0, 1);
            glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
            glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
            glEnd();
        } else
        {
            glBegin(GL_TRIANGLES);
            glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
            glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
            glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
            glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
            glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
            glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
            glEnd();
        }
    }
};

class TriangleGlDrawcallback : public btInternalTriangleIndexCallback
{
public:
    virtual void internalProcessTriangleIndex(btVector3* triangle,int partId,int  triangleIndex)
    {
        (void)triangleIndex;
        (void)partId;


        glBegin(GL_TRIANGLES);//LINES);
        glColor3f(1, 0, 0);
        glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
        glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
        glColor3f(0, 1, 0);
        glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
        glVertex3d(triangle[1].getX(), triangle[1].getY(), triangle[1].getZ());
        glColor3f(0, 0, 1);
        glVertex3d(triangle[2].getX(), triangle[2].getY(), triangle[2].getZ());
        glVertex3d(triangle[0].getX(), triangle[0].getY(), triangle[0].getZ());
        glEnd();
    }
};


Mesh::Mesh(QString filename, btScalar mass) : Object() {
    m_mesh = new btTriangleMesh();

    setColor(0.75, 0.75, 0.75);

    if (filename != NULL)
        loadFile(filename, mass);
}

Mesh::Mesh(QString filename) : Object() {
    m_mesh = new btTriangleMesh();

    setColor(0.75, 0.75, 0.75);

    if (filename != NULL)
        loadFile(filename, 0);
}

Mesh::Mesh() : Object() {
    setColor(0.75, 0.75, 0.75);
    setMass(0);
}

Mesh::~Mesh() {
}

void Mesh::loadFile(QString filename, btScalar mass) {
    const aiScene *scene = aiImportFile(filename.toUtf8(), aiProcessPreset_TargetRealtime_Fast);

    if (!scene) {
        // qDebug() << "Unable to load " << filename << ": using empty shape.";
        btEmptyShape* shape = new btEmptyShape();
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
        assert(scene->mNumMeshes > 0);

        const struct aiMesh* mesh = scene->mMeshes[0];

        unsigned int t;

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

        m_shape = new btGImpactMeshShape(m_mesh);
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

        aiReleaseImport(scene);
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

            .property("shape", &Mesh::getShape, &Mesh::setShape)

            ];
}

QString Mesh::toString() const {
    return QString("Mesh");
}

void Mesh::renderInLocalFrame(QTextStream *s) {
    glColor3ubv(color);

    if (m_shape != NULL) {
        GlDrawcallback drawCallback;
        drawCallback.m_wireframe = true;

        btConcaveShape* concaveMesh = (btConcaveShape*) m_shape;

        concaveMesh->processAllTriangles(&drawCallback,btVector3(-1000,-1000,-1000), btVector3(1000,1000,1000)); // XXX use scene world bounds
    }

    /* XXX add back POV-Ray export

    if (m_scene && m_scene->mMeshes) {
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
    */
}

btGImpactMeshShape* Mesh::getShape() const {
    return m_shape;
}

void Mesh::setShape(btGImpactMeshShape *shape) {
    m_shape = shape;
}

#endif
