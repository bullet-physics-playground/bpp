// ------------------------------------------------------------------
// Persistence of Vision Ray Tracer Include File
// Reflective Spectral Data library for PoV-Ray
// ------------------------------------------------------------------
// adapted from ASTER lunar materials
// http://speclib.jpl.nasa.gov/
// ------------------------------------------------------------------
// Reproduced from the ASTER Spectral Library through the courtesy of
// the Jet Propulsion Laboratory, California  Institute of Technology,
// Pasadena, California.
// Copyright [encircled "c"] 1999, California Institute of Technology.
// ALL RIGHTS RESERVED.
// ------------------------------------------------------------------
/*

  Measurement:  Directional (10 Degree) Hemispherical Reflectance
  -----------
    First Column:  Wavelength (nanometers)
    Second Column: Reflectance (0.0 - 1.0)
  
  Content:
  -------
  Mare:
   RS_Lunar_Maria_1
   RS_Lunar_Maria_2
   RS_Lunar_Maria_3
   RS_Lunar_Maria_4
   RS_Lunar_Maria_5
   
  Transitional:
   RS_Lunar_Transitional_1
   RS_Lunar_Transitional_2
   RS_Lunar_Transitional_3
   RS_Lunar_Transitional_4
   
  Highlands:
   RS_Lunar_Highlands_1
   RS_Lunar_Highlands_2
   RS_Lunar_Highlands_3
   RS_Lunar_Highlands_4
   RS_Lunar_Highlands_5
  
*/

// Standard include file beginning stuff
#ifndef (rspd_lunar_Inc_Temp)
#declare rspd_lunar_Inc_Temp = 1;

#ifdef(View_POV_Include_Stack)
  #debug "Including rspd_lunar.inc\n"
#end

// ==================================================================

#declare RS_Lunar_Maria_1 = spline{ linear_spline
/*
Name: 10084.1939
Type: Soil
Class: Lunar
Subclass: Maria
Particle Size: Fine
Sample No.: 10084.1939
Owner: JHU
Wavelength range: IR
Origin: Apollo 11 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This is the only sample from the Apollo 11 mare site.  This sample
has a large exposure age (Is/FeO=78).
*/
760, 0.05748
751, 0.06346
742, 0.06880
734, 0.07355
726, 0.07793
718, 0.08191
710, 0.08558
702, 0.08868
694, 0.09172
687, 0.09464
680, 0.09732
673, 0.09828
666, 0.09905
659, 0.09973
652, 0.10064
646, 0.10175
640, 0.10266
633, 0.10353
627, 0.10493
621, 0.10565
615, 0.10665
609, 0.10833
604, 0.10906
598, 0.11213
593, 0.11434
587, 0.11709
582, 0.12003
577, 0.12311
572, 0.12549
567, 0.12645
562, 0.12806
557, 0.12919
552, 0.13009
548, 0.13029
543, 0.13007
538, 0.13018
534, 0.12998
530, 0.13102
525, 0.13241
521, 0.13425
517, 0.13639
513, 0.13831
509, 0.14009
505, 0.14205
501, 0.14439
497, 0.14676
493, 0.14925
490, 0.15165
486, 0.15369
482, 0.15570
479, 0.15738
475, 0.15909
472, 0.16055
468, 0.16250
465, 0.16371
462, 0.16516
458, 0.16624
455, 0.16697
452, 0.16750
449, 0.16794
446, 0.16822
443, 0.16844
440, 0.16877
437, 0.16864
434, 0.16878
431, 0.16906
428, 0.16939
425, 0.16922
422, 0.16942
420, 0.16902
417, 0.16895
414, 0.16881
412, 0.16858
409, 0.16881
406, 0.16857
404, 0.16834
401, 0.16821
399, 0.16806
396, 0.16783
394, 0.16766
392, 0.16736
389, 0.16720
387, 0.16683
385, 0.16632
382, 0.16609
380, 0.16562
}

