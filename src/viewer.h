#ifndef VIEWER_H
#define VIEWER_H

#include <lua.hpp>

#include <QGLViewer/qglviewer.h>
#include <QGLViewer/manipulatedFrame.h>

#include <btBulletDynamicsCommon.h>

#include <QFile>
#include <QDir>
#include <QMutex>
#include <QKeyEvent>
#include <QMutexLocker>
#include <QSettings>
#include <QTextStream>

#include "objects/cam.h"

#include "objects/sphere.h"

#include "joystick/joystickhandler.h"
#include "joystick/joystickinterfacesdl.h"

using namespace qglviewer;

class Object;
class Viewer;

std::ostream& operator<<(std::ostream&, const Viewer& v);

class Viewer : public QGLViewer
{
    Q_OBJECT;

public:
    Viewer(QWidget *parent = NULL, QSettings *settings = NULL, bool savePOV = false);
    ~Viewer();

    void setSavePOV(bool pov);
    void toggleSavePOV(bool savePOV);
    void toggleDeactivation(bool deactivation);

    // http://bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
    void setTimeStep(btScalar ts);
    btScalar getTimeStep();

    void setMaxSubSteps(int steps);
    int getMaxSubSteps();

    void setFixedTimeStep(btScalar fts);
    btScalar getFixedTimeStep();

    void startSim();
    void stopSim();
    void restartSim();

    void resetCamView();

    void addObject(Object* o);
    void removeObject(Object* o);
    void setCamera(Cam* cam);
    Cam* getCamera();

    static void luaBind(lua_State *s);
    //static void luabind_error(lua_State *s);
    void luaBindInstance(lua_State *s);
    virtual QString toString() const;
    void setScriptName(QString sn);

    void emitScriptOutput(const QString&);
    void emitClearOutput();
    static int lua_print(lua_State*);

    void addConstraints(QList<btTypedConstraint *> cons);
    void addConstraint(btTypedConstraint *con);
    void addVehicle(btRaycastVehicle *veh);
    void removeConstraint(btTypedConstraint *con);

    void addShortcut(const QString&, const luabind::object &fn);
    void removeShortcut(const QString&);

    btVehicleRaycaster* createVehicleRaycaster();

    // OpenGL properties
    void setGLShininess(const btScalar&);
    btScalar getGLShininess() const;

    void setGLSpecularColor(const btVector4&);
    btVector4 getGLSpecularColor() const;

    void setGLSpecularCol(const btScalar);
    btScalar getGLSpecularCol() const;

    void setGLLight0(const btVector4&);
    btVector4 getGLLight0() const;

    void setGLLight1(const btVector4&);
    btVector4 getGLLight1() const;

    void setGLAmbient(const btVector3&);
    btVector3 getGLAmbient() const;

    void setGLDiffuse(const btVector4&);
    btVector4 getGLDiffuse() const;

    void setGLSpecular(const btVector4&);
    btVector4 getGLSpecular() const;

    void setGLModelAmbient(const btVector4&);
    btVector4 getGLModelAmbient() const;

    void setGLModelAmbientPercent(const btScalar);
    btScalar getGLModelAmbientPercent() const;

    void setGLAmbientPercent(const btScalar);
    btScalar getGLAmbientPercent() const;

    void setGLDiffusePercent(const btScalar);
    btScalar getGLDiffusePercent() const;

    void setGLSpecularPercent(const btScalar);
    btScalar getGLSpecularPercent() const;

#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
    void setBackgroundColor(const QColor& color) { glClearColor(color.redF(), color.greenF(), color.blueF(), color.alphaF()); }
#else
    void setBackgroundColor(const QColor& color) { qglClearColor(color); }
#endif

    // POV-Ray properties
    void setPreSDL(const QString&);
    QString getPreSDL() const;

    void setPostSDL(const QString&);
    QString getPostSDL() const;

    QString toPOV() const;

    void setPOVSettingsInc(QString pov_settings_inc);
    QString getPOVSettingsInc();

    void setSettings(QSettings *settings);

    void setPrefs(QString key, QString value);
    QString getPrefs(QString key, QString defaultValue) const;

