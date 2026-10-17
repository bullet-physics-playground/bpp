# Digest: Heil (2004), *A Trilaterative Localization System for Small Mobile Robots in Swarms*

Page numbers are PDF pages. The PDF page is the printed page number plus 12.

## 1. Bibliographic
- **Title:** A Trilaterative Localization System for Small Mobile Robots in Swarms
- **Author:** Rodney Heil
- **Degree:** M.S. in Electrical Engineering, Department of Electrical and Computer Engineering
- **University:** University of Wyoming, Laramie
- **Date:** August 2004 (defended May 3, 2004)
- **Advisors:** Jerry Hamann (Chairman) and William Spears (Co-Chairman). Committee: Steven Barrett, Diana Spears (p. 1).

## 2. What it is about
The thesis designs a relative ("where are you?") localization device for the Distributed Robotics Lab's physicomimetics robots. The old method, Sharp IR sensors on servos, took about 20–25 s per 360° scan (pp. 16, 19). In the new design a robot "pings" by sending an RF pulse and an ultrasonic pulse at the same moment. Each receiving robot times the gap to the ultrasonic arrival at three receivers mounted in an L-shape, then trilaterates the pinging robot's (x, y) in its own frame. The calculation runs as integer arithmetic in a CPLD (pp. 2, 20).

Most of the thesis covers four things: the trilateration maths, the error from quantization and rounding, the CPLD design (written in Verilog), and a working stand-in built from a Handyboard and modified SRF04 sensors. The CPLD board itself was still being designed when the thesis was written (p. 94). Appendix B adds a scheme for passing neighbour positions along the swarm without any global coordinate frame.

## 3. Hardware specs
- **Design goal:** every robot locates its neighbours to within **1 inch** in **under 1 second** (p. 17).
- **Lab robots:** seven KIPR kit robots, built cylindrical so they look the same from any angle, controlled by a Handyboard (68HC11 processor) (pp. 16, 19, 67, 80). The thesis gives **no robot dimensions or speeds**.
- **Old sensor:** Sharp GP2D12 IR rangers on servos sweeping 180°, two facing opposite ways; one full scan took about 20–25 s (p. 19).
- **Range:** "typically about six feet at least" (p. 21). The design target is 6 ft, and it "is likely to be effective over greater ranges as well" (p. 77).
- **Receiver layout:** L-shape with receivers at (0, d), (0, 0) and (d, 0). The nominal spacing is 6 in, so d ≈ **192** units of 1/32 in (pp. 41–42, 63). Only transducer B, at the origin, transmits; a relay switches it between transmit and receive (p. 69).
- **Ultrasonic drive:** a **40 kHz** square wave, LVTTL at **2.5 V peak-to-peak**, amplified to about **18 V peak-to-peak** (pp. 69–70).
- **Counter clock:**
  - The quantization study requires **1/32 in** steps, which is **about 2.3 µs** of sound travel, so **about 435 kHz** (p. 58).
  - The design text uses **about 420 kHz**, a 2.38 µs period. With sound at about **13,000 in/s**, one count is 0.031 in (p. 72).
  - The clock frequency can be adjusted with a trimpot to correct for the speed of sound (p. 72).
  - The Verilog comments instead say "Counter Clock ~460 kHz" and "Machine Clock ~16 MHz (?)" (p. 127). The thesis does not resolve the difference between these figures.
- **Counters:** 12 bits (`CNTR_SIZE 12`); d is held in 8 bits (p. 123). The thesis does not state the counter's full range. A 12-bit count at 1/32 in reaches about 128 in; that figure is my own calculation.
- **Robot ID:** carried in the length of the RF pulse, measured by a fourth counter (p. 72). Each robot's ID is set on 4 DIP switches, as are the acoustic pulse width and the RF-to-acoustic delay and order (pp. 127–128).
- **Planned RF transceiver:** Abacom AM-RTD-315 (p. 94).
- **Reflector cones:** parabolic, machined from aluminium, focal point 1 in from the apex, maximum diameter about 2.5 in. Profile: r = z²/2000 − 500 for 1000 ≤ z ≤ 1871 and 0 ≤ r ≤ 1250, in thousandths of an inch (pp. 98–99). They spread the sound into a horizontal plane.
- **Handyboard stand-in:**
  - Four SRF04 sensors modified into one transmitter and three receivers. Each ping is an 8-cycle 40 kHz burst, and a hard wire takes the place of the RF start signal (pp. 78–80).
  - The 68HC11 input-capture timer gives about **158.3 counts per inch**.
  - Each ping waits at most **6 ms** (about 78 in, roughly 6 ft) for a return.
  - Pings are spaced **250 ms** apart so echoes can die away.
  - Each sensor's results are averaged over the last **50** readings.
  - Fixed per-sensor offsets are 715, 796 and 818 counts.
  - Spacings as built were d = 6.125 in for x and 6.0625 in for y (pp. 84–89).

## 4. Algorithms and equations
- **Constrained trilateration** (pp. 39–40):
  - y = (b² − a² + d²)/(2d)
  - x = (b² − c² + d²)/(2d)
  - In hardware these are computed as x = (((b+c)(b−c))/d + d) >> 1, and the same form for y.
  - The L-shape gives a condition number of 1, which the thesis calls optimal (Hamann 2002) (pp. 41–42).
  - Worked example with d = 192: true position (−417, 394); measured distances 463, 573 and 725; computed position (−417.79, 392.77) (pp. 42–43).
