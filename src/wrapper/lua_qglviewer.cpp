#include "lua_qglviewer.h"

#include <luabind/operator.hpp>
#include <luabind/out_value_policy.hpp>

#include "lua_qslot.h"

/* simply add a gl viewer
viewer = QGLViewer(mainWindow)
logEdit:clear()
viewer.axisIsDrawn = true
viewer.gridIsDrawn = true
viewer.drawNeeded = function ()
  gl.Begin("QUAD_STRIP")
  local i = 0
  local nbSteps = 200.0
  for i=0,nbSteps do
      ratio = i/nbSteps;
      angle = 21.0*ratio;
      c = math.cos(angle);
      s = math.sin(angle);
      r1 = 1.0 - 0.8*ratio;
      r2 = 0.8 - 0.8*ratio;
      alt = ratio - 0.5;
      nor = 0.5;
      up = math.sqrt(1.0-nor*nor);
      gl.Color(1.0-ratio, 0.2 , ratio);
      gl.Normal(nor*c, up, nor*s);
      gl.Vertex(r1*c, alt, r1*s);
      gl.Vertex(r2*c, alt+0.05, r2*s);
   end
  gl.End();
end
mdiArea:addSubWindow(viewer):show()
  */
QPixmap lqglwidget_renderPixmap1(QGLWidget* o){ return o->renderPixmap();}
QPixmap lqglwidget_renderPixmap2(QGLWidget* o, int w){ return o->renderPixmap(w);}
QPixmap lqglwidget_renderPixmap3(QGLWidget* o, int w, int h){ return o->renderPixmap(w,h);}

LQGLWidget lqglwidget()
{
    return
    class_<QGLWidget,QWidget>("QGLWidget")
    .def(constructor<QWidget*>())
    .def(constructor<QWidget*,QGLWidget*>())
    .def(constructor<QWidget*,QGLWidget*,Qt::WindowFlags>())
    .def("qglClearColor", &QGLWidget::qglClearColor)
    .def("qglColor", &QGLWidget::qglColor)
    .def("renderPixmap", &QGLWidget::renderPixmap)
    .def("renderPixmap", lqglwidget_renderPixmap1)
    .def("renderPixmap", lqglwidget_renderPixmap2)
    .def("renderPixmap", lqglwidget_renderPixmap3)

    .scope[
            def("convertToGLFormat", &QGLWidget::convertToGLFormat)
     ]
    ;
}

qglviewer::Vec lqglvec_cross(qglviewer::Vec& l, qglviewer::Vec& r)
{
    return cross(l,r);
}

QList<double> lqglvec_value(qglviewer::Vec& l)
{
    QList<double> r;
    r.append(l.x);
    r.append(l.y);
    r.append(l.z);
    return r;
}

QString lqglvec_tostring(qglviewer::Vec *w){
    QString s;
    s = QString("%1,%2,%3").arg(w->x).arg(w->y).arg(w->z);
    return s;
}

LQGLVec lqglvec()
{
    return
    class_<qglviewer::Vec>("QGLVec")
    .def(constructor<>())
    .def(constructor<double,double,double>())
    .def(constructor<const qglviewer::Vec&>())
    .def("__tostring", lqglvec_tostring)

    .def_readwrite("x", &qglviewer::Vec::x)
    .def_readwrite("y", &qglviewer::Vec::y)
    .def_readwrite("z", &qglviewer::Vec::x)
    .def(const_self + const_self)
    .def(const_self - const_self)
    .def(const_self * const_self)
    .def(const_self * other<double>())
    .def(other<double>() * const_self)
    .def(const_self / other<double>())
    .def(const_self == const_self)
    .def("cross", lqglvec_cross)
    .def("setValue", &qglviewer::Vec::setValue)
    .def("orthogonalVec", &qglviewer::Vec::orthogonalVec)
    .def("projectOnAxis", &qglviewer::Vec::projectOnAxis)
    .def("projectOnPlane", &qglviewer::Vec::projectOnPlane)
    .property("value", lqglvec_value)
    ;
}

QList<double> lquaternion_value(qglviewer::Quaternion* l)
{
    QList<double> r;
    r.append((*l)[0]);
    r.append((*l)[1]);
    r.append((*l)[2]);
    r.append((*l)[3]);
    return r;
}

