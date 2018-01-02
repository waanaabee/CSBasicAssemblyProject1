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
SECTION .bss            ; Section containing uninitialized data

    BUFFLEN equ 3       ; We read the file 6 bytes at a time
    Buff:   resb BUFFLEN    ; Text buffer itself

SECTION .data           ; Section containing initialised data

    B64Str: resb 64
    B64LEN equ $-B64Str

    Base64Char: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

SECTION .text           ; Section containing code

global  _start          ; Linker needs this to find the entry point!

_start:
    nop         ; This no-op keeps gdb happy...

; Read a buffer full of text from stdin:
Read:
    mov eax,3       ; Specify sys_read call
    mov ebx,0       ; Specify File Descriptor 0: Standard Input
    mov ecx,Buff        ; Pass offset of the buffer to read to
    mov edx,BUFFLEN     ; Pass number of bytes to read at one pass
    int 80h         ; Call sys_read to fill the buffer
    mov ebp,eax     ; Save # of bytes read from file for later
    cmp eax,0       ; If eax=0, sys_read reached EOF on stdin
    je Done         ; Jump If Equal (to 0, from compare)

; Set up the registers for the process buffer step:
    mov esi,Buff        ; Place address of file buffer into esi
    mov edi,B64Str      ; Place address of line string into edi
    xor ecx,ecx     ; Clear line string pointer to 0

		; convert 3 bytes of input into four B64 characters of output
		mov   eax,[esi]  ; read 3 bytes of input
		      ; (reads actually 4B, 1 will be ignored)
		add   esi,3      ; advance pointer to next input chunk
		bswap eax        ; first input byte as MSB of eax
		shr   eax,8      ; throw away the 1 junk byte (LSB after bswap)
		; produce 4 base64 characters backward (last group of 6b is converted first)
		; (to make the logic of 6b group extraction simple: "shr eax,6 + and 0x3F)
		mov   edx,eax    ; get copy of last 6 bits
		shr   eax,6      ; throw away 6bits being processed already
		and   edx,0x3F   ; keep only last 6 bits
		mov   bh,[Base64Char+edx]  ; convert 0-63 value into B64 character (4th)
		mov   edx,eax    ; get copy of next 6 bits
		shr   eax,6      ; throw away 6bits being processed already
		and   edx,0x3F   ; keep only last 6 bits
		mov   bl,[Base64Char+edx]  ; convert 0-63 value into B64 character (3rd)
		shl   ebx,16     ; make room in ebx for next character (4+3 in upper 32b)
		mov   edx,eax    ; get copy of next 6 bits
		shr   eax,6      ; throw away 6bits being processed already
		and   edx,0x3F   ; keep only last 6 bits
		mov   bh,[Base64Char+edx]  ; convert 0-63 value into B64 character (2nd)
		; here eax contains exactly only 6 bits (zero extended to 32b)
		mov   bl,[Base64Char+eax]  ; convert 0-63 value into B64 character (1st)
		mov   [edi],ebx  ; store four B64 characters as output
		add   edi,4      ; advance output pointer

	; Write the line of hexadecimal values to stdout:
		mov eax,4		; Specify sys_write call
		mov ebx,1		; Specify File Descriptor 1: Standard output
		mov ecx,B64Str		; Pass offset of line string
		mov edx,B64LEN		; Pass size of the line string
		int 80h			; Make kernel call to display line string
		jmp Read		; Loop back and load file buffer again

; All done! Let's end this party:
Done:
    mov eax,1       ; Code for Exit Syscall
    mov ebx,0       ; Return a code of zero
    int 80H         ; Make kernel call
