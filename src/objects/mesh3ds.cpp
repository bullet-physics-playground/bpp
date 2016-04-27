#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "mesh3ds.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

#include <lib3ds/mesh.h>
#include <lib3ds/node.h>
#include <lib3ds/vector.h>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Mesh3DS::Mesh3DS(QString filename, btScalar mass) : Object() {
  m_TotalFaces = 0;

  m_model = lib3ds_file_load(filename.toUtf8());

  if (!m_model) {

    qDebug() << "Unable to load " << filename << ": using empty shape.";

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
    Lib3dsMesh *mesh;

    for (mesh = m_model->meshes; mesh != 0; mesh = mesh->next) {
      m_TotalFaces += mesh->faces;
    }

    btTriangleMesh* trimesh = new btTriangleMesh();

    // Allocate memory for our vertices and normals
    Lib3dsVector * vertices = new Lib3dsVector[m_TotalFaces * 3];
    Lib3dsVector * normals = new Lib3dsVector[m_TotalFaces * 3];

    unsigned int f = 0;
    for(mesh = m_model->meshes;mesh != NULL;mesh = mesh->next)
    {
      lib3ds_mesh_calculate_normals(mesh, &normals[f*3]);

      for(unsigned int cur_face = 0; cur_face < mesh->faces;cur_face++)
      {
        Lib3dsFace * face = &mesh->faceL[cur_face];
        for(unsigned int i = 0;i < 3;i++)
        {
          memcpy(&vertices[f*3 + i], mesh->pointL[face->points[ i ]].pos, sizeof(Lib3dsVector));

        }

        trimesh->addTriangle(btVector3(vertices[f*3][0],vertices[f*3][1],vertices[f*3][2]),
                             btVector3(vertices[f*3+1][0],vertices[f*3+1][1],vertices[f*3+1][2]),
                             btVector3(vertices[f*3+2][0],vertices[f*3+2][1],vertices[f*3+2][2]));

        f++;
      }
    }

    // Generate a Vertex Buffer Object and store it with our vertices
    /*
    glGenBuffers(1, &m_VertexVBO);
    glBindBuffer(GL_ARRAY_BUFFER, m_VertexVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Lib3dsVector) * 3 * m_TotalFaces, vertices, GL_STATIC_DRAW);
    */

    // Generate another Vertex Buffer Object and store the normals in it
    /*
    glGenBuffers(1, &m_NormalVBO);
    glBindBuffer(GL_ARRAY_BUFFER, m_NormalVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Lib3dsVector) * 3 * m_TotalFaces, normals, GL_STATIC_DRAW);
    */

    // Clean up our allocated memory
    delete vertices;
    delete normals;

    // We no longer need lib3ds
    lib3ds_file_free(m_model);
    m_model = NULL;

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

void Mesh3DS::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Mesh3DS,Object>("Mesh3DS")
     .def(constructor<QString, btScalar>(), adopt(result))
     .def(tostring(const_self))
     ];
}

QString Mesh3DS::toString() const {
  return QString("Mesh3DS");
}

void Mesh3DS::renderInLocalFrame(QTextStream *s) {

  GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
  GLfloat mat_ambient[] = { color[0] / 255.0f, color[1] / 255.0f, color[2] / 255.0f, 1.0 };
  GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
  GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
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

  if (m_TotalFaces > 0) {
    // Enable vertex and normal arrays
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

    // Bind the vbo with the normals
    /*
    glBindBuffer(GL_ARRAY_BUFFER, m_NormalVBO);
    // The pointer for the normals is NULL which means that OpenGL will use the currently bound vbo
    glNormalPointer(GL_FLOAT, 0, NULL);

    glBindBuffer(GL_ARRAY_BUFFER, m_VertexVBO);
    glVertexPointer(3, GL_FLOAT, 0, NULL);

    // Render the triangles
    glDrawArrays(GL_TRIANGLES, 0, m_TotalFaces * 3);

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    */
  }

  if (s != NULL) {
    if (mPreSDL == NULL) {
      *s << "mesh2 {\n";
      /*
    *s << "  vertex_vectors {\n";
    *s << "    " << count*3 << ", \n";
    for (int i = 0; i < count; i++) {
      for (int y = 0; y < 3; y++) {
    *s << "   <" << vertices[i][y][0] << ", " << vertices[i][y][1] << ", " << vertices[i][y][2] << ">";
      }
      if (i != count - 1) *s << ", \n";
    }
    *s << "  }\n";

    *s << "  normal_vectors {\n";
    *s << "    " << count*3 << ", \n";
    for (int i = 0; i < count; i++) {
      for (int y = 0; y < 3; y++) {
    *s << "   <" << normals[i][0] << ", " << normals[i][1] << ", " << normals[i][2] << ">";
      }
      if (i != count - 1) *s << ", \n";
    }
    *s << "  }\n";

    *s << "  face_indices {\n";
    *s << "    " << count << ", \n";
    for (int i = 0; i < count; i++) {
      *s << "    <" << indices[i][0] << ", " << indices[i][1] << ", " << indices[i][2] << ">";
      if (i != count - 1) *s << ", \n";
    }
    *s << "  }\n";
      */
      *s << "pigment { rgb <"
         << color[0]/255.0 << ", "
         << color[1]/255.0 << ", "
         << color[2]/255.0 << "> }" << endl;
    } else {
      *s << mPreSDL << "\n";
    }

    *s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2] << "," << endl
       << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6] << "," << endl
       << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10] << "," << endl
       << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << endl;

    if (mPostSDL == NULL) {
      *s << "}" << endl << endl;
    } else {
      *s << mPostSDL << endl << endl;
    }

  }

}
