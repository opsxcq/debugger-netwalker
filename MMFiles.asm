; Memory Mapped Files Library - By Net Walker!
; November, 1997
; Revised on May, 1998 - First Public Version.

; lnwalker@hotmail.com

.386P
LOCALS
JUMPS
.MODEL FLAT, STDCALL
UNICODE=0
INCLUDE	W32.inc

PUBLIC	MakeMappedFile
PUBLIC	EndMappedFile
PUBLIC	MMSetFileSize
PUBLIC	MMGetFileHandle
PUBLIC	MMGetFileSize
PUBLIC	MMGetOriginalFileSize
PUBLIC	ShowErrorMsg
EXTRN	wsprintf	: PROC

MAX_FILES	EQU	5
DEFAULT_ACTION	EQU	OPEN_EXISTING


;---------------------------------------------------------------------------
.DATA

;***************************************************
DataBuffer:
FileHandle	DD	0
FileSize	DD	0
MemoryHandle	DD	0
MemoryAddress	DD	0
		DB	16*MAX_FILES dup(0)	; Space for 5 file parameters
;****************************************************
StrBuffer	DB	MAX_PATH dup(0)

; Error Messages
Caption		DB	"Error",0
ErrorMsg1	DB	"Cannot Open File <%s>",0
ErrorMsg2	DB	"File <%s> Not Found",0
ErrorMsg3	DB	"Cannot Create Memory Object For File <%s>",0
ErrorMsg4	DB	"Cannot Map View of File <%s>",0
ErrorMsg5	DB	"Invalid File Name",0
ErrorMsg6	DB	"Path For File <%s> Not Found ",0
ErrorMsg7	DB	"Invalid File ID", 0
ErrorMsg8	DB	"File ID already in use",0


;---------------------------------------------------------------------------
.CODE

MakeMappedFile	PROC	FileID:DWORD, \		; ID for the Mapped file
			FileNameOff:DWORD, \	; Pointer to file path+name
			FSize:DWORD, \		; Size for the file (if NULL, use current file size)
			Action:DWORD		; dwCreationDistribution (if NULL, use DEFAULT_ACTION)

	push	ebx ecx edx esi edi 
; verify if FileName is not empty
	mov	eax, FileNameOff
	cmp	byte ptr [eax], 0
	jz	@@InvalidFileName
	call	GetNewDataOffset, FileID		; get offset for storing file data
	cmp	eax, FALSE
	jz	@@ReturnError 
	mov	esi, eax
; verify if Action is NULL
	cmp	Action, 0
	jnz	@@CreateFile
	mov	Action, DEFAULT_ACTION	; if NULL, use DEFAULT_ACTION
;-------------------
@@CreateFile:				; open file
	call	CreateFile, FileNameOff, GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ + FILE_SHARE_WRITE, NULL, Action, FILE_ATTRIBUTE_NORMAL, 0 
	cmp 	eax, INVALID_HANDLE_VALUE
	jz	@@CreateFileError
	mov	dword ptr [esi+0], eax	; store FileHandle
; get Original FileSize
	call	GetFileSize, dword ptr [esi+0], NULL
	mov	[esi+4], eax	; store original file size

; verify if FileSize parameter is NULL (if NULL, use original file size)
	cmp	FSize, NULL
	jnz	@@CreateFileMapping
	mov	eax, dword ptr [esi+4]
	mov	FSize, eax		; use original file size
;-------------------
@@CreateFileMapping:			; create Memory Object
	call	CreateFileMapping, dword ptr [esi+0], NULL, PAGE_READWRITE, 0, FSize, NULL
	test	eax, eax
	jz	@@CreateFileMappingError
	mov	dword ptr [esi+8], eax	; store MemoryHandle
;-------------------
; map view of file
	call	MapViewOfFile, dword ptr [esi+8], FILE_MAP_WRITE + FILE_MAP_READ, 0, 0, 0
	test	eax, eax
	jz	@@MapViewOfFileError
