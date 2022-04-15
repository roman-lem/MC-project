;===================================================
;	Diabolo pixel KIT project
;	Лепарский Роман Б01-003
;	Платформа: ATmega8535
;===================================================

	.include "m8535def.inc"
	.list

;                Рабочие регистры
;===================================================
	.def temp     = r16
	.def ledLoop  = r17
	.def data     = r18
	.def colorG   = r19
	.def colorR   = r20
	.def colorB   = r21
	.def mode_num = r22
    .def null     = r23

	.equ LED_NUM  = 8      ;Количество светодиодов в линейке
	.equ RES_TIME = 250	   ;Константа задержки сигнала RESET
    .equ DEL_TIME = 0
    .equ ANTIRATT_TIME = 220

	.dseg
	.org 0x60			   

color_num: .db 0           ;Номер цвета в палитре
buf: .byte 24			   ;Массив для вывода текущей линейки

	.cseg
	.org 0

;               Начало программы
;===================================================

start:
    rjmp init                   ;Прерывание на начало кода
    rjmp change_mode            ;Внешнее прерывание смены режима
    rjmp select_color           ;Внешнее прерывание смены основного цвета
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
;               Инициализация стека
;===================================================

	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp

;               Инициализация ПВВ
;===================================================

	ldi temp, 0b00000000
	out DDRD, temp         ;Настройка порта D на ввод
	ldi temp, 0b11111111
	out PORTD, temp		;Включаем внутренний резистор

	out DDRA, temp			;Настройка порта A на вывод
	ldi temp, 0b00000000
	out PORTA, temp

;               Инициализация Таймера
;===================================================

	ldi temp, 0b00000000
	out TCCR0, temp        ;Normal mode, выключение. Для запуска без деления 0b00000001
	out TCNT0, temp        ;Обнуление счетчика

;               Инициализация EXTI
;===================================================

    ldi temp, 0b00001010
    out MCUCR, temp         ;Настройка прерываний по заднему фронту
    ldi temp,  0b11000000
    out GICR, temp          ;Настройка маски прерываний
    sei                     ;Общее разрешение прерываний


;               Инициализация необходимых РОН
;===================================================

    ldi colorR, 0x00
	ldi colorG, 0x00
	ldi colorB, 0xff
    ldi mode_num, 0
    ldi null, 0

;               Основная программа
;===================================================
	
main:
    
	cpi mode_num, 0
    breq set_rainbow            ;В зависимости от значения регистра
    cpi mode_num, 1
    breq set_color
    cpi mode_num, 2
    breq set_chess
    cpi mode_num, 3
    brsh set_saw
    
    set_rainbow:
        rcall Rainbow           ;Вызывается необходимая функция
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

;               Прерывание смены цвета
;===================================================
select_color:
    push temp           ;Сохраняем регистры
    push data
    push ZH
    push ZL

    ldi temp, 5
    color_antiratt_del:
        rcall antiratt
        dec temp
        brne color_antiratt_del


    ldi ZH, high(color_num)		;Записываем адрес ячейки с номером цвета в пару
	ldi ZL, low(color_num)
    ld data, Z                  ;Извлекаем номер цвета
    inc data                    ;Увеличиваем на 1
    color_try_again:
    cpi data, 8                 ;Проверяем, не вышли ли за палитру
    brlo select_color_cont      ;Если не вышли, продолжаем
        subi data, 8            ;Если вышли, обнуляем
        rjmp color_try_again
    select_color_cont:
    st Z, data                  ;Сохраняем номер обратно

    mov temp, data
    add data, temp
    add data, temp              ;Умножаем номер цвета на 3

    ldi ZH, high(palette_dat*2) ;Записываем в пару адрес начала палитры
    ldi ZL, low(palette_dat*2)

    add ZL, data                ;вычисляем адрес первого байта нужного цвета
    adc ZH, null

    lpm colorG, Z+              ;Устанавливаем выбранный цвет, как основной
    lpm colorR, Z+
    lpm colorB, Z

    
    ldi temp, 20
    color_antiratt_del2:
        rcall antiratt
        dec temp
        brne color_antiratt_del2

    pop ZL                      ;Восстанавливаем регистры
    pop ZH
    pop data
    pop temp
reti

;               Прерывание смены режима
;===================================================

change_mode:
    push temp

    ldi temp, 5
    mode_antiratt_del:
        rcall antiratt
        dec temp
        brne mode_antiratt_del

    inc mode_num            ;Увеличиваем режим
    mode_try_again:
    cpi mode_num, 4         ;Проверяем, не вышли ли
    brlo change_mode_cont
        subi mode_num, 4    ;Если вышли, обнуляем
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

