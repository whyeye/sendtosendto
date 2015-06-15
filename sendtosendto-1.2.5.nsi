; Unicode Warning (delete lines to compile for ASCII)
!if "${NSIS_PACKEDVERSION}" <= 0x2046000
    !error "Must compile with NSIS 3.0a0 (or later)"
!endif

; Definitions
!define VERSION "1.2.5.0"
!define NAME "sendtosendto"
;!define PUBSRC "1"
!packhdr "$%TEMP%\exehead.tmp" "upx.exe --best $%TEMP%\exehead.tmp"
 
Name "${NAME}"
Caption "${NAME}"
SubCaption 3 " "
SubCaption 4 " "
OutFile "sendtosendto.exe"
Unicode true
SetDatablockOptimize on
SetCompress force
SetCompressor /SOLID lzma
CRCCheck on
ShowInstDetails nevershow
AutoCloseWindow true
!ifndef PUBSRC
	ChangeUI all "ui\default.exe"
!endif
Icon "ui\default.ico"
InstallColors 000000 FFFFFF
InstProgressFlags colored smooth
RequestExecutionLevel user

; Variables
Var Parameter
Var Input
Var Extension
Var File
Var Directory
Var Name
Var Dialog
Var Text
Var TextState
Var Delete
Var AddHere
Var Create
Var Settings

; Translations
!include "inc\LanguageIDs.nsh"
!include "inc\translations.nsh"


; Inclusions
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"
!include "WordFunc.nsh"
	!insertmacro "WordReplace"
!include "FileFunc.nsh"
	!insertmacro "GetBaseName"
	!insertmacro "GetParent"
	!insertmacro "GetFileExt"
	!insertmacro "GetParameters"
  
; Version Information
VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "${NAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Jan T. Sott"
VIAddVersionKey "FileDescription" "Tool to easily add files/folders to the SendTo dialog"
VIAddVersionKey "Comments" "http://whyeye.org/projects/sendtosendto"

; Pages
Page Custom theUI theData
Page InstFiles

; Sections
Section
SectionEnd


; Functions
Function .onInit
	InitPluginsDir
	SetOutPath $PLUGINSDIR
	
	${If} ${AtLeastWin2000}
		StrCpy "$Settings" "$APPDATA\sendtosendto\settings.ini"
	${ElseIf} ${AtMostWinME}
		StrCpy "$Settings" "$EXEDIR\settings.ini"
	${EndIf}
	
	ReadINIStr $0 "$Settings" "Meta" "Language"
	${If} $0 != ""
		StrCpy $LANGUAGE "$0"
	${Else}
		StrCpy $LANGUAGE 1033
	${EndIf}
FunctionEnd

