#ifdef WIN32
#pragma warning (disable : 4251)
#endif

#include "mesh3ds.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>
#include <assert.h>

#include <lib3ds.h>

Mesh3DS::Mesh3DS(QString filename, btScalar mass) {
  Lib3dsFile *m_model = lib3ds_file_open(filename.toAscii());

  if (!m_model) {
      qDebug() << "Unable to load " << filename;
      return;
  }

  Lib3dsMesh * mesh;
  int i = 0;
  int count = 0;

  btTriangleMesh* trimesh = new btTriangleMesh();

  count = 0;
  for (i = 0; i < m_model->nmeshes; i++) {
    mesh = m_model->meshes[i];
    count += mesh->nfaces;
  }

  int cnt = 0;
  listref = glGenLists(1);
  assert(listref != 0);

  glNewList(listref,GL_COMPILE);
  glBegin(GL_TRIANGLES);

  float (*normals)[3] = new float[count][3];

  for (i = 0; i < m_model->nmeshes; i++) {
    mesh = m_model->meshes[i];
    unsigned int cnt1 = mesh->nfaces;

	lib3ds_mesh_calculate_face_normals(mesh,&normals[cnt]);
    // uint index = 0;
    for (uint x=0; x<cnt1; x++) { // face
      glNormal3f(normals[cnt+x][0], normals[cnt+x][1], normals[cnt+x][2]);
      for (uint y=0; y<3; y++) { // vertex
	//indices[cnt+x][y] = index++;
	uint num = mesh->faces[x].index[y];
	glVertex3f(mesh->vertices[num][0], mesh->vertices[num][1], mesh->vertices[num][2]);
      }

      uint num1 = mesh->faces[x].index[0];
      uint num2 = mesh->faces[x].index[1];
      uint num3 = mesh->faces[x].index[2];
      
      trimesh->addTriangle(btVector3(mesh->vertices[num1][0],mesh->vertices[num1][1],mesh->vertices[num1][2]),
			   btVector3(mesh->vertices[num2][0],mesh->vertices[num2][1],mesh->vertices[num2][2]),
			   btVector3(mesh->vertices[num3][0],mesh->vertices[num3][1],mesh->vertices[num3][2]));
    }

    cnt += cnt1;
  }
  
  glEnd();
  glEndList();

  shape = new btBvhTriangleMeshShape(trimesh, false);

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  body = new btRigidBody(mass, motionState, shape, btVector3(mass, mass, mass));
}

void Mesh3DS::renderInLocalFrame(QTextStream *) const {
  btTransform trans;
  btScalar m[16];

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  glPushMatrix();
  glMultMatrixf(m);
  glColor3ubv(color);
  glCallList(listref);
  glPopMatrix();

  /*
  if (s != NULL) {
    *s << "mesh2 {\n";
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

    *s << "pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;

    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    *s << "}" << endl << endl;
  }
  */
}
