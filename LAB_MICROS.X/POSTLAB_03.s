;   Archivo:    POSTLAB_03.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: Contador Binario de 4 bits que se incrementa cada 10ms, Contador (de segundos) que se incrementa cada 1 segundo,
;	    Contador hexadecimal que se incrementa y decrementa por medio de botones, Alarma realizada por la configuración del contador hexadecimal
    
;   Hardware: LEDs en el puerto A. Pushbuttons en las entradas del puerto B. LEDS en el puerto C. LEDS en el puerto D. Led en el puerto E.
;	    Puerto A: CONTADOR BINARIO   Puerto C: Contador HEXADECIMAL   Puerto D: Contador Segundos	Puerto E: Led BANDERA.
; 	    
;   Creado: 07 de feb, 2023
;   Ultima modificacion: 07 de feb, 2023
    
PROCESSOR 16F887
#include <xc.inc>
    
; configuration word 1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
;-----variables a utilizar------
PSECT udata_bank0 ;common memory
  cont:	    DS 2; 2 byte
  ;cont_small: DS 1 ;1 byte
  ;cont_big:   DS 1
  var: DS 1	;variable de 1 byte
  segundos: DS 1	;variable de 1 byte para el contador de segundos
  
  UP EQU 1
  DOWN EQU 0
    
;----vector Reset----   
PSECT resVect, class=CODE, abs, delta=2
;-------------vector reset--------------
ORG 00h		;Posición 0000h para el reset
    
resetVec:
    PAGESEL main 
    goto main
    
; ----configuracion del microcontrolador----
PSECT code, delta=2, abs
 
ORG 100h ; posicion para la tabla
 tabla: ;tabla donde se retorna el valor de la suma. PARA ANODO
    clrf PCLATH
    bsf PCLATH,0
    addwf PCL,F
    retlw 11000000B ;0
    retlw 11111001B ;1
    retlw 10100100B ;2
    retlw 10110000B ;3
    retlw 10011001B ;4
    retlw 10010010B ;5
    retlw 10000010B ;6
    retlw 11111000B ;7
    retlw 10000000B ;8
    retlw 10010000B ;9
    retlw 10001000B ;10 A
    retlw 10000011B ;11 B
    retlw 11000110B ;12 C 
    retlw 10100001B ;13 D
    retlw 10000110B ;14 E
    retlw 10001110B ;15 F
    
ORG 200h	; posición para el código
 
 ;------configuracion-------
main: 
    call config_io
    call config_reloj
    call init_tmr0 ; configuración del TMR0 como temporizador
    banksel PORTA
    
    ;------loop principal-------
loop:  
    bcf INTCON, 2 ; Apagamos la bandera de interrupción por si hay overflow en el TIMER0
    call timer ; se llama a la subrutina del timer0 que realiza un conteo como temporizador
    call inc_count ; Se llama la subrutina que incrementa el contador
    btfsc PORTA, 3 ; Si el bit 4 del PORTA/timer0 esta en 1, evalua si el bit 2 esta en 1 que en resumen es si el portA tiene el valor 10.
    call verificacion1
    btfsc PORTB, UP ; Si el PushButton1 en el puerto 1 del PORTB está en 0, descarta la siguiente linea, sino la ejecuta
    call inc_var
    btfsc var, 4 ; Si el bit #5 del registro var está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call resetcero
    btfsc PORTB, DOWN ; Si el pushbutton0 en el puerto 0 del PORTB está en 0, descarta la siguiente linea, sino la ejecuta
    call dec_var
    movf var,W
    andlw 00001111B ; mascara para que únicamente queden los bits de interes.
    call tabla
    movwf PORTC	
    call buscador
    goto loop
    
    ;--------sub rutinas---------  

buscador:
    clrw
    bcf STATUS,2
    movf PORTD, W
    subwf var,W
    
    btfsc STATUS, 2
    goto $+2
    goto $+7
    clrf PORTD
    clrf PORTA
    clrf segundos
    bsf PORTE,0
    call delay_big
    bcf PORTE,0
    return
    
verificacion1:
    btfss PORTA, 2 ; verifica si el bit 3 esta apagado, lee la siguiente linea
    call verificacion2
    return
    
