// Towers of Hanoi -- standalone POV-Ray SDL port of demo/koppi/hanoi.lua
//
// A self-contained sibling of the BPP demo: no #include files (not even
// the standard colors.inc/woods.inc -- wood is POV's own built-in pattern
// and the rainbow/plastic look is built from scratch below), no OpenSCAD,
// no external Lua modules -- just povray and this file.
//
// WHY THIS LOOKS DIFFERENT FROM hanoi.lua: that script drives the scene
// with per-simulation-step callbacks (v:postSim(...)), advancing one
// stateful Lua closure call at a time. POV-Ray instead re-evaluates this
// entire file fresh for every rendered frame, as a pure function of the
// built-in `clock` variable -- there is no "advance by one step" hook.
// So instead of animating live, the solver below (a direct port of
// HanoiDoc::makeMove() from qthanoi/hanoidoc.cpp, same as hanoi.lua) runs
// to completion once per frame, replaying the *entire* move sequence and
// recording, for every stone, which peg/slot it occupies after each of
// the MaxMoves moves (PegOf[][]/SlotOf[][] below). Per-frame placement is
// then a pure lookup into that timeline at the current clock, using the
// same 3-phase bezier flight (up its own peg / across the peg tops / down
// the destination peg) as hanoi.lua's beginFlight()/advanceFlight(), and
// the same rainbow-plastic stones and wood-textured platform on an
// OpenSCAD-free torus (POV has a native torus primitive).
//
// Usage:
//   Quick static preview (shows the unsolved starting position):
//     povray +W1280 +H720 hanoi.pov
//
//   Full animation, default 5 stones (this file prints the exact
//   recommended Final_Frame to the console/log when parsed):
//     povray +W1280 +H720 +KFF620 hanoi.pov
//
//   A different stone count (valid range 3..16, as in hanoi.lua; large
//   values are impractical here for the same reason they are in the
//   interactive demo -- 2^n-1 moves to solve):
//     povray +W1280 +H720 +KFF2604 Declare=NumStones=7 hanoi.pov
//
#version 3.7;

global_settings { assumed_gamma 1.0 }

#ifndef (NumStones)
  #declare NumStones = 5;
#end

//----------------------------------------------------------------------
// Dimensions -- same formulas as hanoi.lua, sized directly for the
// actual NumStones (no MAX_STONES-based headroom needed: unlike the
// live interactive demo, this file has no "rebuild with a different
// count" concept, so pegs/platform are simply sized for what's asked).
//----------------------------------------------------------------------
#declare StoneBaseR = 0.45;
#declare StoneStepR = 0.15;
#declare StoneH     = 0.3;

#declare MaxStoneR = StoneBaseR + (NumStones - 1) * StoneStepR;

#declare PegR             = 0.15;
#declare PegSpacing       = MaxStoneR * 2 + 0.8;
#declare PegClearance     = 2.0;
#declare StoneHoleMargin  = 0.03;
#declare StoneHoleR       = PegR + StoneHoleMargin;
#declare StoneFilletR     = StoneH * 0.35;

#declare PegHeight = NumStones * StoneH + PegClearance;

#declare TorusTubeR  = 0.4;
#declare TorusMajorR = (PegSpacing + MaxStoneR) * 0.55;

#declare PlatformR = PegSpacing + MaxStoneR + 0.6;
#declare PlatformH = 0.5;

#declare TorusY    = TorusTubeR;
#declare PlatformY = 2 * TorusTubeR + PlatformH / 2;
#declare BaseY     = 2 * TorusTubeR + PlatformH; // top surface pegs/stones stand on
#declare PegTopY   = BaseY + PegHeight;

#declare PegX = array[3];
#declare PegX[0] = -PegSpacing;
#declare PegX[1] = 0;
#declare PegX[2] = PegSpacing;

#macro SlotWorldY(Slot)
  #local R = BaseY + StoneH / 2 + Slot * StoneH;
  R
#end