;               Функция задержки
;===================================================
delay:
    push temp               ;Сохраняем регистр
    ldi temp, 0
    out TCNT0, temp         ;Обнуляем счетчик
    ldi temp, 0b00000101
    out TCCR0, temp         ;Запускаем таймер с делителем 1024
    delay_loop:
        in temp, TCNT0      ;Читаем значение счетчика
        cpi temp, DEL_TIME	;Сравниваем с пределом
	    brlo delay_loop     ;Если меньше, продолжаем считать
    ldi temp, 0b00000000    
    out TCCR0, temp         ;Останавливаем таймер
    pop temp                ;Восстанавливаем регистр
ret

;               Функция задержки
;===================================================
antiratt:
    push temp               ;Сохраняем регистр
    ldi temp, 0
    out TCNT0, temp         ;Обнуляем счетчик
    ldi temp, 0b00000101
    out TCCR0, temp         ;Запускаем таймер с делителем 1024
    antiratt_loop:
        in temp, TCNT0      ;Читаем значение счетчика
        cpi temp, ANTIRATT_TIME	;Сравниваем с пределом
	    brlo antiratt_loop  ;Если меньше, продолжаем считать
    ldi temp, 0b00000000    
    out TCCR0, temp         ;Останавливаем таймер
    pop temp                ;Восстанавливаем регистр
ret


;               Вывод одного цвета на все диоды
;===================================================

Color:
    
	push temp               ;Сохраняем регистр
	ldi ZH, high(buf)		;Записываем адрес начала массива в пару
	ldi Zl, low(buf)		;
	ldi temp, 8				;Устанавливаем количество циклов
	Color_loop:
		st Z+, colorG       ;Заполняем массив основным цветом
		st Z+, colorR
		st Z+, colorB
		dec temp
		brne Color_loop
	rcall str_upd           ;Обновляем ленту

	pop temp                ;Восстанавливаем регистр
    
ret

;               Шахматы
;===================================================

Chess:
    
    push temp
    push data
    ldi data, 0

	ldi ZH, high(buf)		;Записываем адрес начала массива в пару
	ldi Zl, low(buf)		;
	ldi temp, 4				;Устанавливаем количество циклов
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

    ldi ZH, high(buf)		;Записываем адрес начала массива в пару
	ldi Zl, low(buf)		;
	ldi temp, 4				;Устанавливаем количество циклов
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

;               Пила
;===================================================
Saw:
    
    push temp
    push data
    ldi data, 0 

    ldi ZH, high(buf)		;Записываем адрес начала массива в пару
	ldi Zl, low(buf)		;

    ldi temp, 24
    saw_fill_bk:
        st Z+, data
        dec temp
        brne saw_fill_bk

    ldi ZH, high(buf)		;Записываем адрес начала массива в пару
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

;               Радуга
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
        

;               Обновление ленты
;===================================================

str_upd:
    cli
	push temp	
    push ZH
    push ZL	        		;Сохраняем регистры

	ldi ZH, high(buf)		;Записываем адрес начала массива в пару
	ldi Zl, low(buf)		;
	ldi ledLoop, 24			;Устанавливаем количество циклов

	ldi temp, 0b00000000	;
	out PORTA, temp			;Посылаем сигнал RESET

	out TCNT0, temp			;Чистим таймер
	ldi temp, 0b00000101	;
	out TCCR0, temp			;Начинаем счет

wait:
	in temp, TCNT0			;
	cpi temp, RES_TIME		;
	brlo wait				;Ждем >280us

	ldi temp, 0b00000000	;
	out TCCR0, temp			;Заканчиваем счет

    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay
    rcall Delay

byte_loop:					;Перебор байтов в массиве
	ldi temp, 8				;Бит в байте
	ld data, Z+				;Читаем байт, увеличиваем счетчик

	bit_loop:				;Перебор битов в байте
		lsr data			;Логический сдвиг
		brcs one			;Проверяем значение SREG.C
			rcall set0  	;Посылаем 0
			rjmp cont		;Продолжаем
			one:
			rcall set1  	;Посылаем 1
		cont:
		dec temp			;
		brne bit_loop		;Если прошло <8 циклов, к след. биту

	dec ledLoop				;
	brne byte_loop			;Если прошло <24 циклов, к след. байту
    pop ZL
    pop ZH
	pop temp				;Восстанавливаем temp
    sei
ret
	
;               Посылка 1
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

;               Посылка 0
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


















	