void lquaternion_setFromRotationMatrix(qglviewer::Quaternion& l, const QList<QList<double> >& v)
{
    double m[3][3];
    if(v.count() < 3) return;
    if(v[0].count() < 3) return;
    if(v[1].count() < 3) return;
    if(v[2].count() < 3) return;
    for(int i=0;i<3;i++)
        for(int j=0;j<3;j++)
            m[i][j] = v[i][j];
    l.setFromRotationMatrix(m);
}

qglviewer::Vec lquaternion_getAxisAngle(qglviewer::Quaternion* w, float& angle)
{
    qglviewer::Vec axis;
    w->getAxisAngle(axis,angle);
    return axis;
}

QList<double> lquaternion_matrix(qglviewer::Quaternion* w)
{
    const GLdouble* mat = w->matrix();
    QList<double> r;
    for(int i=0;i<16;i++){
        r.append(mat[i]);
    }
    return r;
}

QList< QList<double> > lquaternion_matrix2(qglviewer::Quaternion* w)
{
    const GLdouble* mat = w->matrix();
    QList< QList<double> > res;
    for(int j=0;j<4;j++){
        QList<double> r;
        for(int i=0;i<4;i++){
            r.append(mat[i+j*4]);
        }
        res.append(r);
    }
    return res;
}

QList< QList<double> > lquaternion_rotationMatrix (qglviewer::Quaternion* w)
{
    float mat[3][3];
    w->getRotationMatrix(mat);
    QList< QList<double> > res;
    for(int j=0;j<3;j++){
        QList<double> r;
        for(int i=0;i<3;i++){
            r.append((double)mat[j][i]);
        }
        res.append(r);
    }
    return res;
}

QList<double> lquaternion_inverseMatrix(qglviewer::Quaternion* w)
{
    const GLdouble* mat = w->inverseMatrix();
    QList<double> r;
    for(int i=0;i<16;i++){
        r.append(mat[i]);
    }
    return r;
}

QList< QList<double> > lquaternion_inverseMatrix2(qglviewer::Quaternion* w)
{
    const GLdouble* mat = w->inverseMatrix();
    QList< QList<double> > res;
    for(int j=0;j<4;j++){
        QList<double> r;
        for(int i=0;i<4;i++){
            r.append(mat[i+j*4]);
        }
        res.append(r);
    }
    return res;
}

QList< QList<double> > lquaternion_inverseRotationMatrix (qglviewer::Quaternion* w)
{
    float mat[3][3];
    w->getInverseRotationMatrix(mat);
    QList< QList<double> > res;
    for(int j=0;j<3;j++){
        QList<double> r;
        for(int i=0;i<3;i++){
            r.append((double)mat[j][i]);
        }
        res.append(r);
    }
    return res;
}

qglviewer::Quaternion lquaternion_slerp(const qglviewer::Quaternion &a, const qglviewer::Quaternion &b, float t)
{
    return qglviewer::Quaternion::slerp(a,b,t);
}

void lquaternion_setValue(qglviewer::Quaternion* w, const QList<double>& v)
{
    if(v.length() < 4) return;
    w->setValue(v[0],v[1],v[2],v[3]);
}

QString lquaternion_toString(qglviewer::Quaternion* w)
{
    QString s;
    s = QString("%1,%2,%3,%4").arg((*w)[0]).arg((*w)[1]).arg((*w)[2]).arg((*w)[3]);
    return s;
}

