#version 3.7;
global_settings { assumed_gamma 1.0 }

#ifndef (NumStones)
  #declare NumStones = 5;
#end

#declare StoneBaseR = 0.45;
#declare StoneStepR = 0.15;
#declare StoneH     = 0.3;
#declare MaxStoneR  = StoneBaseR + (NumStones - 1) * StoneStepR;

#declare PegR         = 0.15;
#declare PegSpacing   = MaxStoneR * 2 + 0.8;
#declare StoneHoleR   = PegR + 0.03;
#declare StoneFilletR = StoneH * 0.35;
#declare PegHeight    = NumStones * StoneH + 2.0;

#declare TorusTubeR  = 0.4;
#declare TorusMajorR = (PegSpacing + MaxStoneR) * 0.55;
#declare PlatformR   = PegSpacing + MaxStoneR + 0.6;
#declare PlatformH   = 0.5;

#declare TorusY    = TorusTubeR;
#declare PlatformY = 2 * TorusTubeR + PlatformH / 2;
#declare BaseY     = 2 * TorusTubeR + PlatformH;
#declare PegTopY   = BaseY + PegHeight;

#declare PegX = array[3] { -PegSpacing, 0, PegSpacing }

#macro SlotWorldY(Slot)
  #local R = BaseY + StoneH / 2 + Slot * StoneH;
  R
#end

#declare MaxMoves = pow(2, NumStones) - 1;
#declare MoveStone = array[MaxMoves + 1];
#declare MoveFrom  = array[MaxMoves + 1];
#declare MoveTo    = array[MaxMoves + 1];
#declare PegOf  = array[NumStones][MaxMoves + 1];
#declare SlotOf = array[NumStones][MaxMoves + 1];
#declare TowerCount = array[3] { NumStones, 0, 0 }

#for (Id, 0, NumStones - 1)
  #declare PegOf[Id][0]  = 1;
  #declare SlotOf[Id][0] = NumStones - 1 - Id;
#end

#declare MoveCount = 0;

#macro Display(Num, Source, Dest)
  #local From = val(Source);
  #local To   = val(Dest);
  #local Id   = Num - 1;
  #declare MoveCount = MoveCount + 1;
  #declare TowerCount[From - 1] = TowerCount[From - 1] - 1;
  #declare TowerCount[To - 1]   = TowerCount[To - 1] + 1;
  #declare MoveStone[MoveCount] = Id;
  #declare MoveFrom[MoveCount]  = From;
  #declare MoveTo[MoveCount]    = To;
  #for (K, 0, NumStones - 1)
    #declare PegOf[K][MoveCount]  = PegOf[K][MoveCount - 1];
    #declare SlotOf[K][MoveCount] = SlotOf[K][MoveCount - 1];
  #end
  #declare PegOf[Id][MoveCount]  = To;
  #declare SlotOf[Id][MoveCount] = TowerCount[To - 1] - 1;
#end

#macro tower_of_hanoi(num, source, dest, helper)
  #if (num = 1)
    Display(1, source, dest)
  #else
    tower_of_hanoi(num - 1, source, helper, dest)
    Display(num, source, dest)
    tower_of_hanoi(num - 1, helper, dest, source)
  #end
#end

tower_of_hanoi(NumStones, "1", "3", "2")

#declare FramesPerMove = 20;
#declare TotalFrames = MaxMoves * FramesPerMove;

#debug concat("hanoi-recursive.pov: ", str(NumStones,0,0), " stones, ", str(MaxMoves,0,0),
              " moves, recommended Final_Frame=", str(TotalFrames,0,0), "\n")

#macro Stone(Id)
  #local OuterR    = StoneBaseR + Id * StoneStepR;
  #local CoreR     = OuterR - StoneFilletR;
  #local HalfCoreH = (StoneH - 2 * StoneFilletR) / 2;
  #local HalfH     = StoneH / 2;
  #local T = Id / (NumStones - 1) * 6;
  #switch (T)
    #range (0, 1)
      #local Col = rgb <1, T, 0>;
    #break
    #range (1, 2)
      #local Col = rgb <2 - T, 1, 0>;
    #break
    #range (2, 3)
      #local Col = rgb <0, 1, T - 2>;
    #break
    #range (3, 4)
      #local Col = rgb <0, 4 - T, 1>;
    #break
    #range (4, 5)
      #local Col = rgb <T - 4, 0, 1>;
    #break
    #else
      #local Col = rgb <1, 0, 6 - T>;
    #break
  #end
  difference {
    union {
      cylinder { <0, -HalfCoreH, 0>, <0, HalfCoreH, 0>, OuterR }
      torus { CoreR, StoneFilletR translate <0, HalfCoreH, 0> }
      torus { CoreR, StoneFilletR translate <0, -HalfCoreH, 0> }
      cylinder { <0, HalfH - 0.001, 0>, <0, HalfH, 0>, CoreR }
      cylinder { <0, -HalfH, 0>, <0, -HalfH + 0.001, 0>, CoreR }
    }
    cylinder { <0, -HalfH - 0.01, 0>, <0, HalfH + 0.01, 0>, StoneHoleR no_image }
    texture {
      pigment { color Col }
      finish { phong 0.9 phong_size 60 ambient 0.15 diffuse 0.6 }
    }
  }
#end

#declare UpFrac     = 0.28;
#declare AcrossFrac = 0.44;

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
    #local T = (Blend - UpFrac - AcrossFrac) / (1 - UpFrac - AcrossFrac);
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
    <PegX[P], BaseY, 0>, <PegX[P], PegTopY, 0>, PegR
    pigment { color rgb <0.75, 0.75, 0.75> }
    finish { phong 0.6 phong_size 40 diffuse 0.6 ambient 0.1 }
  }
#end

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

#declare SceneR     = PlatformR * 1.5;
#declare SceneLookY = (PegTopY + StoneH * 2) / 2;
#declare CamPosBase = <SceneR * 9, SceneR * 11, SceneR * 9>;
#declare CamDist    = sqrt(CamPosBase.x*CamPosBase.x + CamPosBase.y*CamPosBase.y + CamPosBase.z*CamPosBase.z);
#declare CamFovDeg  = degrees(2 * atan(max(SceneR, SceneLookY * 2) * 1.08 / CamDist));

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