; Memory Mapped File successfully created
	mov	dword ptr [esi+12], eax	; store MemoryAddress
	jmp	@@End		; we'll return the File Address on memory
;-------------------
@@InvalidFileName:
	call	ShowErrorMsg, offset ErrorMsg5
	jmp	@@ReturnError
;-------------------
@@CreateFileError:
	call 	GetLastError
	cmp	eax, ERROR_FILE_NOT_FOUND
	jnz	@@1
	call	wsprintf, offset StrBuffer, offset ErrorMsg2, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	jmp 	@@ReturnError
@@1:
	cmp	eax, ERROR_PATH_NOT_FOUND
	jnz	@@2
	call	wsprintf, offset StrBuffer, offset ErrorMsg6, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	jmp	@@ReturnError	
@@2:	
	call	wsprintf, offset StrBuffer, offset ErrorMsg1, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	jmp	@@ReturnError
;-------------------
@@CreateFileMappingError:
	call	EndMappedFile, FileID
	call	wsprintf, offset StrBuffer, offset ErrorMsg3, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	jmp	@@ReturnError
;-------------------
@@MapViewOfFileError:
	call	EndMappedFile, FileID
	call	wsprintf, offset StrBuffer, offset ErrorMsg4, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
;-------------------
@@ReturnError:
	mov	eax, FALSE
;-------------------
@@End:
	pop	edi esi edx ecx ebx
	ret
MakeMappedFile	ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
MMGetFileHandle		PROC	FileID:DWORD
	call	GetDataOffset, FileID
	cmp	eax, FALSE
	jz	@@ReturnError
	mov	eax, dword ptr [eax]
	jmp	@@End
@@ReturnError:
	mov	eax, FALSE
@@End:
	ret
MMGetFileHandle		ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
MMGetFileSize		PROC	FileID:DWORD
	push	ebx ecx edx esi edi
	call	GetDataOffset, FileID
	cmp	eax, FALSE
	jz	@@ReturnError
	call	GetFileSize, dword ptr [eax], NULL
	jmp	@@End
@@ReturnError:
	mov	eax, FALSE
@@End:
	pop	edi esi edx ecx ebx
	ret
MMGetFileSize		ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
MMGetOriginalFileSize	PROC FileID:DWORD
	push	ebx ecx edx esi edi
	call	GetDataOffset, FileID
	cmp	eax, FALSE
	jz	@@ReturnError
	mov	eax, dword ptr [eax+4]	; get stored original file size
@@ReturnError:
	mov	eax, FALSE
@@End:
	pop	edi esi edx ecx ebx
	ret
MMGetOriginalFileSize	ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
MMSetFileSize		PROC	FileID:DWORD, NewSize:DWORD	; memory handle might changes
	LOCAL	esi:DWORD
	push	ebx ecx edx esi edi
	call	GetDataOffset, FileID
	cmp	eax, FALSE
	jz	@@ReturnError
	mov	esi, eax
;-------------------
; close Memory Object
	call	FlushViewOfFile, dword ptr [esi+12], 0
	call	UnmapViewOfFile, dword ptr [esi+12]
	call	CloseHandle, dword ptr [esi+8]	; close memory handle
;-------------------
; adjust file size
	call	SetFilePointer, dword ptr [esi+0], NewSize, NULL, FILE_BEGIN
	call	SetEndOfFile, dword ptr [esi+0]
; re-create MemoryObject
;-------------------
	call	CreateFileMapping, dword ptr [esi+0], NULL, PAGE_READWRITE, 0, FSize, NULL
	test	eax, eax
	jz	@@CreateFileMappingError
	mov	dword ptr dword ptr [esi+8], eax	; store MemoryHandle
;-------------------
; map view of file
	call	MapViewOfFileEx, dword ptr [esi+8], FILE_MAP_WRITE + FILE_MAP_READ, 0, 0, 0, dword ptr [esi+12]
	test	eax, eax
	jz	@@MapViewOfFileError
	mov	dword ptr [esi+12], eax	; store MemoryAddress (probably will not change)
	jmp	@@End
