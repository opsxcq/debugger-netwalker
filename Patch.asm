.386P
.MODEL		FLAT, STDCALL
.CODE
;-----------------------------------------------------------------------------
PatchDlg PROC    hPatchDlg:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	LOCAL	MemAddress:DWORD, ProcID:DWORD
	push	ebx ecx edx esi edi
	mov	eax, hPatchDlg
	mov	g_hPatchDlg, eax
	cmp	wmsg, WM_INITDIALOG
	jz	InitPatchDlg
	cmp	wmsg, WM_COMMAND
	jnz	PatchDefault

; *********
; WM_COMMAND messages
; *********
	cmp	word ptr [wparam], IDC_READDATA
	jz 	Read
	cmp	word ptr [wparam], IDC_WRITEDATA
	jz 	Write
	cmp	word ptr [wparam], IDCANCEL
	jnz 	PatchDefault
LeavePatchDlg:
	call	EnableWindow, hPATCH, TRUE
	call	EndDialog, g_hPatchDlg, TRUE
	mov	eax, TRUE
	jmp	PatchReturn
;---------------------------
InitPatchDlg:
	call	PUpdateCombobox
	call	SendDlgItemMessage, g_hPatchDlg, IDC_PADDRESS, EM_SETLIMITTEXT, 9, 0
	call	SendDlgItemMessage, g_hPatchDlg, IDC_PDATA, EM_SETLIMITTEXT, 9, 0
	mov	eax, TRUE
	jmp	PatchReturn
;---------------------------
Read:
; get memory address to read
	call	GetDlgItemText, g_hPatchDlg, IDC_PADDRESS, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	MemAddress, eax
; get ID of process to read
	call	GetDlgItemText, g_hPatchDlg, IDC_PROCESSID, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	ProcID, eax
	call	ReadMemory, ProcID, MemAddress, offset DataBuffer, 1
	cmp	eax, FALSE
	jz	PatchReturnTrue
; update editbox
	movzx	eax, byte ptr DataBuffer	;show only the first byte 
	call	wsprintf, offset StrBuffer, offset szHex, eax
	add	esp, 12
	call	SetDlgItemText, g_hPatchDlg, IDC_PDATA, offset StrBuffer
	mov	eax, TRUE
	jmp	PatchReturn
;---------------------------
Write:
; get memory address to write
	call	GetDlgItemText, g_hPatchDlg, IDC_PADDRESS, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	MemAddress, eax
; get ID of process to write
	call	GetDlgItemText, g_hPatchDlg, IDC_PROCESSID, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	ProcID, eax
; get data to write
	call	GetDlgItemText, g_hPatchDlg, IDC_PDATA, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	byte ptr DataBuffer, al
	call	WriteMemory, ProcID, MemAddress, offset DataBuffer, 1
;---------------------------
PatchReturnTrue:
	mov	eax, TRUE
	jmp	PatchReturn
PatchDefault:
      	mov     eax, FALSE       
PatchReturn:
	pop	edi esi edx ecx ebx  
	ret
PatchDlg 	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
PUpdateCombobox	PROC
	pushad
; clear combobox
	call	SendDlgItemMessage, g_hPatchDlg, IDC_PROCESSID, CB_RESETCONTENT, 0, 0
; fill combobox with ProcessID values
	lea	esi, ProcessID
	mov	ecx, ProcessCounter
PAddString:
	push	ecx	; most windows API functions do NOT preserve registers
; convert ProcessID dword -> hexadecimal string
	call	wsprintf, offset StrBuffer, offset szHex, dword ptr [esi]
	add	esp, 12
; add string to combobox
	call	SendDlgItemMessage, g_hPatchDlg, IDC_PROCESSID, CB_ADDSTRING, 0, offset StrBuffer
	add	esi, ProcArraySize
	pop	ecx
	loop	PAddString
; select first item
	call	SendDlgItemMessage, g_hPatchDlg, IDC_PROCESSID, CB_SETCURSEL, 0, 0
	popad
	ret
PUpdateCombobox	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
PShowErrorMsg	PROC	PErrorMsgOffset:DWORD
	push	eax
	call	MessageBeep, -1
	call	MessageBox, g_hPatchDlg, PErrorMsgOffset, offset szTitle, MB_ICONHAND
	pop	eax
	ret
PShowErrorMsg	ENDP
;-----------------------------------------------------------------------------


