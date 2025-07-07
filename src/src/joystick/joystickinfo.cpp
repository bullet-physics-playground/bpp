#include "joystickinfo.h"

JoystickInfo::JoystickInfo()
{
}

JoystickInfo::JoystickInfo(
   const QList<int>& axisValues,
   const QList<bool>& buttonValues,
   const QList<JoystickBallVector>& ballValues,
   const QList<JoystickConstants::Hat>& hatValues
)
   : mAxisValues(axisValues),
     mButtonValues(buttonValues),
     mBallValues(ballValues),
     mHatValues(hatValues)
{
}

void JoystickInfo::clear()
{
   mAxisValues.clear();
   mButtonValues.clear();
   mBallValues.clear();
   mHatValues.clear();
}

void JoystickInfo::addAxisValue(int val)
{
   mAxisValues.append(val);
}

void JoystickInfo::addButtonState(bool val)
{
   mButtonValues.append(val);
}

void JoystickInfo::addBallValue(const JoystickBallVector& val)
{
   mBallValues.append(val);
}

void JoystickInfo::addHatValue(JoystickConstants::Hat val)
{
   mHatValues.append(val);
}

const QList<int>& JoystickInfo::getAxisValues() const
{
   return mAxisValues;
}

int JoystickInfo::getAxis0() const {
   return mAxisValues.at(0);
}
int JoystickInfo::getAxis1() const {
   return mAxisValues.at(1);
}
int JoystickInfo::getAxis2() const {
   return mAxisValues.at(2);
}
int JoystickInfo::getAxis3() const {
   return mAxisValues.at(3);
}

const QList<bool>& JoystickInfo::getButtonValues() const
{
   return mButtonValues;
}

bool JoystickInfo::getButton0() const {
   return mButtonValues.at(0);
}
bool JoystickInfo::getButton1() const {
   return mButtonValues.at(1);
}
bool JoystickInfo::getButton2() const {
   return mButtonValues.at(2);
}
bool JoystickInfo::getButton3() const {
   return mButtonValues.at(3);
}

bool JoystickInfo::getTriggeredButton0() const {
   static bool oldVal = false;

   if (mButtonValues.at(0) == true && oldVal == false) {
       oldVal = true;
       return true;
   } else if (mButtonValues.at(0) == false && oldVal == true) {
       oldVal = false;
       return false;
   } else {
       return false;
   }
}
bool JoystickInfo::getTriggeredButton1() const {
    static bool oldVal = false;

    if (mButtonValues.at(1) == true && oldVal == false) {
        oldVal = true;
        return true;
    } else if (mButtonValues.at(1) == false && oldVal == true) {
        oldVal = false;
        return false;
    } else {
        return false;
    }
}
bool JoystickInfo::getTriggeredButton2() const {
    static bool oldVal = false;

    if (mButtonValues.at(2) == true && oldVal == false) {
        oldVal = true;
        return true;
    } else if (mButtonValues.at(2) == false && oldVal == true) {
        oldVal = false;
        return false;
    } else {
        return false;
    }
}
bool JoystickInfo::getTriggeredButton3() const {
    static bool oldVal = false;

    if (mButtonValues.at(3) == true && oldVal == false) {
        oldVal = true;
        return true;
    } else if (mButtonValues.at(3) == false && oldVal == true) {
        oldVal = false;
        return false;
    } else {
        return false;
    }
}

const QList<JoystickBallVector>& JoystickInfo::getBallValues() const
{
   return mBallValues;
}

const QList<JoystickConstants::Hat>& JoystickInfo::getHatValues() const
{
   return mHatValues;
}
