# Digest: Maxim (2008), *An Implementation of a Novel Localization Framework for Robots and its Application to Multi-Robot Tasks*

Page numbers below are PDF pages. The printed page number is the PDF page minus 18.

## 1. Bibliographic
- **Title:** An Implementation of a Novel Localization Framework for Robots and its Application to Multi-Robot Tasks
- **Author:** Paul Mihai Maxim
- **Degree:** Ph.D., Computer Science
- **University:** University of Wyoming, Laramie
- **Year:** December 2008 (defended November 21, 2008)
- **Advisor/Chair:** William M. Spears
- Diana Spears originated the chain-formation idea. You are credited with the mean free path derivation, the simulation work, the EA optimization and the ideal-chain analysis (p. 1, 5).

## 2. What it is about
The thesis builds a plug-in 2D localization module based on RF plus acoustic trilateration. Each robot measures range and bearing to its neighbours in its own frame, with no global information. The module is put on seven "Maxelbots" and tested indoors and outdoors (Ch. 2–3).

Part II uses the module for two tasks:
- **Uniform coverage.** A randomized, single-robot algorithm for any square-tileable region, convex or concave, based on a mean free path. It is justified with Markov-chain theory (Ch. 4).
- **Chain formations.** Physicomimetics is changed to use an elliptical well, plus back-flow and front tangential forces. The method is developed in a "Maxelbot-faithful" simulator, the parameters are evolved, and it is shown on 5 robots (Ch. 5).

## 3. Hardware

**Trilateration geometry**
- RF pulse plus acoustic pulse, timed by difference in time of arrival (TDOA).
- Three transducers in an L shape: A(0,d), B(0,0), C(d,0).
- Position: x = (b²−c²+d²)/2d and y = (b²−a²+d²)/2d.
- Baseline d = 15.24 cm (6″) (p. 24).

**Ranging board (XSRF, derived from the SRF04)**
- SRF04 reference: 30 mA, about 3 cm to 3 m, 10 µs trigger, 8-cycle 40 kHz burst (p. 30).
- Transducers: 400ST/R160, 40.0±1.0 kHz. Wavelength is 8.58 mm at 343 m/s. Alternating the burst with its complement improves accuracy by at most 4.25 mm (p. 33–35).
- MAX232 gives about 16 VDC drive. Dual comparators at ±2.0 VDC (p. 33, 37).
- Gain: 324 gave only about 2 ft of range. 5,832 was too noisy. With the bandpass filter (gain 16–17) the total is 5,184–5,508, with good readings to 4 ft (p. 38–39).
- PIC12F675 controller; MAX362 transmit/receive switch (p. 33, 38).

**Acoustic plane**
- The beam is about 30° wide at 36″, so a ring would need 12 transducers per base point.
- Instead, each transducer points down at a parabolic cone. The focal point is 1″ above the cone tip, and the best spacing is 7/8″ (p. 41–42).

**RF link (AM-RTD-315)**
- 315 MHz, up to 10 kbps. Manchester encoding at 9,600 baud gives 4,800 effective, about 1.67 ms per byte (p. 43–44).
- About 1 mW transmit, −87 dBm sensitivity, 63.5×14.5×3.5 mm, transmit ≤10 mA, receive ≤3 mA (p. 218).

**Controller and timing**
- Minidragon: 25 MHz MC9S12DG256, 16-bit timers, 256 KB. It replaced an 8 MHz HC11 Handy Board (p. 47).
- There is a 250 µs hardware delay from trigger to echo (p. 50).

**Accuracy on the bench**
- 24 grid points from (−24″,−24″) to (24″,24″).
- Mean error 0.6″ (min 0.1″, max 1.2″), compared with 4.8″ for the previous module (p. 28, 53).

**Protocol**
- Token ring by robot ID; N must be known in advance (p. 53–56).
- Acoustic decay needs at least 10 ms in theory. In practice the token passes every 120 ms because the RF module, rated under 5 ms to switch, is unreliable for about 100 ms after switching (p. 56).
- That gives 8.33 Hz (p. 87, 114). The thesis gives the theoretical ceiling as about 33 Hz (p. 215).
- Sync byte 0x33. A software watchdog ticks about every 88 ms, and robots stop moving if the protocol fails (p. 57–58).

**Bus and data format**
- I²C at 100 kbps (400 kbps capable, 400 pF limit) (p. 61–62).
- Each robot's record is X float, Y float, heading byte (0–255) (p. 63).

**Platform (MMP-5)**
- 4.5 lb, carries 4 lb more, 12 VDC 4.5 Ah NiMH, 4-wheel tank drive, zero turning radius (p. 66–67).
- Motor commands are 1–2 ms pulses with 1.5 ms meaning stop (p. 67). Speed is 1 ft/s (p. 166).

