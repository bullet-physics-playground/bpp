#ifdef WIN32_VC90
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

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

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

void Mesh3DS::renderInLocalFrame(QTextStream *s) const {

  GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
  GLfloat mat_ambient[] = { color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, 1.0 };
  GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
  GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
  // GLfloat no_shininess[] = { 0.0 };
  // GLfloat low_shininess[] = { 5.0 };
  GLfloat high_shininess[] = { 100.0 };
  // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};
	
  btTransform trans;
  btScalar m[16];

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  glPushMatrix();
  glMultMatrixf(m);
  glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
  glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);
  glColor3ubv(color);
  glCallList(listref);
  glPopMatrix();

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
      *s << "pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    }else{	    
      *s << mPreSDL << "\n";	    
    }
    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    if (mPostSDL == NULL) {    
      *s << "}" << endl << endl;
    }else{	    
      *s << mPostSDL << endl << endl;	    
    }
	    
  }
  
}
