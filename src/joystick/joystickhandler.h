#ifndef JOYPICK_H
#define JOYPICK_H

/**
 * @file joystickhandler.h
 * @brief Polls a joystick and publishes its state as a Qt signal.
 */

#include <QWidget>
#include <QTimer>
#include <QList>

#include "joystickinfo.h"

class JoystickInterface;

/**
 * @brief Turns a polled joystick into a stream of Qt signals.
 *
 * The underlying APIs have to be asked for the current state rather than
 * reporting changes themselves, so this drives a timer and emits data() with a
 * fresh JoystickInfo on every tick. The Viewer connects that to the script's
 * @c onJoystick callback.
 *
 * The handler does not own the JoystickInterface it polls.
 */
class JoystickHandler : public QObject
{
   Q_OBJECT

   public:

      /**
       * @brief Constructs the handler and its update timer.
       *
       * The timer is created but not started; initialize() does that once an
       * interface has been set.
       *
       * @param parent Parent object, passed through to QObject.
       */
      JoystickHandler(QObject *parent = 0);

      /**
       * @brief Stops polling and destroys the handler.
       */
      ~JoystickHandler();

      /**
       * @brief Selects a joystick and starts polling it.
       *
       * Does nothing if the interface reports fewer devices than @p id needs,
       * so running without a joystick attached is harmless. An interface must
       * have been set first.
       *
       * @param id Index of the joystick to poll.
       */
      void initialize(int id = 0);

      /**
       * @brief Sets the interface used to talk to the hardware.
       * @param iface The interface. Not owned; it must outlive the handler.
       */
      void setInterface(JoystickInterface* iface);

      /**
       * @brief Sets how often the joystick is polled.
       * @param interval Poll interval in milliseconds.
       */
       void setUpdateInterval(int interval);

       /**
        * @brief Stops polling.
        *
        * Safe to call when polling was never started.
        */
       void stop();


    signals:

      /**
       * @brief Emitted once per poll with the joystick's current state.
       * @param info The state; it belongs to the handler and is reused on the
       *             next poll.
       */
      void data(const JoystickInfo& info);


   protected slots:

      /**
       * @brief Reads the joystick and emits data().
       */
      void updateData();


   protected:

      /**
       * @brief Prints the last reading through qDebug().
       *
       * Only called when @c JOYSTICK_DEBUGGING is defined.
       */
      void debug();

      JoystickInterface* mJoystickInterface; ///< Hardware interface; not owned.

      QTimer* mUpdateTimer; ///< Drives the polling.

      JoystickInfo mJoystickInfo; ///< The most recent reading, reused on each
                                  ///< poll.
};

#endif // JOYPICK_H