**Add-ons**
- Sharp GP2D12 IR: 10–80 cm, 33 mA average (up to 100 mA measured), up to 8 per robot, 10-bit ADC (p. 71–73).
- CMPS03 compass (p. 75–76), with an observed average error of about 10.5° (p. 192).
- AD7415 temperature sensor: ±0.5 °C over −40 to +125 °C (p. 76).
- Bluetooth serial: up to 7 paired, worked at 30 ft line of sight (p. 77, 189).

**Range limits and reliability**
- Signal lost above 3.5 m indoors (p. 82) and above 8 ft outdoors (p. 86). Accuracy "reduces drastically above 10 feet" (p. 118).
- Outdoors: RF failure 0.2%, acoustic miss 1%, worst gap 0.24 s (p. 86–87).
- Electronics failed below about 6 °C (p. 87). Wind reached over 9 m/s (p. 82).

## 4. Algorithms and equations

**Uniform coverage**
- Markov argument: if the cell-transition matrix Q is ergodic and symmetric, the steady state is uniform (p. 102–104).
- Algorithm 1 (move until a wall, then turn randomly) is non-uniform: the centre cell gets the fewest visits (888,209 against about 1.2M at the corners, p. 105).
- Algorithm 2 also turns randomly after travelling f·c, where c is the cell size.
- Theory: the mean distance from a uniform point in a unit cell to just inside the adjacent cell is 0.651757, both by integral and by Monte Carlo (p. 108–109).
- In practice f ≈ 0.6 works, because of the wall response range of 1 at cell size 20 (a 5% buffer). The thesis's buffered theory value is 0.6079 (p. 110).
- Multi-robot coverage: choose N so that 1−(1−1/C)^N > P_m (p. 113).

**Chain formation (first, Java simulator)**
- Split-Newtonian force F = G/r^p: repulsive for r ≤ R, attractive for R < r ≤ 1.5R, zero beyond.
- Generalized Lennard-Jones force: R^a/r^(a+1) − R^b/r^(b+1).
- Walls work better with split-Newtonian (p. 137–138).
- Continuous back-flow crams robots together; intermittent back-flow works better (p. 140–141).
- Potential-energy analysis showed tangential wall forces make inner corners "invisible". The fix is repulsion along the sensor beam (p. 142–143).

**Chain formation (second, robot-faithful simulator)**
- Each robot has an ellipse aligned with its heading: d = 1/√(cos²θ/a² + sin²θ/b²). The force is repulsive if r < d and attractive otherwise, within 1.5R (p. 159–161).
- Back-flow pulls a robot toward the last known position of its upstream neighbour, and only while that link is lost (p. 164).
- Front tangential force: when the front IR sensor sees a wall, push ±90° from heading, each with 50% probability (p. 164–165).
- The EA trained on the 15-corner environment with N=10, R=40, Vmax=3, 10% noise, one robot added per 2,000 steps, and 100,000 steps (p. 166).
- Final 11 parameters (p. 168):

| Parameter | Value |
|---|---|
| Friction | 0.579306 |
| Wall detection range | 7.381481 |
| Ellipse major axis | 119,382.723558 |
| Ellipse minor axis | 95.740130 |
| Back-flow magnitude | 0.371287 |
| Back-flow friction | 0.569767 |
| Robot–robot G | 1,895.527010 |
| Robot–robot p | 3.022846 |
| Robot–wall G | 1,218.359939 |
| Robot–wall p | 5.832936 |
| Front tangential force | 2.082259 |

- IR sensors are at 0°, 90° and 270° (p. 168).
- Note: the "minor axis" of 95.74 is larger than the sensing range 1.5R = 60 (or close to it if halved), so the evolved ellipse is almost entirely repulsive. That fits the thesis's "approximately 1/r³" back-flow pulsing (p. 176). This is my observation, not the author's.

**Simulator engine**
- C with Freeglut, 750×750 window.
- Robots can turn on a dime and have a velocity cap.
- Noise is a multiplicative uniform factor in [1−δ, 1+δ], applied to the turn angle, the distance moved, IR range and trilateration range and bearing (p. 145, 169).
- Default config: R=40, max_V=3.0, step=1.0, IR range 30, release every 500 steps (p. 149).
- Unit mapping: 1 pixel = 1 inch and 1 step = 1 s, so Vmax ≤ 12 in simulation (p. 114, 166).
- Speed: the GUI takes over 60 min for 50 robots × 100k steps; the command-line version takes about 3 min (p. 148).

**Chain metrics**
- reachability = |Vc|/N
- sparseness = (|Vc|−1)/|Ec|
- coverage = ΣMST edges / (Rmax(N−1))
- fitness = the mean of the three (p. 154–155)

