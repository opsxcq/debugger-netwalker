; this is the data segment for NWDebugger (Net Walker! Debugger)


.DATA

;**************************************
;***     SOME GENERAL HANDLERS      ***
;/************************************\

hInst		DD	0
hMain		DD	0

; control handles
hEXECUTE	DD	0
hBREAKPOINT	DD	0
hCONTINUE	DD	0
hPATCH		DD	0
hTERMINATE	DD	0
hDEBUGCHILD	DD	0
hSUSPEND	DD	0
hDUMP		DD	0

;**************************************
;***           STRINGS              ***
;/************************************\

szTitle		DB 	"NW Debugger",0
szClassName	DB	"NWCLASS",0
Filter1 	DB	"Executable Files (*.exe)",0,"*.exe",0,"All Files",0,"*.*",0,0
Filter2		DB	"All Files", 0, "*.*", 0, 0
szPathName1	DB	MAX_PATH dup(0)
szPathName2	DB	MAX_PATH dup(0)
szSeparator	DB	95 dup ("-"), 0
szProcCreated	DB	"Process Created", 0
szProcHandle	DB	"Handle:		%08X", 0
szProcID	DB	"Process ID:	%08X", 0
szThreadID	DB	"Thread ID:	%08X", 0
szImageBase	DB	"Image Base:	0x%08X", 0
szStartAddress	DB	"Start Address:	0x%08X", 0
szImageName	DB	"Image Name:	%s", 0
szProcExited	DB	"Process exited with code %d", 0
szException	DB	"Exception <0x%08X> at address 0x%08X", 0 
szBreakPoint	DB	"BreakPoint at 0x%08X", 0
szUserBreak	DB	"User Breakpoint at 0x%08X",0
szDllLoaded1	DB	"%s loaded at 0x%08X", 0
szDllLoaded2	DB	"DLL loaded at 0x%08X", 0
szDebugEvent	DB	"Debug Event.  	Code <%X>.", 0
szSuspended	DB	"Process suspended by user",0
szUnhandExcept	DB	"Unhandled Exception.  Process Terminated.",0
szTerminated	DB	"Debugging Terminated.",0
szProcThrdID	DB	"  (ProcessID: %08X	ThreadID: %08X)",0
szHex		DB	"%X",0
szSet		DB	"Set",0
szRemove	DB	"Remove",0
szDumpOK	DB	"Memory dumped to file <%s>",0
DataBuffer	DB	50 dup (0)
StrBuffer	DB	250 dup (0)

; Error Messages
szCProcError	DB	"Error Creating Process.", 0
szAllocError	DB	"Error allocating memory to Debug Message buffer", 0
szOpenProcError	DB	"Error getting handle to Process ID %08X", 0
szVirtProtError	DB	"Cannot change memory flag on address 0x%08X", 0
szWriteError	DB	"Error writing to address 0x%08X", 0
szReadError	DB	"Error reading address 0x%08X", 0
szErrorCode	DB	"Error code <%d>", 0
szErrorGetCont	DB	"Error getting thread context", 0
szErrorSetCont	DB	"Error setting thread context", 0
szInvalidFName	DB	"Invalid File Name", 0
szInvalidFSize	DB	"Invalid File Size", 0

;**************************************
;***           STRUCTURES           ***
;/************************************\

wc		WNDCLASSEX		<0>
msg		MSG			<0>	
OFN		OPENFILENAME 		<0>
MemoryInfo	MEMORY_BASIC_INFORMATION <0>
StartupInfo	STARTUPINFO		<0>
ProcessInfo	PROCESS_INFORMATION	<0>
DebugEvent	DEBUG_EVENT	<0>
ALIGN  4		; Thread_Contexts must begin at addresses dword aligned
ThreadContext	CONTEXT	<CONTEXT_CONTROL,0>
DebThreadContext	CONTEXT <CONTEXT_CONTROL, 0>

;**************************************
;***            OTHERS              ***
;/************************************\

g_hPatchDlg	DD	0
g_hBreakDlg	DD	0
g_hDumpDlg	DD	0
ThreadID	DD	0
ThreadHwnd	DD	0
DebugMsgSize	DD	0
BufferAddr	DD	0
ProcessCounter	DD	0
OldMemFlag	DD	0
BKP		DB	0CCh
BreakAddress	DD	0
BreakOrigData	DB	0
ProcessArray:
ProcessID	DD	0
DebThreadHwnd	DD	0
		DB	9*8
ProcArraySize	EQU	8
