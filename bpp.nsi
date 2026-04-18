; Include Modern UI

!include "MUI2.nsh"

Name "Bullet Physics Playground"
SetCompressor lzma

# Defines
!define REGKEY "SOFTWARE\$(^Name)" ;
!define VERSION 0.2.29
!define COMPANY "Jakob Flierl"
!define URL https://github.com/bullet-physics-playground

!define DLL C:\msys64\mingw64\bin

Caption "Bullet Physics Playground ${VERSION} Setup" 

BrandingText " � Jakob Flierl "

; The file to write
OutFile "bpp-${VERSION}-x64.exe"

; The default installation directory
InstallDir $PROGRAMFILES\bpp

InstallDirRegKey HKLM "Software\bpp" "Install_Dir"

RequestExecutionLevel admin

;Interface Configuration

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"
  !define MUI_ABORTWARNING

!insertmacro MUI_PAGE_LICENSE "License"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;Languages

  !insertmacro MUI_LANGUAGE "English"

; !include "FileAssociation.nsh"

Section "BPP (required)" ;
  
  SetShellVarContext all
  SetOverwrite on

  SectionIn RO

  SetOutPath $INSTDIR
  File "release\bpp.exe"
  File "QGLViewer2.dll"
  File "${DLL}\libdouble-conversion.dll"
  File "${DLL}\libgcc_s_seh-1.dll"
  File "${DLL}\libicuuc77.dll"
  File "${DLL}\libicuin77.dll"
  File "${DLL}\libpcre2*.dll"
  File "${DLL}\libstdc++-6.dll"
  File "${DLL}\Qt5Core.dll"
  File "${DLL}\Qt5OpenGL.dll"
  File "${DLL}\Qt5Gui.dll"
  File "${DLL}\Qt5Network.dll"
  File "${DLL}\Qt5Svg.dll"
  File "${DLL}\Qt5Widgets.dll"
  File "${DLL}\Qt5Xml.dll"
  File "${DLL}\lua51.dll"
  File "${DLL}\libassimp-*.dll"
  File "${DLL}\libbz2-*.dll"
  File "${DLL}\libiconv-*.dll"
  File "${DLL}\libBullet*.dll"
  File "${DLL}\libLinearMath.dll"
  File "${DLL}\libfreeglut.dll"
  File "${DLL}\libwinpthread-1.dll"
  File "${DLL}\SDL2.dll"
  File "${DLL}\libzstd.dll"
  File "${DLL}\libharfbuzz-*.dll"
  File "${DLL}\libmd4c.dll"
  File "${DLL}\libminizip-*.dll"
  File "${DLL}\libpng16-*.dll"

  WriteRegStr HKLM SOFTWARE\bpp "Install_Dir" "$INSTDIR"
  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "DisplayName" "bpp"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

SectionEnd

Section "Start Menu Shortcuts"

  SetShellVarContext all
  SetOverwrite on

  CreateDirectory "$SMPROGRAMS\bpp"
  CreateShortCut "$SMPROGRAMS\bpp\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\bpp\bpp.lnk" "$INSTDIR\bpp.exe" "" "$INSTDIR\bpp.exe" 0
  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  SetShellVarContext all
  SetOverwrite on

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp"
  DeleteRegKey HKLM SOFTWARE\bpp

  ; Remove files and uninstaller
  Delete $INSTDIR\bpp.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\bpp\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\bpp"
  RMDir "$INSTDIR"

SectionEnd
