.386P
.MODEL		FLAT, STDCALL
.CODE
;-----------------------------------------------------------------------------
BreakDlg PROC   hBreakDlg:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	LOCAL	MemAddress:DWORD, ProcID:DWORD
	push	ebx ecx edx esi edi
	mov	eax, hBreakDlg
	mov	g_hBreakDlg, eax
	cmp	wmsg, WM_INITDIALOG
	jz	InitBreakDlg
	cmp	wmsg, WM_COMMAND
	jnz	BreakDefault

; *********
; WM_COMMAND messages
; *********
	cmp	word ptr [wparam], IDC_SETBKP
	jz 	SetBreak
	cmp	word ptr [wparam], IDCANCEL
	jnz 	BreakDefault
LeaveBreakDlg:
	call	EndDialog, g_hBreakDlg, TRUE
	mov	eax, TRUE
	jmp	BreakReturn
;---------------------------
InitBreakDlg:
	call	BUpdateCombobox
	call	SendDlgItemMessage, g_hBreakDlg, IDC_PADDRESS, EM_SETLIMITTEXT, 9, 0
; update Button Name
	cmp	BreakAddress, 0
	jnz	SetRemove
; set "Set"
	call	SetDlgItemText, g_hBreakDlg, IDC_SETBKP, offset szSet
	jmp	BreakReturnTrue
SetRemove:
	call	SetDlgItemText, g_hBreakDlg, IDC_SETBKP, offset szRemove
	jmp	BreakReturnTrue
;---------------------------
SetBreak:
; get memory address to read
	call	GetDlgItemText, g_hBreakDlg, IDC_BADDRESS, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	MemAddress, eax
; get ID of process to read
	call	GetDlgItemText, g_hBreakDlg, IDC_BPROCESSID, offset StrBuffer, 9
	call	HexToInt, offset StrBuffer
	mov	ProcID, eax
; verify if will set or remove breakpoint
	cmp	BreakAddress, 0
	jz	SetBKP
; remove breakpoint
	call	RemoveBreakpoint, ProcID, MemAddress
	cmp	eax, TRUE
	jnz	BreakReturnTrue
	call	SetDlgItemText, g_hBreakDlg, IDC_SETBKP, offset szSet
	jmp	BreakReturnTrue
SetBKP:
	call	SetBreakpoint, ProcID, MemAddress
	cmp	eax, TRUE
	jnz	BreakReturnTrue
	call	SetDlgItemText, g_hBreakDlg, IDC_SETBKP, offset szRemove
	jmp	BreakReturnTrue
;---------------------------
BreakReturnTrue:
	mov 	eax, TRUE
	jmp	BreakReturn
;---------------------------
BreakDefault:
      	mov     eax, FALSE       
BreakReturn:
	pop	edi esi edx ecx ebx  
	ret
BreakDlg 	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
BShowErrorMsg	PROC	BErrorMsgOffset:DWORD
	push	eax
	call	MessageBeep, -1
	call	MessageBox, g_hBreakDlg, BErrorMsgOffset, offset szTitle, MB_ICONHAND
	pop	eax
	ret
BShowErrorMsg	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
BUpdateCombobox	PROC
	pushad
; clear combobox
	call	SendDlgItemMessage, g_hBreakDlg, IDC_BPROCESSID, CB_RESETCONTENT, 0, 0
; fill combobox with ProcessID values
	lea	esi, ProcessID
	mov	ecx, ProcessCounter
BAddString:
	push	ecx	; most windows API functions do NOT preserve registers
; convert ProcessID dword -> hexadecimal string
	call	wsprintf, offset StrBuffer, offset szHex, dword ptr [esi]
	add	esp, 12
; add string to combobox
	call	SendDlgItemMessage, g_hBreakDlg, IDC_BPROCESSID, CB_ADDSTRING, 0, offset StrBuffer
	add	esi, ProcArraySize
	pop	ecx
	loop	BAddString
; select first item
	call	SendDlgItemMessage, g_hBreakDlg, IDC_BPROCESSID, CB_SETCURSEL, 0, 0
	popad
	ret
BUpdateCombobox	ENDP
;-----------------------------------------------------------------------------