#declare RS_Lunar_Maria_2 = spline{ linear_spline
/*
Name: 12023.139
Type: Soil
Class: Lunar
Subclass: Maria
Particle Size: Fine
Sample No.: 12023.139
Owner: JHU
Wavelength range: IR
Origin: Apollo 12 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils of similar chemistry, but 
different exposure ages, from the Apollo 12 mare site.  This sample has the 
greatest exposure age of the three soils of that suite (Is/FeO=60).
*/
760, 0.05007
751, 0.05742
742, 0.06441
734, 0.07087
726, 0.07693
718, 0.08223
710, 0.08723
702, 0.09187
694, 0.09584
687, 0.09926
680, 0.10213
673, 0.10373
666, 0.10447
659, 0.10546
652, 0.10673
646, 0.10811
640, 0.10900
633, 0.10932
627, 0.10971
621, 0.11037
615, 0.11181
609, 0.11352
604, 0.11474
598, 0.11752
593, 0.12139
587, 0.12499
582, 0.12853
577, 0.13111
572, 0.13295
567, 0.13397
562, 0.13568
557, 0.13850
552, 0.13977
548, 0.14029
543, 0.14007
538, 0.14025
534, 0.14029
530, 0.14120
525, 0.14279
521, 0.14596
517, 0.14913
513, 0.15224
509, 0.15542
505, 0.15869
501, 0.16259
497, 0.16607
493, 0.17041
490, 0.17426
486, 0.17772
482, 0.18152
479, 0.18436
475, 0.18706
472, 0.19011
468, 0.19309
464, 0.19614
461, 0.19836
458, 0.20031
455, 0.20177
451, 0.20283
448, 0.20353
445, 0.20417
442, 0.20456
439, 0.20482
436, 0.20509
433, 0.20562
430, 0.20586
428, 0.20622
425, 0.20613
422, 0.20622
419, 0.20622
417, 0.20608
414, 0.20615
411, 0.20579
409, 0.20563
406, 0.20549
404, 0.20527
401, 0.20507
399, 0.20489
396, 0.20475
394, 0.20454
391, 0.20397
389, 0.20366
387, 0.20319
384, 0.20276
382, 0.20223
380, 0.20159
}

#declare RS_Lunar_Maria_3 = spline{ linear_spline
/*
Name: 12024.69
Type: Soil
Class: Lunar
Subclass: Maria
Particle Size: Fine
Sample No.: 12024.69
Owner: JHU
Wavelength range: IR
Origin: Apollo 12 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils of similar chemistry, but 
different exposure ages, from the Apollo 12 mare site.  This sample has the 
intermediate exposure age of the three soils of that suite (Is/FeO=30).
*/
760, 0.05177
751, 0.05950
742, 0.06687
734, 0.07366
726, 0.08009
718, 0.08579
710, 0.09140
702, 0.09616
694, 0.10015
687, 0.10417
680, 0.10716
673, 0.10897
666, 0.10991
659, 0.11023
652, 0.11195
646, 0.11328
640, 0.11395
633, 0.11385
627, 0.11476
621, 0.11526
615, 0.11642
609, 0.11892
604, 0.11872
598, 0.12258
593, 0.12679
587, 0.13137
582, 0.13595
577, 0.14009
572, 0.14324
567, 0.14460
562, 0.14739
557, 0.15004
552, 0.15237
548, 0.15267
543, 0.15302
538, 0.15287
534, 0.15245
530, 0.15341
525, 0.15571
521, 0.15900
517, 0.16284
513, 0.16672
509, 0.17069
505, 0.17445
501, 0.17889
497, 0.18350
493, 0.18880
490, 0.19379
486, 0.19821
482, 0.20244
479, 0.20649
475, 0.21018
472, 0.21405
468, 0.21805
465, 0.22150
462, 0.22491
458, 0.22769
455, 0.22997
452, 0.23174
449, 0.23282
446, 0.23387
443, 0.23462
440, 0.23527
437, 0.23569
434, 0.23670
431, 0.23754
428, 0.23796
425, 0.23830
422, 0.23871
420, 0.23876
417, 0.23876
414, 0.23869
412, 0.23882
409, 0.23864
406, 0.23862
404, 0.23863
401, 0.23851
399, 0.23844
396, 0.23819
394, 0.23800
392, 0.23759
389, 0.23742
387, 0.23710
385, 0.23666
382, 0.23610
380, 0.23581
}

