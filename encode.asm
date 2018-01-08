;  Executable name : encode
;  Version         : 1.0
;  Created date    : 1/1/2018
;  Authors         : Abgottspon Nicola and Gjokaj Dennis
;  Description     : Program encoding binary files into Base 64.
;
;  Build using these commands:
;    nasm -f elf64 -g -F stabs hexdump2.asm
;    ld -o hexdump2 hexdump2.o
;
;  Usage:
;    encode < [input file]
;
SECTION .data           ; Section containing initialised data
	;CharacterMap for B64
	B64Char: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	LineFeed: db 10

SECTION .bss            ; Section containing uninitialized data

	BUFFLEN equ 3       	; We read the file 3 bytes at a time
	Buff resb BUFFLEN	; Text buffer itself
	B64Str resb 64		; OutputString
	B64LEN equ $-B64Str	; OutputString Length

SECTION .text           	; Section containing code

global  _start          	; Linker needs this to find the entry point!

_start:
	nop         		; This no-op keeps gdb happy...
	xor rbp,rbp
; Read a buffer full of text from stdin:
Read:
	mov rax,3       	; Specify sys_read call
  mov rbx,0       		; Specify File Descriptor 0: Standard Input
	mov rcx,Buff    	; Pass offset of the buffer to read to
	mov rdx,BUFFLEN 	; Pass number of bytes to read at one pass
	int 80h         	; Call sys_read to fill the buffer
	mov rbp,rax     	; Save # of bytes read from file for later
	cmp rax,0       	; If rax=0, sys_read reached EOF on stdin
	je Done         	; Jump If Equal (to 0, from compare)
	call ConvertB64


ConvertB64:
	; Set up the registers for the process buffer step:
	mov rsi,Buff        	; Place address of file buffer into rsi
	mov rdi,B64Str      	; Place address of line string into rdi
	xor rcx,rcx     	; Clear line string pointer to 0
	mov   rax,[rsi]  	; read 3 bytes of input
	add   rsi,3      	; advance pointer to next input chunk
	bswap eax        	; change order (bswap only works with 32bit)
	shr   rax,8      	; throw away unwanted 0
	call Encodeshifter
	mov   bh,[B64Char+rdx]  ; convert value to character
	call Encodeshifter
	mov   bl,[B64Char+rdx]  ; convert value to character
	shl   rbx,16     	; make room in rbx
	call Encodeshifter
	mov   bh,[B64Char+rdx]  ; convert value to character
	mov   bl,[B64Char+rax]  ; convert value to character
	mov   [rdi],rbx  	; store four B64 characters as output

				; Write the line of hexadecimal values to stdout:
	call OutputPrint
	jmp Read		; Loop back and load file buffer again

Encodeshifter:
	mov   rdx,rax    	; copy of 6 bits
	shr   rax,6      	; throw away 6bits
	and   rdx,0x3F   	; keep only last 6 bits
	ret			; return function

OutputPrint:
	mov rax,4		; Specify sys_write call
	mov rbx,1		; Specify File Descriptor 1: Standard output
	mov rcx,B64Str		; Pass offset of line string
	mov rdx,B64LEN		; Pass size of the line string
	int 80h			; Make kernel call to display line string
	ret			; return function

; All done! Let's end this party:
Done:
	mov rax, 1		; Code for sys_write call
	mov rdi, 1		; Specify File Descriptor 1: Standard Output
	mov rsi, LineFeed	; Pass offset, which is the ASCII code for line feed
	mov rdx, 1		; Pass the length of the message
	syscall			; Make kernel call
	mov rax, 60 		; Code for exit
	mov rdi, 0 		; Return a code of zero
	syscall			; Make kernel call