LQuaternion lquaternion()
{
    return
    myclass_<qglviewer::Quaternion>("Quaternion")
    .def(constructor<>())
    .def(constructor<const qglviewer::Vec&, double>())
    .def(constructor<const qglviewer::Vec&, const qglviewer::Vec&>())
    .def(constructor<double,double,double,double>())
    .def(constructor<const qglviewer::Quaternion&>())
    .def("setAxisAngle", &qglviewer::Quaternion::setAxisAngle)
    .def("setValue", &qglviewer::Quaternion::setValue)
    .def("setValue", lquaternion_setValue)
    .def("__tostring", lquaternion_toString)

    .def("setFromRotationMatrix", lquaternion_setFromRotationMatrix)
    .def("setFromRotatedBasis", &qglviewer::Quaternion::setFromRotatedBasis)
    .def("getAxisAngle", lquaternion_getAxisAngle, pure_out_value(_2))
    .property("axis", &qglviewer::Quaternion::axis)
    .property("angle", &qglviewer::Quaternion::angle)

    .def("rotate", &qglviewer::Quaternion::rotate)
    .def("inverseRotate", &qglviewer::Quaternion::inverseRotate)
    .def(const_self * const_self)
    .def(const_self * other<qglviewer::Vec>())
    .property("inverse", &qglviewer::Quaternion::inverse)
    .def("invert", &qglviewer::Quaternion::invert)
    .def("negate", &qglviewer::Quaternion::negate)
    .def("normalize", &qglviewer::Quaternion::normalize)
    .property("normalized", &qglviewer::Quaternion::normalized)
    .property("matrix", lquaternion_matrix)
    .property("matrix2", lquaternion_matrix2)
    .property("rotationMatrix", lquaternion_rotationMatrix)
    .property("inverseMatrix", lquaternion_inverseMatrix)
    .property("inverseMatrix2", lquaternion_inverseMatrix2)
    .property("inverseRotationMatrix", lquaternion_inverseRotationMatrix)
    .property("log", &qglviewer::Quaternion::log)
    .property("exp", &qglviewer::Quaternion::exp)
    .class_<qglviewer::Quaternion>::property("value", lquaternion_value, lquaternion_setValue)
    .scope[
            def("slerp", &qglviewer::Quaternion::slerp),
            def("slerp", lquaternion_slerp),
            def("squad", &qglviewer::Quaternion::squad),
            def("dot", &qglviewer::Quaternion::dot),
            def("lnDif", &qglviewer::Quaternion::lnDif),
            def("squadTangent", &qglviewer::Quaternion::squadTangent),
            def("randomQuaternion", &qglviewer::Quaternion::randomQuaternion)
    ]
    ;
}

void lqcamera_setOrientation1(qglviewer::Camera* w, qglviewer::Quaternion &q) { w->setOrientation(q);}
void lqcamera_setOrientation2(qglviewer::Camera* w, float theta, float phi) { w->setOrientation(theta,phi);}

void lqcamera_setFromModelViewMatrix(qglviewer::Camera* w, QList<double> &m) {
    GLdouble mvm[16];
    if(m.count()<16) return;
    for(int i=0;i<16;i++) mvm[i] = m[i];
    w->setFromModelViewMatrix(mvm);
}

void lqcamera_setFromProjectionMatrix(qglviewer::Camera* w, QList<double> &m) {
    float mvm[12];
    if(m.count()<12) return;
    for(int i=0;i<12;i++) mvm[i] = (float)m[i];
    w->setFromProjectionMatrix(mvm);
}

QList<int> lqcamera_getViewPort(qglviewer::Camera* w)
{
    GLint m[4];
    QList<int> r;
    w->getViewport(m);
    for(int i=0;i<4;i++) r.append(m[i]);
    return r;
}

double lqcamera_getOrthoWidthHeight(qglviewer::Camera* w, double& halfHeight)
{
    double halfWidth;
    w->getOrthoWidthHeight(halfWidth,halfHeight);
    return halfWidth;
}

QList< QList<double> > lqcamera_getFrustumPlanesCoefficients(qglviewer::Camera* w)
{
    QList< QList <double> > res;
    GLdouble coef[6][4];
    w->getFrustumPlanesCoefficients(coef);
    for(int i=0;i<6;i++){
        QList<double> s;
        for(int j=0;j<4;j++){
            s.append(coef[i][j]);
        }
        res.append(s);
    }
    return res;
}

ENUM_FILTER(Camera,type,setType)