#declare RS_Lunar_Maria_4 = spline{ linear_spline
/*
Name: 12030.135
Type: Soil
Class: Lunar
Subclass: Maria
Particle Size: Fine
Sample No.: 12030.135
Owner: JHU
Wavelength range: IR
Origin: Apollo 12 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils of similar chemistry, but 
different exposure ages, from the Apollo 12 mare site.  This sample has the 
lowest exposure age of the three soils of that suite (Is/FeO=14).
*/
760, 0.05522
751, 0.06228
742, 0.06908
734, 0.07584
726, 0.08176
718, 0.08686
710, 0.09174
702, 0.09627
694, 0.10038
687, 0.10484
680, 0.10747
673, 0.10857
666, 0.10925
659, 0.10987
652, 0.11130
646, 0.11306
640, 0.11426
633, 0.11408
627, 0.11390
621, 0.11417
615, 0.11625
609, 0.11858
604, 0.12118
598, 0.12420
593, 0.12992
587, 0.13577
582, 0.14024
577, 0.14386
572, 0.14625
567, 0.14775
562, 0.15014
557, 0.15416
552, 0.15583
548, 0.15633
543, 0.15558
538, 0.15452
534, 0.15296
530, 0.15341
525, 0.15594
521, 0.15994
517, 0.16378
513, 0.16770
509, 0.17154
505, 0.17545
501, 0.17980
497, 0.18472
493, 0.19043
490, 0.19620
486, 0.20146
482, 0.20645
479, 0.21112
475, 0.21534
472, 0.21998
468, 0.22479
465, 0.22881
462, 0.23278
458, 0.23611
455, 0.23860
452, 0.24094
449, 0.24235
446, 0.24345
443, 0.24447
440, 0.24544
437, 0.24624
434, 0.24742
431, 0.24822
428, 0.24897
425, 0.24993
422, 0.25015
420, 0.25103
417, 0.25171
414, 0.25210
412, 0.25230
409, 0.25260
406, 0.25292
404, 0.25328
401, 0.25323
399, 0.25365
396, 0.25395
394, 0.25377
392, 0.25378
389, 0.25384
387, 0.25389
385, 0.25370
382, 0.25341
380, 0.25335
}

#declare RS_Lunar_Maria_5 = spline{ linear_spline
/*
Name: 12070.405
Type: Soil
Class: Lunar
Subclass: Maria
Particle Size: Fine
Sample No.: 12070.405
Owner: JHU
Wavelength range: IR
Origin: Apollo 12 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This is an extra sample from the Apollo 12 mare site.  This sample 
has an intermediate exposure age compared to the other three soils from the 
Apollo 12 site (Is/FeO=47).
*/
760, 0.05436
751, 0.06231
742, 0.06987
734, 0.07668
726, 0.08293
718, 0.08844
710, 0.09350
702, 0.09823
694, 0.10246
687, 0.10632
680, 0.10925
673, 0.11115
666, 0.11182
659, 0.11266
652, 0.11357
646, 0.11454
640, 0.11541
633, 0.11571
627, 0.11611
621, 0.11653
615, 0.11803
609, 0.12000
604, 0.12084
598, 0.12383
593, 0.12757
587, 0.13204
582, 0.13580
577, 0.13925
572, 0.14117
567, 0.14211
562, 0.14420
557, 0.14695
552, 0.14846
548, 0.14885
543, 0.14860
538, 0.14858
534, 0.14824
530, 0.14915
525, 0.15117
521, 0.15417
517, 0.15757
513, 0.16115
509, 0.16440
505, 0.16788
501, 0.17174
497, 0.17567
493, 0.18039
490, 0.18467
486, 0.18848
482, 0.19202
479, 0.19534
475, 0.19837
472, 0.20154
468, 0.20498
465, 0.20755
462, 0.20997
458, 0.21186
455, 0.21354
452, 0.21482
449, 0.21557
446, 0.21614
443, 0.21658
440, 0.21717
437, 0.21717
434, 0.21766
431, 0.21810
428, 0.21854
425, 0.21846
422, 0.21873
420, 0.21846
417, 0.21832
414, 0.21809
412, 0.21804
409, 0.21795
406, 0.21787
404, 0.21756
401, 0.21748
399, 0.21716
396, 0.21670
394, 0.21671
392, 0.21614
389, 0.21575
387, 0.21546
385, 0.21486
382, 0.21428
380, 0.21364
}

