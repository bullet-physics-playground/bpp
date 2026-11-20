-- the slate's steps, in words (made by make-slate.py)
return {
  ["left4"] = { "1. Left, passing the first number three times; stop on it the fourth", "the cam picks up all three wheels; wheel 1, at the back, is left there" },
  ["right3"] = { "2. Right, passing the second number twice; stop on it the third", "wheel 1 stays where it is; wheels 3 and 2 come round, and 2 is left there" },
  ["left2"] = { "3. Left, passing the third number once; stop on it the second", "wheels 1 and 2 stay; wheel 3 is left on the third number" },
  ["open"] = { "4. Right, until the dial stops", "the cam's notch comes round under the fence" },
  ["opened"] = { "The fence fell into the gates: the bolt is drawn back", "every gate was under it, and the cam's notch caught it and pulled" },
  ["locked"] = { "The dial turns on: the bolt stays out", "a wheel's rim holds the fence up, out of the cam's notch" },
  ["close"] = { "Left, two turns: the bolt thrown, the wheels scrambled", "the cam pushes the fence back, then lifts it out of the gates" },
  ["t-own"] = { "The lock's own combination", "watch each wheel's gate come round under the fence and stay" },
  ["t-wrong"] = { "The last number five off", "wheel 3's gate will stop five numbers from the fence" },
  ["t-near"] = { "Every number one off", "a gate one number from the fence still lets it fall" },
  ["warn-12"] = { "The second number is too close above the first", "wheel 2, setting it, will come round to wheel 1 and carry it off" },
  ["warn-23"] = { "The third number is too close below the second", "wheel 3, setting it, will come round to wheel 2 and carry it off" },
  ["warn-zone"] = { "The last number is in the forbidden zone (90 to 99)", "turning right, the cam will carry wheel 3 off before it can draw the bolt" },
}