**Ideal chain analysis**
- Expected chain length E[L] = (p − p^N)/(1 − p) (p. 176–178).

## 5. Results worth reproducing
- **Treadmill follower** (Tables 3.1–3.2, p. 83): following distance 0.5–3.5 m at 0.32 and 0.64 m/s. Y error under 1%, X error under 5%. At 350 cm and 0.64 m/s, X error is −16.5±3.8 cm.
- **Outdoor formations** at about 0.55 m/s on grass, with slopes up to 20° (p. 84–85):
  - Chain: ideal X of 63.5 and 145 cm, measured means 67.1 and 159.8 cm.
  - Triangle and diamond: within about 11%.
  - Following distance 2–8 ft (Fig. 3.1, p. 87).
- **Coverage in simulation:** KL divergence ≤ about 0.001 over 40M steps. The 84-cell environment reaches 0.000632; the full table is on p. 112.
- **Coverage on hardware** with 2.5 ft cells (p. 115–126):

| Arena | Run time | KL divergence | Other |
|---|---|---|---|
| 5×5 ft | 20 min | 0.001158 | |
| 15×5 ft | 2 h | 0.015255 | 0.002 if treated as three 5 ft cells |
| L-shape, 15×15 ft (20 cells) | 4 h | 0.008751 | all cells visited by about 7 min |

- **Chain in simulation** (p. 170–179):
  - Scalability tested for N = 5–50.
  - Noise tested from 0–50%; fitness is least sensitive to motor noise.
  - Robustness run: add up to 50 robots, then remove them at random down to 2. Fitness stays flat and sparseness is about 0.5.
  - Back-flow fires about every 35 steps, so p ≈ 34/35.
  - Expected chain length for N=50: 25.785 with single links, 47.8 with redundant links.
- **Chain on hardware** (p. 189–208):
  - 5 robots, 5 ft maximum spacing, lock-step moves with a token every 4.25 s.
  - Corridors 5 ft wide. Chain reached 14, 16.5 and 17.5 ft (of 20 ft) in the open, straight and L-shaped environments.
  - The chain cuts corners and hugs the inner wall.
  - Per-hop token success p ≈ 0.99. For comparison, p = 0.9 over 5 hops gives 59%.

## 6. 3D, aerial and underwater
- The whole system is explicitly 2D. The parabolic cones deliberately flatten the acoustic field into a plane (p. 2, 41–42).
- A sudden elevation change almost equal to the robot's height still allowed localization (p. 91).
- Future work proposes extending uniform coverage to 3D, and adapting chain formations to 3D because "physicomimetics… has been proven to work in 3D environments" (p. 216).
- Aerial vehicles appear only as cited NRL MITE air-vehicle references for the AP gas models (p. 133).
- Underwater vehicles are not mentioned anywhere.

## 7. Implications for our simulation plan
- **Sensing model.** Range and bearing with multiplicative U[0.9, 1.1] noise. Drop 1% of acoustic and 0.2% of RF readings.
  - Broadcast slots are 120 ms in round-robin, so each neighbour is refreshed every N×0.12 s. That interval is my inference from the protocol, not a figure in the thesis.
  - Use a hard range cutoff that can be set to 2.4 m (outdoor) or 3.5 m (indoor), with error growing with distance.
  - Acoustic line of sight should be blocked by geometry while RF is not (p. 196).
- **3D trilateration.** Add a fourth transducer at (0,0,d). By analogy with the 2D formulas, z = (b²−e²+d²)/2d (my extension). Emission must be omnidirectional or spherical; the planar cone design does not carry over.
- **3D coverage.** Keep the move, random-turn-after-f·c, turn-at-wall rule.
  - For cube cells, f ≈ 0.772 is **unverified (digest author's own Monte Carlo)**: it is my analogue of Listing 4.5, against 0.652 in 2D, and is not in the thesis. Calibrate empirically as the thesis did.
  - Validate with KL divergence over voxel cells, using the 2D tables above as regression targets.
- **3D chains.**
  - Generalize the ellipse to a prolate spheroid about the heading. The same d formula applies, with θ measured from the heading axis.
  - The front tangential force should pick a random direction perpendicular to the heading, not just left or right.
  - Add up and down IR sensors for vertical shafts.
  - Keep back-flow intermittent.
  - Reproduce N = 5–50, the noise sweeps and the robustness schedule with reachability, sparseness and coverage.
- **Units and validation.** First reproduce the 2D Maxelbot runs in Bullet: 12 in/s, 3 IR sensors at 9″ range, 5 ft maximum spacing, the 14 ft and 8+12 ft corridors. Do this before moving to quadcopters.
