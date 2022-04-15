;===================================================
;	Diabolo pixel KIT project
;	��������� ����� �01-003
;	���������: ATmega8535
;===================================================

	.include "m8535def.inc"
	.list

;                ������� ��������
;===================================================
	.def temp     = r16
	.def ledLoop  = r17
	.def data     = r18
	.def colorG   = r19
	.def colorR   = r20
	.def colorB   = r21
	.def mode_num = r22
    .def null     = r23

	.equ LED_NUM  = 8      ;���������� ����������� � �������
	.equ RES_TIME = 250	   ;��������� �������� ������� RESET
    .equ DEL_TIME = 0
    .equ ANTIRATT_TIME = 220

	.dseg
	.org 0x60			   

color_num: .db 0           ;����� ����� � �������
buf: .byte 24			   ;������ ��� ������ ������� �������

	.cseg
	.org 0

;               ������ ���������
;===================================================

start:
    rjmp init                   ;���������� �� ������ ����
    rjmp change_mode            ;������� ���������� ����� ������
    rjmp select_color           ;������� ���������� ����� ��������� �����
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti
    reti    

init:
;               ������������� �����
;===================================================

	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp

;               ������������� ���
;===================================================

	ldi temp, 0b00000000
	out DDRD, temp         ;��������� ����� D �� ����
	ldi temp, 0b11111111
	out PORTD, temp		;�������� ���������� ��������

	out DDRA, temp			;��������� ����� A �� �����
	ldi temp, 0b00000000
	out PORTA, temp

;               ������������� �������
;===================================================

	ldi temp, 0b00000000
	out TCCR0, temp        ;Normal mode, ����������. ��� ������� ��� ������� 0b00000001
	out TCNT0, temp        ;��������� ��������

;               ������������� EXTI
;===================================================

    ldi temp, 0b00001010
    out MCUCR, temp         ;��������� ���������� �� ������� ������
    ldi temp,  0b11000000
    out GICR, temp          ;��������� ����� ����������
    sei                     ;����� ���������� ����������


;               ������������� ����������� ���
;===================================================

    ldi colorR, 0x00
	ldi colorG, 0x00
	ldi colorB, 0xff
    ldi mode_num, 0
    ldi null, 0

;               �������� ���������
;===================================================
	
main:
    
	cpi mode_num, 0
    breq set_rainbow            ;� ����������� �� �������� ��������
    cpi mode_num, 1
    breq set_color
    cpi mode_num, 2
    breq set_chess
    cpi mode_num, 3
    brsh set_saw
    
    set_rainbow:
        rcall Rainbow           ;���������� ����������� �������
        rjmp main
    set_color:
        rcall Color
        rjmp main
    set_chess:
        rcall Chess
        rjmp main
    set_saw:
        rcall Saw
        rjmp main
rjmp main

;               ���������� ����� �����
;===================================================
select_color:
    push temp           ;��������� ��������
    push data
    push ZH
    push ZL

    ldi temp, 5
    color_antiratt_del:
        rcall antiratt
        dec temp
        brne color_antiratt_del


    ldi ZH, high(color_num)		;���������� ����� ������ � ������� ����� � ����
	ldi ZL, low(color_num)
    ld data, Z                  ;��������� ����� �����
    inc data                    ;����������� �� 1
    color_try_again:
    cpi data, 8                 ;���������, �� ����� �� �� �������
    brlo select_color_cont      ;���� �� �����, ����������
        subi data, 8            ;���� �����, ��������
        rjmp color_try_again
    select_color_cont:
    st Z, data                  ;��������� ����� �������

    mov temp, data
    add data, temp
    add data, temp              ;�������� ����� ����� �� 3

    ldi ZH, high(palette_dat*2) ;���������� � ���� ����� ������ �������
    ldi ZL, low(palette_dat*2)

    add ZL, data                ;��������� ����� ������� ����� ������� �����
    adc ZH, null

    lpm colorG, Z+              ;������������� ��������� ����, ��� ��������
    lpm colorR, Z+
    lpm colorB, Z

    
    ldi temp, 20
    color_antiratt_del2:
        rcall antiratt
        dec temp
        brne color_antiratt_del2

    pop ZL                      ;��������������� ��������
    pop ZH
    pop data
    pop temp
reti

;               ���������� ����� ������
;===================================================

change_mode:
    push temp

    ldi temp, 5
    mode_antiratt_del:
        rcall antiratt
        dec temp
        brne mode_antiratt_del

    inc mode_num            ;����������� �����
    mode_try_again:
    cpi mode_num, 4         ;���������, �� ����� ��
    brlo change_mode_cont
        subi mode_num, 4    ;���� �����, ��������
        rjmp mode_try_again
    change_mode_cont:

    

    change_mode_wait2:
        in temp, PIND
        sbrs temp, 2
        rjmp change_mode_wait2

    ldi temp, 20
    mode_antiratt_del2:
        rcall antiratt
        dec temp
        brne mode_antiratt_del2

    

    pop temp
reti

;               ������� ��������
;===================================================
delay:
    push temp               ;��������� �������
    ldi temp, 0
    out TCNT0, temp         ;�������� �������
    ldi temp, 0b00000101
    out TCCR0, temp         ;��������� ������ � ��������� 1024
    delay_loop:
        in temp, TCNT0      ;������ �������� ��������
        cpi temp, DEL_TIME	;���������� � ��������
	    brlo delay_loop     ;���� ������, ���������� �������
    ldi temp, 0b00000000    
    out TCCR0, temp         ;������������� ������
    pop temp                ;��������������� �������
ret

