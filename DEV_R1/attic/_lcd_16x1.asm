;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; HD44780 LCD 16x1 driver (_lcd_16x1.asm) [last modified: 2020-10-26]
; indentation setting: tab size = 8
;===========================================================================
; include this in "_dev.asm"
;_LCD_16x1:	equ 1
; 70h-7fh: LCD
;_LCD_CMD:	equ 71h			; LCD command
;_LCD_DAT:	equ 70h			; LCD characters
;---------------------------------------------------------------------------
; include this in "_dev.asm"
;if _LCD_16x1
;include "_lcd_16x1.asm"
;endif
;---------------------------------------------------------------------------
; to init call this first
;if _LCD_16x1
;		call _lcd_init_8	; set 8-bit LCD interface
;endif
;---------------------------------------------------------------------------
; and later this
;if _LCD_16x1
;		call _lcd_init		; finish LCD initialization
;endif
;---------------------------------------------------------------------------
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
; DWYYMMDDHHMMSS : set date time (W 20YY-MM-DD HH:MM:SS) [W=day of the week]
		ld a, (hl)		; no checks done
		inc hl
		ex af, af'		; day of the week
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
;---------------------------------------------------------------------------
_lcd_ready:	in a, (_LCD_CMD)	; read busy flag
		rlca			; bit 7 set ?
		jr c, _lcd_ready	; if yes, wait until cleared
		ld a, c
		ret
;---------------------------------------------------------------------------
_lcd_colon:	ld c, ':'
		jr _lcd_dat
;---------------------------------------------------------------------------
_lcd_dash:	ld c, '-'
		jr _lcd_dat
;---------------------------------------------------------------------------
_lcd_prompt:	ld c, '>'		; LCD uses ASCII
;---------------------------------------------------------------------------
_lcd_dat:	call _lcd_ready
		out (_LCD_DAT), a
		ret
;---------------------------------------------------------------------------
_lcd_cmd:	call _lcd_ready
		out (_LCD_CMD), a
		ret
;---------------------------------------------------------------------------
_lcd_9:		ld c, 0c0h		; 11000000b address=40h
		jr _lcd_cmd
;---------------------------------------------------------------------------
_lcd_clear:	ld c, 01h		; 00000001b clear display|address=00h
		jr _lcd_cmd
;---------------------------------------------------------------------------
_lcd_init_8:	ld bc, 0300h
_lcd_init_3:	dec c			; 4*256 + 12*255 + 7 T
		jr nz, _lcd_init_3	; delay ~ 0,2 ms @ 20 MHz
		ld a, 30h		; 00110000b set 8-bit interface
		out (_LCD_CMD), a
		djnz _lcd_init_3	; repeat for reliable 8-bit init
		ret
;---------------------------------------------------------------------------
_lcd_init:	ld hl, _dat_lcd_init
		ld b, (hl)
		inc hl
_lcd_init_r:	ld c, (hl)
		inc hl
		call _lcd_cmd
		djnz _lcd_init_r
		ret
;---------------------------------------------------------------------------
_dat_lcd_init:	db 04h			; 4 commands
		db 38h			; 00111000b 8-bit|2 lines|5x7 dots
		db 06h			; 00000110b address inc|no shift
		db 0ch			; 00001100b display on|cursor off|blink off
		db 01h			; 00000001b clear display|address=00h
;---------------------------------------------------------------------------
_dat_hi:	db 'reZet80 ', 00h
		db 'DEV R0'
_dat_next1:	db ' ', 7eh, 00h
_dat_kib:	db 'H KiB ', 00h
_dat_rom:	db 'ROM    ', 7eh, 00h
_dat_ram:	db 'RAM    ', 7eh, 00h
_dat_next2:	db '       ', 7eh, 00h
;===========================================================================
