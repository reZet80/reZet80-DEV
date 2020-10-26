;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; reZet80 DEV (_dev.asm) [last modified: 2020-10-26]
; indentation setting: tab size = 8
;===========================================================================
; hardware configuration:
_LCD_16x1:	equ 0			; one display mandatory
_LCD_20x4:	equ 1			; only one LCD allowed
_KEYPAD_16:	equ 1			; one keypad mandatory
_RTC_72421:	equ 1			; one RTC mandatory
;===========================================================================
; I/O ports:
; 00h-0fh: tbd
; 10h-1fh: tbd
; 20h-2fh: tbd
; 30h-3fh: tbd
;---------------------------------------------------------------------------
; 40h-4fh: keypad 16
_KEY_OUT:	equ 40h			; output buffer
;---------------------------------------------------------------------------
; 50h-5fh: keypad 16
_KEY_IN:	equ 50h			; input buffer
;---------------------------------------------------------------------------
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
;---------------------------------------------------------------------------
; 70h-7fh: LCD
_LCD_CMD:	equ 71h			; LCD command
_LCD_DAT:	equ 70h			; LCD characters
;===========================================================================
; logical memory:
; 0000h-0fffh: code (4 KiB)
; f000h-ffffh: data (4 KiB)
; |f000h-fbffh: unused (3 KiB)
; |fc00h-fdffh: stack (0.5 KiB)
; |fe00h-ffffh: reZet80 data (0.5 KiB)
_buffer:	equ 0fe00h		; 16-byte buffer (max command = 14)
;---------------------------------------------------------------------------
; start of Z80 execution - maskable interrupts disabled by hardware reset
		ds 03h, 00h		; placeholder
		jp _dinit
		ds 02h, 00h		; reserved for now
;---------------------------------------------------------------------------
		ds 08h, 0ffh		; rst 08h
		ds 08h, 00h		; rst 10h
		ds 08h, 0ffh		; rst 18h
		ds 08h, 00h		; rst 20h
		ds 08h, 0ffh		; rst 28h
		ds 08h, 00h		; rst 30h
		ds 2eh, 0ffh		; ISR starts at 0038h
		ds 9ah, 00h		; NMISR starts at 0066h
;---------------------------------------------------------------------------
_rinit:		ld (hl), 00h
		ld d, h
		ld e, l
		inc de
		ldir
		ret
;---------------------------------------------------------------------------
_dinit:		ld hl, _buffer
		ld sp, hl		; stack below reZet80 data
if _LCD_16x1 | _LCD_20x4
		call _lcd_init_8	; set 8-bit LCD interface
endif
		ld bc, 01ffh
		call _rinit		; init reZet80 data with zeroes
; determine how much memory we have
; if a memory location cannot be changed assume it's ROM (TODO: could be bad RAM, too)
_rxm_cnt:	xor a
		ld h, a
		ld l, a			; start address
		exx
		ld b, a			; RAM pages count
		ld c, a			; ROM pages count
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
		inc b			; checked 1 RAM page
		exx
		djnz _rxm_page
		jr _dinit2
_rxm_rom:	exx
		inc c			; found 1 ROM page
		exx
		add hl, de		; next page
		djnz _rxm_next
;---------------------------------------------------------------------------
_dinit2:
if _LCD_16x1 | _LCD_20x4
		call _lcd_init		; finish LCD initialization
endif
		ld hl, _dat_hi		; welcome message
		call _text		; output
;---------------------------------------------------------------------------
if _LCD_16x1
; all this does is show amount of ROM and RAM, display date and time and
; provide us with a prompt to enter new date / time
		call _lcd_9		; go to 9th char
		call _text		; output welcome message 2nd part
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		exx
		ld a, b
		exx
		call _conv_kib
		ld hl, _dat_kib		; output amount of ROM
		call _text
		call _lcd_9		; go to 9th char
		ld hl, _dat_rom
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		exx
		ld a, c
		exx
		call _conv_kib
		ld hl, _dat_kib		; output amount of RAM
		call _text
		call _lcd_9		; go to 9th char
		ld hl, _dat_ram
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		call _rtc_date		; get date
		push hl
		push de
		push bc
		ld hl, _dat_weekday	; output day of week
		ld de, 0004h
_day_week:	and a
		jr z, _day_week_done
		add hl, de
		dec a
		jr _day_week
_day_week_done:	call _text
		ld hl, _dat_2k		; output '20'
		call _text
		pop bc			; output year
		ld a, c
		call _to_ascii
		ld a, b
		call _to_ascii
		call _lcd_9		; go to 9th char
		call _lcd_dash		; output a '-'
		pop de			; output month
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_dash		; output a '-'
		pop hl			; output day
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		ld hl, _dat_next1	; output an arrow
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		call _rtc_time		; get time
		push hl
		push de
		ld a, c
		call _to_ascii		; output hour
		ld a, b
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop de			; output minute
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop hl			; output second
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		call _lcd_9		; go to 9th char
		ld hl, _dat_next2	; output an arrow
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		call _lcd_prompt	; at last a prompt
_loop_begin:	ld e, 01h		; key count
		ld hl, _buffer