;               ������� ��������
;===================================================
antiratt:
    push temp               ;��������� �������
    ldi temp, 0
    out TCNT0, temp         ;�������� �������
    ldi temp, 0b00000101
    out TCCR0, temp         ;��������� ������ � ��������� 1024
    antiratt_loop:
        in temp, TCNT0      ;������ �������� ��������
        cpi temp, ANTIRATT_TIME	;���������� � ��������
	    brlo antiratt_loop  ;���� ������, ���������� �������
    ldi temp, 0b00000000    
    out TCCR0, temp         ;������������� ������
    pop temp                ;��������������� �������
ret


;               ����� ������ ����� �� ��� �����
;===================================================

Color:
    
	push temp               ;��������� �������
	ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;
	ldi temp, 8				;������������� ���������� ������
	Color_loop:
		st Z+, colorG       ;��������� ������ �������� ������
		st Z+, colorR
		st Z+, colorB
		dec temp
		brne Color_loop
	rcall str_upd           ;��������� �����

	pop temp                ;��������������� �������
    
ret

;               �������
;===================================================

Chess:
    
    push temp
    push data
    ldi data, 0

	ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;
	ldi temp, 4				;������������� ���������� ������
    chess_loop_odd:
        st Z+, colorG
		st Z+, colorR
		st Z+, colorB
        st Z+, data
		st Z+, data
		st Z+, data
		dec temp
		brne chess_loop_odd
    rcall str_upd
    rcall Delay

    ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;
	ldi temp, 4				;������������� ���������� ������
    chess_loop_even:
        st Z+, data
		st Z+, data
		st Z+, data
        st Z+, colorG
		st Z+, colorR
		st Z+, colorB
		dec temp
		brne chess_loop_even
    rcall str_upd
    rcall Delay
    pop data
    pop temp
    
ret

;               ����
;===================================================
Saw:
    
    push temp
    push data
    ldi data, 0 

    ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;

    ldi temp, 24
    saw_fill_bk:
        st Z+, data
        dec temp
        brne saw_fill_bk

    ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;
    ldi temp, 8
    saw_fill:
        st Z+, colorG
		st Z+, colorR
		st Z+, colorB
        rcall str_upd
        rcall delay
        dec temp
        brne saw_fill
    pop data
    pop temp
    
ret

;               ������
;===================================================

Rainbow:

    push temp
    push data
    push colorR
    push colorG
    push colorB

    ldi ZH, high(rainbow_dat*2)
    ldi ZL, low(rainbow_dat*2)
    ldi YH, high(buf)
    ldi YL, low(buf)

    ldi temp, 24
    rainbow_init:
        lpm data, Z+
        st Y+, data
        dec temp
        brne rainbow_init

    rcall str_upd
    rcall Delay

    ldi temp, 7
    rainbow_loop:
        ldi YH, high(buf)
        ldi YL, low(buf)
        adiw Y, 21
        ld colorG, Y+
        ld colorR, Y+
        ld colorB, Y
        sbiw Y, 2
        
        push temp
        ldi temp, 21
        rainbow_shift:
            ld data, -Y
            std Y+3, data
            dec temp
            brne rainbow_shift
        pop temp

        st Y+, colorG
        st Y+, colorR
        st Y+, colorB

        rcall str_upd
        rcall Delay

        dec temp
        brne rainbow_loop

    pop colorB
    pop colorR
    pop colorG
    pop data
    pop temp
ret
        

;               ���������� �����
;===================================================

str_upd:
    cli
	push temp	
    push ZH
    push ZL	        		;��������� ��������

	ldi ZH, high(buf)		;���������� ����� ������ ������� � ����
	ldi Zl, low(buf)		;
	ldi ledLoop, 24			;������������� ���������� ������

	ldi temp, 0b00000000	;
	out PORTA, temp			;�������� ������ RESET

	out TCNT0, temp			;������ ������
	ldi temp, 0b00000101	;
	out TCCR0, temp			;�������� ����

wait:
	in temp, TCNT0			;
	cpi temp, RES_TIME		;
	brlo wait				;���� >280us

	ldi temp, 0b00000000	;
	out TCCR0, temp			;����������� ����

    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay

byte_loop:					;������� ������ � �������
	ldi temp, 8				;��� � �����
	ld data, Z+				;������ ����, ����������� �������

	bit_loop:				;������� ����� � �����
		lsr data			;���������� �����
		brcs one			;��������� �������� SREG.C
			rcall set0  	;�������� 0
			rjmp cont		;����������
			one:
			rcall set1  	;�������� 1
		cont:
		dec temp			;
		brne bit_loop		;���� ������ <8 ������, � ����. ����

	dec ledLoop				;
	brne byte_loop			;���� ������ <24 ������, � ����. �����
    pop ZL
    pop ZH
	pop temp				;��������������� temp
    sei
ret
	
;               ������� 1
;===================================================
set1:
	push temp
	ldi temp, 0b00000001
	out PORTA, temp
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ldi temp, 0b00000000
	out PORTA, temp
	pop temp
ret

;               ������� 0
;===================================================
set0:
	push temp
	ldi temp, 0b00000001
	out PORTA, temp
	nop
	nop
	nop
	nop
	nop
	ldi temp, 0b00000000
	out PORTA, temp
	pop temp
ret
	
	
rainbow_dat: .db  0x00, 0x7f, 0x00, 0x52, 0x7f, 0x00, 0x4f, 0x7f, 0x00, 0x7f, 0x7d, 0x00, 0x7f, 0x00, 0x00, 0x7f, 0x00, 0x7f, 0x00, 0x00, 0x7f, 0x00, 0x7f, 0x7f
palette_dat: .db  0x7f, 0x7f, 0x7f, 0x49, 0x7f, 0x00, 0x7e, 0x5b, 0x6a, 0x7f, 0x7b, 0x00, 0x00, 0x04, 0x7f, 0x20, 0x5d, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x7f, 0x00


















	
