; Include Modern UI

!include "MUI2.nsh"

Name "bullet-physics-playground"
SetCompressor lzma

# Defines
!define REGKEY "SOFTWARE\$(^Name)" ;
!define VERSION 1.0.1
!define COMPANY "Jakob Flierl"
!define URL https://github.com/koppi/bullet-physics-playground

!define QTDIR C:\Qt\4.8.4

Caption "Bullet Physics Playground ${VERSION} Setup"

BrandingText " © Jakob Flierl "

; The file to write
OutFile "setup-bpp-${VERSION}-win32.exe"

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

!include "FileAssociation.nsh"

Section "physics (required)" ;
  
  SetShellVarContext all
  SetOverwrite on

  SectionIn RO

  SetOutPath $INSTDIR
  File "C:\bullet-physics-playground\release\physics.exe"
  File "${QTDIR}\bin\QtCore4.dll"
  File "${QTDIR}\bin\QtOpenGL4.dll"
  File "${QTDIR}\bin\QtGui4.dll"
  File "${QTDIR}\bin\QtSvg4.dll"
  File "${QTDIR}\bin\QtXml4.dll"

  WriteRegStr HKLM SOFTWARE\physics "Install_Dir" "$INSTDIR"
  
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\physics" "DisplayName" "physics"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\physics" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\physics" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\physics" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

SectionEnd

Section "Start Menu Shortcuts"

  SetShellVarContext all
  SetOverwrite on

  CreateDirectory "$SMPROGRAMS\physics"
  CreateShortCut "$SMPROGRAMS\physics\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\physics\physics.lnk" "$INSTDIR\physics.exe" "" "$INSTDIR\physics.exe" 0
  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  SetShellVarContext all
  SetOverwrite on

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\physics"
  DeleteRegKey HKLM SOFTWARE\physics

  ; Remove files and uninstaller
  Delete $INSTDIR\physics.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\physics\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\physics"
  RMDir "$INSTDIR"

SectionEnd
