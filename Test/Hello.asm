.386P
LOCALS
JUMPS
.model FLAT, STDCALL
UNICODE=0
include w32.inc
	
.data
szTitle	DB	"Message",0
szHost		DB	"Child.exe",0
szCall		DB	"Press OK to Execute CHILD.EXE",0
szExit		DB	"Press OK to exit",0
szProcessError	DB	"Error creating process",0
StartupInfo	STARTUPINFO		<0>
ProcessInfo	PROCESS_INFORMATION	<0>
.code
start:
	call	MessageBox, NULL, offset szCall, offset szTitle, MB_OK
	call	CreateProcess, offset szHost, NULL, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, NULL,NULL, offset StartupInfo, offset ProcessInfo	
	cmp	eax, TRUE
	jnz	ErrorCreatingProcess
ExitMainProcess:
	call	MessageBox, NULL, offset szExit, offset szTitle, MB_OK
	call	ExitProcess, 0
ErrorCreatingProcess:
	call	MessageBeep, -1
	call	MessageBox, NULL, offset szProcessError, offset szTitle, MB_ICONHAND
	jmp	ExitMainProcess
ends
end start
