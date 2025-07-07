#include "joystickhandler.h"

#include "joystickinterface.h"

// #define JOYSTICK_DEBUGGING

JoystickHandler::JoystickHandler(QObject* parent)
   : QObject(parent),
     mJoystickInterface(nullptr),
     mUpdateTimer(nullptr)
{
   // init timer
   mUpdateTimer = new QTimer(this);
#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
   mUpdateTimer->setTimerType(Qt::PreciseTimer);
#endif

   connect(
      mUpdateTimer,
      SIGNAL(timeout()),
      this,
      SLOT(updateData())
   );
}

JoystickHandler::~JoystickHandler()
{
}

void JoystickHandler::initialize(int id)
{
   // init
   int joystickCount = mJoystickInterface->getJoystickCount();

   #ifdef JOYSTICK_DEBUGGING

      for (int i = 0; i < joystickCount; i++)
      {
         mJoystickInterface->setActiveJoystick(0);

         int axisCount = mJoystickInterface->getAxisCount(i);
         int buttonCount  = mJoystickInterface->getButtonCount(i);
         int hatCount = mJoystickInterface->getHatCount(i);

         qDebug(
            "id: %d, name: %s, axes: %d, buttons: %d, hats: %d",
            i,
            qPrintable(mJoystickInterface->getName(i)),
            axisCount,
            buttonCount,
            hatCount
         );
      }

   #endif

   // init timer
   if (joystickCount > id)
   {
      mJoystickInterface->setActiveJoystick(id);
      mUpdateTimer->start();
   }
}

void JoystickHandler::setInterface(JoystickInterface* interface)
{
   mJoystickInterface = interface;
}

void JoystickHandler::setUpdateInterval(int interval)
{
   mUpdateTimer->setInterval(interval);
}

void JoystickHandler::updateData()
{
   mJoystickInterface->update(mJoystickInfo);

   #ifdef JOYSTICK_DEBUGGING
      debug();
   #endif

   emit data(mJoystickInfo);
}

void JoystickHandler::debug()
{
   QString debug;

   debug.append("axes ");

   foreach (int value, mJoystickInfo.getAxisValues())
   {
      debug.append(QString("[%1]").arg(value));
   }

   debug.append(" buttons ");

   foreach (bool value, mJoystickInfo.getButtonValues())
   {
      debug.append(QString("[%1]").arg(value));
   }

   debug.append(" hats ");

   foreach (int value, mJoystickInfo.getHatValues())
   {
      debug.append(QString("[%1]").arg(value));
   }

   qDebug("%s", qPrintable(debug));
}
