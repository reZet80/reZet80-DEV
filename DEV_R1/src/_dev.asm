;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; reZet80 DEV (_dev.asm) [last modified: 2020-12-19]
; indentation setting: tab size = 8
;===========================================================================
; hardware configuration:
_KEYPAD_20:	equ 1			; one keypad mandatory
_RTC_72421:	equ 1			; one RTC mandatory
_7_SEG:		equ 1			; 7-segment LED display
_7_SEG_CC:	equ 1			; common cathode LED display
_7_SEG_CA:	equ 0			; common anode LED display
;===========================================================================
; I/O ports:
; 00h-0fh: tbd
; 10h-1fh: tbd
; 20h-2fh: tbd
; 30h-3fh: tbd
; 40h-4fh: keypad 20
_KEY_IO:	equ 40h
; 50h-5fh: 8-digit 7-segment debug display
_DBG_IO:	equ 50h
; 60h-6fh: RTC
_RTC_0:		equ 60h
_RTC_1:		equ 61h
_RTC_2:		equ 62h
_RTC_3:		equ 63h
_RTC_4:		equ 64h
_RTC_5:		equ 65h
_RTC_6:		equ 66h
_RTC_7:		equ 67h
_RTC_8:		equ 68h
_RTC_9:		equ 69h
_RTC_A:		equ 6ah
_RTC_B:		equ 6bh
_RTC_C:		equ 6ch
_RTC_D:		equ 6dh
_RTC_E:		equ 6eh
_RTC_F:		equ 6fh
; 70h-7fh: 6-digit 7-segment clock display
_CLK_IO:	equ 70h
;===========================================================================
; logical memory:
; 0000h-0fffh: code (4 KiB)
; f000h-ffffh: data (4 KiB)
; |f000h-fbffh: unused (3 KiB)
; |fc00h-fdffh: stack (0.5 KiB)
; |fe00h-ffffh: reZet80 data (0.5 KiB)
_buffer:	equ 0fe00h		; 64-byte buffer
_vram:		equ 0fe40h		; pointer to cursor in VRAM
_curs_x:	equ 0fe42h		; cursor column [0-59]
_curs_y:	equ 0fe43h		; cursor line [0-30]
;---------------------------------------------------------------------------
; start of Z80 execution - maskable interrupts disabled by hardware reset
_0000h:		nop
		nop
		ds 03h, 00h		; placeholder
		jp _dinit
;---------------------------------------------------------------------------
		ds 08h, 00h		; rst 08h
		ds 08h, 00h		; rst 10h
		ds 08h, 00h		; rst 18h
		ds 08h, 00h		; rst 20h
		ds 08h, 00h		; rst 28h
		ds 08h, 00h		; rst 30h
;---------------------------------------------------------------------------
_isr:		di			; ISR starts at 0038h
		push af
		push bc
		push de
		push hl
		ex af, af'
		exx
		push af			; push both register sets
		push bc
		push de
		push hl
		call _rtc_isr		; RTC ISR
		pop hl
		pop de
		pop bc
		pop af
		exx
		ex af, af'
		pop hl
		pop de
		pop bc
		pop af
		ei
		reti
		ds 13h, 00h		; fill up
;---------------------------------------------------------------------------
_nmi:		retn			; NMISR starts at 0066h
;---------------------------------------------------------------------------
_rinit:		ld (hl), 00h
		ld d, h
		ld e, l
		inc de
		ldir
		ret
;---------------------------------------------------------------------------
_dinit:		di			; needed for soft reset
		im 1
		ld hl, _buffer
		ld sp, hl		; stack below reZet80 data
		ld bc, 01ffh
		call _rinit		; init reZet80 data with zeroes
; determine how much memory we have
; if a memory location cannot be changed assume it's ROM
; TODO: could be bad RAM, too
_rxm_cnt:	xor a
		ld h, a
		ld l, a			; start address
		exx
		ld b, a			; ROM pages count
		ld c, a			; RAM pages count
		exx
		ld b, 10h		; 16 pages
_rxm_page:	ld de, 1000h		; 4096 bytes = 1 page
_rxm_next:	ld c, (hl)		; save value
		ld a, 55h		; 01010101b
		ld (hl), a
		cp (hl)
		jr nz, _rxm_rom
		cpl			; 10101010b=aah
		ld (hl), a
		cp (hl)
		jr nz, _rxm_rom
		ld (hl), c		; restore value
		inc hl
		dec de
		jr nz, _rxm_next
		exx
		inc c			; checked 1 RAM page
		exx
		djnz _rxm_page
		jr _dinit2
_rxm_rom:	exx
		inc b			; found 1 ROM page
		exx
		add hl, de		; next page
		djnz _rxm_next
;---------------------------------------------------------------------------
_dinit2:
include "_demon.asm"
;---------------------------------------------------------------------------
if _7_SEG
include "_7segment.asm"
endif
;---------------------------------------------------------------------------
if _KEYPAD_20
include "_keypad20.asm"
endif
;---------------------------------------------------------------------------
if _RTC_72421
include "_rtc.asm"
endif
;---------------------------------------------------------------------------
		ds 8000h-$, 00h		; fill up (32 KiB)
;===========================================================================
