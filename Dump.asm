.386P
.MODEL		FLAT, STDCALL

EXTRN	MakeMappedFile	: PROC
EXTRN	EndMappedFile	: PROC

.CODE
;-----------------------------------------------------------------------------
DumpDlg PROC    hDumpDlg:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	LOCAL	MemAddress:DWORD, ProcID:DWORD, FileSize:DWORD
	push	ebx ecx edx esi edi
	mov	eax, hDumpDlg
	mov	g_hDumpDlg, eax
	cmp	wmsg, WM_INITDIALOG
	jz	InitDumpDlg
	cmp	wmsg, WM_COMMAND
	jnz	DumpDefault

; *********
; WM_COMMAND messages
; *********
	cmp	word ptr [wparam], IDC_DBROWSE
	jz 	ChooseFile
	cmp	word ptr [wparam], IDC_DDUMP
	jz 	Dump
	cmp	word ptr [wparam], IDCANCEL
	jnz 	DumpDefault
LeaveDumpDlg:
	call	EndMappedFile, 0	; just in case
	call	EndDialog, g_hDumpDlg, TRUE
	jmp	DumpReturnTrue
;---------------------------
InitDumpDlg:
	call	DUpdateCombobox
	call	SendDlgItemMessage, g_hDumpDlg, IDC_DADDRESS, EM_SETLIMITTEXT, 9, 0
	call	SendDlgItemMessage, g_hDumpDlg, IDC_DSIZE, EM_SETLIMITTEXT, 12, 0
	mov	eax, TRUE
	jmp	DumpReturn
;---------------------------
ChooseFile:
	call	SaveDialog
	cmp	eax, FALSE
	jz	DumpReturn
	call	SetDlgItemText, g_hDumpDlg, IDC_DFILE, offset szPathName2
	jmp	DumpReturnTrue
;---------------------------
Dump:
; get ID of process to read
	call	GetDlgItemText, g_hDumpDlg, IDC_DPROCESSID, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	ProcID, eax
; get memory address to read
	call	GetDlgItemText, g_hDumpDlg, IDC_DADDRESS, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	MemAddress, eax
; get File name
	call	GetDlgItemText, g_hDumpDlg, IDC_DFILE, offset szPathName2, MAX_PATH-1
	cmp	eax, 0
	jz	@@InvalidFileName
; get File Size
	call	GetDlgItemInt, g_hDumpDlg, IDC_DSIZE, NULL, FALSE
	cmp	eax, 0
	jz	@@InvalidFileSize
	mov	FileSize, eax
; dump memory
	call	DumpMemory, ProcID, MemAddress, offset szPathName2, FileSize
	cmp	eax, FALSE
	jz	DumpReturnTrue
;---------------------------
	call	wsprintf, offset StrBuffer, offset szDumpOK, offset szPathName2
	add	esp, 12
	call	MessageBox, g_hDumpDlg, offset StrBuffer, offset szTitle, MB_OK
	jmp	DumpReturnTrue
;---------------------------
@@InvalidFileName:
	call	MessageBeep, -1
	call	MessageBox, g_hDumpDlg, offset szInvalidFName, offset szTitle, MB_ICONHAND
	mov	eax, FALSE
	jmp	EndDM
;---------------------------
@@InvalidFileSize:
	call	MessageBeep, -1
	call	MessageBox, g_hDumpDlg, offset szInvalidFSize, offset szTitle, MB_ICONHAND
	mov 	eax, FALSE
	jmp	EndDM
DumpReturnTrue:
	mov	eax, TRUE
	jmp	DumpReturn
;---------------------------
DumpDefault:
      	mov     eax, FALSE
;---------------------------
DumpReturn:
	pop	edi esi edx ecx ebx  
	ret
DumpDlg 	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
DUpdateCombobox	PROC
	pushad
; clear combobox
	call	SendDlgItemMessage, g_hDumpDlg, IDC_DPROCESSID, CB_RESETCONTENT, 0, 0
; fill combobox with ProcessID values
	lea	esi, ProcessID
	mov	ecx, ProcessCounter
DAddString:
	push	ecx	; most windows API functions do NOT preserve registers
; convert ProcessID dword -> hexadecimal string
	call	wsprintf, offset StrBuffer, offset szHex, dword ptr [esi]
	add	esp, 12
; add string to combobox
	call	SendDlgItemMessage, g_hDumpDlg, IDC_DPROCESSID, CB_ADDSTRING, 0, offset StrBuffer
	add	esi, ProcArraySize
	pop	ecx
	loop	DAddString
; select first item
	call	SendDlgItemMessage, g_hDumpDlg, IDC_DPROCESSID, CB_SETCURSEL, 0, 0
	popad
	ret
DUpdateCombobox	ENDP
;-----------------------------------------------------------------------------