//----------------------------------------------------------------------
// Hanoi solver precomputation -- direct port of HanoiDoc::makeMove()
// (same case_flag 1/2/3 state machine as hanoi.lua's makeMove()), except
// it runs to completion in one pass instead of one call per move: there
// is no "moved" early-exit here, since nothing needs to pause between
// moves at precompute time -- only the per-frame lookup below paces the
// animation. Stack indices are shifted +1 from hanoi.lua's (SP starts at
// 0 meaning empty, not -1) since POV arrays can't take negative indices.
//----------------------------------------------------------------------
#declare MaxMoves = pow(2, NumStones) - 1;

#declare MoveStone = array[MaxMoves + 1];
#declare MoveFrom  = array[MaxMoves + 1];
#declare MoveTo    = array[MaxMoves + 1];

// PegOf[id][k] / SlotOf[id][k]: which peg (1..3) / 0-based slot height
// stone `id` occupies after k moves have completed (k = 0..MaxMoves).
#declare PegOf  = array[NumStones][MaxMoves + 1];
#declare SlotOf = array[NumStones][MaxMoves + 1];

// Tower[p-1][1..TowerCount[p-1]] = stone ids on peg p, bottom..top.
#declare Tower      = array[3][NumStones + 1];
#declare TowerCount = array[3];
#declare TowerCount[0] = 0;
#declare TowerCount[1] = 0;
#declare TowerCount[2] = 0;

#for (Id, NumStones - 1, 0, -1)
  #declare TowerCount[0] = TowerCount[0] + 1;
  #declare Tower[0][TowerCount[0]] = Id;
  #declare PegOf[Id][0]  = 1;
  #declare SlotOf[Id][0] = TowerCount[0] - 1;
#end

#declare Height    = NumStones;
#declare From      = 1;
#declare With      = 3;
#declare To        = 2;
#declare SP        = 0; // 0 = empty (hanoi.lua's SP=-1, shifted by +1)
#declare CaseFlag  = 1;
#declare AlgDone   = false;
#declare MoveCount = 0;

#declare HeightStack = array[NumStones + 2];
#declare FromStack   = array[NumStones + 2];
#declare ToStack     = array[NumStones + 2];
#declare WithStack   = array[NumStones + 2];
#declare ReturnAddr  = array[NumStones + 2];

#while (!AlgDone)
  #if (CaseFlag = 1)
    #while (Height > 0)
      #declare SP = SP + 1;
      #declare HeightStack[SP] = Height;
      #declare FromStack[SP]   = From;
      #declare ToStack[SP]     = To;
      #declare WithStack[SP]   = With;
      #declare ReturnAddr[SP]  = 2;
      #declare Height = Height - 1;
      #declare Tmp = To; #declare To = With; #declare With = Tmp;
    #end
    #declare CaseFlag = 3;
  #elseif (CaseFlag = 2)
    #declare MoveCount = MoveCount + 1;
    #declare MovedId = Tower[From - 1][TowerCount[From - 1]];
    #declare TowerCount[From - 1] = TowerCount[From - 1] - 1;
    #declare TowerCount[To - 1]   = TowerCount[To - 1] + 1;
    #declare Tower[To - 1][TowerCount[To - 1]] = MovedId;

    #declare MoveStone[MoveCount] = MovedId;
    #declare MoveFrom[MoveCount]  = From;
    #declare MoveTo[MoveCount]    = To;

    #for (K, 0, NumStones - 1)
      #declare PegOf[K][MoveCount]  = PegOf[K][MoveCount - 1];
      #declare SlotOf[K][MoveCount] = SlotOf[K][MoveCount - 1];
    #end
    #declare PegOf[MovedId][MoveCount]  = To;
    #declare SlotOf[MovedId][MoveCount] = TowerCount[To - 1] - 1;

    #declare SP = SP + 1;
    #declare HeightStack[SP] = Height;
    #declare FromStack[SP]   = From;
    #declare ToStack[SP]     = To;
    #declare WithStack[SP]   = With;
    #declare ReturnAddr[SP]  = 3;
    #declare Height = Height - 1;
    #declare Tmp = From; #declare From = With; #declare With = Tmp;
    #declare CaseFlag = 1;
  #elseif (CaseFlag = 3)
    #if (SP >= 1)
      #while (SP >= 1 & CaseFlag = 3)
        #declare Height   = HeightStack[SP];
        #declare From     = FromStack[SP];
        #declare To       = ToStack[SP];
        #declare With     = WithStack[SP];
        #declare CaseFlag = ReturnAddr[SP];
        #declare SP = SP - 1;
      #end
    #else
      #declare AlgDone = true;
    #end
  #end
