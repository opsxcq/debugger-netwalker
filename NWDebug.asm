; Simple Debug Model
; Net Walker! / Brazil
; Version 0.3 (alpha)
; May, 14th - 1998
; Please, report any bugs or comments to lnwalker@hotmail.com
; Built with TASM 5.0
;
; You can use this source code as a learning tool. It will introduce you to 
; the basics of Win32 Debug API.  Its a very simple code that can be easily
; upgraded to a Dynamic Patcher, Tracers, PE Unpackers an so on.  I also hope
; you can use this program as a model for building Win32 GUI in pure assembly.
; 
; As you will see, I have implemented a very crude Memory Patcher.
; I will wait for suggestions regarding a nicer and more usefull interface.
; The "Patch" can be used to read/write any process (even one not being 
; debugged - you must provide a Process ID - use Windows NT Task Manager or
; any other system info application).
;
; If you use this in another project, please, I'd be very happy to see my
; nickname in your Credits.
; You CANNOT use these sources to comercial projects.   If you really want to 
; make money, you MUST send a percentage to a local or international
; Ecological/Pro-Child/Anti-Poorness/etc Non-Governamental Organization.
;
; I'd like to acknowledge Stone/UCF.  He is one of the best crackers in 
; the world and one of the few that releases source code to us, mere mortals.
; I also wants to thanks to Fravia, Lord Caligo, Mammon, IceMan and NaTzGUL for
; their unvaluable contribution to the spread of pure and applied Knowledge 
; to the reverse-enginnering community.

; You will found more information on Fravia site:
; a)	WIN32 - Inside Debug API - http://fravia.org/Iceman1.htm
; b)	Extending NuMega' sofIce for Windows 95 using Protected Mode
;		Debugger services API - http://fravia.org/iceext1.txt
; c)	How to access memory of a process - http://fravia.org/natz_mp2.htm
; d)	Tweaking with memory in Window95 - http://fravia.org/Iceman.htm
; e)	In memory patching: three approaches - http://fravia.org/stone1.htm
;	

.386P
LOCALS
JUMPS
.MODEL FLAT, STDCALL			 

UNICODE = 0			; Used in w32.inc
INCLUDE W32.inc			; Windows definitions, messages, errors, structures,
				; API functions declarations, and so on.  Very usefull.
				; Thanks to Barry Kauler and Sven Schreiber.  Modified
				; by Net Walker!
INCLUDE		RESOURCE.ASH

EXTRN	wsprintf	: PROC	; This function can receive variable number of
				; parameters.  Then, its difficult to declare
				; it on W32.INC.  You must empty the stack
				; after calling it.

INCLUDE		NWDEBUG-DATA.ASM	; data segment

.CODE

