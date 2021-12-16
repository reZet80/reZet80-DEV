;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; RTC driver (_rtc.asm) [last modified: 2020-10-26]
; indentation setting: tab size = 8
;===========================================================================
; for Epson's RTC-72421: 4-bit, 16 regs, time/date in BCD, int, no century
; not tested yet: Epson's RTC-72423, RTC-62421 and RTC-62423, OKI's MSM6242B
;---------------------------------------------------------------------------
_rtc_ready:	in a, (_RTC_D)		; read register D
		or 01h			; set HOLD bit
		out (_RTC_D), a
		in a, (_RTC_D)
		and 02h			; BUSY bit set ?
		ret z			; leave with HOLD bit set
_rtc_hold:	in a, (_RTC_D)
		and 0eh			; clear HOLD bit
		out (_RTC_D), a
		jr _rtc_ready
;---------------------------------------------------------------------------
_rtc_time:	call _rtc_ready
		in a, (_RTC_5)
		and 03h			; bits 0 - 1 | AMPM ignored
		exx
		ld b, a			; b = HOUR_10
		in a, (_RTC_4)
		and 0fh			; bits 0 - 3
		ld c, a			; c = HOUR_1
		in a, (_RTC_3)
		and 07h			; bits 0 - 2
		ld d, a			; d = MIN_10
		in a, (_RTC_2)
		and 0fh			; bits 0 - 3
		ld e, a			; e = MIN_1
		in a, (_RTC_1)
		and 07h			; bits 0 - 2
		ld h, a			; h = SEC_10
		in a, (_RTC_0)
		and 0fh			; bits 0 - 3
		ld l, a			; l = SEC_1
		exx
		call _rtc_hold
		ret			; (exx)bc:de:hl (HH:MM:SS)
;---------------------------------------------------------------------------
_rtc_date:	call _rtc_ready
		in a, (_RTC_B)
		and 0fh			; bits 0 - 3
		exx
		ld b, a			; b = YEAR_10
		in a, (_RTC_A)
		and 0fh			; bits 0 - 3
		ld c, a			; c = YEAR_1
		in a, (_RTC_9)
		and 01h			; bit 0
		ld d, a			; d = MONTH_10
		in a, (_RTC_8)
		and 0fh			; bits 0 - 3
		ld e, a			; e = MONTH_1
		in a, (_RTC_7)
		and 03h			; bits 0 - 1
		ld h, a			; h = DAY_10
		in a, (_RTC_6)
		and 0fh			; bits 0 - 3
		ld l, a			; l = DAY_1
		exx
		; ignore day of week
		;in a, (_RTC_C)
		;and 07h			; bits 0 - 2
		;ex af, af'		; a = WEEK_DAY
		call _rtc_hold
		;ex af, af'
		ret			; a (exx)bc-de-hl (DW 20YY-MM-DD)
;---------------------------------------------------------------------------
_rtc_init:	ld a, 04h		; 0100b TEST|2412|STOP|RESET
		out (_RTC_F), a
		xor a			; 0000b T1|T0|INT|MASK
		out (_RTC_E), a
		out (_RTC_D), a		; 0000b 30ADJ|IRQ|BUSY|HOLD
		exx
		ret
;---------------------------------------------------------------------------
_rtc_common:	call _rtc_init
		call _rtc_ready
		ld a, 07h		; 0111b TEST|2412|STOP|RESET
		out (_RTC_F), a
		ret
;---------------------------------------------------------------------------
_rtc_set_date:	call _rtc_common
		ex af, af'		; write registers 6 - C
		out (_RTC_C), a
		ld a, b			; (exx)a 20bc-de-hl (DW 20YY-MM-DD)
		out (_RTC_B), a
		ld a, c
		out (_RTC_A), a
		ld a, d
		out (_RTC_9), a
		ld a, e
		out (_RTC_8), a
		ld a, h
		out (_RTC_7), a
		ld a, l
		out (_RTC_6), a
		call _rtc_init
		ret
;---------------------------------------------------------------------------
_rtc_set_time:	call _rtc_common
		ld a, b			; write registers 0 - 5
		out (_RTC_5), a		; (exx)bc:de:hl (HH:MM:SS)
		ld a, c
		out (_RTC_4), a
		ld a, d
		out (_RTC_3), a
		ld a, e
		out (_RTC_2), a
		ld a, h
		out (_RTC_1), a
		ld a, l
		out (_RTC_0), a
		call _rtc_init
		ret
;---------------------------------------------------------------------------
_rtc_int:	ld a, 06h		; 0110b T1|T0|INT|MASK
		out (_RTC_E), a		; enable 1s interrupt
		ei			; enable Z80 interrupts
		ret
;---------------------------------------------------------------------------
_rtc_isr:	in a, (_RTC_D)		; interrupt request handler
		bit 2, a
		ret z			; no RTC interrupt occured
		and 0bh			; 1011b, clears carry flag
		out (_RTC_D), a		; clear IRQ flag
;		call _show_clk		; show current time on clock display
		ret
;---------------------------------------------------------------------------
;_dat_weekday:	db 'SUN', 00h		; = 0
;		db 'MON', 00h		; = 1
;		db 'TUE', 00h		; = 2
;		db 'WED', 00h		; = 3
;		db 'THU', 00h		; = 4
;		db 'FRI', 00h		; = 5
;		db 'SAT', 00h		; = 6
;_dat_2k:	db ' 20', 00h
;===========================================================================
