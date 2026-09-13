#ifndef QJOYSTICK_H
#define QJOYSTICK_H

/**
 * @file joystickinterfacesdl.h
 * @brief SDL-backed implementation of the joystick interface.
 */

// Qt
#include <QObject>
#include <QString>
#include <QList>

// base
#include "joystickinterface.h"

// SDL
#ifdef SDL1
   #include "../sdl/SDL.h"
#else
#ifdef Q_OS_MAC
#ifdef MAC_OS_X_VERSION_MIN_REQUIRED
#undef MAC_OS_X_VERSION_MIN_REQUIRED
#endif
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_9
#endif

#ifdef Q_OS_MAC
   #include <SDL2/SDL.h>
#else
   #include <SDL.h>
#endif
#endif

/**
 * @brief Talks to joysticks through SDL.
 *
 * Built against either SDL 1 or SDL 2, selected by the @c SDL1 macro. With
 * SDL 2 a device SDL recognises as a game controller is opened through the
 * controller API as well, which is what makes a consistent button mapping and
 * rumble possible; anything else falls back to the plain joystick API and is
 * reported exactly as the driver numbers it.
 *
 * D-pad directions that SDL exposes as ordinary buttons are recognised and
 * reported as always released, so they do not act as face buttons while still
 * keeping every other button at the index the device gave it.
 */
class JoystickInterfaceSDL : public JoystickInterface
{
   Q_OBJECT

   public:

      /**
       * @brief Initialises SDL's joystick and haptic subsystems.
       * @param parent Parent object, passed through to JoystickInterface.
       */
      JoystickInterfaceSDL(QObject* parent = 0);

      /**
       * @brief Closes the active device and shuts the SDL subsystems down.
       */
      virtual ~JoystickInterfaceSDL();

      // joystick management

      /**
       * @brief Returns how many joysticks SDL can see.
       * @return The device count.
       */
      virtual int getJoystickCount();

      /**
       * @brief Opens a joystick and makes it the one update() reads.
       *
       * Any previously open device is closed first, so switching does not leak
       * its SDL handle. A device SDL recognises as a game controller also gets
       * its button mapping and D-pad bindings set up.
       *
       * @param id Index of the device; out-of-range values are ignored.
       */
      virtual void setActiveJoystick(int id);

      /**
       * @brief Returns SDL's identifier for the active joystick.
       * @return The instance id under SDL 2, or the device index under SDL 1.
       */
      virtual int getActiveJoystick();


      // information about the current joystick

      /**
       * @brief Returns a joystick's human readable name.
       * @param id Index of the device.
       * @return Its name, or an empty string if @p id is out of range.
       */
      virtual QString getName(int id);

      /**
       * @brief Returns how many axes a joystick has.
       * @param id Index of the device.
       * @return The axis count.
       */
      virtual int getAxisCount(int id);

      /**
       * @brief Returns how many buttons a joystick has.
       * @param id Index of the device.
       * @return The button count.
       */
      virtual int getButtonCount(int id);

      /**
       * @brief Returns how many trackballs a joystick has.
       * @param id Index of the device.
       * @return The ball count.
       */
      virtual int getBallCount(int id);

      /**
       * @brief Returns how many hat switches a joystick has.
       * @param id Index of the device.
       * @return The hat count.
       */
      virtual int getHatCount(int id);

      /**
       * @brief Reads the active joystick into a snapshot.
       *
       * Clears @p info, polls SDL and appends the current value of every axis,
       * button, ball and hat. Buttons that are really D-pad directions are
       * reported as released, keeping the remaining button indices unchanged.
       *
       * @param[out] info Receives the reading.
       */
      virtual void update(JoystickInfo& info);


#ifndef SDL1

   public slots:

      /**
       * @brief Rumbles at full strength for two seconds, to test the effect.
       */
      virtual void rumbleTest();

      /**
       * @brief Starts a rumble effect on the active joystick.
       *
       * Does nothing if an effect is already running or the device has no
       * haptic support. The effect is closed again when it expires.
       *
       * @param intensity Strength from 0 to 1.
       * @param ms        Duration in milliseconds.
       */
      virtual void rumble(float intensity, int ms);


   protected slots:

      /**
       * @brief Closes the haptic device once a rumble effect has finished.
       */
      void cleanupRumble();


   protected:

      /**
       * @brief Records how the controller reports its D-pad directions.
       *
       * The bindings are what isDpadButton() later tests against.
       */
      void bindDpadButtons();

      /**
       * @brief Tells whether a raw button index is really a D-pad direction.
       * @param button Raw button index.
       * @return True if the controller maps that index to a D-pad direction.
       */
      bool isDpadButton(int button) const;

      /**
       * @brief Builds the raw-index to named-button mapping for the controller.
       *
       * Allocates one entry per button and hands it to
       * JoystickInterface::setButtonMapping(), which takes ownership and frees
       * any previous mapping itself.
       */
      void initializeButtonMappings();

      /**
       * @brief Converts an SDL controller button to bpp's own enumeration.
       * @param button The SDL button.
       * @return The matching JoystickConstants::ControllerButton, or
       *         @c ControllerButtonInvalid if there is none.
       */
      JoystickConstants::ControllerButton getControllerButton(
         SDL_GameControllerButton button
      ) const;

      /**
       * @brief Finds which SDL controller button a raw index corresponds to.
       *
       * Searches the controller's bindings for the one reporting @p buttonId.
       *
       * @param buttonId Raw button index.
       * @return The SDL button, or @c SDL_CONTROLLER_BUTTON_INVALID if the
       *         index is not bound.
       */
      SDL_GameControllerButton getButtonType(int buttonId) const;

#endif

   private:


      SDL_Joystick* mActiveJoystick; ///< The open joystick, or null.

      #ifndef SDL1

      SDL_GameController* mController; ///< The open game controller, or null
                                       ///< when the device is not one; it owns
                                       ///< #mActiveJoystick when set.
      SDL_GameControllerButtonBind mDpadUpBind;    ///< How the controller
                                                   ///< reports D-pad up.
      SDL_GameControllerButtonBind mDpadDownBind;  ///< D-pad down binding.
      SDL_GameControllerButtonBind mDpadLeftBind;  ///< D-pad left binding.
      SDL_GameControllerButtonBind mDpadRightBind; ///< D-pad right binding.

      SDL_Haptic* mHaptic; ///< Open haptic device while a rumble effect runs.

      #endif
};

#endif // QJOYSTICK_H