;**********************************************************
;******		      INITIALIZATION                 ******
;/********************************************************\

start:

; First of all, get the Module Handle
; we'll not use it, but its a good practice to keep it for future use

	call 	GetModuleHandle, NULL
	mov	hInst, eax

; initialize the WndClass (Window Class) structure 
; Actually, we'll get the window class from a DIALOG resource (with CLASS directive)

	mov	wc.wc_cbSize, WNDCLASSEX_
	mov	wc.wc_style, CS_HREDRAW + CS_VREDRAW 
	mov	wc.wc_lpfnWndProc, offset WinMain
	mov	wc.wc_cbClsExtra, 0
	mov	wc.wc_cbWndExtra, DLGWINDOWEXTRA	; necessary to use a DialogBox as
							; an window class
	mov	eax, hInst
	mov	wc.wc_hInstance, eax

; load main icon from resource
	call 	LoadIcon, hInst, IDI_ICON1
	mov	wc.wc_hIcon, eax
	mov	wc.wc_hIconSm, eax
; load a default cursor
  	call 	LoadCursor,NULL, IDC_ARROW
	mov	wc.wc_hCursor, eax
	
	mov	wc.wc_hbrBackground, COLOR_BACKGROUND
	mov	wc.wc_lpszMenuName, NULL
	mov	wc.wc_lpszClassName, offset szClassName

  	call 	RegisterClassEx, offset wc

; create main window
	call	CreateDialogParam, hInst, offset szClassName, 0, NULL, 0
	mov	hMain, eax

; get child control handles
	call	GetDlgItem, hMain, IDC_EXECUTE
	mov	hEXECUTE, eax
	call	GetDlgItem, hMain, IDC_BREAKPOINT
	mov	hBREAKPOINT, eax
	call	GetDlgItem, hMain, IDC_CONTINUE
	mov	hCONTINUE, eax
	call	GetDlgItem, hMain, IDC_PATCH
	mov	hPATCH, eax
	call	GetDlgItem, hMain, IDC_TERMINATE
	mov	hTERMINATE, eax
	call	GetDlgItem, hMain, IDC_DEBUGCHILD
	mov	hDEBUGCHILD, eax
	call	GetDlgItem, hMain, IDC_SUSPEND
	mov	hSUSPEND, eax
	call	GetDlgItem, hMain, IDC_DUMP
	mov	hDUMP, eax

; get command line
	call	AdjustCommandLine
; allocate memory for Debug Messages editbox buffer
	call	VirtualAlloc, BufferAddr, 32768, MEM_COMMIT, PAGE_READWRITE
	test	eax, eax
	jz	AllocError
	mov	BufferAddr, eax
	jmp	msg_loop
AllocError:
	call	ShowErrorMsg, offset szAllocError
	call	ExitProcess, 0

;**********************************************************
;******		       MESSAGE LOOP                  ******
;/********************************************************\

msg_loop:
    	call 	GetMessage, offset msg, 0,0,0
	cmp	ax, 0
        je      end_loop
	call	IsDialogMessage, hMain, offset msg	; put this if you want to let the 
	cmp	eax, TRUE				; system handle TAB, ENTER, etc
	jz	msg_loop

    	call 	TranslateMessage, offset msg
    	call 	DispatchMessage, offset msg
	jmp	msg_loop

end_loop:
    call 	ExitProcess, msg.ms_wParam

;**********************************************************
;******		         WINMAIN                     ******
;/********************************************************\

WinMain PROC USES ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	
	cmp	wmsg, WM_DESTROY
	jz	wmdestroy
	cmp	wmsg, WM_COMMAND
	jz	wmcommand
	call 	DefWindowProc, hwnd,wmsg,wparam,lparam
	jmp 	finish
;----------------------------------------------------------------
wmcommand: 
@@1:	cmp	word ptr [wparam], IDC_EXECUTE
	jnz	@@2
	call	DebugFile
	jmp	finish
@@2:	cmp	word ptr [wparam], IDC_BROWSE
	jnz	@@3
	call	OpenDialog
	jmp	finish
@@3:	cmp	word ptr [wparam], IDC_CONTINUE
	jnz	@@4
	call	ResumeThread, DebThreadHwnd
	call	ResumeThread, ThreadHwnd
	call	EnableWindow, hCONTINUE, FALSE	; adjust for resuming
	call	EnableWindow, hSUSPEND, TRUE	; suspended process
	jmp	finish
@@4:	cmp	word ptr [wparam], IDCANCEL
	jnz	@@5
	call	ExitProcess, 0
@@5:	cmp	word ptr [wparam], IDM_ABOUT
	jnz	@@6
	call    DialogBoxParam, hInst, IDD_ABOUT, hMain, offset AboutDlg, 0
	jmp	finish
@@6:	cmp	word ptr [wparam], IDC_TERMINATE
	jnz	@@7
	call	TerminateThread, ThreadHwnd, -1	; Kill thread containing debugged process
	call	AddLine, offset szTerminated
	call	AdjustForDebugExit	; adjust controls for exiting debugging mode
	jmp	finish
@@7:	cmp	word ptr [wparam], IDC_PATCH
	jnz	@@8
	call    DialogBoxParam, hInst, IDD_PATCHDLG, hMain, offset PatchDlg, 0
	jmp	finish
@@8:	cmp	word ptr [wparam], IDC_BREAKPOINT
	jnz	@@9
	call    DialogBoxParam, hInst, IDD_SETBREAKPOINT, hMain, offset BreakDlg, 0
	jmp	finish	
@@9:	cmp	word ptr [wparam], IDC_SUSPEND
	jnz 	@@10
	call	SuspendThread, DebThreadHwnd	; suspend main debugged thread
	call	AddLine, offset szSuspended
	call	AdjustForSuspend
	jmp	finish
@@10:	cmp	word ptr [wparam], IDC_DUMP
	jnz	@@11
	call	DialogBoxParam, hInst, IDD_DUMPDLG, hMain, offset DumpDlg, 0
@@11:
	jmp	finish    
;----------------------------------------------------------------
wmdestroy:
; Free Debug message buffer
	call	VirtualFree, BufferAddr, 32768, MEM_DECOMMIT	
        call    PostQuitMessage, 0
        mov     eax, 0
        jmp     finish
;----------------------------------------------------------------
finish:
	ret
WinMain 	ENDP


;**********************************************************
;******		     SPECIFIC FUNCTIONS              ******
;/********************************************************\

;-----------------------------------------------------------------------------
AddLine		PROC	LineToAdd: DWORD
	LOCAL	LineLength:DWORD
; ths function add one line to Debugger Messages box
	push 	eax ebx ecx edx esi edi
; get length of line
	call	StrLen, LineToAdd
	mov	LineLength, eax
		
CopyLine:
; copy line to the end of allocated memory 	
	mov	edi, BufferAddr
	add	edi, DebugMsgSize
	mov	esi, LineToAdd
	mov	ecx, LineLength
	push	ecx
	shr	ecx, 2
	cld
	rep	movsd
	pop	ecx
	and 	ecx, 3
	rep	movsb
	mov	dword ptr [edi], 00000A0Dh
	mov	eax, LineLength
	add	DebugMsgSize, eax
	add	DebugMsgSize, 2		; for the CR/LF
; updates control text
	call	SetDlgItemText, hMain, IDC_DEBUGBOX, BufferAddr
	call	SendDlgItemMessage, hMain, IDC_DEBUGBOX, EM_GETLINECOUNT, 0, 0
	dec 	eax
	call	SendDlgItemMessage, hMain, IDC_DEBUGBOX, EM_LINESCROLL, 0, eax
EndAL:
	pop 	edi esi edx ecx ebx eax
	ret

AddLine		ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
DebugFile	PROC
	pushad
; clear some variables
	mov	DebugMsgSize, 0
	mov	ProcessCounter, 0
	mov	BreakAddress, 0
; Get FilePath from EditBox
	call	GetDlgItemText, hMain, IDC_FILE, offset szPathName1, MAX_PATH
	cmp	eax, 0
	jz	@@InvalidNFileName
; fill some StartUpInfo fields (only si_cb is enough for now)
	mov	StartupInfo.si_cb, STARTUPINFO_
; create thread to handle Debug loop
	call	CreateThread, NULL, 0, offset DebugThread, 0, 0, offset ThreadID
	mov	ThreadHwnd, eax
	jmp	EndDF
@@InvalidNFileName:
	call	ShowErrorMsg, offset szInvalidFName
EndDF:
	popad
	ret
DebugFile	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
DebugThread	PROC	Parameter:DWORD
	push	ebx ecx edx esi edi
; verify if needs to debug child processes
	call	SendDlgItemMessage, hMain, IDC_DEBUGCHILD, BM_GETCHECK, 0, 0
	cmp	eax, BST_CHECKED
	jz	DebugChild
	call	CreateProcess, NULL, offset szPathName1, NULL, NULL, FALSE, DEBUG_ONLY_THIS_PROCESS+NORMAL_PRIORITY_CLASS, NULL, NULL, offset StartupInfo, offset ProcessInfo
	jmp	ProcessCreated
DebugChild:
	call	CreateProcess, NULL, offset szPathName1, NULL, NULL, FALSE, DEBUG_PROCESS+NORMAL_PRIORITY_CLASS, NULL,	NULL, offset StartupInfo, offset ProcessInfo
ProcessCreated:
	cmp	eax, TRUE
	jnz	ErrorCreatingProcess
; clear Debug Messages edit box
	call	SetDlgItemText, hMain, IDC_DEBUGBOX, NULL
	call	AddLine, offset szPathName1

;---------------
DebugLoop:
	call	WaitForDebugEvent, offset DebugEvent, INFINITE
	cmp	DebugEvent.de_dwDebugEventCode, CREATE_PROCESS_DEBUG_EVENT
	jz	CreateProcessEvent 

	cmp	DebugEvent.de_dwDebugEventCode, EXIT_PROCESS_DEBUG_EVENT
	jz	ExitProcessEvent

	cmp	DebugEvent.de_dwDebugEventCode, EXCEPTION_DEBUG_EVENT
	jz	ExceptionEvent

	cmp	DebugEvent.de_dwDebugEventCode, LOAD_DLL_DEBUG_EVENT
	jz	LoadDllEvent

; Unhandled Debug Event
	call	wsprintf, offset StrBuffer, offset szDebugEvent, DebugEvent.de_dwDebugEventCode
	add	esp, 12
	call	AddLine, offset StrBuffer
	jmp	ReturnProcess
;---------------
CreateProcessEvent:
; save ProcessID and Main Thread Handle of process
	lea	esi, ProcessArray
	mov	eax, ProcessCounter
	cmp	eax, 10
	jae	ShowProcInfo		; we'll save just 10 process data
	mov	ecx, ProcArraySize
	mul	ecx
	add	esi, eax
	mov	eax, DebugEvent.de_dwProcessId
	mov	dword ptr [esi], eax
	mov	eax, DebugEvent.de_U.cpdi_hThread
	mov	dword ptr [esi+4], eax
	mov	eax, DebugEvent.de_U.cpdi_hThread
	mov	dword ptr [esi+8], eax
ShowProcInfo:
	call	ShowProcessInfo
	inc	ProcessCounter
; adjust controls
	call	EnableWindow, hEXECUTE, FALSE
	call	EnableWindow, hTERMINATE, TRUE
	call	EnableWindow, hSUSPEND, TRUE
	call	EnableWindow, hDEBUGCHILD, FALSE
	call	EnableWindow, hPATCH, TRUE
	call	EnableWindow, hBREAKPOINT, TRUE
	call	EnableWindow, hDUMP, TRUE

	jmp 	ReturnProcess
;---------------
ExitProcessEvent:
	call	wsprintf, offset StrBuffer, offset szProcExited, dword ptr DebugEvent.de_U
	add	esp, 12
	call	AddLine, offset StrBuffer
	call	ShowIDs
	call	ContinueDebugEvent, DebugEvent.de_dwProcessId, DebugEvent.de_dwThreadId, DBG_CONTINUE
	call	AdjustProcessArray
	dec	ProcessCounter
	cmp	ProcessCounter, 0
	jnz	ReturnProcess
	call	AdjustForDebugExit
	call	ExitThread, 0
;---------------
ExceptionEvent:
; is exception a Breakpoint?
	cmp	DebugEvent.de_U.ExceptionRecord.ExceptionCode, EXCEPTION_BREAKPOINT
	jz	ShowInfo
; does the user wants to see exception info?
	call	SendDlgItemMessage, hMain, IDC_FAULTSOFF, BM_GETCHECK, 0, 0
	cmp	eax, BST_CHECKED
	jnz	ShowInfo
	cmp	DebugEvent.de_U.dwFirstChance, 0
	jz	TerminateDebugging
	cmp	DebugEvent.de_U.ExceptionRecord.ExceptionFlags, EXCEPTION_NONCONTINUABLE
	jnz	ContinueProcess

TerminateDebugging:
	call	AddLine, offset szUnhandExcept
	call	AdjustForDebugExit
	call	ExitThread, -1	; exit thread since there is a unhandled exception

ShowInfo:
	call	ShowExceptionInfo
	jmp	SuspendProcess		; Exceptions will stop the debugger
					; even if "Dont stop..." option is checked
;---------------
LoadDllEvent:
	call	ShowDllInfo
	jmp	ReturnProcess
;---------------
ReturnProcess:
	call	SendDlgItemMessage, hMain, IDC_STOPONALL, BM_GETCHECK, 0, 0
	cmp	eax, BST_CHECKED
	jnz	ContinueProcess
SuspendProcess:
	call	AdjustForSuspend
	call	MessageBeep, -1
	call	SuspendThread, ThreadHwnd	; pause debugging for user action
ContinueProcess:
	call	ContinueDebugEvent, DebugEvent.de_dwProcessId, DebugEvent.de_dwThreadId, DBG_CONTINUE
	jmp 	DebugLoop
;---------------
ErrorCreatingProcess:
	call	ShowErrorMsg, offset szCProcError
	call	ExitThread, 0		
;---------------
	pop	ebp edi esi edx ecx ebx
	ret	
DebugThread	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ShowProcessInfo		PROC
	pushad
	call	AddLine, offset szSeparator
	call	AddLine, offset szProcCreated
; Show Process ImageName (if it exists)
	mov 	ebx, DebugEvent.de_U.lddi_lpImageName
	call	IsBadStringPtr, ebx, MAX_PATH 
	cmp	eax, TRUE
	jz	@@ContinueInfo
	cmp	byte ptr [ebx], 0
	jz	@@ContinueInfo
	call	wsprintf, offset StrBuffer, offset szImageName, dword ptr [ebx]
	add	esp, 12
	call	AddLine, offset StrBuffer
@@ContinueInfo:
; show Process Handle
	call	wsprintf, offset StrBuffer, offset szProcHandle, DebugEvent.de_U.cpdi_hProcess
	add	esp, 12
	call	AddLine, offset StrBuffer
; show Process ID
	call	wsprintf, offset StrBuffer, offset szProcID, DebugEvent.de_dwProcessId
	add	esp, 12
	call	AddLine, offset StrBuffer
; show Primary Thread ID
	call	wsprintf, offset StrBuffer, offset szThreadID, DebugEvent.de_dwThreadId
	add	esp, 12
	call	AddLine, offset StrBuffer
; Show Process Image Base
	call	wsprintf, offset StrBuffer, offset szImageBase, DebugEvent.de_U.cpdi_lpBaseOfImage
	add	esp, 12
	call	AddLine, offset StrBuffer
; Show Process Start Address	
	call	wsprintf, offset StrBuffer, offset szStartAddress, DebugEvent.de_U.cpdi_lpStartAddress
	add	esp, 12
	call	AddLine, offset StrBuffer
	call	AddLine, offset szSeparator
	popad
	ret
ShowProcessInfo		ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ShowExceptionInfo	PROC	; also handles user breakpoint
	LOCAL	DebThreadHandle:DWORD
	pushad
; is a breakpoint exception?
	cmp	DebugEvent.de_U.ExceptionRecord.ExceptionCode, 80000003h
	jnz	UndeterminedException
; is there any set breakpoint?
	cmp	BreakAddress, 0
	jz	NotUserBreak
	mov	eax, DebugEvent.de_U.ExceptionRecord.ExceptionAddress
; is this our own breakpoint?
	cmp	BreakAddress, eax
	jnz	NotUserBreak


;******************************
;****  BreakPoint Handler  ****
;******************************

	call	wsprintf, offset StrBuffer, offset szUserBreak, DebugEvent.de_U.ExceptionRecord.ExceptionAddress
	add	esp, 12
	call	AddLine, offset StrBuffer
; remove breakpoint
	call	RemoveBreakpoint, DebugEvent.de_dwProcessId, DebugEvent.de_U.ExceptionRecord.ExceptionAddress
; get debugged thread handle
	call	GetThreadHandle, DebugEvent.de_dwProcessId
	mov	DebThreadHandle, eax
; get ThreadContext and store it to our structure
	call	GetThreadContext, DebThreadHandle, offset DebThreadContext
	cmp	eax, FALSE
	jz	GetThreadContextError
; return one byte (decrease EIP)
	dec	DebThreadContext.cx_Eip
	mov	DebThreadContext.cx_ContextFlags, CONTEXT_CONTROL
; set thread context with our new EIP
	call	SetThreadContext, DebThreadHandle, offset DebThreadContext
	cmp	eax, FALSE
	jz	SetThreadContextError
	jmp	EndSEI
NotUserBreak:
	call	wsprintf, offset StrBuffer, offset szBreakPoint, DebugEvent.de_U.ExceptionRecord.ExceptionAddress
	add	esp, 12
	call	AddLine, offset StrBuffer
	jmp	EndSEI
UndeterminedException:
	call	wsprintf, offset StrBuffer, offset szException, DebugEvent.de_U.ExceptionRecord.ExceptionCode, DebugEvent.de_U.ExceptionRecord.ExceptionAddress
	add	esp, 16
	call	AddLine, offset StrBuffer
	jmp	EndSEI
GetThreadContextError:
	call	ShowErrorMsg, offset szErrorGetCont
	jmp	EndSEI
SetThreadContextError:
	call	ShowErrorMsg, offset szErrorSetCont
EndSEI:
; show Process ID and Thread ID if necessary
	call	ShowIDs
	popad
	ret
ShowExceptionInfo	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ShowDllInfo		PROC
	pushad
	mov 	ebx, DebugEvent.de_U.lddi_lpImageName
	call	IsBadStringPtr, ebx, MAX_PATH 
	cmp	eax, TRUE
	jz	@@Info2
	cmp	byte ptr [ebx], 0
	jz	@@Info2
	call	wsprintf, offset StrBuffer, offset szDllLoaded1, dword ptr [ebx], DebugEvent.de_U.lddi_lpBaseOfDll
	add	esp, 16
	jmp	@@ShowString
@@Info2:
	call	wsprintf, offset StrBuffer, offset szDllLoaded2, DebugEvent.de_U.lddi_lpBaseOfDll
	add	esp, 12
@@ShowString:
	call	AddLine, offset StrBuffer
; show Process ID and Thread ID if necessary
	call	ShowIDs
	popad
	ret
ShowDllInfo		ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ReadMemory	PROC	RProcID:DWORD, RAddress:DWORD, RDataOff:DWORD, RSize:DWORD
	LOCAL	DebProcessHwnd:DWORD
	push	ebx ecx edx esi edi
; get process handle with PROCESS_ALL_ACCESS flag.
; This would not be necessary, since we created this process (consequently 
; we already have complete access to the debugged process).  We are using 
; the function "GetProcessHandle" in order to be able to read/write to any 
; process running on the computer.
	call	GetProcessHandle, RProcID
	cmp	eax, FALSE
	jz	GetReadHandleError
	mov	DebProcessHwnd, eax
; read from memory
	call	ReadProcessMemory, DebProcessHwnd, RAddress, RDataOff, RSize, NULL 
	cmp	eax, FALSE
	jz	ReadError
; Flush Instruction Cache
	call	FlushInstructionCache, DebProcessHwnd, RAddress, RSize
	mov	eax, TRUE
	jmp	EndRead
GetReadHandleError:
	call	wsprintf, offset StrBuffer, offset szOpenProcError, RProcID
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	mov	eax, FALSE
	jmp	EndRead
ReadError:
	call	wsprintf, offset StrBuffer, offset szReadError, RAddress
	add	esp, 12
	call 	ShowErrorMsg, offset StrBuffer
	mov	eax, FALSE
EndRead:
	push	eax
	call	CloseHandle, DebProcessHwnd	; close Process Handle
	pop	eax
	pop	edi esi edx ecx ebx
	ret
ReadMemory	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
WriteMemory	PROC	WProcID:DWORD, WAddress:DWORD, WDataOff:DWORD, WSize
	LOCAL	DebProcessHwnd:DWORD
	pushad
; get process handle
	call	GetProcessHandle, WProcID
	cmp	eax, FALSE
	jz	GetWriteHandleError
	mov	DebProcessHwnd, eax
; write to memory
	call	WriteProcessMemory, DebProcessHwnd, WAddress, WDataOff, WSize, NULL
	cmp	eax, FALSE
	jz	WriteError
	call	FlushInstructionCache, DebProcessHwnd, WAddress, WSize
	mov	eax, TRUE
	jmp	EndWrite
GetWriteHandleError:
	call	wsprintf, offset StrBuffer, offset szOpenProcError, WProcID
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	mov	eax, FALSE
	jmp	EndWrite
WriteError:
	call	wsprintf, offset StrBuffer, offset szWriteError, WAddress
	add	esp, 12
	call 	ShowErrorMsg, offset StrBuffer
	mov	eax, FALSE
EndWrite:
	push	eax
	call	CloseHandle, DebProcessHwnd
	pop	eax
	popad
	ret
WriteMemory	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
GetProcessHandle	PROC	GProcID:DWORD
	push	ebx ecx edx esi edi
; get a process handle
	call	OpenProcess, PROCESS_ALL_ACCESS, FALSE, GProcID
	test	eax, eax
	jz	OpenProcessError
	jmp	EndGPH
OpenProcessError:
	mov	eax, FALSE
EndGPH:
	pop	edi esi edx ecx ebx
	ret
GetProcessHandle	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
GetThreadHandle	PROC	GProcID:DWORD
	push	ecx esi
	lea	esi, ProcessID
	mov	ecx, ProcessCounter
GetThreadHwnd:
	mov	eax, dword ptr [esi]
	cmp	eax, GProcID
	jz	ProcFound
	add	esi, 8
	loop	GetThreadHwnd
	mov	eax, FALSE
	jmp	EndGTH
ProcFound:
	mov	eax, dword ptr [esi+4]
EndGTH:
	pop	esi ecx
	ret
GetThreadHandle	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
SetBreakpoint	PROC	BProcID:DWORD, BAddress:DWORD
	push	ebx ecx edx esi edi
; read original data to DataBuffer
	call	ReadMemory, BProcID, BAddress, offset DataBuffer, 1
	cmp	eax, FALSE
	jz	EndSBKP
; write CCh to address
	call	WriteMemory, BProcID, BAddress, offset BKP, 1
	cmp	eax, FALSE
	jz	EndSBKP
; set variables
	mov	eax, BAddress
	mov	BreakAddress, eax	; store breakpoint address
	mov	al, byte ptr DataBuffer
	mov	BreakOrigData, al	; store original byte
	mov	eax, TRUE
EndSBKP:
	pop	edi esi edx ecx ebx
	ret
SetBreakpoint	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
RemoveBreakpoint	PROC	RBProcID:DWORD, RBAddress
	push	ebx ecx edx esi edi
; read byte at address
	call	ReadMemory, RBProcID, RBAddress, offset DataBuffer, 1
	cmp	eax, FALSE
	jz	EndRBKP
; verify if have a breakpoint
	cmp	byte ptr DataBuffer, 0CCh
	jnz	ClearVariables
; write original data
	call	WriteMemory, RBProcID, RBAddress, offset BreakOrigData, 1
	cmp	eax, FALSE
	jz	EndRBKP
ClearVariables:
	mov	BreakAddress, 0
	mov	BreakOrigData, 0
EndRBKP:
	pop	edi esi edx ecx ebx
	ret 
RemoveBreakpoint	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
DumpMemory	PROC	ProcID:DWORD, MemAddr:DWORD, FileOff:DWORD, FileSize:DWORD
	LOCAL	MMFAddress:DWORD
	push	ebx ecx edx esi edi
; check if Filename is empty
	mov	eax, FileOff
	cmp	byte ptr [eax], 0
	jz	@@ReturnError
; check if filesize is zero
	cmp	FileSize, 0
	jz	@@ReturnError
; create memory mapped file
	call	MakeMappedFile, 0, FileOff, FileSize, CREATE_ALWAYS
	cmp	eax, FALSE
	jz	EndDM
	mov	MMFAddress, eax
; read memory to MMFAddress
	call	ReadMemory, ProcID, MemAddr, MMFAddress, FileSize
	push	eax	; store return value
; close (and flush) memory mapped file
	call	EndMappedFile, 0
	pop	eax	
	jmp	EndDM
@@ReturnError:
	mov	eax, FALSE
EndDM:
	pop	edi esi edx ecx ebx
	ret
DumpMemory	ENDP
;-----------------------------------------------------------------------------



;-----------------------------------------------------------------------------
ShowIDs		PROC
	pushad
; verify if the user wants to see ProcessID and ThreadID
	call	SendDlgItemMessage, hMain, IDC_SHOWID, BM_GETCHECK, 0, 0
	cmp	eax, BST_CHECKED
	jnz	EndSID
	call	wsprintf, offset StrBuffer, offset szProcThrdID, DebugEvent.de_dwProcessId, DebugEvent.de_dwThreadId
	add	esp, 16
	call	AddLine, offset StrBuffer
EndSID:
	popad
	ret
ShowIDs		ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
AdjustForSuspend	PROC
	push	eax edx
	call	EnableWindow, hSUSPEND, FALSE
	call	EnableWindow, hCONTINUE, TRUE
	pop	edx eax
	ret
AdjustForSuspend	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
AdjustForDebugExit	PROC
	push	eax edx
	call	EnableWindow, hEXECUTE, TRUE
	call	EnableWindow, hTERMINATE, FALSE
	call	EnableWindow, hCONTINUE, FALSE
	call	EnableWindow, hPATCH, FALSE
	call	EnableWindow, hBREAKPOINT, FALSE
	call	EnableWindow, hDEBUGCHILD, TRUE
	call	EnableWindow, hSUSPEND, FALSE
	call	EnableWindow, hDUMP, FALSE
	pop	edx eax
	ret
AdjustForDebugExit	ENDP
;-----------------------------------------------------------------------------


;------------------------------------------------------------------------------
AdjustProcessArray		PROC
	pushad
	popad
	ret
AdjustProcessArray		ENDP

;------------------------------------------------------------------------------

INCLUDE 	FUNCT.ASM
INCLUDE		ABOUT.ASM
INCLUDE 	PATCH.ASM
INCLUDE		BREAK.ASM
INCLUDE		DUMP.ASM

ends
end start