LQCamera lqcamera()
{
    return
    myclass_<qglviewer::Camera,QObject>("QCamera")
    .def(constructor<>())
    .def(constructor<const qglviewer::Camera&>())

    .def("setPosition", &qglviewer::Camera::setPosition)
    .def("setUpVector", &qglviewer::Camera::setUpVector)
    .def("setViewDirection", &qglviewer::Camera::setViewDirection)
    .def("setOrientation", lqcamera_setOrientation1)
    .def("setOrientation", lqcamera_setOrientation2)
    .def("setFromModelViewMatrix", lqcamera_setFromModelViewMatrix)
    .def("setFromProjectionMatrix", lqcamera_setFromProjectionMatrix)

    .def("lookAt", &qglviewer::Camera::lookAt)
    .def("showEntireScene", &qglviewer::Camera::showEntireScene)
    .def("fitSphere", &qglviewer::Camera::fitSphere)
    .def("fitBoundingBox", &qglviewer::Camera::fitBoundingBox)
    .def("fitScreenRegion", &qglviewer::Camera::fitScreenRegion)
    .def("centerScene", &qglviewer::Camera::centerScene)
    .def("interpolateToZoomOnPixel", &qglviewer::Camera::interpolateToZoomOnPixel)
    .def("interpolateToFitScene", &qglviewer::Camera::interpolateToFitScene)
    .def("interpolateTo", &qglviewer::Camera::interpolateTo)
    .def("setType", &qglviewer::Camera::setType)
    .def("setAspectRatio", &qglviewer::Camera::setAspectRatio)
    .def("setFieldOfView", &qglviewer::Camera::setFieldOfView)
    .def("setScreenWidthAndHeight", &qglviewer::Camera::setScreenWidthAndHeight)
    .def("pixelGLRatio", &qglviewer::Camera::pixelGLRatio)
    .def("getViewPort", lqcamera_getViewPort)
    .def("setZNearCoefficient", &qglviewer::Camera::setZNearCoefficient)
    .def("setZClippingCoefficient", &qglviewer::Camera::setZClippingCoefficient)
    .def("setHorizontalFieldOfView", &qglviewer::Camera::setHorizontalFieldOfView)
    .def("setFOVToFitScene", &qglviewer::Camera::setFOVToFitScene)
    .def("getOrthoWidthHeight", lqcamera_getOrthoWidthHeight, pure_out_value(_2))
    .def("getFrustumPlanesCoefficients", lqcamera_getFrustumPlanesCoefficients)
    .def("setSceneRadius", &qglviewer::Camera::setSceneRadius)
    .def("setSceneCenter", &qglviewer::Camera::setSceneCenter)
    .def("setSceneCenterFromPixel", &qglviewer::Camera::setSceneCenterFromPixel)
    .def("setSceneBoundingBox", &qglviewer::Camera::setSceneBoundingBox)
    .def("setRevolveAroundPoint", &qglviewer::Camera::setRevolveAroundPoint)
    .def("setRevolveAroundPointFromPixel", &qglviewer::Camera::setRevolveAroundPointFromPixel)

    .def("setFlySpeed", &qglviewer::Camera::setFlySpeed)

    .class_<qglviewer::Camera,QObject>::property("position", &qglviewer::Camera::position, &qglviewer::Camera::setPosition)
    .property("upVector", &qglviewer::Camera::upVector, &qglviewer::Camera::setUpVector)
    .property("viewDirection", &qglviewer::Camera::viewDirection, &qglviewer::Camera::setViewDirection)
    .property("rightVector", &qglviewer::Camera::rightVector)
    .property("orientation", &qglviewer::Camera::orientation, lqcamera_setOrientation1)
    .property("type", Camera_type, Camera_setType)
    .property("fieldOfView", &qglviewer::Camera::fieldOfView, &qglviewer::Camera::setFieldOfView)
    .property("horizontalFieldOfView", &qglviewer::Camera::horizontalFieldOfView, &qglviewer::Camera::setHorizontalFieldOfView)
    .property("aspectRatio", &qglviewer::Camera::aspectRatio, &qglviewer::Camera::setAspectRatio)
    .property("screenWidth", &qglviewer::Camera::screenWidth)
    .property("screenHeight", &qglviewer::Camera::screenHeight)
    .property("viewPort", lqcamera_getViewPort)
    .property("zNearCoefficient", &qglviewer::Camera::zNearCoefficient, &qglviewer::Camera::setZNearCoefficient)
    .property("zClippingCoefficient", &qglviewer::Camera::zClippingCoefficient, &qglviewer::Camera::setZClippingCoefficient)
    .property("zNear", &qglviewer::Camera::zNear)
    .property("zFar", &qglviewer::Camera::zFar)
    .property("frustumPlanesCoefficients", lqcamera_getFrustumPlanesCoefficients)
    .property("sceneRadius", &qglviewer::Camera::sceneRadius, &qglviewer::Camera::setSceneRadius)
    .property("sceneCenter", &qglviewer::Camera::sceneCenter, &qglviewer::Camera::setSceneCenter)
    .property("distanceToSceneCenter", &qglviewer::Camera::distanceToSceneCenter)
    .property("revolveAroundPoint", &qglviewer::Camera::revolveAroundPoint, &qglviewer::Camera::setRevolveAroundPoint)

    .property("flySpeed", &qglviewer::Camera::flySpeed, &qglviewer::Camera::setFlySpeed)
    ;
}

