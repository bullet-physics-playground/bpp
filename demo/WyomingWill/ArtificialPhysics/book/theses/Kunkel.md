# Digest: Kunkel (2006), *Hardware Architecture of a Swarm of Robots*

PDF page = printed page + 7. All page numbers below are PDF pages.

## 1. Bibliographic
- **Title:** *Hardware Architecture of a Swarm of Robots*
- **Author:** Thomas Kunkel
- **Degree:** M.S. "Plan B Paper" (Master's candidate), Department of Electrical Engineering. The university is not named on the title page, but the text places the work at the University of Wyoming Distributed Robotics Laboratory (p.2, p.12).
- **Date:** December 2006
- **Advisor:** Jerry Hamann (p.1)

## 2. What it is about
This is the hardware report for the UW "Maxelbot" swarm. It covers the RF plus acoustic trilateration localization system, which the paper credits to Heil, Hamann and Spears (p.12). It describes the redesigned ultrasonic receiver board (XSRF) and the two-processor head on an I2C bus. It covers motor drivers for two chassis, Lego and the MMP5 from The Machine Lab, and a planned move to PIC processors. Applications are chemical plume tracing (chemotaxis tested; fluxotaxis/anemotaxis hardware built) and box pushing. The paper says it is a hardware and wiring document, and it has almost no quantitative evaluation.

## 3. Hardware
**Trilateration principle:** RF acts as "lightning" and a 40 kHz ultrasonic pulse acts as "thunder". Each robot has one RF transceiver and three acoustic receivers (p.18–19).

**Acoustic optics:** Reflective parabolic cones spread the transmitted pulse "through 360° in a horizontal plane". At the receiver, each cone focuses the signal onto its transducer (p.18, photo Fig 5.1).

**RF:**
- Transceiver: AMD-RTD-315, 315 MHz, AM (p.19).
- Antenna: quarter-wave, 8.91 inches (p.21).
- 10 kΩ pull-ups on the data lines and 1.2 kΩ I2C pull-ups (p.21).
- The RF board connects to the processor's SCI receive and transmit lines (Table 2, p.53).

**Processors:**
- Wytec Minidragon boards with a Motorola MC9S12DP256 (HCS12) (p.19). There are two per robot, on I2C: one handles trilateration and RF comms, the other handles motors (p.30, p.33).
- Robot ID is set by 4 hardware lines, which gives 16 IDs (p.33).
- Minidragon pins source at most 25 mA each and 200 mA in total (p.43).

**XSRF sensor board** (modified Devantech SRF04):
- Parts: PIC (12F)675, MAX232, 2× LMC6032 op-amps, 2× LP311 comparators and a MAX362 switch for TX/RX mode (p.26). The schematic labels these as PIC12F675, HIN232 and MAX352 (Fig 5.10, p.26).
- Power: +5 V (p.25).
- Transmit: complementary 40 kHz TTL signals are differenced by the MAX232 into a −10 to +10 V drive. Fig 5.11 shows a burst of roughly 7–8 cycles (p.27).
- Receive: two gain stages of about 18× each (p.27), then a Delyiannis-Friend bandpass filter. The filter's design target was 35–45 kHz with a peak gain of 18 at 40 kHz. In practice it used 62 kΩ instead of 80 kΩ and gave a gain of 16 at 40 kHz. Other parts are 2.2 kΩ, 220 Ω and 2× 1 nF (pp.22–23).
- Detection: dual comparators with thresholds at ±2 V (p.23).
- The transmit waveform alternates between the 40 kHz signal and its complement on successive transmissions (p.22).
- 80 kHz transducers were considered and rejected as costlier with little gain in accuracy (p.23).
- Output: an echo pulse whose width is the time from the RF trigger to acoustic arrival, captured on Minidragon timer channels (pp.25–28).

**Scope example (Fig 5.12, p.28):** ΔX = 1.4027 ms between the RF/trigger cursor and acoustic arrival. At about 343 m/s this is roughly 0.48 m; that conversion is mine, not the paper's.

**Motors (Lego Maxelbot):**
- SN754410NE H-bridge with a 74HC04 inverter, PWM speed control and one direction line per motor (pp.30–31).
- Power: +9.6 V battery; the schematic shows Vcc1 = 9 V and Vcc2 = 5 V (Fig 5.14, p.31).
- Shaft encoders on both wheels (p.36).

**Chassis:**
- First Lego version was "just over one foot tall" and tipped over because of its high centre of gravity. It was shortened by about 6 inches and given a wider wheelbase (p.31).
- MMP5 (four wheels, skid-steer, Fig 5.19) uses servo-style pulses: 1 ms is full reverse, 1.5 ms is stop, 2 ms is full forward. It is driven at a 400 Hz PWM period (2.5 ms), so 40% to 80% duty covers the range. The paper gives 500 Hz as the maximum allowed frequency (pp.37–38).
- The text is inconsistent about which pin drives which side (p.37 vs p.39).

**Other sensors:**
- Devantech CMPS03 digital compass on I2C (p.32).
- Figaro TGS2620 ethanol sensors: up to 40 mA each, 47 Ω bias resistor, 5 kΩ calibration pot. Junction boards take 32 sensors each, up to 96 in total (pp.43–45).
- Anemometers need +12 V DC and output 0–12 V. Two per robot are needed for wind speed and direction (p.47).
- IR sensors are used for obstacle avoidance (p.46).

**PIC board:**
- 16F876(A) or 16F767, 28-pin, 20 MHz crystal, 8 kb memory.
- Only the 16F767 has enough timer pins for the three echo pulses (pp.39–40, p.51).
- LM7805 regulator from +9 V (Fig 5.21, p.41).
- Plan: 42 boards, so up to 6 PICs per robot for 7 robots (p.50).

## 4. Algorithms and protocols
- **Receiver geometry:** B at the origin, A at (0, d), C at (d, 0). Closed-form solution: x_T = (d² − d_C² + d_B²)/(2d) and y_T = (d² − d_A² + d_B²)/(2d) (eqs 3.1–3.6, pp.12–15).
- d should be chosen as a power of 2 for convenient digital arithmetic (p.14). Fig 5.8 suggests d ≈ 6 in.
- **Protocol:** the transmitter sends RF and ultrasound together. Each receiving robot triggers on RF, times the three acoustic arrivals and computes (x, y) of the transmitter in its own frame. The result goes over I2C to the motor processor (pp.28–30).
- No medium-access scheme, transmit scheduling, cycle time or update rate is given.
- **Box pushing (Maxim):** a leader moves to a goal while two followers keep a fixed position relative to it using trilateration (p.48).
- **Chemotaxis (Zarzhitsky/Karlsson):** the algorithm is not described. Trials were capped at 30 min (p.46).

## 5. Measured results
- **Trilateration error:** mean error fell from **4.8 in to about 0.7 in**, and range rose from **"two or three feet" to "almost nine feet"** (p.23).
  - Fig 5.7, the old version (Rod prototype, May 2004), and Fig 5.8, the new version (Prototype IIb, 17 May 2005), test only a 5×5 grid at ±24 in with 12 in spacing (p.24).
  - The 9 ft range is not supported by the plotted data.
- **Goal:** accuracy out to at least 5 ft (p.16). Related-work text also says "up to nine feet" (p.10).
- **Chemotaxis:** with one robot, the source was found "much of the time" from under 5 ft; larger distances were less successful (p.46).
- **Swarm size:** four robots working on two platforms (p.49).

## 6. 3D, aerial or underwater content
None. Localization is explicitly in "the horizontal plane" (p.12), and the cones radiate 360° horizontally (p.18). The only terrain remark is that the Lego chassis tipped over on rough ground and the MMP5 is for rugged terrain (pp.31, 37). Satellite GPS is called inadequate (accurate to "tens of feet") and poor indoors or in caves (p.17).

## 7. Implications for the simulation plan
- **Ground-robot baseline sensor:** transmitter (x, y) from three ranges with receivers at (0,0), (0,d), (d,0), d ≈ 0.15 m. Add Gaussian position error of about 0.7 in (about 1.8 cm) mean. Use a hard range cutoff near 9 ft (about 2.7 m); a conservative value is 5 ft (about 1.5 m).
- **Better error model:** apply noise to each range (time of flight) rather than to the final (x, y), so that geometric dilution emerges naturally. Fig 3.2 (p.13) shows the near-parallel circle intersections for distant transmitters. Fit the per-range sigma so that position error is about 0.7 in at ≤ 24 in.
- **Timing:** time of flight is about 1.4 ms at roughly 0.5 m (p.28). At 2.7 m it is about 8 ms. Model one transmitter per slot with at least about 10 ms per slot plus guard time, so N robots give an update rate per neighbour of roughly 1/(N·slot). The rate is not given in the paper, so treat it as a parameter.
- **3D quadcopters:** the cone design is planar. For 3D you need at least 4 non-coplanar receivers, which is multilateration, so build that as a new model rather than reuse these numbers. Elevation-dependent signal loss from the cone optics is unquantified here.
- **Underwater:** sound speed is about 1500 m/s instead of 343 m/s. That is my assumption, not from the paper. The RF "lightning" will not propagate underwater, so you need a different sync model, such as an optical or a clock-synchronized trigger.
- **Ground vehicle model (MMP5):** skid-steer with a per-side command in [−1, 1], mapped from 1–2 ms pulses with 1.5 ms as stop. Lego Maxelbot: differential drive at 9.6 V with PWM.
- **CPT demos:** model a single robot's point chemical sensors and a two-anemometer wind vector. Sensor response and noise are not characterized in the paper.
