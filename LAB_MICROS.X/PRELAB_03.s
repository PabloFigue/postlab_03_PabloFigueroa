;   Archivo:    PRELAB_03_POSTLAB.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: contador binario de 4 bits en el que cada incremento se realizará cada 100ms, utilizando el Timer0. 
;   Hardware: LEDs en el puerto A. 
; 
;   Creado: 04 Feb, 2023
;   Ultima modificacion: 06 feb, 2023
    
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
      

;----vector Reset----   
PSECT resVect, class=CODE, abs, delta=2
;-------------vector reset--------------
ORG 00h		;Posición 0000h para el reset
    
resetVec:
    PAGESEL main 
    goto main
    
; ----configuracion del microcontrolador----
PSECT code, delta=2, abs
ORG 100h	; posición para el código
 
 ;------configuracion-------
main: 
    call config_io ; configuración de pines de entrada y salida
    call init_tmr0 ; configuración del TMR0 como temporizador
    call config_reloj ; configuración del oscilador interno del PIC.
    banksel PORTA
    
    ;------loop principal-------
loop:
    bcf INTCON, 2
    call timer
    call inc_count ; Se llama la subrutina que incrementa el contador
    goto loop
    
    ;--------sub rutinas---------

inc_count:
    incf PORTA
    btfsc PORTA, 4 ; Si el bit #5 del registro PORTA está en 0, descarta la siguiente linea, si esta en 1 ejecuta la linea inmediata.
    call resetcero
    return
    
resetcero:
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
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

config_io:
    bsf STATUS, 5 ;banco 11 (3)
    bsf STATUS, 6 
    clrf ANSEL ; 0 = pines digitales, ANS<4:0> = PORTA,  ANS<7:5> = PORTE // Clear Register ANSEL
    clrf ANSELH ; 0 = pines digitales, ANS<13:8>, estos corresponden al PORTB
    
    bsf STATUS, 5 ;banco 01 (1)
    bcf STATUS, 6 
    clrf TRISA ; 0 = PORTA como salida
     
    bcf STATUS, 5 ;banco 00 (0)
    bcf STATUS, 6 
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    return
    
config_reloj:
    banksel OSCCON
    ; frecuencia de 1MHz
    bsf IRCF2 ; OSCCON, 6
    bcf IRCF1 ; OSCCON, 5
    bcf IRCF0 ; OSCCON, 4
    bsf SCS ; reloj interno
    return
    
    
END ; Finalización del código