#declare RS_Lunar_Transitional_1  = spline{ linear_spline
/*
Name: 14141.146
Type: Soil
Class: Lunar
Subclass: Transitional
Particle Size: Fine
Sample No.: 14141.146
Owner: JHU
Wavelength range: IR
Origin: Apollo 14 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils at the Apollo 14 site 
representing major element chemistry transitional between the highlands and 
maria.  It has the least exposure age of the three soils of that suite 
((Is/FeO=6).
*/
760, 0.03845
751, 0.04447
742, 0.05095
734, 0.05717
726, 0.06299
718, 0.06848
710, 0.07364
702, 0.07824
694, 0.08265
687, 0.08662
680, 0.08977
673, 0.09191
666, 0.09328
659, 0.09492
652, 0.09690
646, 0.09892
640, 0.09996
633, 0.09976
627, 0.09937
621, 0.09987
615, 0.10187
609, 0.10449
604, 0.10749
598, 0.11043
593, 0.11654
587, 0.12300
582, 0.12805
577, 0.13184
572, 0.13501
567, 0.13662
562, 0.13909
557, 0.14328
552, 0.14528
548, 0.14639
543, 0.14706
538, 0.14921
534, 0.15119
530, 0.15261
525, 0.15492
521, 0.15842
517, 0.16212
513, 0.16760
509, 0.17316
505, 0.17829
501, 0.18347
497, 0.18886
493, 0.19509
490, 0.20097
486, 0.20620
482, 0.21186
479, 0.21723
475, 0.22211
472, 0.22697
468, 0.23267
465, 0.23792
462, 0.24361
458, 0.24852
455, 0.25275
452, 0.25626
449, 0.25868
446, 0.26093
443, 0.26279
440, 0.26446
437, 0.26609
434, 0.26835
431, 0.27056
428, 0.27304
425, 0.27393
422, 0.27616
420, 0.27641
417, 0.27703
414, 0.27801
412, 0.27852
409, 0.27936
406, 0.28008
404, 0.28082
401, 0.28122
399, 0.28195
396, 0.28260
394, 0.28301
392, 0.28322
389, 0.28353
387, 0.28413
385, 0.28425
382, 0.28459
380, 0.28468
}

#declare RS_Lunar_Transitional_2  = spline{ linear_spline
/*
Name: 14148.183
Type: Soil
Class: Lunar
Subclass: Transitional
Particle Size: Fine
Sample No.: 14148.183
Owner: JHU
Wavelength range: IR
Origin: Apollo 14 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils at the Apollo 14 site 
representing major element chemistry transitional between the highlands and 
maria.  It has the greatest exposure age of the three soils of that suite 
(Is/FeO=74).
*/
760, 0.04286
751, 0.05025
742, 0.05798
734, 0.06500
726, 0.07134
718, 0.07727
710, 0.08308
702, 0.08785
694, 0.09258
687, 0.09686
680, 0.10011
673, 0.10267
666, 0.10434
659, 0.10645
652, 0.10852
646, 0.11059
640, 0.11150
633, 0.11202
627, 0.11283
621, 0.11358
615, 0.11541
609, 0.11776
604, 0.11992
598, 0.12300
593, 0.12768
587, 0.13264
582, 0.13677
577, 0.14037
572, 0.14319
567, 0.14477
562, 0.14707
557, 0.14990
552, 0.15217
548, 0.15330
543, 0.15417
538, 0.15613
534, 0.15824
530, 0.16020
525, 0.16230
521, 0.16554
517, 0.16904
513, 0.17390
509, 0.17874
505, 0.18357
501, 0.18796
497, 0.19254
493, 0.19760
490, 0.20200
486, 0.20615
482, 0.21028
479, 0.21434
475, 0.21797
472, 0.22149
468, 0.22521
465, 0.22868
462, 0.23229
458, 0.23512
455, 0.23769
452, 0.23962
449, 0.24071
446, 0.24243
443, 0.24329
440, 0.24429
437, 0.24476
434, 0.24576
431, 0.24672
428, 0.24745
425, 0.24771
422, 0.24850
420, 0.24856
417, 0.24854
414, 0.24877
412, 0.24868
409, 0.24884
406, 0.24892
404, 0.24896
401, 0.24857
399, 0.24885
396, 0.24894
394, 0.24873
392, 0.24845
389, 0.24804
387, 0.24808
385, 0.24722
382, 0.24712
380, 0.24679
}