void lqglviewer_setAxisIsDrawn(QGLViewer* w){ w->setAxisIsDrawn();}
void lqglviewer_setGridIsDrawn(QGLViewer* w){ w->setGridIsDrawn();}
void lqglviewer_setFPSIsDisplayed(QGLViewer* w){ w->setFPSIsDisplayed();}
void lqglviewer_setTextIsEnabled(QGLViewer* w){ w->setTextIsEnabled();}
void lqglviewer_setCameraIsEdited(QGLViewer* w){ w->setCameraIsEdited();}
void lqglviewer_setFullScreen(QGLViewer* w){ w->setFullScreen();}
void lqglviewer_setStereoDisplay(QGLViewer* w){ w->setStereoDisplay();}

SIGNAL_PROPERYT(lqglviewer, viewerInitialized, QGLViewer, "()")
SIGNAL_PROPERYT(lqglviewer, drawNeeded, QGLViewer, "()")
SIGNAL_PROPERYT(lqglviewer, drawFinished, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, animateNeeded, QGLViewer, "()")
SIGNAL_PROPERYT(lqglviewer, helpRequired, QGLViewer, "()")
SIGNAL_PROPERYT(lqglviewer, axisIsDrawnChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, gridIsDrawnChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, FPSIsDisplayedChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, textIsEnabledChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, cameraIsEditedChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, stereoChanged, QGLViewer, "(bool)")
SIGNAL_PROPERYT(lqglviewer, pointSelected, QGLViewer, "(const QMouseEvent *)")

void lqglviewer_drawText (QGLViewer* w, int x, int y, const QString &text){ w->drawText(x,y,text);}
void lqglviewer_displayMessage (QGLViewer* w, const QString &text){ w->displayMessage(text);}

void lqglviewer_drawArrow1(){ QGLViewer::drawArrow(); }
void lqglviewer_drawArrow2(float length){ QGLViewer::drawArrow(length); }
void lqglviewer_drawArrow3(float length, float radius){ QGLViewer::drawArrow(length,radius); }
void lqglviewer_drawArrow4(float length, float radius, int nbSub){ QGLViewer::drawArrow(length,radius, nbSub); }
void lqglviewer_drawArrow5(float length, float radius){ QGLViewer::drawArrow(length,radius); }
void lqglviewer_drawArrow6(const qglviewer::Vec &from, const qglviewer::Vec &to){ QGLViewer::drawArrow(from,to); }
void lqglviewer_drawArrow7(const qglviewer::Vec &from, const qglviewer::Vec &to, float radius){ QGLViewer::drawArrow(from,to,radius); }
void lqglviewer_drawArrow8(const qglviewer::Vec &from, const qglviewer::Vec &to, float radius, int nbSub){ QGLViewer::drawArrow(from,to,radius, nbSub); }

void lqglviewer_drawAxis1(){ QGLViewer::drawAxis(); }
void lqglviewer_drawAxis2(float len){ QGLViewer::drawAxis(len); }

void lqglviewer_drawGrid1(){ QGLViewer::drawGrid(); }
void lqglviewer_drawGrid2(float size){ QGLViewer::drawGrid(size); }
void lqglviewer_drawGrid3(float size, int nbSub){ QGLViewer::drawGrid(size,nbSub); }

