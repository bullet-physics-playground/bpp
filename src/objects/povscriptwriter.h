#ifndef POVSCRIPTWRITER_H
#define POVSCRIPTWRITER_H

/**
 * @file povscriptwriter.h
 * @brief Moray-style POV-Ray scene exporter.
 *
 * Provides sophisticated POV-Ray export with:
 * - Global scene settings (camera, lights, globals)
 * - Shared mesh/include file management
 * - Animation frame export
 * - Photon mapping, radiosity, media support
 * - Texture library integration
 */

#include <QString>
#include <QTextStream>
#include <QFile>
#include <QDir>
#include <QHash>
#include <QVector>
#include <QDateTime>

#include "object.h"

class Object;

/**
 * @brief Global POV-Ray scene settings.
 */
struct PovSceneSettings {
  // Camera
  QString cameraType = "perspective";  // perspective, orthographic, fisheye, etc.
  btVector3 cameraLocation = btVector3(0, 0, -10);
  btVector3 cameraLookAt = btVector3(0, 0, 0);
  btVector3 cameraSky = btVector3(0, 1, 0);
  float cameraAngle = 45.0f;
  float cameraDistance = 10.0f;

  // Image output
  int width = 800;
  int height = 600;
  int antialias = 0;
  float antialiasThreshold = 0.3f;
  QString outputFile = "scene.png";
  QString outputFormat = "png";  // png, tga, bmp, etc.

  // Quality settings
  int maxTraceLevel = 5;
  int maxIntersections = 64;

  // Global settings
  bool photonsEnabled = false;
  bool radiosityEnabled = false;
  bool mediaEnabled = false;
  QString assumedGamma = "1.0";
  QString version = "3.8";
  QString charset = "utf8";
  bool hfGray16 = false;

  // Fog
  bool fogEnabled = false;
  int fogType = 1;        // 0=none, 1=constant, 2=ground fog
  double fogDistance = 100.0;
  QString fogColor = "rgb <0.5, 0.5, 0.5>";
  double fogFilter = 0.0;
  double fogTrans = 0.0;
  QString fogTurbulence;  // e.g. "<0.2, 0.2, 0.2>"
  double fogOmega = 0.0;
  double fogLambda = 0.0;
  int fogOctaves = 0;
  double fogTurbDepth = 0.0;
  bool fogGround = false;
  double fogOffset = 0.0;
  double fogAltitude = 0.0;

  // Atmosphere
  bool atmosphereEnabled = false;
  bool atmosphereMedia = false;
  QString atmosphereMediaName;

  // Radiosity (detailed)
  int radCount = 350;
  double radErrorBound = 0.5;
  double radGrayThreshold = 0.0;
  double radLowErrorFactor = 0.2;
  double radMinimumReuse = 0.0;
  int radNearestCount = 10;
  int radRecursionLimit = 2;
  double radADCBailout = 0.001;
  double radMaximumSample = 45.0;
  bool radMedia = false;
  bool radNormal = false;
  bool radAlwaysSample = false;
  double radPreTraceStart = 0.08;
  double radPreTraceEnd = 0.01;

  // Photons (detailed)
  double photonSpacing = 0.5;
  int photonCount = 2000;
  int photonGatherMin = 10;
  int photonGatherMax = 20;
  bool photonMedia = false;
  int photonMediaMaxSteps = 100;
  double photonMediaFactor = 0.5;
  double photonJitter = 0.0;
  int photonMaxTraceLevel = 5;
  double photonAutoStop = 0.0;
  bool photonUseSpacing = false;
  double photonRadius = 0.0;
  double photonRadiusFactor = 0.0;
  bool photonUseRadiusOverride = false;
  bool photonUseRadiusFactor = false;
  double photonExpandThresholds = 0.001;
  int photonExpandMin = 10;

  // Background
  QString backgroundColor = "rgb <0.5, 0.5, 0.7>";

  // Animation
  bool isAnimation = false;
  int initialFrame = 1;
  int finalFrame = 1;
  int initialClock = 0;
  int finalClock = 1;

