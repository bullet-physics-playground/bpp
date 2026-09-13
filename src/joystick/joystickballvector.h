#ifndef JOYSTICKBALLVALUE_H
#define JOYSTICKBALLVALUE_H

/**
 * @file joystickballvector.h
 * @brief Relative motion reported by a joystick trackball.
 */

/**
 * @brief The relative movement of one trackball since the last reading.
 *
 * A joystick trackball reports how far it has been rolled rather than where it
 * is, so both components are deltas and are zero when the ball is still.
 */
class JoystickBallVector
{
   public:

      /**
       * @brief Constructs a vector from an x and y movement.
       * @param x Horizontal movement; truncated to an integer.
       * @param y Vertical movement; truncated to an integer.
       */
      JoystickBallVector(float x, float y)
         : mX(x),
           mY(y)
      {
      }

      /**
       * @brief Constructs a zero vector, meaning the ball has not moved.
       */
      JoystickBallVector()
        : mX(0.0f),
          mY(0.0f)
      {
      }

      /**
       * @brief Gives direct access to the horizontal component.
       *
       * Returned as a pointer so it can be passed straight to a driver call
       * that writes the reading into it.
       *
       * @return Pointer to the stored x movement.
       */
      int* getXPtr()
      {
         return &mX;
      }

      /**
       * @brief Gives direct access to the vertical component.
       * @return Pointer to the stored y movement.
       */
      int* getYPtr()
      {
         return &mY;
      }

   protected:

      int mX; ///< Horizontal movement since the last reading.
      int mY; ///< Vertical movement since the last reading.
};

#endif // JOYSTICKBALLVALUE_H