#declare RS_Lunar_Transitional_3  = spline{ linear_spline
/*
Name: 14149.18
Type: Soil
Class: Lunar
Subclass: Transitional
Particle Size: Fine
Sample No.: 14149.18
Owner: JHU
Wavelength range: IR
Origin: Apollo 14 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of soils at the Apollo 14 site 
representing major element chemistry transitional between the highlands and 
maria.  It has an intermediate exposure age of the three soils of that suite 
(Is/FeO=53).
*/
760, 0.04272
751, 0.05003
742, 0.05733
734, 0.06439
726, 0.07110
718, 0.07692
710, 0.08271
702, 0.08768
694, 0.09228
687, 0.09656
680, 0.09996
673, 0.10249
666, 0.10441
659, 0.10614
652, 0.10841
646, 0.11063
640, 0.11174
633, 0.11153
627, 0.11238
621, 0.11282
615, 0.11457
609, 0.11737
604, 0.11943
598, 0.12304
593, 0.12785
587, 0.13303
582, 0.13807
577, 0.14207
572, 0.14540
567, 0.14701
562, 0.14951
557, 0.15277
552, 0.15509
548, 0.15639
543, 0.15755
538, 0.15962
534, 0.16169
530, 0.16391
525, 0.16632
521, 0.16939
517, 0.17321
513, 0.17814
509, 0.18326
505, 0.18803
501, 0.19288
497, 0.19753
493, 0.20288
490, 0.20750
486, 0.21199
482, 0.21636
479, 0.22101
475, 0.22474
472, 0.22839
468, 0.23274
465, 0.23679
462, 0.24081
458, 0.24434
455, 0.24727
452, 0.24975
449, 0.25142
446, 0.25270
443, 0.25418
440, 0.25532
437, 0.25621
434, 0.25751
431, 0.25880
428, 0.25965
425, 0.26036
422, 0.26091
420, 0.26103
417, 0.26148
414, 0.26148
412, 0.26144
409, 0.26175
406, 0.26205
404, 0.26204
401, 0.26202
399, 0.26223
396, 0.26214
394, 0.26207
392, 0.26190
389, 0.26167
387, 0.26156
385, 0.26118
382, 0.26088
380, 0.26046
} 

#declare RS_Lunar_Transitional_4  = spline{ linear_spline
/*
Name: 14259.61
Type: Soil
Class: Lunar
Subclass: Transitional
Particle Size: Fine
Sample No.: 14259.61
Owner: JHU
Wavelength range: IR
Origin: Apollo 14 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description: The Apollo 14 site represents major element chemistry transitional 
between the highlands and maria.  This sample is an additional sample to the 
suite of soils  from this site selected to represent different exposure ages of 
the same basic soil.  The exposure age of this soil is very great (Is/FeO=85).
*/
760, 0.04156
751, 0.04907
742, 0.05652
734, 0.06338
726, 0.07014
718, 0.07602
710, 0.08144
702, 0.08616
694, 0.09085
687, 0.09515
680, 0.09856
673, 0.10087
666, 0.10275
659, 0.10473
652, 0.10678
646, 0.10884
640, 0.10998
633, 0.11035
627, 0.11046
621, 0.11132
615, 0.11337
609, 0.11567
604, 0.11822
598, 0.12094
593, 0.12586
587, 0.13055
582, 0.13478
577, 0.13788
572, 0.14003
567, 0.14145
562, 0.14330
557, 0.14640
552, 0.14794
548, 0.14926
543, 0.15018
538, 0.15199
534, 0.15380
530, 0.15557
525, 0.15793
521, 0.16097
517, 0.16423
513, 0.16889
509, 0.17348
505, 0.17779
501, 0.18198
497, 0.18623
493, 0.19081
490, 0.19490
486, 0.19863
482, 0.20217
479, 0.20597
475, 0.20937
472, 0.21229
468, 0.21570
465, 0.21860
462, 0.22165
458, 0.22401
455, 0.22612
452, 0.22769
449, 0.22897
446, 0.22979
443, 0.23083
440, 0.23142
437, 0.23207
434, 0.23274
431, 0.23360
428, 0.23452
425, 0.23442
422, 0.23522
420, 0.23444
417, 0.23437
414, 0.23442
412, 0.23404
409, 0.23418
406, 0.23421
404, 0.23401
401, 0.23398
399, 0.23390
396, 0.23372
394, 0.23333
392, 0.23291
389, 0.23278
387, 0.23229
385, 0.23164
382, 0.23118
380, 0.23078
}

