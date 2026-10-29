/**
 * @file csg.cpp
 * @brief Implementation of the CSG object.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "csg.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

CsgObject::CsgObject(btScalar mass) {
  root = nullptr;
  compoundShape = nullptr;
  setMass(mass);
}

CsgObject::CsgObject(CsgNode *rootNode, btScalar mass) : root(rootNode) {
  compoundShape = nullptr;
  buildCompoundShape(mass);
}

CsgObject::~CsgObject() {
  root = nullptr;
  if (compoundShape) {
    delete compoundShape;
    compoundShape = nullptr;
  }
  deleteOwnShape(true);
}

void CsgObject::buildCompoundShape(btScalar mass) {
  if (!root) return;

  compoundShape = new btCompoundShape();

  // Collect all leaf objects
  std::vector<Object *> leaves;
  class LeafCollector : public Visitor {
  public:
    std::vector<Object *> &out;
    LeafCollector(std::vector<Object *> &o) : out(o) {}
    bool Visiting(Object *obj) override {
      if (obj && obj->getCollisionShape())
        out.push_back(obj);
      return true;
    }
  } collector(leaves);

  // Traverse the CSG tree
  std::function<void(CsgNode *)> traverse = [&](CsgNode *node) {
    if (!node) return;
    if (node->isLeaf() && node->object) {
      collector.Visiting(node->object);
    } else {
      traverse(node->left);
      traverse(node->right);
    }
  };
  traverse(root);

  // Compute average position of all leaves as CSG local origin reference,
  // so child shapes are positioned relative to the CSG object's origin
  btVector3 avgPos(0, 0, 0);
  int count = 0;
  for (Object *obj : leaves) {
    if (obj->getCollisionShape()) {
      avgPos += obj->getPosition();
      count++;
    }
  }
  if (count > 0) avgPos /= btScalar(count);

  // Add all shapes to compound with local-space transforms
  for (Object *obj : leaves) {
    if (obj->getCollisionShape()) {
      btTransform childTrans = obj->getTransform();
      // Make origin relative to CSG object origin
      childTrans.setOrigin(childTrans.getOrigin() - avgPos);
      if (root && !root->isLeaf()) {
        childTrans = root->transform * childTrans;
      }
      compoundShape->addChildShape(childTrans, obj->getCollisionShape());
    }
  }

  // Create rigid body with compound shape
  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  compoundShape->calculateLocalInertia(mass, inertia);
  shape = compoundShape;
  body = new btRigidBody(mass, motionState, shape, inertia);
  _ownsBody = true;
}

void CsgObject::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[
    class_<CsgObject, Object>("CsgObject")
      .def(constructor<>())
      .def(constructor<btScalar>())
      .def(constructor<CsgNode *>())
      .def(constructor<CsgNode *, btScalar>())
      .def(tostring(const_self))
      .def(const_self == const_self)
      .def("setRoot", &CsgObject::setRoot)
      .def("getRoot", &CsgObject::getRoot)
  ];

  module(s)[
    class_<CsgNode>("CsgNode")
      .def(constructor<>())
      .def(constructor<Object *>())
      .def(constructor<CsgOperation, CsgNode *, CsgNode *>())
      .def_readwrite("object", &CsgNode::object)
      .def_readwrite("operation", &CsgNode::operation)
      .def_readwrite("left", &CsgNode::left)
      .def_readwrite("right", &CsgNode::right)
  ];
}

QString CsgObject::toString() const { return QString("CsgObject"); }

void CsgObject::writeCsgNode(QTextStream *s, const CsgNode *node, int depth) const {
  if (!node || !s) return;

  QString indent(depth * 2, ' ');

  if (node->isLeaf() && node->object) {
    // Leaf node - write the object
    node->object->toPOV(s);
  } else {
    // Internal node - write CSG operation
    QString op;
    switch (node->operation) {
      case CSG_UNION: op = "union"; break;
      case CSG_DIFFERENCE: op = "difference"; break;
      case CSG_INTERSECTION: op = "intersection"; break;
    }

    *s << indent << op << " {\n";
    writeCsgNode(s, node->left, depth + 1);
    writeCsgNode(s, node->right, depth + 1);
    *s << indent << "}\n";
  }
}

void CsgObject::toPOV(QTextStream *s) const {
  if (!root || !s) return;

  // Get world transform
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    if (placed)
      trans = place * trans;
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      QString op;
      switch (root->operation) {
        case CSG_UNION: op = "union"; break;
        case CSG_DIFFERENCE: op = "difference"; break;
        case CSG_INTERSECTION: op = "intersection"; break;
      }
      *s << op << " {\n";
    } else {
      *s << mPreSDL << "\n";
    }

    // Write children (skip root if root is internal node)
    if (root->isLeaf() && root->object) {
      root->object->toPOV(s);
    } else {
      writeCsgNode(s, root->left, 1);
      writeCsgNode(s, root->right, 1);
    }

    // Apply matrix transform inside the CSG block (before closing brace)
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
}

void CsgObject::renderCsgNode(const CsgNode *node) const {
  if (!node) return;

  if (node->isLeaf() && node->object) {
    btVector3 minaabb, maxaabb;
    node->object->render(minaabb, maxaabb);
  } else {
    switch (node->operation) {
      case CSG_UNION:
        // Union: draw both children normally
        renderCsgNode(node->left);
        renderCsgNode(node->right);
        break;

      case CSG_DIFFERENCE: {
        // Difference A - B: draw A normally, then draw B only where A is NOT visible
        // Step 1: Draw A normally
        renderCsgNode(node->left);

        // Step 2: Mark where A is visible in stencil
        glEnable(GL_STENCIL_TEST);
        glClear(GL_STENCIL_BUFFER_BIT);
        glStencilFunc(GL_ALWAYS, 1, 0xFF);
        glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        glDepthMask(GL_FALSE);
        renderCsgNode(node->left);

        // Step 3: Draw B where stencil != 1 (B not overlapping A), with depth test
        glStencilFunc(GL_NOTEQUAL, 1, 0xFF);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glDepthMask(GL_TRUE);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
        renderCsgNode(node->right);

        glDisable(GL_STENCIL_TEST);
        break;
      }

      case CSG_INTERSECTION: {
        // Intersection A * B: draw B only where A is visible
        // Step 1: Mark where A is visible in stencil
        glEnable(GL_STENCIL_TEST);
        glClear(GL_STENCIL_BUFFER_BIT);
        glStencilFunc(GL_ALWAYS, 1, 0xFF);
        glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        glDepthMask(GL_FALSE);
        renderCsgNode(node->left);

        // Step 2: Draw B where stencil == 1 (B overlapping A), with depth test
        glStencilFunc(GL_EQUAL, 1, 0xFF);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glDepthMask(GL_TRUE);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
        renderCsgNode(node->right);

        glDisable(GL_STENCIL_TEST);
        break;
      }
    }
  }
}

void CsgObject::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  if (!root) return;

  // Render the CSG tree in local space.
  // The viewer applies the object's 'place' matrix externally before calling
  // renderInLocalFrame, so we only render each node's local transform here.
  renderCsgNode(root);
}

namespace Csg {

CsgObject *makeCsg(CsgNode *root, btScalar mass) {
  return new CsgObject(root, mass);
}

} // namespace Csg