- **Intersection of two general circles** in polar form, plus a 7-step test for whether two circles intersect (pp. 28–35).
- **"Quick & Dirty" method:** compare the three counts against each other and look up the result in a table to get one of 6 sectors ("hextants"). Bearing accuracy is ±30° inside a sector and exact on a sector boundary. It takes one clock cycle and is proposed for UAVs (pp. 44–48). It was not built in the CPLD.
- **Rounding-error bound:** at most ±(1 − 1/(2d)) units per axis, so the total is at most √2/32 in (pp. 63–65).
- **Appendix B, relaying positions without a global frame** (pp. 100–118):
  - The transform is ᴬP = ᴬ_B R ᴮP + ᴬP_B.
  - The rotation is recovered in closed form (Eqs. B.9 and B.10) from ᴮP_A and ᴬP_B.
  - A "doubt level" counts hops; a robot rejects any report whose doubt is not lower than what it already has.
  - Each robot runs a stop / scan / transmit / move cycle.
  - For every robot to learn everything, each should transmit n − 1 times.

## 5. Measured results worth reproducing
- **Quantization simulation:** steps of 1/32 in keep the worst-case position error **under 1 in** within 6 ft (p. 58).
- **Handyboard and SRF04 test with cones** (pp. 89–91):
  - Setup: 24 transmitter positions on a ±24 in grid, 10 readings averaged at each, 6 in spacing, transducer 7/8 in below the cone tip.
  - Mean position error **4.8 in**.
  - Mean range error **3.5 in**.
  - Mean bearing error **0.25 rad (14.5°)**.
  - Results are only "ballpark" within about **2–3 ft**; the signal is increasingly lost beyond that. The worst errors in Fig. 15.4 are at the ±24 in corners.
  - With the cones removed and the transducers pointed at each other, distances were accurate out to **6–7 ft**.
  - Suspected causes: cone and transducer misaligned with the focal point, tilt, and occlusion by the mounting rods.

## 6. 3D, aerial and underwater
- 3D needs a **fourth** sensor and counter, which "would obviously be necessary for … UAV applications" (pp. 17–18).
- A fourth sensor placed orthogonally to the others would allow 3D; the thesis also lists underwater mapping, cave mapping and covert mapping as uses (p. 77).
- Future work suggests a fourth receiver "placed above the other three" if ultrasound can be transmitted equally in 3D (p. 95).
- The Quick & Dirty method is aimed at UAVs where speed matters more than precision (p. 44).
- Tilting the transmitter's cone tilts the plane of sound so it can pass "under or over a receiver" (p. 91). For quadcopters, which tilt as they fly, this is directly relevant.
- **Trilateration without RF** from differences in arrival time (MacArthur 2003) is suggested as a backup (p. 95).

## 7. What this means for our simulation plan
1. **Sensor model, ideal hardware:**
   - Range to each receiver = floor(true distance / q), with q = 1/32 in (0.79 mm).
   - Use d = 6 in (0.152 m) and the L-shape, and compute positions with Heil's integer formulas.
   - Expect sub-inch error within 6 ft (1.83 m). Use this as the "design spec" preset.
2. **Sensor model, as measured:**
   - Add range noise with σ around 3.5 in (0.089 m) and bearing noise around 14.5°.
   - The thesis reports only means, so treating these as σ is our assumption.
   - Drop packets at an increasing rate beyond 2–3 ft (0.6–0.9 m), and cut off completely at 6 ft.
   - Use this as the "pessimistic" preset to stress-test Newtonian, Lennard-Jones and honeycomb formations and chain relays.
3. **Timing:**
   - Robots ping in turn (time-division), with 6 ms listening windows.
   - Use a 250 ms gap between pings as the conservative setting.
   - Optionally apply the 50-sample running average, which adds lag; this matters for kinetic-theory sweeps and Daedalus adaptation.
4. **Gating:**
   - Reject a reading triplet when any pairwise count difference exceeds the baseline (960 counts for 6 in, 1360 for the diagonal), or when any range is under 1 in.
   - Report an overflow or timeout when a receiver hears nothing.
5. **3D (multilateration):** add a receiver at (0, 0, d). By the same derivation, z = (b² − e² + d²)/(2d), where e is the range to the new receiver. This is our extension; Heil only says a fourth orthogonal sensor is needed.
6. **Couple sensing to attitude:**
   - Under quadcopter roll or pitch, tilt the transmit "sound plane" accordingly.
   - Treat receivers outside that plane, beyond a set angle, as dropouts, matching the effect described on p. 91.
7. **Speed of sound:**
   - Use c ≈ 13,000 in/s (330 m/s), the thesis's figure.
   - Expose a calibration parameter matching the trimpot and the self-calibration idea (pp. 72, 94); this matters for underwater vehicles, where sound travels at a very different speed.
8. **Relaying for chain relays and statistical scouts:** implement Appendix B's frame transform and hop-count "doubt level" to pass on the positions of out-of-range robots. Gaussian, occasional gross and systematic error models are all listed as upgrades to its uniform ±ε error (p. 116).
9. **Cheap baseline:** offer the Quick & Dirty sector-only bearing mode (±30°) as a low-cost sensing option to compare against full trilateration.