#declare RS_Lunar_Highlands_1  = spline{ linear_spline
/*
Name: 60051.19
Type: Soil
Class: Lunar
Subclass: Highlands
Particle Size: Fine
Sample No.: 60051.19
Owner: JHU
Wavelength range: IR
Origin: Apollo 16 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of relatively more aluminous and 
lower iron and titanium soils at the Apollo 16 site, and has the second oldest 
exposure age of the four soils of that suite (Is/FeO=57).
*/
760, 0.03503
751, 0.04205
742, 0.04963
734, 0.05673
726, 0.06331
718, 0.06997
710, 0.07541
702, 0.08058
694, 0.08529
687, 0.08866
680, 0.09160
673, 0.09489
666, 0.09688
659, 0.09952
652, 0.10227
646, 0.10473
640, 0.10682
633, 0.10670
627, 0.10739
621, 0.10880
615, 0.11054
609, 0.11277
604, 0.11490
598, 0.11958
593, 0.12772
587, 0.13583
582, 0.14413
577, 0.15148
572, 0.15671
567, 0.16022
562, 0.16435
557, 0.16856
552, 0.16873
548, 0.16848
543, 0.16977
538, 0.17488
534, 0.18107
530, 0.18550
525, 0.19144
521, 0.19728
517, 0.20318
513, 0.21069
509, 0.21767
505, 0.22364
501, 0.23066
497, 0.23769
493, 0.24440
490, 0.25110
486, 0.25743
482, 0.26336
479, 0.26866
475, 0.27328
472, 0.27897
468, 0.28481
465, 0.28942
462, 0.29641
458, 0.30322
455, 0.30860
452, 0.31294
449, 0.31588
446, 0.31803
443, 0.31912
440, 0.31999
437, 0.32204
434, 0.32483
431, 0.32799
428, 0.33186
425, 0.33388
422, 0.33633
420, 0.33580
417, 0.33629
414, 0.33680
412, 0.33697
409, 0.33722
406, 0.33747
404, 0.33756
401, 0.33773
399, 0.33788
396, 0.33791
394, 0.33784
392, 0.33738
389, 0.33710
387, 0.33714
385, 0.33637
382, 0.33603
380, 0.33492
} 

#declare RS_Lunar_Highlands_2  = spline{ linear_spline
/*
Name: 61221.79
Type: Soil
Class: Lunar
Subclass: Highlands
Particle Size: Fine
Sample No.: 61221.79
Owner: JHU
Wavelength range: IR
Origin: Apollo 16 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of relatively more aluminous and 
lower iron and titanium soils at the Apollo 16 site, and has the lowest exposure age 
of the four soils of that suite (Is/FeO=10).
*/
760, 0.03698
751, 0.04428
742, 0.05184
734, 0.05930
726, 0.06649
718, 0.07290
710, 0.07857
702, 0.08339
694, 0.08806
687, 0.09172
680, 0.09536
673, 0.09846
666, 0.09995
659, 0.10269
652, 0.10593
646, 0.10910
640, 0.11125
633, 0.11101
627, 0.11285
621, 0.11404
615, 0.11544
609, 0.11778
604, 0.11849
598, 0.12478
593, 0.13335
587, 0.14233
582, 0.15203
577, 0.16133
572, 0.16819
567, 0.17210
562, 0.17738
557, 0.18159
552, 0.18249
548, 0.18199
543, 0.18390
538, 0.19003
534, 0.19655
530, 0.20214
525, 0.20886
521, 0.21552
517, 0.22295
513, 0.23224
509, 0.24049
505, 0.24797
501, 0.25685
497, 0.26557
493, 0.27428
490, 0.28321
486, 0.29165
482, 0.29985
479, 0.30697
475, 0.31358
472, 0.32158
468, 0.33021
465, 0.33749
462, 0.34727
458, 0.35704
455, 0.36501
452, 0.37168
449, 0.37716
446, 0.38083
443, 0.38333
440, 0.38567
437, 0.38907
434, 0.39355
431, 0.39872
428, 0.40470
425, 0.40883
422, 0.41258
420, 0.41393
417, 0.41571
414, 0.41713
412, 0.41817
409, 0.41910
406, 0.42032
404, 0.42107
401, 0.42201
399, 0.42263
396, 0.42313
394, 0.42392
392, 0.42416
389, 0.42457
387, 0.42493
385, 0.42479
382, 0.42493
380, 0.42484
}

