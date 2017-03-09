; some general use windows functions
; by Net Walker! 1997-1998


.386P
.MODEL		FLAT, STDCALL
.CODE

;------------------------------------------------------------------------
AdjustCommandLine	PROC
	push	eax ecx esi edi
	call	GetCommandLine
; parse the command line - we want just the parameters
	mov	edi, eax
	call	StrLen, edi
	mov 	al,20h
	repnz 	scasb
	repz 	scasb
	test	ecx,ecx
	jz	EndGCL
	dec 	edi	

; adjust edit box text to command line parameter
	call	SetDlgItemText, hMain, IDC_FILE, edi
	
EndGCL:
	pop	edi esi ecx eax
	ret
AdjustCommandLine	ENDP
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
OpenDialog	PROC
	push	eax
; Fill OPENFILENAME Structure (OFN)
	mov	OFN.on_lStructSize, OPENFILENAME_
	mov	eax, hMain
	mov	OFN.on_hwndOwner, eax
	mov    	eax, hInst
	mov	OFN.on_hInstance, eax
	mov	OFN.on_lpstrFilter, offset Filter1
	mov 	OFN.on_lpstrFile, offset szPathName1
	mov	OFN.on_nMaxFile, MAX_PATH-1
	mov 	OFN.on_Flags, OFN_PATHMUSTEXIST+ OFN_FILEMUSTEXIST + OFN_HIDEREADONLY
	call    GetOpenFileName, offset OFN
	cmp	eax, FALSE
	jz	EndOD
; Change EditBox text
	call	SetDlgItemText, hMain, IDC_FILE, offset szPathName1
EndOD:
	pop	eax
	ret
OpenDialog	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
SaveDialog	proc

; Fill OPENFILENAME Structure (OFN)
	mov	OFN.on_lStructSize, OPENFILENAME_
	mov	eax, hMain
	mov	OFN.on_hwndOwner, eax
	mov    	eax, hInst
	mov	OFN.on_hInstance, eax
	mov	OFN.on_lpstrFilter, OFFSET Filter2
	mov 	OFN.on_lpstrFile, OFFSET szPathName2
	mov	OFN.on_nMaxFile, MAX_PATH-1
	mov 	OFN.on_Flags, OFN_HIDEREADONLY+OFN_OVERWRITEPROMPT
	call    GetSaveFileName, offset OFN
	ret
SaveDialog	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ShowErrorMsg	PROC	ErrorText:DWORD
	push 	eax
	call	MessageBeep, -1
	call	MessageBox, hMain, ErrorText, offset szTitle, MB_ICONHAND
	pop	eax
	ret
ShowErrorMsg	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
StrLen	PROC	StrOffset:DWORD
	push 	esi
	mov	esi,	StrOffset
	xor	eax, eax
@@LoopInit:
	cmp	byte ptr [esi],0
	jz	@FoundZero
	inc	eax
	inc 	esi
	jmp	@@LoopInit
@FoundZero:	
	pop	esi
	ret
StrLen	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
ShowErrorCode	PROC
	pushad
	call	GetLastError
	test	eax, eax
	jz	EndSEC
	call	wsprintf, offset StrBuffer, offset szErrorCode, eax
	add	esp, 12
	call	MessageBeep, -1
	call	MessageBox, NULL, offset StrBuffer, offset szTitle, MB_ICONHAND
EndSEC:
	popad
	ret
ShowErrorCode	ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
HexToInt	PROC	StringOffset:DWORD	; from Stone's API
	pushf
	push ebx ecx edi esi ebp
	xor	eax, eax
	mov	esi, StringOffset
	call	StrLen, StringOffset
	test 	eax, eax
	jz	EndHTI
	mov	ecx, eax
	mov EBP, 10h
	xor eax, eax
	xor ebx, ebx

nextchar:
	xor edx, edx	
	imul ebx, ebx, 10h
      mul EBP
	add ebx, edx

	movzx edi, byte ptr [esi]	
	cmp edi, 40h
	jl number
	sub edi,7

number:
	add eax, edi
	adc ebx, 0	
	sub eax, 30h

	inc esi
	dec ecx
	jnz nextchar

	xchg edx, ebx
EndHTI:
	pop ebp esi edi ecx ebx 
	popf
	RET
	
HexToInt ENDP
;------------------------------------------------------------------------------

