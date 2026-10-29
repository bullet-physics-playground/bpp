/**
 * @file povscriptwriter_lua.cpp
 * @brief Lua bindings for PovScriptWriter.
 */

#include "povscriptwriter.h"

#include <luabind/luabind.hpp>
#include <luabind/adopt_policy.hpp>

using namespace luabind;

void PovScriptWriter_luaBind(lua_State *s) {
  module(s)[
    class_<PovSceneSettings>("PovSceneSettings")
      .def(constructor<>())
      .def_readwrite("cameraType", &PovSceneSettings::cameraType)
      .def_readwrite("cameraLocation", &PovSceneSettings::cameraLocation)
      .def_readwrite("cameraLookAt", &PovSceneSettings::cameraLookAt)
      .def_readwrite("cameraSky", &PovSceneSettings::cameraSky)
      .def_readwrite("cameraAngle", &PovSceneSettings::cameraAngle)
      .def_readwrite("width", &PovSceneSettings::width)
      .def_readwrite("height", &PovSceneSettings::height)
      .def_readwrite("antialias", &PovSceneSettings::antialias)
      .def_readwrite("outputFile", &PovSceneSettings::outputFile)
      .def_readwrite("photonsEnabled", &PovSceneSettings::photonsEnabled)
      .def_readwrite("radiosityEnabled", &PovSceneSettings::radiosityEnabled)
      .def_readwrite("assumedGamma", &PovSceneSettings::assumedGamma)
      .def_readwrite("backgroundColor", &PovSceneSettings::backgroundColor)
      .def_readwrite("isAnimation", &PovSceneSettings::isAnimation)
      .def_readwrite("initialFrame", &PovSceneSettings::initialFrame)
      .def_readwrite("finalFrame", &PovSceneSettings::finalFrame),

    class_<PovLight>("PovLight")
      .def(constructor<>())
      .def_readwrite("type", &PovLight::type)
      .def_readwrite("position", &PovLight::position)
      .def_readwrite("direction", &PovLight::direction)
      .def_readwrite("color", &PovLight::color)
      .def_readwrite("intensity", &PovLight::intensity)
      .def_readwrite("radius", &PovLight::radius)
      .def_readwrite("falloff", &PovLight::falloff)
      .def_readwrite("tightness", &PovLight::tightness)
      .def_readwrite("shadows", &PovLight::shadows),

class_<PovScriptWriter>("PovScriptWriter")
      .def(constructor<>())
      .def("setSceneSettings", &PovScriptWriter::setSceneSettings)
      .def("sceneSettings", static_cast<PovSceneSettings & (PovScriptWriter::*)()>(&PovScriptWriter::sceneSettings))
      .def("addLight", &PovScriptWriter::addLight)
      .def("clearLights", &PovScriptWriter::clearLights)
      .def("addObject", &PovScriptWriter::addObject)
      .def("writeScene", &PovScriptWriter::writeScene)
  ];
}