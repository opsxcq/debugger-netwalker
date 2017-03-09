.386P
.MODEL		FLAT, STDCALL
.CODE
;-----------------------------------------------------------------------------
AboutDlg proc    hAbout:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	cmp	wmsg, WM_INITDIALOG
	mov 	eax, TRUE
	jz	Return	
	cmp	wmsg, WM_COMMAND
	jnz	Default
	cmp	word ptr [wparam], IDOK
	jz 	AboutEnd
	cmp	word ptr [wparam], IDCANCEL
	jnz 	Default
AboutEnd:
	call	EndDialog, hAbout, TRUE
	mov	eax, TRUE
	jmp	Return
Default:
      	mov     eax, FALSE       
Return:
      ret                     
AboutDlg endp
;-----------------------------------------------------------------------------
