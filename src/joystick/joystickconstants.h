#ifndef JOYSTICKCONSTANTS_H
#define JOYSTICKCONSTANTS_H

/**
 * @file joystickconstants.h
 * @brief Enumerations shared by the joystick classes.
 */

/**
 * @brief Namespace-style holder for the joystick enumerations.
 *
 * Has no members of its own; it exists only to scope the enumerations.
 */
class JoystickConstants
{
   public:

      /**
       * @brief The direction a hat switch is pushed in.
       */
      enum Hat
      {
         HatCentered  = 0, ///< At rest.
         HatUp        = 1, ///< Pushed up.
         HatRight     = 2, ///< Pushed right.
         HatDown      = 3, ///< Pushed down.
         HatLeft      = 4, ///< Pushed left.
         HatRightUp   = 5, ///< Pushed up and right.
         HatRightDown = 6, ///< Pushed down and right.
         HatLeftUp    = 7, ///< Pushed up and left.
         HatLeftDown  = 8  ///< Pushed down and left.
      };

      // a= 10
      // b= 11
      // x= 12
      // y= 13
      // left shoulder= 8
      // right shoulder= 9
      // start= 15
      // select= 5
      // left stick= 6
      // right stick= 7

      /**
       * @brief The buttons of a game controller, in the layout bpp expects.
       *
       * A JoystickInterface maps the raw button indices its driver reports
       * onto these, so the rest of the code can work in terms of named
       * buttons.
       */
      enum ControllerButton
      {
         ControllerButtonInvalid = -1,      ///< No button; an unmapped index.
         ControllerButtonDpadUp = 0,        ///< D-pad up.
         ControllerButtonDpadDown = 1,      ///< D-pad down.
         ControllerButtonDpadLeft = 2,      ///< D-pad left.
         ControllerButtonDpadRight = 3,     ///< D-pad right.
         ControllerButtonStart = 4,         ///< Start.
         ControllerButtonBack = 5,          ///< Back or Select.
         ControllerButtonLeftStick = 6,     ///< Left stick pressed in.
         ControllerButtonRightStick = 7,    ///< Right stick pressed in.
         ControllerButtonLeftShoulder = 8,  ///< Left shoulder button.
         ControllerButtonRightShoulder = 9, ///< Right shoulder button.
         ControllerButtonA = 10,            ///< Face button A.
         ControllerButtonB = 11,            ///< Face button B.
         ControllerButtonX = 12,            ///< Face button X.
         ControllerButtonY = 13,            ///< Face button Y.
         ControllerButtonGuide = 14, // ?! home
         ControllerButtonMax                ///< One past the last button; the
                                            ///< size a mapping array needs.
      };
};


#endif // JOYSTICKCONSTANTS_H