#end

#declare FramesPerMove = 20; // simulation steps a single stone flight takes, see hanoi.lua's ANIM_FRAMES
#declare TotalFrames    = MaxMoves * FramesPerMove;

#debug concat("hanoi.pov: ", str(NumStones,0,0), " stones, ", str(MaxMoves,0,0),
              " moves, recommended Final_Frame=", str(TotalFrames,0,0), "\n")

//----------------------------------------------------------------------
// Rainbow (colormaps' "hsv" map equivalent) and the classic POV-Ray
// "plastic" finish -- phong highlight, no reflection -- matching
// hanoi.lua's stoneTexture(): POV's own docs describe phong specifically
// as simulating a plastic-like surface, as opposed to specular/
// reflection (metal) or an ior (glass).
//----------------------------------------------------------------------
#macro Rainbow(T)
  #local H = T * 6;
  #switch (H)
    #range (0, 1)
      #local R = rgb <1, H, 0>;
    #break
    #range (1, 2)
      #local R = rgb <2 - H, 1, 0>;
    #break
    #range (2, 3)
      #local R = rgb <0, 1, H - 2>;
    #break
    #range (3, 4)
      #local R = rgb <0, 4 - H, 1>;
    #break
    #range (4, 5)
      #local R = rgb <H - 4, 0, 1>;
    #break
    #else
      #local R = rgb <1, 0, 6 - H>;
    #break
  #end
  R
#end

#macro PlasticFinish()
  finish {
    phong 0.9
    phong_size 60
    ambient 0.15
    diffuse 0.6
  }
#end

// A stone: a cylinder with a hole through its center (sized to slide
// over a peg -- StoneHoleR matches the peg diameter plus a small
// clearance margin), its outer edge rounded off by StoneFilletR. This is
// the exact minkowski(core_cylinder, sphere) decomposition hanoi.lua's
// OpenSCAD minkowski() builds -- a shrunk core cylinder blown back out to
// the full (OuterR, TotalH) footprint via a straight outer side wall,
// two rim-fillet tori, and two flat polar caps -- expressed here as
// native POV primitives instead of an OpenSCAD subprocess call.
#macro RoundedHollowDisk(OuterR, TotalH, FilletR, HoleR)
  #local CoreR      = OuterR - FilletR;
  #local HalfCoreH  = (TotalH - 2 * FilletR) / 2;
  #local HalfTotalH = TotalH / 2;
  difference {
    union {
      cylinder { <0, -HalfCoreH, 0>, <0, HalfCoreH, 0>, OuterR }
      torus { CoreR, FilletR translate <0, HalfCoreH, 0> }
      torus { CoreR, FilletR translate <0, -HalfCoreH, 0> }
      cylinder { <0, HalfTotalH - 0.001, 0>, <0, HalfTotalH, 0>, CoreR }
      cylinder { <0, -HalfTotalH, 0>, <0, -HalfTotalH + 0.001, 0>, CoreR }
    }
    cylinder { <0, -HalfTotalH - 0.01, 0>, <0, HalfTotalH + 0.01, 0>, HoleR no_image }
  }
#end

#macro Stone(Id)
  #local OuterR = StoneBaseR + Id * StoneStepR;
  object {
    RoundedHollowDisk(OuterR, StoneH, StoneFilletR, StoneHoleR)
    texture {
      pigment { color Rainbow(Id / (NumStones - 1)) }
      PlasticFinish()
    }
  }
#end