Function .onGUIInit
	ReadINIStr $AddHere "$Settings" "Dialogs" "AddHere"
	StrCmp $AddHere "" 0 postAddHere
	StrCpy "$AddHere" "$(AddHere)"
	StrCmp $AddHere "" 0 postAddHere
	StrCpy "$AddHere" "Add here"
	postAddHere:
	
	ReadINIStr $Create "$Settings" "Dialogs" "Create"
	StrCmp $Create "" 0 postCreate
	StrCpy "$Create" "$(Create)"
	StrCmp $Create "" 0 postCreate
	StrCpy "$Create" "Create"
	postCreate:
	
	${GetParameters} $Parameter

	StrCmp $Parameter "/help" HelpParameter
	StrCmp $Parameter "-help" HelpParameter
	StrCmp $Parameter "/?" HelpParameter
	StrCmp $Parameter "-?" HelpParameter
	StrCmp $Parameter "/install" InstallParameter
	StrCmp $Parameter "/uninstall" UninstallParameter
	StrCmp $Parameter "/dialogs" DialogsParameter
	StrCmp $Parameter "/manage" ManageParameter

	${WordReplace} $Parameter '"' "" "+" $Input
	IfFileExists "$Input" NoParameters
	${If} ${FileExists} "$EXEDIR\$Input"
		StrCpy "$Input" "$EXEDIR\$Input"
		IfFileExists "$Input" NoParameters
	${EndIf}
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "?ERROR: No input file specified" IDCANCEL NoParameters
	Quit

	HelpParameter:
	Var /GLOBAL Switches
	StrCpy $Switches "${NAME} ${VERSION} Switches:$\r$\n"
	StrCpy $Switches "$Switches$\r$\n/help$\tshows this dialog"
	StrCpy $Switches "$Switches$\r$\n/install$\tadd to SendTo folder"
	StrCpy $Switches "$Switches$\r$\n/uninstall$\tremove from SendTo folder"
	StrCpy $Switches "$Switches$\r$\n/dialogs$\tedit default dialogs"
	StrCpy $Switches "$Switches$\r$\n/manage$\tshow SendTo folder"
	StrCpy $Switches "$Switches$\r$\n$\r$\nbuilt with NSIS ${NSIS_VERSION}/${NSIS_MAX_STRLEN} [${__DATE__}]"
	MessageBox MB_ICONINFORMATION|MB_OK "$Switches"
	Quit

	InstallParameter:
	System::Call 'kernel32::GetModuleFileNameA(i 0, t .R0, i 1024) i r1'
	CreateShortCut "$SENDTO\ $AddHere.lnk" "$R0"
	WriteINIStr "$Settings" "Dialogs" "AddHere" "$AddHere"
	WriteINIStr "$Settings" "Dialogs" "Create" "$Create"
	
	SetFileAttributes "$EXEDIR\settings.ini" HIDDEN
	Quit

	UninstallParameter:
	ReadINIStr $0 "$Settings" "Dialogs" "AddHere"
	${If} ${FileExists} "$SENDTO\ $0.lnk"
		Delete "$SENDTO\ $0.lnk"
	${ElseIf} ${FileExists} "$SENDTO\ $AddHere.lnk"
		Delete "$SENDTO\ $AddHere.lnk"
	${EndIf}
	MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON1 "Do you want to review the entries in your SendTo folder?" IDNO +2
	ExecShell open "$SENDTO"
	Quit

	DialogsParameter:
	ReadINIStr $0 "$Settings" "Dialogs" "AddHere"
	ReadINIStr $1 "$Settings" "Dialogs" "Create"
	${If} $0 == ""
	${AndIf} $1 == ""
		WriteINIStr "$Settings" "Dialogs" "AddHere" ""
		WriteINIStr "$Settings" "Dialogs" "Create" ""
	${EndIf}
	ExecShell open "$Settings"
	Quit

	ManageParameter:
	ExecShell open "$SENDTO"
	Quit

	NoParameters:
	${GetFileExt} "$Input" "$Extension"
	${GetBaseName} "$Input" "$File"
	${GetParent} "$Input" "$Directory"

	${If} $File != ""
	${AndIf} $Extension != ""
		StrCpy $Name "$File.$Extension"
	${EndIf}
FunctionEnd


Function theUI
	nsDialogs::Create /NOUNLOAD 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}
	
	Var /GLOBAL Next
	GetDlgItem $Next $HWNDPARENT 1
	${NSD_SetText} $Next "$Create"

	${If} $Name != ""
		SendMessage $HWNDPARENT ${WM_SETTEXT} 0 "STR:${NAME} - [$Name]"
	${Else}
		SendMessage $HWNDPARENT ${WM_SETTEXT} 0 "STR:${NAME}"
		EnableWindow $Next 0
	${EndIf}
	
	${NSD_CreateText} 0 1u 188u 14u "$File"
	Pop $Text
	GetFunctionAddress $0 changeText
	nsDialogs::OnChange	/NOUNLOAD $Text $0
	
	${NSD_CreateButton} 192u 1u 12u 14u "×"
	Pop $Delete
	GetFunctionAddress $0 deleteButton
	nsDialogs::OnClick	/NOUNLOAD $Delete $0
	Call changeText
	
	nsDialogs::Show
FunctionEnd

Function changeText
	${NSD_GetText} $Text $0
	
	${If} $0 != ""
	${AndIf} $Name != ""
		EnableWindow $Next 1
	${Else}
		EnableWindow $Next 0
	${EndIf}
	
	${If} ${FileExists} "$SENDTO\$0.lnk"
	${AndIf} $0 != ""
	${AndIf} $Name != ""
		EnableWindow $Delete 1
	${Else}
		EnableWindow $Delete 0
	${EndIf}
FunctionEnd

Function deleteButton
	${NSD_GetText} $Text $0
	
	Delete "$SENDTO\$0.lnk"
	Call changeText
FunctionEnd

Function theData
	WriteINIStr "$Settings" "Meta" "Version" "${VERSION}"
	
	${NSD_GetText} $Text $TextState
	CreateShortCut "$SENDTO\$TextState.lnk" "$Input"
	
	Quit
FunctionEnd