verificacion2:
    btfsc PORTA, 1 ; verifica si el bit 2 esta encendido, lee la siguiente linea
    call verificacion3
    return 
verificacion3:
    btfss PORTA, 0 ; verifica si el bit 1 esta apagado, eso significaria que el valor del portA es 10.
    incf segundos
    movf segundos, W
    movwf PORTD
    btfsc segundos, 4
    clrf segundos
    clrf PORTA
    return
    
inc_count:
    incf PORTA
    btfsc PORTA, 4 ; Si el bit #5 del registro PORTA está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    clrf PORTA
    return

resetcero:
    clrf var; 0 
    return
    
timer:
    movlw 158 ;Se carga el valor del TMR0 para generar un temporizador de 100ms con un prescaler de 256 y una frecuencia interna de 1MHz
    movwf TMR0 ;Se empieza a contar de forma inmediata
    btfss INTCON, 2 ; verificar si la bandera T0IF esta en 1, se salta la siguiente linea, de lo contrario lee lo inmediato
    goto $-1 ; Si no se ha levantado la vandera no se sale del bucle
    return
    
    
init_tmr0:
    bsf STATUS, 5 
    bcf STATUS, 6 ; Seleccion banco 1
    
    bcf OPTION_REG, 5 ;Selección TMR0 como temporizador
    bcf OPTION_REG, 3 ; Asignamos Prescaler a TMR0
    
    bsf OPTION_REG, 2
    bsf OPTION_REG, 1
    bsf OPTION_REG, 0 ;Prescaler de 256   
    
    bcf STATUS, 5
    bcf STATUS, 6 ;Seleccion banco 0
    
    bcf INTCON, 2 ;Apagado de la bandera de interrupccion TMR0
    
    return

    
inc_var:
    call delay_small
    btfsc PORTB, UP
    goto $-1
    incf var
    btfsc var, 4 ; Si el bit #5 del registro PORTC está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call resetcero
    return
    
dec_var:
    call delay_small
    btfsc PORTB, DOWN
    goto $-1
    decf var
    btfsc var, 5 ; Si el bit #5 del registro PORTC está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call seteo
    return
    
seteo:
    movlw 15
    movwf var
    return
    
config_io:
    bsf STATUS, 5 ;banco 11 (3)
    bsf STATUS, 6 
    clrf ANSEL ; 0 = pines digitales, ANS<4:0> = PORTA,  ANS<7:5> = PORTE // Clear Register ANSEL
    clrf ANSELH ; 0 = pines digitales, ANS<13:8>, estos corresponden al PORTB
    
    bsf STATUS, 5 ;banco 01 (1)
    bcf STATUS, 6 
    clrf TRISA ; 0 = port A como salida
    clrf TRISC ; 0 = PORTC como salida
    clrf TRISD ; 0 = PORTD como salida
    clrf TRISE
    ; los primeros dos bits del registro PORTB se colocan como entrada digital
    bsf TRISB, UP ; Bit set (1), BIT 1 del registro TRISB
    bsf TRISB, DOWN ; Bit set (1), BIT 0 del registro TRISB
    
    bcf STATUS, 5 ;banco 00 (0)
    bcf STATUS, 6 
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    clrf PORTC ; 0 = Apagados, todos los puertos del PORTC estan apagados.
    clrf var ; 0 a la variable VAR
    clrf PORTD ; 0 = Apagados, todos los puertos del PORTD estan apagados.
    clrf PORTE
    return
    
config_reloj:
    banksel OSCCON
    ; frecuencia de 500kHz
    bcf IRCF2 ; OSCCON, 6
    bsf IRCF1 ; OSCCON, 5
    bsf IRCF0 ; OSCCON, 4
    bsf SCS ; reloj interno
    return
    
delay_big:
    movlw 50	    ;valor inicial del contador
    movwf cont+1  ;Se guarda el valor inicial en la variable
    call delay_small	;rutina delay
    decfsz cont+1, 1	;decrementar el contador
    goto   $-2	    ; ejecutar dos líneas atrás
    return
    
delay_small:
    movlw 160	    ; valor inicial del	contador
    movwf cont	
    decfsz cont, 1    ; decrementar el contador
    goto $-1		    ; ejecutar línea anterior 
    return
    
END ; Finalización del código






