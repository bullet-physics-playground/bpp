#ifdef _WIN32 //needed for glut.h
#include <windows.h>
#endif

#if defined(__APPLE__) && !defined (VMDMESA)
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#else

#ifdef GLEW_STATIC
#include "CustomGL/glew.h"
#else
#include <GL/glew.h>
#endif//GLEW_STATIC

#ifdef _WINDOWS
#include <windows.h>
//#include <GL/gl.h>
//#include <GL/glu.h>
#else
//#include <GL/gl.h>
//#include <GL/glu.h>
#endif //_WINDOWS
#endif //APPLE

#include <GL/glut.h>

#include "GL_ShapeDrawer.h"
#include "BulletCollision/CollisionShapes/btPolyhedralConvexShape.h"
#include "BulletCollision/CollisionShapes/btTriangleMeshShape.h"
#include "BulletCollision/CollisionShapes/btBoxShape.h"
#include "BulletCollision/CollisionShapes/btSphereShape.h"
#include "BulletCollision/CollisionShapes/btConeShape.h"
#include "BulletCollision/CollisionShapes/btCylinderShape.h"
#include "BulletCollision/CollisionShapes/btTetrahedronShape.h"
#include "BulletCollision/CollisionShapes/btCompoundShape.h"
#include "BulletCollision/CollisionShapes/btCapsuleShape.h"
#include "BulletCollision/CollisionShapes/btConvexTriangleMeshShape.h"
#include "BulletCollision/CollisionShapes/btUniformScalingShape.h"
#include "BulletCollision/CollisionShapes/btStaticPlaneShape.h"
#include "BulletCollision/CollisionShapes/btMultiSphereShape.h"
#include "BulletCollision/CollisionShapes/btConvexPolyhedron.h"
#include "BulletDynamics/Dynamics/btDiscreteDynamicsWorld.h"
#include "BulletDynamics/Dynamics/btRigidBody.h"
#include "LinearMath/btDefaultMotionState.h"

///
#include "BulletCollision/CollisionShapes/btShapeHull.h"

#include "LinearMath/btTransformUtil.h"

#include "LinearMath/btIDebugDraw.h"
//for debugmodes

#include <QDebug>

#if defined(BT_USE_DOUBLE_PRECISION)
#define btglLoadMatrix glLoadMatrixd
#define btglMultMatrix glMultMatrixd
#define btglColor3 glColor3d
#define btglVertex3 glVertex3d
#else
#define btglLoadMatrix glLoadMatrixf
#define btglMultMatrix glMultMatrixf
#define btglColor3 glColor3f
#define btglVertex3 glVertex3d
#endif

void GL_ShapeDrawer::drawCoordSystem()  {
    glBegin(GL_LINES);
    glColor3f(1, 0, 0);
    glVertex3d(0, 0, 0);
    glVertex3d(1, 0, 0);
    glColor3f(0, 1, 0);
    glVertex3d(0, 0, 0);
    glVertex3d(0, 1, 0);
    glColor3f(0, 0, 1);
    glVertex3d(0, 0, 0);
    glVertex3d(0, 0, 1);
    glEnd();

}

class GlDrawcallback : public btTriangleCallback
{

public:

    bool	m_wireframe;

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
            //glColor3f(1, 1, 1);

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


void GL_ShapeDrawer::drawSphere(btScalar radius, int lats, int longs) 
{
    glutSolidSphere(radius, lats, longs);
}


GL_ShapeDrawer::ShapeCache*		GL_ShapeDrawer::cache(btConvexShape* shape)
{
    ShapeCache*		sc=(ShapeCache*)shape->getUserPointer();
    if(!sc)
    {
        sc=new(btAlignedAlloc(sizeof(ShapeCache),16)) ShapeCache(shape);
        sc->m_shapehull.buildHull(shape->getMargin());
        m_shapecaches.push_back(sc);
        shape->setUserPointer(sc);
        /* Build edges	*/
        const int			ni=sc->m_shapehull.numIndices();
        const int			nv=sc->m_shapehull.numVertices();
        const unsigned int*	pi=sc->m_shapehull.getIndexPointer();
        const btVector3*	pv=sc->m_shapehull.getVertexPointer();
        btAlignedObjectArray<ShapeCache::Edge*>	edges;
        sc->m_edges.reserve(ni);
        edges.resize(nv*nv,0);
        for(int i=0;i<ni;i+=3)
        {
            const unsigned int* ti=pi+i;
            const btVector3		nrm=btCross(pv[ti[1]]-pv[ti[0]],pv[ti[2]]-pv[ti[0]]).normalized();
            for(int j=2,k=0;k<3;j=k++)
            {
                const unsigned int	a=ti[j];
                const unsigned int	b=ti[k];
                ShapeCache::Edge*&	e=edges[btMin(a,b)*nv+btMax(a,b)];
                if(!e)
                {
                    sc->m_edges.push_back(ShapeCache::Edge());
                    e=&sc->m_edges[sc->m_edges.size()-1];
                    e->n[0]=nrm;e->n[1]=-nrm;
                    e->v[0]=a;e->v[1]=b;
                }
                else
                {
                    e->n[1]=nrm;
                }
            }
        }
    }
    return(sc);
}

void renderSquareA(float x, float y, float z)
{
    glBegin(GL_LINE_LOOP);
    glVertex3f(x, y, z);
    glVertex3f(x + 10.f, y, z);
    glVertex3f(x + 10.f, y + 10.f, z);
    glVertex3f(x, y + 10.f, z);
    glEnd();
}

inline void glDrawVector(const btVector3& v) { glVertex3d(v[0], v[1], v[2]); }


void GL_ShapeDrawer::drawOpenGL(Object* o, btVector3& minaabb, btVector3& maxaabb)
{
    o->render(minaabb, maxaabb);

    // XXX add caching
}

GL_ShapeDrawer::GL_ShapeDrawer()
{
}

GL_ShapeDrawer::~GL_ShapeDrawer()
{
    int i;
    for (i=0;i<m_shapecaches.size();i++)
    {
        m_shapecaches[i]->~ShapeCache();
        btAlignedFree(m_shapecaches[i]);
    }
    m_shapecaches.clear();
}