#declare RS_Lunar_Highlands_3  = spline{ linear_spline
/*
Name: 61241.98
Type: Soil
Class: Lunar
Subclass: Highlands
Particle Size: Fine
Sample No.: 61241.98
Owner: JHU
Wavelength range: IR
Origin: Apollo 16 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of relatively less aluminous soils 
at the Apollo 16 site, and has an intermediate exposure age of the three soils of that 
suite (Is/FeO=47).
*/
760, 0.04479
751, 0.05239
742, 0.05992
734, 0.06704
726, 0.07373
718, 0.07999
710, 0.08579
702, 0.09073
694, 0.09512
687, 0.09899
680, 0.10211
673, 0.10447
666, 0.10584
659, 0.10716
652, 0.10968
646, 0.11187
640, 0.11295
633, 0.11309
627, 0.11447
621, 0.11562
615, 0.11696
609, 0.11921
604, 0.11961
598, 0.12445
593, 0.12990
587, 0.13579
582, 0.14200
577, 0.14799
572, 0.15224
567, 0.15469
562, 0.15846
557, 0.16145
552, 0.16346
548, 0.16358
543, 0.16488
538, 0.16736
534, 0.16971
530, 0.17261
525, 0.17643
521, 0.18095
517, 0.18607
513, 0.19174
509, 0.19731
505, 0.20245
501, 0.20813
497, 0.21393
493, 0.22025
490, 0.22639
486, 0.23183
482, 0.23684
479, 0.24189
475, 0.24642
472, 0.25126
468, 0.25634
465, 0.26062
462, 0.26566
458, 0.27020
455, 0.27390
452, 0.27691
449, 0.27911
446, 0.28101
443, 0.28217
440, 0.28338
437, 0.28445
434, 0.28646
431, 0.28836
428, 0.29016
425, 0.29126
422, 0.29256
420, 0.29303
417, 0.29325
414, 0.29355
412, 0.29373
409, 0.29392
406, 0.29428
404, 0.29424
401, 0.29444
399, 0.29442
396, 0.29453
394, 0.29442
392, 0.29404
389, 0.29395
387, 0.29375
385, 0.29335
382, 0.29277
380, 0.29266
}

#declare RS_Lunar_Highlands_4  = spline{ linear_spline
/*
Name: 62231.15
Type: Soil
Class: Lunar
Subclass: Highlands
Particle Size: Fine
Sample No.: 62231.15
Owner: JHU
Wavelength range: IR
Origin: Apollo 16 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  Chemistry is not available for this extra sample, but it appears 
to be one of the relatively less aluminous soils at the Apollo 16 site from its 
spectrum (i.e., it resembles suite 16b samples, such as 67941, 61241, and 68501), but 
has a very great exposure age (Is/FeO=91).
*/
760, 0.03637
751, 0.04394
742, 0.05136
734, 0.05858
726, 0.06541
718, 0.07162
710, 0.07724
702, 0.08249
694, 0.08710
687, 0.09105
680, 0.09396
673, 0.09678
666, 0.09884
659, 0.10133
652, 0.10430
646, 0.10707
640, 0.10914
633, 0.10991
627, 0.11133
621, 0.11286
615, 0.11433
609, 0.11648
604, 0.11843
598, 0.12330
593, 0.13031
587, 0.13761
582, 0.14489
577, 0.15133
572, 0.15614
567, 0.15937
562, 0.16341
557, 0.16713
552, 0.16812
548, 0.16844
543, 0.17005
538, 0.17467
534, 0.18007
530, 0.18415
525, 0.18944
521, 0.19479
517, 0.20060
513, 0.20750
509, 0.21396
505, 0.21986
501, 0.22658
497, 0.23293
493, 0.23941
490, 0.24571
486, 0.25163
482, 0.25724
479, 0.26216
475, 0.26671
472, 0.27190
468, 0.27720
465, 0.28163
462, 0.28738
458, 0.29304
455, 0.29722
452, 0.30079
449, 0.30354
446, 0.30577
443, 0.30681
440, 0.30800
437, 0.30962
434, 0.31208
431, 0.31436
428, 0.31688
425, 0.31863
422, 0.32003
420, 0.32062
417, 0.32124
414, 0.32174
412, 0.32194
409, 0.32204
406, 0.32251
404, 0.32266
401, 0.32281
399, 0.32301
396, 0.32305
394, 0.32310
392, 0.32270
389, 0.32255
387, 0.32233
385, 0.32179
382, 0.32113
380, 0.32041
}

