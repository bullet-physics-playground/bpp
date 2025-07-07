#include "joystickinterface.h"

JoystickInterface::JoystickInterface(QObject* parent)
   : QObject(parent),
     mButtonMapping(0)
{
}

JoystickInterface::~JoystickInterface()
{
}

JoystickConstants::ControllerButton* JoystickInterface::getButtonMapping()
{
   return mButtonMapping;
}

void JoystickInterface::setButtonMapping(
   JoystickConstants::ControllerButton *mapping
)
{
   mButtonMapping = mapping;
}

void JoystickInterface::rumble(float intensity, int ms)
{
   Q_UNUSED(intensity);
   Q_UNUSED(ms);
}