_loop:		call _key_in		; wait for keypress
		ld a, d
		ld (hl), a		; save key
		inc hl
		inc e
		call _to_ascii		; output
		ld a, e
		cp 08h			; need to move to 9th char ?
		call z, _lcd_9
		cp 0fh			; 15 chars max
		jr nz, _loop
		ld hl, _buffer
		ld a, (hl)
		inc hl
		cp 0dh			; 'D' ?
		jr nz, _loop_end	; if no start again
		ld a, (hl)		; day of the week
		inc hl
		ex af, af'
		ld b, (hl)		; Y
		inc hl
		ld c, (hl)		; Y
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		push hl
		ld l, (hl)		; D
		ld h, a			; D
		exx
		pop hl
		inc hl
		ld b, (hl)		; H
		inc hl
		ld c, (hl)		; H
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		ld l, (hl)		; S
		ld h, a			; S
		call _rtc_set		; set new time/date
_loop_end:	call _lcd_clear		; clear screen
		call _lcd_prompt	; prompt again
		jr _loop_begin
include "_lcd_16x1.asm"
endif
;---------------------------------------------------------------------------
if _LCD_20x4
		ld bc, 0100h
		call _lcd_line		; pos=0,2
		exx
		ld a, b
		exx
		call _conv_kib
		ld hl, _dat_rom		; output amount of ROM
		call _text
		ld bc, 0200h
		call _lcd_line		; pos=0,3
		exx
		ld a, c
		exx
		call _conv_kib
		ld hl, _dat_ram		; output amount of RAM
		call _text
		ld bc, 0300h
		call _lcd_line		; pos=0,4
		call _rtc_date		; get date
		push hl
		push de
		push bc
		ld hl, _dat_weekday	; output day of week
		ld de, 0004h
_day_week:	and a
		jr z, _day_week_done
		add hl, de
		dec a
		jr _day_week
_day_week_done:	call _text
		ld hl, _dat_2k		; output '20'
		call _text
		pop bc			; output year
		ld a, c
		call _to_ascii
		ld a, b
		call _to_ascii
		call _lcd_dash		; output a '-'
		pop de			; output month
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_dash		; output a '-'
		pop hl			; output day
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		ld bc, 020ch
		call _lcd_line		; pos=12,3
		call _rtc_time		; get time
		push hl
		push de
		ld a, c
		call _to_ascii		; output hour
		ld a, b
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop de			; output minute
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop hl			; output second
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		ld bc, 0313h
		call _lcd_line		; pos=20,4
		ld hl, _dat_next	; output an arrow
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		call _lcd_prompt	; at last a prompt
_loop_begin:	ld e, 01h		; key count
		ld hl, _buffer
_loop:		call _key_in		; wait for keypress
		ld a, d
		ld (hl), a		; save key
		inc hl
		inc e
		call _to_ascii		; output
		ld a, e
		cp 0fh			; 15 chars max
		jr nz, _loop
		ld hl, _buffer
		ld a, (hl)
		inc hl
		cp 0dh			; 'D' ?
		jr nz, _loop_end	; if no start again
		ld a, (hl)		; day of the week
		inc hl
		ex af, af'
		ld b, (hl)		; Y
		inc hl
		ld c, (hl)		; Y
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		push hl
		ld l, (hl)		; D
		ld h, a			; D
		exx
		pop hl
		inc hl
		ld b, (hl)		; H
		inc hl
		ld c, (hl)		; H
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		ld l, (hl)		; S
		ld h, a			; S
		call _rtc_set		; set new time/date
_loop_end:	call _lcd_clear		; clear screen
		call _lcd_prompt	; prompt again
		jr _loop_begin
include "_lcd_20x4.asm"
endif
;---------------------------------------------------------------------------
_to_ascii:	add a, 30h		; 0 - 9
		cp 3ah
		jr c, _to_ascii_out
		add a, 07h		; A - F
_to_ascii_out:	ld c, a
if _LCD_16x1 | _LCD_20x4
		call _lcd_dat
endif
		ret
;---------------------------------------------------------------------------
_conv_kib:	sla a
		sla a			; 4 KiB per page
		ld b, a			; save original
		srl a			; bits 4-7
		srl a
		srl a
		srl a
		call _to_ascii
		ld a, b
		and 0fh			; bits 0-3
		call _to_ascii
		ret
;---------------------------------------------------------------------------
_text:		ld a, (hl)
		inc hl
		and a
		ret z			; zero-terminated string
		call _to_ascii_out
		jr _text
;---------------------------------------------------------------------------
if _RTC_72421
include "_rtc_72421.asm"
endif
;---------------------------------------------------------------------------
; monitor command for 16-key keypad:
; DWYYMMDDHHMMSS : set date time (W 20YY-MM-DD HH:MM:SS) [W=day of the week]
if _KEYPAD_16
include "_keypad16.asm"
endif
;---------------------------------------------------------------------------
		ds 8000h-$, 00h		; fill up (32 KiB)
;===========================================================================
