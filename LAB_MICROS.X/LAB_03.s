;   Archivo:    LAB_03.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: Contador hexadecimal de 4 bits en 7 segmentos 
;   Hardware: LEDs en el puerto A. Pushbuttons en las entradas del puerto B.
; 
;   Creado: 31 ene, 2023
;   Ultima modificacion: 31 ene, 2023
    
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
    banksel PORTA
    
    ;------loop principal-------
loop:  
    btfsc PORTB, UP ; Si el PushButton1 en el puerto 1 del PORTB está en 0, descarta la siguiente linea, sino la ejecuta
    call inc_porta
    btfsc PORTA, 4 ; Si el bit #5 del registro PORTA está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call resetcero
    btfsc PORTB, DOWN ; Si el pushbutton0 en el puerto 0 del PORTB está en 0, descarta la siguiente linea, sino la ejecuta
    call dec_porta
    movf PORTA,W
    andlw 00001111B ; mascara para que únicamente queden los bits de interes.
    call tabla
    movwf PORTC	
    goto loop
    
    ;--------sub rutinas---------  
    
resetcero:
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    return
    
inc_porta:
    call delay_small
    btfsc PORTB, UP
    goto $-1
    incf PORTA
    btfsc PORTA, 4 ; Si el bit #5 del registro PORTC está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call resetcero
    return
    
dec_porta:
    call delay_small
    btfsc PORTB, DOWN
    goto $-1
    decf PORTA
    btfsc PORTA, 5 ; Si el bit #5 del registro PORTC está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call seteo
    return
    
seteo:
    movlw 15
    movwf PORTA
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
    ; los primeros dos bits del registro PORTB se colocan como entrada digital
    bsf TRISB, UP ; Bit set (1), BIT 1 del registro TRISB
    bsf TRISB, DOWN ; Bit set (1), BIT 0 del registro TRISB
    
    bcf STATUS, 5 ;banco 00 (0)
    bcf STATUS, 6 
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    clrf PORTC ; 0 = Apagados, todos los puertos del PORTC estan apagados.
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