    virtual void startAnimation();
    virtual void stopAnimation();
    virtual void animate();
    virtual void draw();
    virtual void postDraw();

public slots:
    void close();

    bool parse(QString txt);
    void clear();

    void setCBPreStart(const luabind::object &fn);
    void setCBPreDraw(const luabind::object &fn);
    void setCBPostDraw(const luabind::object &fn);
    void setCBPreSim(const luabind::object &fn);
    void setCBPostSim(const luabind::object &fn);
    void setCBPreStop(const luabind::object &fn);
    void setCBOnCommand(const luabind::object &fn);
    void setCBOnJoystick(const luabind::object &fn);

    void keyPressEvent(QKeyEvent *e);

    void command(QString cmd);

    void showLuaException(const std::exception& e, const QString& context = "");

    void onQuickRender();
    void onQuickRender(QString povargs);

    void onJoystickData(const JoystickInfo &ji);

    void updateGLViewer() {
#if QGLVIEWER_VERSION < 0x020700
      this->updateGL();
#else
      this->update();
#endif
  };

signals:
    void statusEvent(const QString&);

    void scriptFinished();
    void scriptStarts();
    void scriptStopped();
    void scriptHasOutput(const QString&);

    void postDrawShot(int);
    void simulationStateChanged(bool);
    void POVStateChanged(bool);
    void PNGStateChanged(bool);
    void deactivationStateChanged(bool);

    void clearDebugText();

protected:
    virtual void init();

    void setGravity(btVector3 gravity);
    btVector3 getGravity();

    virtual void addObjects();

    void addObject(Object *o, int type, int mask);

    void addObjects(QList<Object *> ol, int type, int mask);

    void drawSceneInternal(int pass);

    void computeBoundingBox();

    void openPovFile();
    void closePovFile();
    void savePOV(bool force = false);

    void loadPrefs();
    void savePrefs();

public:

    //  QList<Object*> l[13];

private:
    lua_State *L;
    QString lua_error;

    Cam *_cam;
    Vec _initialCameraPosition;
    Quaternion _initialCameraOrientation;
    btScalar _initialCameraHorizontalFieldOfView;

    bool _simulate;

    Sphere *mioSphere;

    //  ManipulatedFrame** keyFrame_;
    //  KeyFrameInterpolator kfi_;
    //  int nbKeyFrames;
    //  int currentKF_;

    QSet<Object*> *_objects;
    QSet<btTypedConstraint*> *_constraints;
    QSet<btRaycastVehicle*> *_raycast_vehicles;

    btScalar           _aabb[6];

    btDefaultCollisionConfiguration *collisionCfg;
    btDiscreteDynamicsWorld *dynamicsWorld;

    QTime              _time;

    QTextStream      *_stream;

    int              _frameNum;
    int		   _firstFrame;

    QFile            *_file;
    QFile            *_fileMain;
    QFile            *_fileINI;

    bool               _savePOV;
    bool		_deactivation;
    QString	_scriptName;
    QString	_scriptContent;

    QMutex mutex;
    QMutex cammutex;

    // Lua callback functions
    luabind::object _cb_preStart;
    luabind::object _cb_preDraw,_cb_postDraw;
    luabind::object _cb_preSim,_cb_postSim;
    luabind::object _cb_preStop;
    luabind::object _cb_onCommand;
    luabind::object _cb_onJoystick;

    QHash<QString, luabind::object> *_cb_shortcuts;

    bool _parsing;
    bool _has_exception;

    // OpenGL properties
    btScalar  _gl_shininess;
    btVector4 _gl_specular_col;

    btVector4 _light0;
    btVector4 _light1;

    btVector3 _gl_ambient;
    btVector4 _gl_diffuse, _gl_specular;

    btVector4 _gl_model_ambient;

    // POV-Ray properties
    QString mPreSDL;
    QString mPostSDL;

    QString _pov_settings_inc;

    QSettings * _settings;

    // bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
    btScalar _timeStep;
    int      _maxSubSteps;
    btScalar _fixedTimeStep;

    // joystick handler
    JoystickInterfaceSDL* _joystickInterface;
    JoystickHandler _joystickHandler;

};

#endif // VIEWER_H
