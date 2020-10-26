;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; HD44780 LCD 20x4 driver (_lcd_20x4.asm) [last modified: 2020-10-26]
; indentation setting: tab size = 8
;===========================================================================
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
_lcd_line:	ld de, _dat_lcd_line
		ld a, b
		add a, e
		ld e, a
		ld a, (de)
		add c
		or 80h			; 1xxxxxxxb set address
		ld c, a
		jr _lcd_cmd
;---------------------------------------------------------------------------
_dat_lcd_line:	db 00h, 40h, 14h, 54h	; line address
;---------------------------------------------------------------------------
_dat_lcd_init:	db 04h			; 4 commands
		db 38h			; 00111000b 8-bit|2 lines|5x7 dots
		db 06h			; 00000110b address inc|no shift
		db 0ch			; 00001100b display on|cursor off|blink off
		db 01h			; 00000001b clear display|address=0
;---------------------------------------------------------------------------
_dat_hi:	db 'reZet80 DEV R0', 00h
_dat_rom:	db 'H KiB ROM', 00h
_dat_ram:	db 'H KiB RAM', 00h
_dat_next:	db 7eh, 00h
;===========================================================================