//----------------------------------------------------------------------
// Flight path: the same 3-phase bezier as hanoi.lua's beginFlight()/
// advanceFlight() -- a straight vertical rise up the source peg, a cubic
// Bezier hop across the (shared) peg-top height, then a straight
// vertical fall down the destination peg -- so a stone never drifts
// sideways while still low enough to clip a peg's side.
//----------------------------------------------------------------------
#declare UpFrac     = 0.28;
#declare AcrossFrac = 0.44;
#declare DownFrac   = 0.28;

#macro FlightPos(FromPeg, ToPeg, FromSlot, ToSlot, Blend)
  #local X0 = PegX[FromPeg - 1];
  #local Y0 = SlotWorldY(FromSlot);
  #local X1 = PegX[ToPeg - 1];
  #local Y1 = SlotWorldY(ToSlot);
  #local BulgeY = PegTopY + StoneH * 2;
  #if (Blend < UpFrac)
    #local T = Blend / UpFrac;
    #local R = <X0, Y0 + (PegTopY - Y0) * T, 0>;
  #elseif (Blend < UpFrac + AcrossFrac)
    #local T  = (Blend - UpFrac) / AcrossFrac;
    #local P0 = <X0, PegTopY, 0>;
    #local P1 = <X0 + (X1 - X0) / 3, BulgeY, 0>;
    #local P2 = <X0 + (X1 - X0) * 2 / 3, BulgeY, 0>;
    #local P3 = <X1, PegTopY, 0>;
    #local Mt = 1 - T;
    #local R = (Mt*Mt*Mt)*P0 + (3*Mt*Mt*T)*P1 + (3*Mt*T*T)*P2 + (T*T*T)*P3;
  #else
    #local T = (Blend - UpFrac - AcrossFrac) / DownFrac;
    #local R = <X1, PegTopY + (Y1 - PegTopY) * T, 0>;
  #end
  R
#end

#macro FlightSpin(FromPeg, ToPeg, Blend)
  #local Dir = 1;
  #if (ToPeg < FromPeg)
    #local Dir = -1;
  #end
  #if (Blend < UpFrac)
    #local R = 0;
  #elseif (Blend < UpFrac + AcrossFrac)
    #local R = Dir * ((Blend - UpFrac) / AcrossFrac) * 180;
  #else
    #local R = Dir * 180;
  #end
  R
#end

//----------------------------------------------------------------------
// Static scenery: floor, pedestal torus (POV's native torus primitive --
// already Y-axis/hole-up by default, unlike hanoi.lua's OpenSCAD
// rotate_extrude() workaround), and the wood-textured platform (POV's
// built-in `wood` pattern, no woods.inc needed).
//----------------------------------------------------------------------
plane {
  y, 0
  pigment { color rgb <0.1, 0.1, 0.1> }
  finish { diffuse 0.8 ambient 0.05 }
}

torus {
  TorusMajorR, TorusTubeR
  pigment { color rgb <0.17, 0.17, 0.17> }
  finish { phong 0.4 phong_size 30 diffuse 0.7 ambient 0.08 }
  translate <0, TorusY, 0>
}

cylinder {
  <0, PlatformY - PlatformH / 2, 0>, <0, PlatformY + PlatformH / 2, 0>, PlatformR
  pigment {
    wood
    turbulence 0.05
    color_map {
      [0.0 color rgb <0.35, 0.12, 0.06>]
      [0.5 color rgb <0.20, 0.05, 0.02>]
      [1.0 color rgb <0.35, 0.12, 0.06>]
    }
    scale 4
  }
  finish { phong 0.3 phong_size 20 diffuse 0.7 ambient 0.1 }
}

#for (P, 0, 2)
  cylinder {
    <PegX[P], BaseY, 0>, <PegX[P], BaseY + PegHeight, 0>, PegR
    pigment { color rgb <0.75, 0.75, 0.75> }
    finish { phong 0.6 phong_size 40 diffuse 0.6 ambient 0.1 }
  }
#end

