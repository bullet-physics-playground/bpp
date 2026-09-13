#ifndef JOYSTICKINFO_H
#define JOYSTICKINFO_H

/**
 * @file joystickinfo.h
 * @brief One snapshot of a joystick's axes, buttons, balls and hats.
 */

// Qt
#include <QList>

// joystick
#include "joystickballvector.h"
#include "joystickconstants.h"


/**
 * @brief The state of every control on a joystick at one instant.
 *
 * A JoystickInterface fills one of these on each poll and JoystickHandler
 * emits it; the Viewer passes it on to a script's @c onJoystick callback,
 * where it is the @c JoystickInfo class.
 *
 * The lists only hold as many entries as the device actually has, so the
 * numbered accessors are only safe for controls the device really provides.
 */
class JoystickInfo
{
   public:

      /**
       * @brief Constructs an empty snapshot, with no controls recorded.
       */
      JoystickInfo();

      /**
       * @brief Constructs a snapshot from ready-made control values.
       * @param axisValues   Axis positions.
       * @param buttonValues Button states.
       * @param ballValues   Trackball movements.
       * @param hatValues    Hat switch directions.
       */
      JoystickInfo(
         const QList<int>& axisValues,
         const QList<bool>& buttonValues,
         const QList<JoystickBallVector>& ballValues,
         const QList<JoystickConstants::Hat>& hatValues
      );

      /**
       * @brief Empties every control list, ready to be filled again.
       */
      void clear();

      /**
       * @brief Appends one axis position.
       * @param value The position, in the driver's own range.
       */
      void addAxisValue(int value);

      /**
       * @brief Appends one button state.
       * @param value True if the button is down.
       */
      void addButtonState(bool value);

      /**
       * @brief Appends one trackball movement.
       * @param value The movement since the previous poll.
       */
      void addBallValue(const JoystickBallVector& value);

      /**
       * @brief Appends one hat switch direction.
       * @param value The direction the hat is pushed in.
       */
      void addHatValue(JoystickConstants::Hat value);

      /**
       * @brief Returns every axis position.
       * @return The axis positions, in device order.
       */
      const QList<int>& getAxisValues() const;

      /**
       * @brief Returns every button state.
       * @return The button states, in device order.
       */
      const QList<bool>& getButtonValues() const;

      /**
       * @brief Returns every trackball movement.
       * @return The ball movements, in device order.
       */
      const QList<JoystickBallVector>& getBallValues() const;

      /**
       * @brief Returns every hat switch direction.
       * @return The hat directions, in device order.
       */
      const QList<JoystickConstants::Hat>& getHatValues() const;

      /**
       * @brief Returns the first axis.
       * @return Its position. The device must have at least one axis.
       */
      int getAxis0() const;

      /**
       * @brief Returns the second axis.
       * @return Its position. The device must have at least two axes.
       */
      int getAxis1() const;

      /**
       * @brief Returns the third axis.
       * @return Its position. The device must have at least three axes.
       */
      int getAxis2() const;

      /**
       * @brief Returns the fourth axis.
       * @return Its position. The device must have at least four axes.
       */
      int getAxis3() const;

      /**
       * @brief Returns whether the first button is down.
       * @return True while it is held.
       */
      bool getButton0() const;

      /**
       * @brief Returns whether the second button is down.
       * @return True while it is held.
       */
      bool getButton1() const;

      /**
       * @brief Returns whether the third button is down.
       * @return True while it is held.
       */
      bool getButton2() const;

      /**
       * @brief Returns whether the fourth button is down.
       * @return True while it is held.
       */
      bool getButton3() const;

      /**
       * @brief Reports the moment the first button is pressed.
       *
       * True only on the poll where the button went from up to down, so a held
       * button fires once rather than on every frame.
       *
       * @note The previous state lives in a function-local static, so it is
       *       shared by every JoystickInfo rather than kept per instance, and
       *       each of these accessors must be called exactly once per poll for
       *       the edge to be detected correctly.
       * @return True on the press, false otherwise.
       */
      bool getTriggeredButton0() const;

      /**
       * @brief Reports the moment the second button is pressed.
       *
       * Same edge detection and the same shared-state caveat as
       * getTriggeredButton0().
       *
       * @return True on the press, false otherwise.
       */
      bool getTriggeredButton1() const;

      /**
       * @brief Reports the moment the third button is pressed.
       *
       * Same edge detection and the same shared-state caveat as
       * getTriggeredButton0().
       *
       * @return True on the press, false otherwise.
       */
      bool getTriggeredButton2() const;

      /**
       * @brief Reports the moment the fourth button is pressed.
       *
       * Same edge detection and the same shared-state caveat as
       * getTriggeredButton0().
       *
       * @return True on the press, false otherwise.
       */
      bool getTriggeredButton3() const;

   protected:

      QList<int> mAxisValues; ///< Axis positions, in device order.

      QList<bool> mButtonValues; ///< Button states, in device order.

      QList<JoystickBallVector> mBallValues; ///< Ball movements, in device
                                             ///< order.

      QList<JoystickConstants::Hat> mHatValues; ///< Hat directions, in device
                                                ///< order.
};

#endif // JOYSTICKINFO_H
