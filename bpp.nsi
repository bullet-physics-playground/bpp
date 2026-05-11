; Include Modern UI

!include "MUI2.nsh"

Name "Bullet Physics Playground"
SetCompressor /SOLID lzma

# Defines
!define REGKEY "SOFTWARE\$(^Name)"
!define VERSION "0.3.33"
!define COMPANY "Jakob Flierl"
!define URL "https://github.com/bullet-physics-playground"

!define DLL "C:\msys64\mingw64\bin"

Caption "Bullet Physics Playground ${VERSION} Setup" 

BrandingText " � Jakob Flierl "

; The file to write
OutFile "bpp-${VERSION}-win-x64.exe"

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

Section "BPP (required)"

  SetShellVarContext all

  SectionIn RO

  SetOutPath $INSTDIR
  File "release\bpp.exe"
  File "release\QGLViewer3.dll"
  File "${DLL}\libdouble-conversion.dll"
  File "${DLL}\libgcc_s_seh-1.dll"
  File "${DLL}\libicuuc7?.dll"
  File "${DLL}\libicuin7?.dll"
  File "${DLL}\libicudt7?.dll"
  File "${DLL}\libpcre2*.dll"
  File "${DLL}\libstdc++-?.dll"
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
  File "${DLL}\libwinpthread-1.dll"
  File "${DLL}\SDL2.dll"
  File "${DLL}\libzstd.dll"
  File "${DLL}\libharfbuzz-*.dll"
  File "${DLL}\libmd4c.dll"
  File "${DLL}\libminizip-*.dll"
  File "${DLL}\libpng16-*.dll"
  File "${DLL}\zlib1.dll"
  File "${DLL}\libfreetype-6.dll"
  File "${DLL}\libglib-2.0-?.dll"
  File "${DLL}\libgraphite?.dll"
  File "${DLL}\libintl-?.dll"
  File "${DLL}\libbrotlidec.dll"
  File "${DLL}\libbrotlicommon.dll"

  File /r "release\imageformats"
  File /r "release\iconengines"
  File /r "release\platforms"
  File /r "release\styles"
  File /r "release\translations"

  File /r "demo"
  File /r "includes"

  SetOutPath $INSTDIR

  WriteRegStr HKLM SOFTWARE\bpp "Install_Dir" "$INSTDIR"
  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "DisplayName" "bpp"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

SectionEnd

Section "Start Menu Shortcuts"

  SetShellVarContext all

  CreateDirectory "$SMPROGRAMS\bpp"
  CreateShortCut "$SMPROGRAMS\bpp\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\bpp\bpp.lnk" "$INSTDIR\bpp.exe" "" "$INSTDIR\bpp.exe" 0
  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  SetShellVarContext all

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\bpp"
  DeleteRegKey HKLM SOFTWARE\bpp

  Delete "$INSTDIR\bpp.exe"
  Delete "$INSTDIR\QGLViewer2.dll"
  Delete "$INSTDIR\libdouble-conversion.dll"
  Delete "$INSTDIR\libgcc_s_seh-1.dll"
  Delete "$INSTDIR\libicuuc77.dll"
  Delete "$INSTDIR\libicuin77.dll"
  Delete "$INSTDIR\libpcre2*.dll"
  Delete "$INSTDIR\libstdc++-6.dll"
  Delete "$INSTDIR\Qt5Core.dll"
  Delete "$INSTDIR\Qt5OpenGL.dll"
  Delete "$INSTDIR\Qt5Gui.dll"
  Delete "$INSTDIR\Qt5Network.dll"
  Delete "$INSTDIR\Qt5Svg.dll"
  Delete "$INSTDIR\Qt5Widgets.dll"
  Delete "$INSTDIR\Qt5Xml.dll"
  Delete "$INSTDIR\lua51.dll"
  Delete "$INSTDIR\libassimp-*.dll"
  Delete "$INSTDIR\libbz2-*.dll"
  Delete "$INSTDIR\libiconv-*.dll"
  Delete "$INSTDIR\libBullet*.dll"
  Delete "$INSTDIR\libLinearMath.dll"
  Delete "$INSTDIR\libwinpthread-1.dll"
  Delete "$INSTDIR\SDL2.dll"
  Delete "$INSTDIR\libzstd.dll"
  Delete "$INSTDIR\libharfbuzz-*.dll"
  Delete "$INSTDIR\libmd4c.dll"
  Delete "$INSTDIR\libminizip-*.dll"
  Delete "$INSTDIR\libpng16-*.dll"
  Delete "$INSTDIR\uninstall.exe"

  RMDir /r "$INSTDIR\imageformats"
  RMDir /r "$INSTDIR\iconengines"
  RMDir /r "$INSTDIR\platforms"
  RMDir /r "$INSTDIR\styles"
  RMDir /r "$INSTDIR\translations"

  Delete "$SMPROGRAMS\bpp\*.*"
  RMDir "$SMPROGRAMS\bpp"
  RMDir /r "$INSTDIR"

SectionEnd