  // Include paths
  QStringList includePaths;

  // Custom globals
  QStringList globalSettings;
};

/**
 * @brief Light source description for export.
 */
struct PovLight {
  enum Type { Point, Spot, Directional, Area } type = Point;
  btVector3 position = btVector3(0, 10, 0);
  btVector3 direction = btVector3(0, -1, 0);
  QString color = "rgb <1, 1, 1>";
  float intensity = 1.0f;
  float radius = 0.0f;  // for area lights
  float falloff = 0.0f;
  float tightness = 0.0f;
  bool shadows = true;
  QStringList media;  // media interactions
};

/**
 * @brief Moray-style POV-Ray script writer.
 *
 * Handles exporting a complete POV-Ray scene with proper
 * include file management, shared mesh caching, and global settings.
 */
class PovScriptWriter {
public:
  /**
   * @brief Constructs a writer with default settings.
   */
  PovScriptWriter();

  /**
   * @brief Sets the scene settings.
   */
  void setSceneSettings(const PovSceneSettings &settings) { m_settings = settings; }

  /**
   * @brief Gets the scene settings.
   */
  PovSceneSettings &sceneSettings() { return m_settings; }
  const PovSceneSettings &sceneSettings() const { return m_settings; }

  /**
   * @brief Adds a light to the scene.
   */
  void addLight(const PovLight &light) { m_lights.append(light); }

  /**
   * @brief Clears all lights.
   */
  void clearLights() { m_lights.clear(); }

  /**
   * @brief Adds an object to the scene.
   * @param obj The object to add.
   * @param sceneDir Directory for shared mesh files.
   */
  void addObject(Object *obj, const QString &sceneDir);

  /**
   * @brief Writes the complete POV-Ray scene to a file.
   * @param sceneDir Directory for scene files.
   * @param frame Frame number (for animation).
   * @return True on success.
   */
  bool writeScene(const QString &sceneDir, int frame = 1);

  /**
   * @brief Writes the main scene file.
   */
  bool writeMainFile(const QString &sceneDir, int frame);

  /**
   * @brief Writes shared mesh include files.
   */
  void writeMeshIncludes(const QString &sceneDir);

  /**
   * @brief Generates a unique mesh hash for an object.
   */
  QString generateMeshHash(Object *obj) const;

  /**
   * @brief Registers a shared mesh to avoid duplication.
   */
  void registerSharedMesh(Object *obj, const QString &hash);

  /**
   * @brief Checks if a mesh is already shared.
   */
  bool isSharedMesh(const QString &hash) const;

  /**
   * @brief Gets the shared mesh filename for a hash.
   */
  QString getSharedMeshFile(const QString &hash) const;

private:
  PovSceneSettings m_settings;
  QVector<PovLight> m_lights;
  QVector<Object *> m_objects;
  QHash<QString, QString> m_sharedMeshes;  // hash -> filename
  QHash<Object *, QString> m_objectHashes; // object -> hash

  void writeHeader(QTextStream &s, int frame);
  void writeCamera(QTextStream &s);
  void writeLights(QTextStream &s);
  void writeObjects(QTextStream &s, const QString &sceneDir, int frame);
  void writeGlobalSettings(QTextStream &s);
  void writeBackground(QTextStream &s);
  QString sanitizeFilename(const QString &name) const;
};

/**
 * @brief Convenience function to export a scene.
 * @param objects List of objects to export.
 * @param sceneDir Output directory.
 * @param settings Scene settings.
 * @param frame Frame number.
 */
bool exportPovScene(const QVector<Object *> &objects,
                    const QString &sceneDir,
                    const PovSceneSettings &settings = PovSceneSettings(),
                    int frame = 1);

/**
 * @brief Registers the PovScriptWriter classes with a Lua state.
 * @param s The Lua state to register in.
 */
void PovScriptWriter_luaBind(lua_State *s);

#endif // POVSCRIPTWRITER_H