#declare RS_Lunar_Highlands_5  = spline{ linear_spline
/*
Name: 64801.34
Type: Soil
Class: Lunar
Subclass: Highlands
Particle Size: Fine
Sample No.: 64801.34
Owner: JHU
Wavelength range: IR
Origin: Apollo 16 landing site via the NASA Lunar Sample Repository at Johnson 
Space Center, Houston, TX.
Description:  This sample is one of a suite of relatively more aluminous soils 
at the Apollo 16 site, and has the oldest exposure age of the four soils of that 
suite (Is/FeO=78).
*/
760, 0.03987
751, 0.04840
742, 0.05682
734, 0.06474
726, 0.07216
718, 0.07909
710, 0.08518
702, 0.09085
694, 0.09597
687, 0.09969
680, 0.10331
673, 0.10697
666, 0.10925
659, 0.11186
652, 0.11519
646, 0.11794
640, 0.12008
633, 0.12067
627, 0.12247
621, 0.12406
615, 0.12569
609, 0.12853
604, 0.12996
598, 0.13590
593, 0.14322
587, 0.15092
582, 0.15921
577, 0.16698
572, 0.17273
567, 0.17620
562, 0.18074
557, 0.18431
552, 0.18576
548, 0.18604
543, 0.18824
538, 0.19305
534, 0.19865
530, 0.20331
525, 0.20884
521, 0.21437
517, 0.22071
513, 0.22794
509, 0.23515
505, 0.24139
501, 0.24832
497, 0.25522
493, 0.26205
490, 0.26852
486, 0.27441
482, 0.28006
479, 0.28526
475, 0.28991
472, 0.29500
468, 0.30059
465, 0.30497
462, 0.31065
458, 0.31597
455, 0.32007
452, 0.32360
449, 0.32628
446, 0.32821
443, 0.32943
440, 0.33081
437, 0.33215
434, 0.33425
431, 0.33625
428, 0.33824
425, 0.33985
422, 0.34083
420, 0.34165
417, 0.34217
414, 0.34252
412, 0.34272
409, 0.34283
406, 0.34326
404, 0.34317
401, 0.34332
399, 0.34364
396, 0.34360
394, 0.34335
392, 0.34291
389, 0.34245
387, 0.34208
385, 0.34157
382, 0.34079
380, 0.33996
}

//=============================================================

#macro rspd_lunar_Release()
  #undef RS_Lunar_Maria_1
  #undef RS_Lunar_Maria_2
  #undef RS_Lunar_Maria_3
  #undef RS_Lunar_Maria_4
  #undef RS_Lunar_Maria_5
  #undef RS_Lunar_Transitional_1
  #undef RS_Lunar_Transitional_2
  #undef RS_Lunar_Transitional_3
  #undef RS_Lunar_Transitional_4
  #undef RS_Lunar_Highlands_1
  #undef RS_Lunar_Highlands_2
  #undef RS_Lunar_Highlands_3
  #undef RS_Lunar_Highlands_4
  #undef RS_Lunar_Highlands_5
  #undef rspd_lunar_Inc_Temp
#end   

//=============================================================
       
#end // eof
