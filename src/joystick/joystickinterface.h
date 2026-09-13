#ifndef JOYSTICKINTERFACE_H
#define JOYSTICKINTERFACE_H

/**
 * @file joystickinterface.h
 * @brief Abstract interface to the joystick hardware.
 */

// Qt
#include <QObject>

// joystick
#include "joystickconstants.h"
#include "joystickinfo.h"

/**
 * @brief What a joystick backend has to provide.
 *
 * Keeps JoystickHandler independent of any particular library; the only
 * implementation in bpp is JoystickInterfaceSDL. An implementation enumerates
 * the attached devices, keeps one of them active and fills a JoystickInfo on
 * demand.
 *
 * The button mapping translates the raw indices the driver reports into
 * JoystickConstants::ControllerButton values, so the same controller layout
 * can be recognised across devices that number their buttons differently.
 */
class JoystickInterface : public QObject
{
   Q_OBJECT

   public:

       /**
        * @brief Constructs the interface with no button mapping.
        * @param parent Parent object, passed through to QObject.
        */
       JoystickInterface(QObject* parent = 0);

       /**
        * @brief Destroys the interface.
        */
       virtual ~JoystickInterface();

       /**
        * @brief Returns how many joysticks are attached.
        * @return The device count.
        */
       virtual int getJoystickCount() = 0;

       /**
        * @brief Selects the joystick that update() will read.
        * @param id Index of the device to make active.
        */
       virtual void setActiveJoystick(int id) = 0;

       /**
        * @brief Returns which joystick update() reads.
        * @return Index of the active device.
        */
       virtual int getActiveJoystick() = 0;

       /**
        * @brief Returns the current raw-index to named-button mapping.
        * @return The mapping array, or null if none has been set. It stays
        *         owned by the interface.
        */
       JoystickConstants::ControllerButton* getButtonMapping();

       /**
        * @brief Installs a new raw-index to named-button mapping.
        *
        * The interface takes ownership and deletes any previous mapping.
        *
        * @param mapping Array indexed by raw button number, allocated with
        *                @c new[].
        */
       void setButtonMapping(JoystickConstants::ControllerButton* mapping);


       // information about the current joystick

       /**
        * @brief Returns a joystick's human readable name.
        * @param id Index of the device.
        * @return Its name.
        */
       virtual QString getName(int id) = 0;

       /**
        * @brief Returns how many axes a joystick has.
        * @param id Index of the device.
        * @return The axis count.
        */
       virtual int getAxisCount(int id) = 0;

       /**
        * @brief Returns how many buttons a joystick has.
        * @param id Index of the device.
        * @return The button count.
        */
       virtual int getButtonCount(int id) = 0;

       /**
        * @brief Returns how many trackballs a joystick has.
        * @param id Index of the device.
        * @return The ball count.
        */
       virtual int getBallCount(int id) = 0;

       /**
        * @brief Returns how many hat switches a joystick has.
        * @param id Index of the device.
        * @return The hat count.
        */
       virtual int getHatCount(int id) = 0;

       /**
        * @brief Reads the active joystick into a snapshot.
        * @param[out] info Receives the current axis, button, ball and hat
        *                  values.
        */
       virtual void update(JoystickInfo& info) = 0;


   public slots:

       /**
        * @brief Makes the joystick rumble.
        *
        * Does nothing unless an implementation overrides it.
        *
        * @param intensity Strength from 0 to 1.
        * @param ms        Duration in milliseconds.
        */
       virtual void rumble(float intensity, int ms);


   protected:


       JoystickConstants::ControllerButton* mButtonMapping; ///< Raw index to
                                                            ///< named button;
                                                            ///< owned here.
};

#endif // JOYSTICKINTERFACE_H