;-------------------
@@CreateFileMappingError:
	call	EndMappedFile, FileID
	call	wsprintf, offset StrBuffer, offset ErrorMsg3, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
	jmp	@@ReturnError
;-------------------
@@MapViewOfFileError:
	call	EndMappedFile, FileID
	call	wsprintf, offset StrBuffer, offset ErrorMsg4, FileNameOff
	add	esp, 12
	call	ShowErrorMsg, offset StrBuffer
;-------------------
@@ReturnError:
	mov	eax, FALSE
@@End:
	pop	edi esi edx ecx ebx
	ret
MMSetFileSize		ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
EndMappedFile	PROC	FileID:DWORD
	push	ebx ecx edx esi edi
	call	GetDataOffset, FileID
	cmp	eax, FALSE
	jz	@@ReturnError
	mov	esi, eax
	cmp	dword ptr [esi], 0
	jz	@@Closed
;-------------------
; close Memory Object
	call	FlushViewOfFile, dword ptr [esi+12], 0
	call	UnmapViewOfFile, dword ptr [esi+12]
	call	CloseHandle, dword ptr [esi+8]		; close memory handle
;-------------------
; close file
	call	CloseHandle, dword ptr [esi+0]		; close file handle
;-------------------
; clear variables
	mov	dword ptr [esi+0], 0
	mov	dword ptr [esi+4], 0
	mov	dword ptr [esi+8], 0
	mov	dword ptr [esi+12], 0
	jmp	@@End
;-------------------
@@ReturnError:
	mov	eax, FALSE
	jmp	@@End
@@Closed:
	mov	eax, TRUE
@@End:
	pop	edi esi edx ecx ebx
	ret
EndMappedFile	ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
GetNewDataOffset	PROC	FileID:DWORD
	push	ebx ecx edx esi edi
	mov	eax, FileID
; verify if File ID < MAX_FILES
	cmp	eax, MAX_FILES	
	jg	@@InvalidFileID
	
; get pointer for DataBuffer
	mov	ecx, 16	; Size for each DataBuffer entry
	mul	ecx
	add	eax, offset DataBuffer
; verify if file ID already in use
	cmp	dword ptr [eax], 0
	jnz	@@FileIDAlreadyInUse 
; Return esi
	jmp	@@End
;-------------------
@@InvalidFileID:
	call	ShowErrorMsg, offset ErrorMsg7
	jmp	@@ReturnError
;-------------------
@@FileIDAlreadyInUse:
	call	ShowErrorMsg, offset ErrorMsg8
;-------------------
@@ReturnError:
	mov	eax, FALSE
;-------------------
@@End:
	pop	edi esi edx ecx ebx
	ret
GetNewDataOffset	ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
GetDataOffset	PROC	FileID:DWORD
	push	ebx ecx edx esi edi
	mov	eax, FileID
; verify if File ID < MAX_FILES
	cmp	eax, MAX_FILES	
	jg	@@InvalidFileID
; get pointer for DataBuffer
	mov	ecx, 16	; Size for each DataBuffer entry
	mul	ecx
	add	eax, offset DataBuffer
; Return esi
	jmp	@@End
;-------------------
@@InvalidFileID:
	call	ShowErrorMsg, offset ErrorMsg7
;-------------------
@@ReturnError:
	mov	eax, FALSE
;-------------------
@@End:
	pop	edi esi edx ecx ebx
	ret
GetDataOffset	ENDP
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
ShowErrorMsg		PROC	MsgOff:DWORD
	push	eax
	call	MessageBeep, 0FFFFFFFFh
	call	MessageBox, NULL, MsgOff, offset Caption, MB_ICONHAND
	pop	eax
	ret	
ShowErrorMsg		ENDP
;--------------------------------------------------------------------------------------


END