//----------------------------------------------------------------------
// Per-frame stone placement: a pure lookup into the precomputed
// PegOf/SlotOf timeline at the current clock, exactly mirroring the
// resting-vs-flying split of hanoi.lua's updateRestingStonePoses()/
// advanceFlight() -- just evaluated once per stone per frame here
// instead of once per postSim step.
//----------------------------------------------------------------------
#declare GlobalStep = clock * TotalFrames;
#declare CurMove    = min(floor(GlobalStep / FramesPerMove) + 1, MaxMoves);
#declare LocalBlend = min((GlobalStep - (CurMove - 1) * FramesPerMove) / FramesPerMove, 1);

#for (Id, 0, NumStones - 1)
  #local IsMover = (MoveStone[CurMove] = Id);
  #if (IsMover)
    #local Pos  = FlightPos(MoveFrom[CurMove], MoveTo[CurMove],
                             SlotOf[Id][CurMove - 1], SlotOf[Id][CurMove], LocalBlend);
    #local Spin = FlightSpin(MoveFrom[CurMove], MoveTo[CurMove], LocalBlend);
  #else
    #local RestPeg  = PegOf[Id][CurMove - 1];
    #local RestSlot = SlotOf[Id][CurMove - 1];
    #local Pos  = <PegX[RestPeg - 1], SlotWorldY(RestSlot), 0>;
    #local Spin = 0;
  #end

  object {
    Stone(Id)
    rotate <0, 0, -Spin>
    translate Pos
  }
#end

//----------------------------------------------------------------------
// Pseudo-orthogonal camera (see demo/basic/06-mesh.lua's comment and
// hanoi.lua's own camera section for the reasoning: parked far enough
// away, with a horizontal FOV sized against whichever of the scene's
// horizontal or vertical extent is larger under a worst-case aspect
// ratio, that perspective distortion flattens out while still framing
// the full scene at any viewport shape). It orbits the static scene at
// the same 0.005 rad/step pace as hanoi.lua's CAMERA_ORBIT_SPEED.
//
// SceneLookY MUST be the true vertical midpoint (SceneTopY/2), not some
// offset from it: the required vertical half-angle is
// max(SceneTopY - LookY, LookY) / CamDist, which is only minimized (and
// only symmetric top-to-bottom) when LookY sits exactly at the center --
// any offset makes the *far* side's required coverage grow by the same
// amount the near side's shrinks, so CamNeed below (which only scales
// off SceneLookY as a stand-in for the vertical half-extent) silently
// under-covers whichever side ends up farther from an off-center look
// point. A previous off-center LookY (SceneTopY/2 - 3) clipped the peg
// tops for exactly this reason. CameraMargin adds a little extra
// headroom on top of the exact minimum.
//----------------------------------------------------------------------
#declare SceneR         = PlatformR * 1.5;
#declare SceneTopY      = BaseY + PegHeight + StoneH * 2;
#declare SceneLookY     = SceneTopY / 2;
#declare CameraMaxAspect = 2.0;
#declare CameraMargin    = 1.08;

#declare CamPosBase = <SceneR * 9, SceneR * 11, SceneR * 9>;
#declare CamDist = sqrt(CamPosBase.x*CamPosBase.x + CamPosBase.y*CamPosBase.y + CamPosBase.z*CamPosBase.z);
#declare CamNeed = max(SceneR, SceneLookY * CameraMaxAspect) * CameraMargin;
#declare CamFovDeg = degrees(2 * atan(CamNeed / CamDist));

#declare CameraAngle = GlobalStep * 0.005;
#declare CamPos = <
  CamPosBase.x * cos(CameraAngle) - CamPosBase.z * sin(CameraAngle),
  CamPosBase.y,
  CamPosBase.x * sin(CameraAngle) + CamPosBase.z * cos(CameraAngle)
>;

camera {
  location CamPos
  right image_width / image_height * x
  look_at <0, SceneLookY, 0>
  angle CamFovDeg
  sky <0, 1, 0>
}

light_source { <SceneR * 6, SceneR * 10, -SceneR * 4> color rgb <1, 1, 0.95> }
light_source { <-SceneR * 5, SceneR * 6, SceneR * 5> color rgb <0.35, 0.35, 0.45> shadowless }

// EOF