void lqglviewer_saveSnapshot1(QGLViewer* w){ w->saveSnapshot(); }
void lqglviewer_saveSnapshot2(QGLViewer* w, bool automatic){ w->saveSnapshot(automatic); }
void lqglviewer_saveSnapshot3(QGLViewer* w, bool automatic, bool overwrite){ w->saveSnapshot(automatic, overwrite); }
void lqglviewer_saveSnapshot2(QGLViewer* w, const QString& name){ w->saveSnapshot(name); }
void lqglviewer_saveSnapshot3(QGLViewer* w, const QString& name, bool overwrite){ w->saveSnapshot(name, overwrite); }


LQGLViewer lqglviewer()
{
    return
    myclass_<QGLViewer,QGLWidget>("QGLViewer")
    .def(constructor<QWidget*>())
    .def(constructor<QWidget*,QGLWidget*>())
    .def(constructor<QWidget*,QGLWidget*,Qt::WindowFlags>())
    .def("setAxisIsDrawn", &QGLViewer::setAxisIsDrawn)
    .def("setAxisIsDrawn", lqglviewer_setAxisIsDrawn)
    .def("setGridIsDrawn", &QGLViewer::setGridIsDrawn)
    .def("setGridIsDrawn", lqglviewer_setGridIsDrawn)
    .def("setFPSIsDisplayed", &QGLViewer::setFPSIsDisplayed)
    .def("setFPSIsDisplayed", lqglviewer_setFPSIsDisplayed)
    .def("setTextIsEnabled", &QGLViewer::setTextIsEnabled)
    .def("setTextIsEnabled", lqglviewer_setTextIsEnabled)
    .def("setCameraIsEdited", &QGLViewer::setCameraIsEdited)
    .def("setCameraIsEdited", lqglviewer_setCameraIsEdited)
    .def("setFullScreen", &QGLViewer::setFullScreen)
    .def("setFullScreen", lqglviewer_setFullScreen)
    .def("setStereoDisplay", &QGLViewer::setStereoDisplay)
    .def("setStereoDisplay", lqglviewer_setStereoDisplay)
    .def("setBackgroundColor", &QGLViewer::setBackgroundColor)
    .def("setForegroundColor", &QGLViewer::setForegroundColor)


    .def("toggleAxisIsDrawn", &QGLViewer::toggleAxisIsDrawn)
    .def("toggleCameraIsEdited", &QGLViewer::toggleCameraIsEdited)
    .def("toggleFPSIsDisplayed", &QGLViewer::toggleFPSIsDisplayed)
    .def("toggleFullScreen", &QGLViewer::toggleFullScreen)
    .def("toggleGridIsDrawn", &QGLViewer::toggleGridIsDrawn)
    .def("toggleAnimation", &QGLViewer::toggleAnimation)
    .def("toggleCameraMode", &QGLViewer::toggleCameraMode)
    .def("toggleTextIsEnabled", &QGLViewer::toggleTextIsEnabled)
    .def("toggleStereoDisplay", &QGLViewer::toggleStereoDisplay)

    .def("startAnimation", &QGLViewer::startAnimation)
    .def("stopAnimation", &QGLViewer::stopAnimation)
    .def("animate", &QGLViewer::animate)
    .def("setAnimationPeriod", &QGLViewer::setAnimationPeriod)
    .property("animationPeriod", &QGLViewer::animationPeriod, &QGLViewer::setAnimationPeriod)
    .property("animationIsStarted", &QGLViewer::animationIsStarted)

    .property("axisIsDrawn", &QGLViewer::axisIsDrawn, &QGLViewer::setAxisIsDrawn)
    .property("gridIsDrawn", &QGLViewer::gridIsDrawn, &QGLViewer::setGridIsDrawn)
    .property("FPSIsDisplayed", &QGLViewer::FPSIsDisplayed, &QGLViewer::setFPSIsDisplayed)
    .property("textIsEnabled", &QGLViewer::textIsEnabled, &QGLViewer::setTextIsEnabled)
    .property("cameraIsEdited", &QGLViewer::cameraIsEdited, &QGLViewer::setCameraIsEdited)
    .property("fullScreen", &QGLViewer::isFullScreen, &QGLViewer::setFullScreen)
    .property("stereoDisplay", &QGLViewer::displaysInStereo, &QGLViewer::setStereoDisplay)
    .property("currentFPS", &QGLViewer::currentFPS)
    .property("aspectRatio", &QGLViewer::aspectRatio)
    .property("backgroundColor", &QGLViewer::backgroundColor, &QGLViewer::setBackgroundColor)
    .property("foregroundColor", &QGLViewer::foregroundColor, &QGLViewer::setForegroundColor)

    .sig_prop(lqglviewer, viewerInitialized)
    .sig_prop(lqglviewer, drawNeeded)
    .sig_prop(lqglviewer, drawFinished)
    .sig_prop(lqglviewer, animateNeeded)
    .sig_prop(lqglviewer, helpRequired)
    .sig_prop(lqglviewer, axisIsDrawnChanged)
    .sig_prop(lqglviewer, gridIsDrawnChanged)
    .sig_prop(lqglviewer, FPSIsDisplayedChanged)
    .sig_prop(lqglviewer, textIsEnabledChanged)
    .sig_prop(lqglviewer, cameraIsEditedChanged)
    .sig_prop(lqglviewer, stereoChanged)
    .sig_prop(lqglviewer, pointSelected)

    .def("setSceneRadius", &QGLViewer::setSceneRadius)
    .def("setSceneCenter", &QGLViewer::setSceneCenter)
    .def("showEntireScene", &QGLViewer::showEntireScene)

    .def("drawText", &QGLViewer::drawText)
    .def("drawText", lqglviewer_drawText)
    .def("displayMessage", &QGLViewer::displayMessage)
    .def("displayMessage", lqglviewer_displayMessage)

    .property("snapshotFilename", &QGLViewer::snapshotFilename, &QGLViewer::setSnapshotFileName)
    .property("snapshotFormat", &QGLViewer::snapshotFormat, &QGLViewer::setSnapshotFormat)
    .property("snapshotQuality", &QGLViewer::snapshotQuality, &QGLViewer::setSnapshotQuality)
    .property("snapshotCounter", &QGLViewer::snapshotCounter, &QGLViewer::setSnapshotCounter)
    .def("openSnapshotFormatDialog", &QGLViewer::openSnapshotFormatDialog)
    .def("snapshotToClipboard", &QGLViewer::snapshotToClipboard)
    .def("setSnapshotFileName", &QGLViewer::setSnapshotFileName)
    .def("setSnapshotFormat", &QGLViewer::setSnapshotFormat)
    .def("setSnapshotQuality", &QGLViewer::setSnapshotQuality)
    .def("setSnapshotCounter", &QGLViewer::setSnapshotCounter)


    .property("stateFileName", &QGLViewer::stateFileName, &QGLViewer::setStateFileName)
    .def("setStateFileName", &QGLViewer::setStateFileName)
    .def("saveStateToFile", &QGLViewer::saveStateToFile)
    .def("restoreStateFromFile", &QGLViewer::restoreStateFromFile)

    .class_<QGLViewer,QGLWidget>::property("sceneRadius", &QGLViewer::sceneRadius, &QGLViewer::setSceneRadius)
    .property("sceneCenter", &QGLViewer::sceneCenter, &QGLViewer::setSceneCenter)
    .property("camera", &QGLViewer::camera, &QGLViewer::setCamera)

    .scope[
        def("drawArrow",lqglviewer_drawArrow1),
        def("drawArrow",lqglviewer_drawArrow2),
        def("drawArrow",lqglviewer_drawArrow3),
        def("drawArrow",lqglviewer_drawArrow4),
        def("drawArrow",lqglviewer_drawArrow5),
        def("drawArrow",lqglviewer_drawArrow6),
        def("drawArrow",lqglviewer_drawArrow7),
        def("drawArrow",lqglviewer_drawArrow8),
        def("drawAxis", lqglviewer_drawAxis1),
        def("drawAxis", lqglviewer_drawAxis2),
        def("drawGrid", lqglviewer_drawGrid1),
        def("drawGrid", lqglviewer_drawGrid2),
        def("drawGrid", lqglviewer_drawGrid3)

    ];
}
