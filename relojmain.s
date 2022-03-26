/*
    Archivo:		Proyecto1main.S
    Dispositivo:	PIC16F887
    Autor:		Jorge Cerón 20288
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Reloj digital
			
    Hardware:		

    Creado:			10/03/22
    Última modificación:	16/03/22	
*/
PROCESSOR 16F887
#include <xc.inc>

;------------------------------------------- CONFIGURACIÓN 1 -------------------------------------------;

  CONFIG  FOSC = INTRC_NOCLKOUT // Oscillador Interno sin salidas
  CONFIG  WDTE = OFF            // WDT (Watchdog Timer Enable bit) disabled (reinicio repetitivo del pic)
  CONFIG  PWRTE = OFF           // PWRT enabled (Power-up Timer Enable bit) (espera de 72 ms al iniciar)
  CONFIG  MCLRE = OFF           // El pin de MCL se utiliza como I/O
  CONFIG  CP = OFF              // Sin proteccion de codigo
  CONFIG  CPD = OFF             // Sin proteccion de datos
  
  CONFIG  BOREN = OFF           // Sin reinicio cunado el voltaje de alimentación baja de 4V
  CONFIG  IESO = OFF            // Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           // Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = OFF             // programación en bajo voltaje permitida

;------------------------------------------- CONFIGURACIÓN 2 -------------------------------------------;
  
  CONFIG  WRT = OFF             // Protección de autoescritura por el programa desactivada
  CONFIG  BOR4V = BOR40V        // Reinicio abajo de 4V, (BOR21V = 2.1V)
  
;---------------------------------------------- VARIABLES ----------------------------------------------;
PSECT udata_bank0
    MODO:	    DS 1    // VAR selección de modo: HORA/FECHA/TIMER/ALARMA
    
    MITADSEGUNDO:   DS 1    // VAR cuenta mitad de un segundo
    QUINIENTOSMS:   DS 1    // VAR 500ms 
    SEGUNDOS:	    DS 1    // VAR segundos
    
    MINUTO_UNI:	    DS 1    // VAR unidades de minutos
    MINUTO_DECE:    DS 1    // VAR decenas de minutos
    HORA_UNI:	    DS 1    // VAR unidades de horas
    HORA_DECE:	    DS 1    // VAR decenas de horas
    
    DIA_UNI:	    DS 1    // VAR unidades de dias
    DIA_DECE:	    DS 1    // VAR decenas de dias
    MES_UNI:	    DS 1    // VAR unidades de mes
    MES_DECE:	    DS 1    // VAR decenas de mes
    
    BANDERAS_SET:   DS 1    // VAR banderas para determinar el set-display
    
    DISPLAY:	    DS 4    // VAR seleccion de displays (4 displays distintos):
			    // DISPLAY1_UNIDADES/DISPLAY1_DECENAS/DISPLAY2_UNIDADES/DISPLAY2_DECENAS
				
    EDITAR:	    DS 1    // VAR selección de modo: MOSTRAR/CONFIG_DISPLAY2/CONFIG_DISPLAY1

    MINTMR_UNI:	    DS 1    // VAR unidades de minutos TMR
    MINTMR_DECE:    DS 1    // VAR decenas de minutos TMR
    SEGTMR_UNI:	    DS 1    // VAR unidades de segundos TMR
    SEGTMR_DECE:    DS 1    // VAR decenas de segundos TMR
    
    HORAALARMA_UNI: DS 1    // VAR unidades de hora alarma
    HORAALARMA_DECE:DS 1    // VAR decenas de hora alarma
    MINALARMA_UNI:  DS 1    // VAR unidades de minutos alarma
    MINALARMA_DECE: DS 1    // VAR decenas de minutos alarma
    
    CONTADORMES:    DS 1    // VAR contador de mes (suma de decenas y unidades de mes)
    CANTIDADMES10:  DS 1    // VAR contador de cuánto se añadio a CONTADORMES hasta alcanzar 10 por valor de decena
    
    VAL_DIAS_TABLA: DS 1    // VAR almacena regreso de valores de TABLA DE DIAS

    CONTADORDIAS:   DS 1    // VAR contador de dias (suma de decenas y unidades de dias) 
    CANTIDADDIAS10: DS 1    // VAR contador de cuánto se añadio a CONTADORDIAS hasta alcanzar 10 por valor de decena
    
    VAL_MES_TABLA:  DS 1    // VAR almacena regreso de valores de TABLA DE MES
    
    CONTADORMES_2:  DS 1    // VAR contador de mes 2 (suma de decenas y unidades de mes)		
    CANTIDADMES10_2:DS 1    // VAR contador 2 de cuánto se añadio a CONTADORMES hasta alcanzar 10 por valor de decena
    
    CONTADORMES_3:  DS 1    // VAR contador de mes 3 (suma de decenas y unidades de mes)	
    CANTIDADMES10_3:DS 1    // VAR contador 3 de cuánto se añadio a CONTADORMES hasta alcanzar 10 por valor de decena
    
    VAL_MES2_TABLA: DS 1    // VAR almacena regreso de valores de TABLA DE MES
    
    CONTADORDIAS_3: DS 1    // VAR contador de dias 3 (suma de decenas y unidades de mes)	
    CONTADORMES_4:  DS 1    // VAR contador de mes 4 (suma de decenas y unidades de mes)
    
    CANTIDADMES10_4:	DS 1	// VAR contador 4 de cuánto se añadio a CONTADORMES hasta alcanzar 10 por valor de decena
    CANTIDADDIAS10_3:	DS 1	// VAR contador 3 de cuánto se añadio a CONTADORDIAS hasta alcanzar 10 por valor de decena
    
    SEGUNDOSTMR:    DS 1
    SEGUNDOSTMR2:   DS 1
    SEGUNDOSTMR3:   DS 1

    MINUTOSTMR:	    DS 1
    MINUTOSTMR2:    DS 1
    MINUTOSTMR3:    DS 1
    
    MINUTOSTMR4:    DS 1
    SEGUNDOSTMR4:   DS 1
    BANDERA_ALARMA: DS 1
    TIEMPOALARMA:   DS 1
    
    B_ON_OFF:	    DS 1
    
    CINCUENTAMS:    DS 1
    
    BANDERA_FORZAR_APAGAR:  DS 1
;------------------------------------------------ MACROS ------------------------------------------------;

RESETTIMER0 MACRO	    // Macro para reiniciar el valor del Timer0
    BANKSEL TMR0	    // Direccionamiento al banco 00
    MOVLW   250		    // Cargar literal en el registro W
    MOVWF   TMR0	    // Configuración completa para que tenga 1.5ms de retardo
    BCF	    T0IF	    // Se limpia la bandera de interrupción
    
    ENDM

RESETTIMER1 MACRO TMR1_H, TMR1_L    // Macro para reiniciar el valor del Timer0
    BANKSEL TMR1H		    // Direccionamiento al banco
    MOVLW   TMR1_H		    // Cargar literal en el registro W
    MOVWF   TMR1H		    // Cargar literal en TMR1H
    MOVLW   TMR1_L		    // Cargar literal en el registro W
    MOVWF   TMR1L		    // Cargar literal en TMR1L
    // Configuración completa para que tenga 500ms de retardo
    BCF	    TMR1IF		    // Se limpia la bandera de interrupción
    ENDM

;----------------------------------------- VARIABLES GLOBALES -----------------------------------------;
;			    VARIABLES USADAS DE STATUS PARA INTERRUPCIONES			       ;
    
PSECT udata_shr			// Variables globales en memoria compartida
    WTEMP:	    DS 1	// VAR W temporal
    STATUSTEMP:	    DS 1	// VAR STATUS temporal

 
PSECT resVect, class=CODE, abs, delta=2  
;------------------------------------------- VECTOR RESET -------------------------------------------;
ORG 00h				// Posición 0000h para el reset
resVect:
    PAGESEL	main		// Cambio de página
    GOTO	main		// Ir al main

;---------------------------------------- VECTOR INTERRUPCIÓN ----------------------------------------;
ORG 04h				// Posición 0004h para las interrupciones
PUSH:				
    MOVWF   WTEMP		// Se mueve W a la variable WTEMP
    SWAPF   STATUS, W		// Swap de nibbles del status y se almacena en W
    MOVWF   STATUSTEMP		// Se mueve W a la variable STATUSTEMP
ISR:				// Rutina de interrupción
    BANKSEL PORTA
    BTFSC   RBIF		// Analiza la bandera de cambio del PORTB si esta encendida (si no lo está salta una linea)
    CALL    INTERRUPIOCB	// Se llama la rutina de interrupción del puerto B
    
    BTFSC   TMR1IF		// Analiza la bandera de cambio del TMR1 si esta encendida (si no lo está salta una linea)
    CALL    INT_TMR1		// Se llama la rutina de interrupción del TMR1
    
    BTFSC   T0IF		// Analiza la bandera de cambio del TMR0 si esta encendida (si no lo está salta una linea)
    CALL    INT_TMR0		// Se llama la rutina de interrupción del TMR0

    BTFSC   TMR2IF		// Analiza la bandera de cambio del TMR2 si esta encendida (si no lo está salta una linea)
    CALL    INT_TMR2		// Se llama la rutina de interrupción del TMR2
    
POP:				// Intruccion movida de la pila al PC
    SWAPF   STATUSTEMP, W	// Swap de nibbles de la variable STATUSTEMP y se almacena en W
    MOVWF   STATUS		// Se mueve W a status
    SWAPF   WTEMP, F		// Swap de nibbles de la variable WTEMP y se almacena en WTEMP 
    SWAPF   WTEMP, W		// Swap de nibbles de la variable WTEMP y se almacena en w
    
    RETFIE
;-------------------------------------- SUBRUTINAS DE INTERRUPCIÓN --------------------------------------;
;-------------------------------------- SUBRUTINA DE INTERRUPCIÓN B -------------------------------------;
INTERRUPIOCB:
    BANKSEL PORTA
    BTFSS   PORTB, 4		// Analiza RB4 si no esta presionado (1) salta una linea (si está presionado (0) sigue)
    CALL    MODOS		// Se llama la subrutina de delimitar los modos
    
    BTFSS   PORTB, 2		// Analiza RB3 si no esta presionado (1) salta una linea (si está presionado (0) sigue)
    CALL    EDITAR_ACEPTAR	// Se llama la subrutina de delimitar los modos de editar
    
    MOVF    MODO, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    CALL    HABILITAR_ON_OFF	    // Si ZERO está activo, se llama la rutina de HORA
    
    BCF	    RBIF		// Se limpia la bandera de interrupcion del puerto B
    RETURN
HABILITAR_ON_OFF:
    BTFSS   PORTB, 3
    CALL    ON_OFF
    RETURN
MODOS:
    BANKSEL PORTA
    INCF    MODO		// Se incrementa en 1 la variable MODO
    MOVF    MODO, W		// Se mueve el valor de MODO a W
    SUBLW   3			// Se resta W a 3 (3-W)
    BTFSC   ZERO		// Analiza si la operacion anterior da ZERO (si no da ZERO regresa)
    CLRF    MODO		// Si la operacion dio ZERO limpa la variable MODO
    
    RETURN
    
EDITAR_ACEPTAR:
    BANKSEL PORTA
    INCF    EDITAR		// Se incrementa en 1 la variable EDITAR
    MOVF    EDITAR, W		// Se mueve el valor de EDITAR a W
    SUBLW   3			// Se resta W a 3 (3-W)
    BTFSC   ZERO		// Analiza si la operacion anterior da ZERO (si no da ZERO regresa)
    CLRF    EDITAR		// Si la operacion dio ZERO limpa la variable EDITAR
    
    RETURN

ON_OFF:
    BANKSEL PORTA
    INCF    B_ON_OFF		// Se incrementa en 1 la variable EDITAR
    MOVF    B_ON_OFF, W		// Se mueve el valor de EDITAR a W
    SUBLW   3			// Se resta W a 3 (3-W)
    BTFSC   ZERO		// Analiza si la operacion anterior da ZERO (si no da ZERO regresa)
    CLRF    B_ON_OFF		// Si la operacion dio ZERO limpa la variable EDITAR
    
    RETURN
;----------------------------------- SUBRUTINA DE INTERRUPCIÓN TMR1 ----------------------------------;
INT_TMR1:
    RESETTIMER1  0x0B, 0xDC
    CALL    LEDS_INT_ENCENDIDO	// Se llama la subrutina para leds intermitentes
    
    INCF    MITADSEGUNDO	// Se incrementa en 1 la variable MITADSEGUNDO
    BTFSS   MITADSEGUNDO, 1	// Analiza si el 2do bit de MITADSEGUNDOS es 1
    RETURN			// Si no es 1 regresa a interrupcion
    CLRF    MITADSEGUNDO	// Si es 1, se limpia la variable MITADSEGUNDO para la repetición de 2 equivalente a 1 S
    INCF    SEGUNDOS		// Se incrementa en 1 la variable SEGUNDOS
    MOVF    SEGUNDOS, W		// Se mueve el valor de SEGUNDOS a W
    SUBLW   60			// Se resta SEGUNDOS a 60
    BTFSC   ZERO		// Analiza la bandera de ZERO esté, si está apagada regresa a interrupción
    CALL    INC_MIN		// Si ZERO está encendida, se llama la subrutina para obtener las unidades y decenas de minutos
    
    RETURN

LEDS_INT_ENCENDIDO:
    INCF    QUINIENTOSMS	// Se incrementa en 1 la variable QUINIENTOSMS
    BSF	    PORTA, 4		// Se enciende RB4
    BSF	    PORTA, 5		// Se enciende RB5
    BTFSS   QUINIENTOSMS, 1	// Analiza si el 2do bit de QUINIENTOSMS es 1
    RETURN			// Si no es 1 regresa a interrupcion TMR1
    BCF	    PORTA, 4		// Se apaga RB4
    BCF	    PORTA, 5		// Se apaga RB5
    CLRF    QUINIENTOSMS	// Se limpia QUINIENTOSMS pues se cumplio 1 seg
    RETURN

    
INC_MIN:
    CLRF    SEGUNDOS		// Se limpia la variable SEGUNDOS
    INCF    MINUTO_UNI		// Se incrementa en 1 la variable MINUTOS_UNI
    MOVF    MINUTO_UNI, W	// Se mueve el valor de MINUTOS_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    MINUTO_UNI		// Si está encendido, MINUTO_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    MINUTO_DECE		// Si está encedido, se incrementa en 1 la variable MINUTO_DECE
    MOVF    MINUTO_DECE, W	// Se mueve el valor de MINUTO_DECE a W
    SUBLW   6			// Se resta W a 6 (6-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    MINUTO_DECE		// Si está encedido, MINUTO_DECE se limpia
    BTFSC   ZERO		// Analiza si Zero está apagado, se salta una línea
    CALL    INC_HORA		// Si está encedido, se llama la subrutina para obtener las unidades y decenas de hora
    
    RETURN
    
INC_HORA:
    INCF    HORA_UNI		// Se incrementa en 1 la variable HORA_UNI
    MOVF    HORA_UNI, W		// Se mueve el valor de HORA_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    HORA_UNI		// Si está encendido, HORA_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    HORA_DECE		// Si está encendido, se incrementa en 1 la variable HORA_DECE
    MOVF    HORA_DECE, W	// Se mueve el valor de HORA_DECE a W
    SUBLW   2			// Se resta W a 2
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    HORA24		// Se llama la subrutina para obtener las 24 horas completas
    
    RETURN

HORA24:
    MOVF    HORA_UNI, W		// Se mueve el valor de HORA_UNI a W
    SUBLW   4			// Se resta W a 4 (4-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    CALL    RESET_HORAS_MIN	// Si está encendido, Se llama la subrutina de poner en cero horas y minutos (se cumplio el dia)
    
    RETURN
    
RESET_HORAS_MIN:
    CLRF    MINUTO_UNI		// Se limpia MINUTO_UNI
    CLRF    MINUTO_DECE		// Se limpia MINUTO_DECE
    CLRF    HORA_UNI		// Se limpia HORA_UNI
    CLRF    HORA_DECE		// Se limpia HORA_DECE
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    MOVF    DIA_UNI, W		// Se mueve el valor de DIA_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    CLRF    DIA_UNI		// Si está encendido, DIA_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    DIA_DECE		// Si está encendido, se incrementa en 1 la variable DIA_DECE
        
    CLRF    CONTADORMES		// Se limpia CONTADORMES
    CLRF    CANTIDADMES10	// Se limpia CANTIDADMES10
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    ADDWF   CONTADORMES, F	// Se añade W a CONTADORMES, y se guarda en CONTADORMES
    EVALUARMESDECE:
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    ADDWF   CONTADORMES, F	// Se añade W a CONTADORMES, y se guarda en CONTADORMES
    
    INCF    CANTIDADMES10	// Se incrementa en 1 la variable CANTIDADMES10
    MOVF    CANTIDADMES10, W	// Se mueve el valor de CANTIDADMES10 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea 
    GOTO    EVALUARMESDECE	// Si está apagado, se regresa a la etiqueta de
				// EVALUARMESDECE para sumar 10 veces el valor de MES_DECE
 
    MOVF    CONTADORMES, W	// Se mueve el valor de CONTADORMES a W
    CALL    TABLA_DE_DIAS	// Se busca valor del contador mes para determinar los dias
    MOVWF   VAL_DIAS_TABLA	// Se guarda el valor de la tabla en VAL_DIAS_TABLA
    
    CLRF    CONTADORDIAS	// Se limpia CONTADORDIAS 
    CLRF    CANTIDADDIAS10	// Se limpia CANTIDADDIAS10
    MOVF    DIA_UNI, W		// Se mueve el valor de DIA_UNI a W
    ADDWF   CONTADORDIAS, F	// Se añade W a CONTADORDIAS, y se guarda en CONTADORDIAS
    EVALUARDIADECE:
    MOVF    DIA_DECE, W		// Se mueve el valor de DIA_DECE a W
    ADDWF   CONTADORDIAS, F	// Se añade W a CONTADORDIAS, y se guarda en CONTADORDIAS
    
    INCF    CANTIDADDIAS10	// Se incrementa en 1 la variable CANTIDADDIAS10
    MOVF    CANTIDADDIAS10, W	// Se mueve el valor de CANTIDADDIAS10 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea 
    GOTO    EVALUARDIADECE	// Si está apagado, se regresa a la etiqueta de
				// EVALUARDIADECE para sumar 10 veces el valor de DIA_DECE
    MOVF    CONTADORDIAS, W	// Se mueve el valor de CONTADORDIAS a W
    SUBWF   VAL_DIAS_TABLA	// Se resta CONTADORDIAS a VAL_DIAS_TABLA (VAL_DIAS_TABLA-CONTADORDIAS)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    REINICIAR_DIAS	// Si está encendido, ir a REINICIAR_DIAS
    REGRESO:
    RETURN
REINICIAR_DIAS:
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE
    
    INCF    MES_UNI		// Se incrementa en 1 la variable MES_UNI
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    CLRF    MES_UNI		// Se limpia MES_UNI
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    INCF    MES_DECE		// Se incrementa en 1 la variable MES_DECE
    
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    SUBLW   1			// Se resta W a 2 (2-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES12		// Se llama la subrutina para obtener las 12 meses completos
    REGRESO2:
    GOTO    REGRESO		// Si está encendido, ir a etiqueta de REGRESO
    
MES12:
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    SUBLW   3			// Se resta W a 3 (3-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    GOTO    RESET_MES_DIA	// Se llama la subrutina de poner en cero meses y dias (se cumplio el año)
    REGRESO3:
    GOTO    REGRESO2		// Si está encendido, ir a etiqueta de REGRESO2
    
RESET_MES_DIA:
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE
    CLRF    MES_UNI		// Se limpia MES_UNI
    INCF    MES_UNI		// Se incrementa en 1 la variable MES_UNI
    CLRF    MES_DECE		// Se limpia MES_DECE    
    GOTO    REGRESO3		// Si está encendido, ir a etiqueta de REGRESO3

;----------------------------------- SUBRUTINA DE INTERRUPCIÓN TMR0 ----------------------------------;
INT_TMR0:
    RESETTIMER0			// Se reinicia TMR0 para 1.5ms  
    BCF	    PORTD, 0		// Se limpia set-display de DISPLAY1_DECENAS
    BCF	    PORTD, 1		// Se limpia set-display de DISPLAY1_UNIDADES
    BCF	    PORTD, 2		// Se limpia set-display de DISPLAY2_DECENAS
    BCF	    PORTD, 3		// Se limpia set-display de DISPLAY2_UNIDADES
    BTFSC   BANDERAS_SET, 0	// Se verifica bandera DISPLAY1_DECENAS si esta apagada salta(bit 0 de la variable)
    GOTO    DISPLAY1_DECENAS	// Si está encendida nos movemos al display de centenas
    BTFSC   BANDERAS_SET, 1	// Se verifica bandera DISPLAY1_UNIDADES si esta apagada salta(bit 1 de la variable)
    GOTO    DISPLAY1_UNIDADES	// Si está encendida nos movemos al display de decenas
    BTFSC   BANDERAS_SET, 2	// Se verifica bandera DISPLAY2_DECENAS si esta apagada salta (bit 2 de la variable)
    GOTO    DISPLAY2_DECENAS	// Si está encendida nos movemos al display de unidades
    BTFSC   BANDERAS_SET, 3	// Se verifica bandera DISPLAY2_UNIDADES si esta apagada salta (bit 3 de la variable)
    GOTO    DISPLAY2_UNIDADES	// Si está encendida nos movemos al display de unidades

DISPLAY2_UNIDADES:
    MOVF    DISPLAY+2, W	// Se mueve valor de MINUTO_UNI/DIA_UNI a W
    MOVWF   PORTC		// Se mueve a PORTC para que lo muestre
    BSF	    PORTD, 3		// Se enciende set-display DISPLAY2_UNIDADES
    BCF	    BANDERAS_SET, 3	// Se apaga la bandera de DISPLAY2_UNIDADES
    BSF	    BANDERAS_SET, 2	// Se enciende la bandera de DISPLAY2_DECENAS
    
    RETURN

DISPLAY2_DECENAS:
    MOVF    DISPLAY+3, W	// Se mueve valor de MINUTO_DECE/DIA_DECE a W
    MOVWF   PORTC		// Se mueve a PORTC para que lo muestre
    BSF	    PORTD, 2		// Se enciende set-display DISPLAY2_DECENAS
    BCF	    BANDERAS_SET, 2	// Se apaga la bandera de DISPLAY2_DECENAS
    BSF	    BANDERAS_SET, 1	// Se enciende la bandera de DISPLAY1_UNIDADES
 
    RETURN
    
DISPLAY1_UNIDADES:
    MOVF    DISPLAY, W		// Se mueve valor de HORA_UNI/MES_UNI a W
    MOVWF   PORTC		// Se mueve a PORTC para que lo muestre
    BSF	    PORTD, 1		// Se enciende display DISPLAY1_UNIDADES
    BCF	    BANDERAS_SET, 1	// Se apaga la bandera de DISPLAY1_UNIDADES
    BSF	    BANDERAS_SET, 0	// Se enciende la bandera de DISPLAY1_DECENAS
    
    RETURN

DISPLAY1_DECENAS:
    MOVF    DISPLAY+1, W	// Se mueve valor de HORA_DECE/MES_DECE a W
    MOVWF   PORTC		// Se mueve a PORTC para que lo muestre
    BSF	    PORTD, 0		// Se enciende display DISPLAY1_DECENAS
    BCF	    BANDERAS_SET, 0	// Se apaga la bandera DISPLAY1_DECENAS
    BSF	    BANDERAS_SET, 3	// Se enciende la bandera de DISPLAY2_UNIDADES
    
    RETURN
;----------------------------------- SUBRUTINA DE INTERRUPCIÓN TMR2 ----------------------------------;
INT_TMR2:
    BCF	    TMR2IF		// Se limpia la bandera de interrupción
    INCF    CINCUENTAMS		// Se incrementa en 1 la variable CINCUENTAMS
    MOVF    CINCUENTAMS, W
    SUBLW   20
    BTFSS   ZERO
    RETURN
    BTFSC   BANDERA_ALARMA, 0
    GOTO    CONTARMINALARMA
    CLRF    CINCUENTAMS
    DECF    SEGUNDOSTMR		// Se decrementa en 1 la variable SEGUNDOSTMR
    MOVF    SEGUNDOSTMR, W	// Se mueve SEGUNDOSTMR a W
    SUBLW   -1			// Se resta W a -1 (-1-W)
    BTFSC   ZERO		// Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVLW   59			// Si la activa, se mueve 59 a W
    BTFSC   ZERO		// Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVWF   SEGUNDOSTMR		// Se mueve W a SEGUNDOSTMR
    BTFSC   ZERO		// Analiza si la operación anterior activó ZERO, si no salta una línea
    CALL    DEC_MINT3		// Si la activa, ir a la rutina de decrementar minutos
    CALL    DEC_SEGST3		// Si no está presionado se llama la subrutina de DEC_SEGST
    SALTARALARMA:
    RETURN
DEC_SEGST3:
    BANKSEL PORTA
    MOVF    SEGUNDOSTMR, W	// Se mueve SEGUNDOSTMR a W
    MOVWF   SEGUNDOSTMR4	// Se mueve W a SEGUNDOSTMR4
    
    CLRF    SEGTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    SEGTMR_DECE		// Se limpia SEGTMR_DECE

    MOVLW   10			// Se mueve 10 a W
    SUBWF   SEGUNDOSTMR4, F	// Se resta W a SEGUNDOSTMR y se guarda en SEGUNDOSTMR
    INCF    SEGTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    SEGTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   SEGUNDOSTMR4, F	// Se añaden los 10 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo
    CALL    OBTENER_UNIDADESSEGT// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESSEGT:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   SEGUNDOSTMR4, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR2
    INCF    SEGTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    SEGTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR2
    MOVLW   1			// Se mueve 1 a W
    ADDWF   SEGUNDOSTMR4, F	// Se añade 1 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo (en este caso, cero)
    MOVF    SEGTMR_UNI, W
    ADDWF   SEGTMR_DECE, W
    ADDWF   MINTMR_UNI, W
    ADDWF   MINTMR_DECE, W
    BTFSC   ZERO
    CALL    ACTIVAR_ALARMA
    RETURN    
    
DEC_MINT3:
    BANKSEL PORTA
    DECF    MINUTOSTMR
    MOVF    MINUTOSTMR, W
    MOVWF   MINUTOSTMR4
    
    CLRF    MINTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    MINTMR_DECE		// Se limpia SEGTMR_DECE

    MOVLW   10			// Se mueve 10 a W
    SUBWF   MINUTOSTMR4, F	// Se resta W a SEGUNDOSTMR y se guarda en SEGUNDOSTMR
    INCF    MINTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    MINTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   MINUTOSTMR4, F	// Se añaden los 10 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo
    CALL    OBTENER_UNIDADESMINT// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESMINT:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   MINUTOSTMR4, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR2
    INCF    MINTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    MINTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR2
    MOVLW   1			// Se mueve 1 a W
    ADDWF   MINUTOSTMR4, F	// Se añade 1 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo (en este caso, cero)
    
    
    RETURN
ACTIVAR_ALARMA:
    BSF	    BANDERA_ALARMA, 0
    BSF	    BANDERA_FORZAR_APAGAR, 0
    BSF	    PORTE, 0
    BCF	    PORTA, 3
    RETURN
    
CONTARMINALARMA:
    CLRF    CINCUENTAMS
    INCF    TIEMPOALARMA	// Se incrementa en 1 la vairable TIEMPOALARMA
    MOVF    TIEMPOALARMA, W	// Se mueve TIEMPOALARMA a W
    SUBLW   60			// Se resta W a 60 (60-W)
    BTFSC   ZERO
    GOTO    APAGAR
    IR_SALTAR:
    GOTO    SALTARALARMA
APAGAR:
    BCF	    TMR2ON
    CLRF    PORTE
    CLRF    B_ON_OFF
    CLRF    BANDERA_ALARMA
    CLRF    CINCUENTAMS
    CLRF    SEGUNDOSTMR
    CLRF    SEGUNDOSTMR4
    CLRF    MINUTOSTMR
    CLRF    MINUTOSTMR4
    CLRF    TIEMPOALARMA
    GOTO    IR_SALTAR

PSECT code, abs, delta=2
;--------------------------------------------- CÓDIGO CENTRAL--------------------------------------------;
;------------------------------------------------- TABLAS -------------------------------------------------;
ORG 200h
TABLA:
    CLRF    PCLATH	// Se limpia el registro PCLATH
    BSF	    PCLATH, 1	// En posición 200 en adelante
    ANDLW   0x0F	// Solo deja pasar valores menores a 16
    ADDWF   PCL		// Se añade al PC el caracter en ASCII del contador
    RETLW   00111111B	// Return que devuelve una literal a la vez 0 en el contador de 7 segmentos
    RETLW   00000110B	// Return que devuelve una literal a la vez 1 en el contador de 7 segmentos
    RETLW   01011011B	// Return que devuelve una literal a la vez 2 en el contador de 7 segmentos
    RETLW   01001111B	// Return que devuelve una literal a la vez 3 en el contador de 7 segmentos
    RETLW   01100110B	// Return que devuelve una literal a la vez 4 en el contador de 7 segmentos
    RETLW   01101101B	// Return que devuelve una literal a la vez 5 en el contador de 7 segmentos
    RETLW   01111101B	// Return que devuelve una literal a la vez 6 en el contador de 7 segmentos
    RETLW   00000111B	// Return que devuelve una literal a la vez 7 en el contador de 7 segmentos
    RETLW   01111111B	// Return que devuelve una literal a la vez 8 en el contador de 7 segmentos
    RETLW   01101111B	// Return que devuelve una literal a la vez 9 en el contador de 7 segmentos
    RETLW   01110111B	// Return que devuelve una literal a la vez A en el contador de 7 segmentos
    RETLW   01111100B	// Return que devuelve una literal a la vez b en el contador de 7 segmentos
    RETLW   00111001B	// Return que devuelve una literal a la vez C en el contador de 7 segmentos
    RETLW   01011110B	// Return que devuelve una literal a la vez d en el contador de 7 segmentos
    RETLW   01111001B	// Return que devuelve una literal a la vez E en el contador de 7 segmentos
    RETLW   01110001B	// Return que devuelve una literal a la vez F en el contador de 7 segmentos

TABLA_DE_DIAS:
    CLRF    PCLATH	// Se limpia el registro PCLATH
    BSF	    PCLATH, 1	// En posición 200 en adelante
    ANDLW   0x0F	// Solo deja pasar valores menores a 16
    ADDWF   PCL		// Se añade al PC el caracter en ASCII del contador
    RETLW   0		// Nunca se usa// Solo deja pasar valores menores a 16
    RETLW   32		// ENERO
    RETLW   29		// FEBRERO
    RETLW   32		// MARZO
    RETLW   31		// ABRIL
    RETLW   32		// MAYO
    RETLW   31		// JUNIO
    RETLW   32		// JULIO
    RETLW   32		// AGOSTO
    RETLW   31		// SEPTIEMBRE
    RETLW   32		// OCTUBRE
    RETLW   31		// NOVIEMBRE
    RETLW   32		// DICIEMBRE
    
TABLA_DE_MES:
    CLRF    PCLATH	// Se limpia el registro PCLATH
    BSF	    PCLATH, 1	// En posición 200 en adelante
    ANDLW   0x0F	// Solo deja pasar valores menores a 16
    ADDWF   PCL		// Se añade al PC el caracter en ASCII del contador
    RETLW   0		// DICIEMBRE
    RETLW   1		// ENERO
    RETLW   2		// FEBRERO
    RETLW   3		// MARZO
    RETLW   4		// ABRIL
    RETLW   5		// MAYO
    RETLW   6		// JUNIO
    RETLW   7		// JULIO
    RETLW   8		// AGOSTO
    RETLW   9		// SEPTIEMBRE
    RETLW   10		// OCTUBRE
    RETLW   11		// NOVIEMBRE
    RETLW   12		// NO LLEGA
    
TABLA_DET_MES:
    CLRF    PCLATH	// Se limpia el registro PCLATH
    BSF	    PCLATH, 1	// En posición 200 en adelante
    ANDLW   0x0F	// Solo deja pasar valores menores a 16
    ADDWF   PCL		// Se añade al PC el caracter en ASCII del contador
    RETLW   0		// NO LLEGA
    RETLW   1		// ENERO
    RETLW   2		// FEBRERO
    RETLW   3		// MARZO
    RETLW   4		// ABRIL
    RETLW   5		// MAYO
    RETLW   6		// JUNIO
    RETLW   7		// JULIO
    RETLW   8		// AGOSTO
    RETLW   9		// SEPTIEMBRE
    RETLW   10		// OCTUBRE
    RETLW   11		// NOVIEMBRE
    RETLW   12		// DICIEMBRE
;-------------------------------------------- CÓDIGO PRINCIPAL --------------------------------------------;    
main:
    CALL    CONFIGIO	    // Se llama la rutina configuración de entradas/salidas
    CALL    CONFIGRELOJ	    // Se llama la rutina configuración del reloj
    CALL    CONFIGTIMER0    // Se llama la rutina configuración del TMR0
    CALL    CONFIGTMR1	    // Se llama la rutina configuración del TMR1
    CALL    CONFIGTMR2	    // Se llama la rutina configuración del TMR2
    CALL    CONFIGINTERRUP  // Se llama la rutina configuración de interrupciones
    CALL    CONFIIOCB	    // Se llama la rutina configuración de interrupcion en PORTB
    BANKSEL PORTA 
    
loop:
    BANKSEL IOCB
    BTFSS   IOCB, 4	    // Analiza si IOCB de RB4 está activado, se salta una línea 
    BSF	    IOCB, 4	    // Si no está activado, lo activa
    
    BANKSEL PORTA
    MOVF    MODO, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   0		    // XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    HORA	    // Si ZERO está activo, se llama la rutina de HORA
    
    MOVF    MODO, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   1		    // XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    FECHA	    // Si ZERO está activo, se llama la rutina de FECHA
    
    MOVF    MODO, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    TIMER	    // Si ZERO está activo, se llama la rutina de TIMER
       
    GOTO    loop	    // Regresa a revisar
    
;------------------------------------ RUTINAS DE CONFIGURACIÓN -----------------------------------;  
CONFIGIO:
    BANKSEL ANSEL	    // Direccionar al banco 11
    CLRF    ANSEL	    // I/O digitales
    CLRF    ANSELH	    // I/O digitales
    
    BANKSEL TRISA	    // Direccionar al banco 01
    BSF	    TRISB, 0	    // RB0 como entrada
    BSF	    TRISB, 1	    // RB1 como entrada
    BSF	    TRISB, 2	    // RB2 como entrada
    BSF	    TRISB, 3	    // RB3 como entrada
    BSF	    TRISB, 4	    // RB4 como entrada
    
    CLRF    TRISA	    // PORTA como salida
    CLRF    TRISC	    // PORTC como salida
    CLRF    TRISD	    // PORTD como salida
    BCF	    TRISE, 0	    // RE0 como salida
    
    BCF	    OPTION_REG, 7   // RBPU habilita las resistencias pull-up 
    CLRF    WPUB	    // Se deshabilita todo el registro de pull-up (WPUB)
    BSF	    WPUB, 0	    // Habilita el registro de pull-up en RB0 
    BSF	    WPUB, 1	    // Habilita el registro de pull-up en RB1
    BSF	    WPUB, 2	    // Habilita el registro de pull-up en RB2 
    BSF	    WPUB, 3	    // Habilita el registro de pull-up en RB3
    BSF	    WPUB, 4	    // Habilita el registro de pull-up en RB4
    BSF	    WPUB, 5	    // Habilita el registro de pull-up en RB4
    
    BANKSEL PORTA	    // Direccionar al banco 00
    CLRF    PORTA	    // Se limpia PORTA
    CLRF    PORTB	    // Se limpia PORTB
    CLRF    PORTC	    // Se limpia PORTC
    CLRF    PORTD	    // Se limpia PORTD
    CLRF    PORTE	    // Se limpia PORTE
    
    // Limpieza general de variables a utilizar
    CLRF    MODO	    
    CLRF    EDITAR

    CLRF    MITADSEGUNDO
    CLRF    QUINIENTOSMS
    CLRF    SEGUNDOS
    
    CLRF    MINUTO_UNI
    CLRF    MINUTO_DECE
    CLRF    HORA_UNI
    CLRF    HORA_DECE

    CLRF    DIA_UNI
    MOVLW   4		    // PONER EN 1
    MOVWF   DIA_UNI
    CLRF    DIA_DECE
    MOVLW   0		    // BORRAR
    MOVWF   DIA_DECE	    // BORRAR
    CLRF    MES_UNI
    INCF    MES_UNI
    CLRF    MES_DECE
    
    CLRF    BANDERAS_SET

    CLRF    DISPLAY

    
    CLRF    MINTMR_UNI
    CLRF    MINTMR_DECE
    CLRF    SEGTMR_UNI
    CLRF    SEGTMR_DECE
    
    CLRF    HORAALARMA_UNI
    CLRF    HORAALARMA_DECE
    CLRF    MINALARMA_UNI
    CLRF    MINALARMA_DECE
    
    CLRF    CONTADORMES
    CLRF    CANTIDADMES10
    
    CLRF    CONTADORMES_2		
    CLRF    CANTIDADMES10_2
   
    
    CLRF    CONTADORMES_3		
    CLRF    CANTIDADMES10_3
    
    CLRF    VAL_MES2_TABLA
    
    CLRF    CONTADORDIAS_3
    CLRF    CONTADORMES_4	
    CLRF    CANTIDADMES10_4
    CLRF    CANTIDADDIAS10_3
    
    CLRF    SEGUNDOSTMR
    CLRF    SEGUNDOSTMR2
    CLRF    SEGUNDOSTMR3
    
    CLRF    MINUTOSTMR
    CLRF    MINUTOSTMR2
    CLRF    MINUTOSTMR3
    
    CLRF    MINUTOSTMR4
    CLRF    SEGUNDOSTMR4
    CLRF    BANDERA_ALARMA
    CLRF    TIEMPOALARMA
    
    CLRF    B_ON_OFF
    
    CLRF    CINCUENTAMS
    
    CLRF    BANDERA_FORZAR_APAGAR
    RETURN

CONFIGINTERRUP:
    BANKSEL PIE1
    BSF	    TMR1IE	    // Habilita interrupciones del TMR1
    BSF	    TMR2IE	    // Habilita interrupciones del TMR2
    
    BANKSEL INTCON
    BSF	    GIE		    // Habilita interrupciones globales
    BSF	    PEIE	    // Habilita interrupciones de periféricos
    
    BSF	    RBIE	    // Habilita interrupciones de cambio de estado del PORTB
    BCF	    RBIF	    // Se limpia la banderda de cambio del puerto B
    
    BSF	    T0IE	    // Habilita interrupción TMR0
    BCF	    T0IF	    // Se limpia la bandera de TMR0
    
    BCF	    TMR1IF	    // Se limpia la bandera de TMR1
    BCF	    TMR2IF	    // Se limpia la bandera de TMR2
    RETURN

CONFIIOCB:		    // Interrupt on-change PORTB register
    BANKSEL TRISA
    BSF	    IOCB, 4	    // Interrupción control de cambio en el valor de RB4
    BSF	    IOCB, 3	    // Interrupción control de cambio en el valor de RB3
    BSF	    IOCB, 2	    // Interrupción control de cambio en el valor de RB2
    
    BANKSEL PORTA
    MOVF    PORTB, W	    // Termina la condición de mismatch, compara con W
    BCF	    RBIF	    // Se limpia la bandera de cambio de PORTB
    
    RETURN    
    
CONFIGRELOJ:		    // Configuración de reloj
    BANKSEL OSCCON	    // Direccionamiento al banco 01
    BSF	    OSCCON, 0	    // SCS en 1, se configura a reloj interno
    BSF	    OSCCON, 6	    // bit 6 en 1
    BSF	    OSCCON, 5	    // bit 5 en 1
    BCF	    OSCCON, 4	    // bit 4 en 0
    // Frecuencia interna del oscilador configurada a 4MHz
    RETURN 

CONFIGTIMER0:		    // Configuración de Timer0
    BANKSEL OPTION_REG	    // Direccionamiento al banco 01
    BCF	    OPTION_REG, 5   // TMR0 como temporizador
    BCF	    OPTION_REG, 3   // Prescaler a TMR0
    BSF	    OPTION_REG, 2   // bit 2 en 1
    BSF	    OPTION_REG, 1   // bit 1 en 1
    BSF	    OPTION_REG, 0   // bit 0 en 1
    // Prescaler en 256
    // Sabiendo que N = 256 - (T*Fosc)/(4*Ps) -> 256-(0.0015*4*10^6)/(4*256) = 250.14 (250 aprox)
    RESETTIMER0
    
    RETURN

CONFIGTMR1:		    // Configuración de Timer1
    BANKSEL T1CON
    BCF	    TMR1CS	    // Se habilita reloj interno
    BCF	    T1OSCEN	    // Se apaga LP
    
    BSF	    T1CKPS1	    
    BSF	    T1CKPS0	  
    // Prescaler de 1:8
    BCF	    TMR1GE	    // TMR1 siempre esté contando
    BSF	    TMR1ON	    // Se enciende TMR1
    
    
    // Configuración de TMR1 cuenta 500 mS
    RESETTIMER1 0x0B, 0xDC
    RETURN
    
CONFIGTMR2:		    // Configuración de Timer2
    // Configuración de TMR2 cuenta 50 mS
    BANKSEL TRISA
    MOVLW   195		    // Se mueve literal al registro W
    MOVWF   PR2		    // Se configuran los 50 mS del TMR2
    CLRF    TMR2
    
    BANKSEL PORTA
    BSF	    T2CKPS1
    BSF	    T2CKPS0
    // Prescaler de 1:16
    BSF	    TOUTPS3
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    // Postscaler de 1:16
    BCF	    TMR2ON	    // Se APAGA TMR2 
    BCF	    TMR2IF	    // Se limpia la bandera de TMR2
    RETURN
    
;---------------------------------- RUTINAS Y SUBRUTINAS DE MODOS ---------------------------------;
;-------------------------------------------- MODO HORA -------------------------------------------;
HORA:
    BANKSEL PORTA
    BTFSS   TMR1ON	    // Analiza si TMR1ON está activado, se salta una línea
    BSF	    TMR1ON	    // Si no está activado, lo activa
    
    BSF	    PORTA, 0	    // Se enciende led indicador de modo HORA
    BCF	    PORTA, 1
    BCF	    PORTA, 2
    BCF	    PORTA, 6
    BCF	    PORTA, 7
    // Apaga todos los les indicadores de los estados
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    HORA_UNI, W	    // Se mueve valor de HORA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display
    
    MOVF    HORA_DECE, W    // Se mueve valor de HORA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display+1
    
    MOVF    MINUTO_UNI, W   // Se mueve valor de MINUTO_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display+2
    
    MOVF    MINUTO_DECE, W  // Se mueve valor de MINUTO_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display+3
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   1		    // XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_MIN   // Si ZERO está activo, se llama la subrutina de MODIFICAR_MIN	    
       
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_HORA  // Si ZERO está activo, se llama la subrutina de MODIFICAR_HORA
    
    GOTO    loop	    // Regresar a revisar
    
MODIFICAR_MIN:
    BANKSEL IOCB    
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    BANKSEL PORTA
    BCF	    TMR1ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    
    BSF	    PORTA, 7	    // Se activa el indicador que se está modiicando el display2 (minutos)
    BCF	    PORTA, 6	    // Se desactiva el indicador que se está modiicando el display1 (horas)
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_MIN  // Si está presionado, ir a subrutina de incremento de minutos
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_MIN  // Si está presionado, ir a subrutina de decremento de minutos
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    HORA_UNI, W	    // Se mueve valor de HORA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display
    
    MOVF    HORA_DECE, W    // Se mueve valor de HORA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display+1
    
    MOVF    MINUTO_UNI, W   // Se mueve valor de MINUTO_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display+2
    
    MOVF    MINUTO_DECE, W  // Se mueve valor de MINUTO_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display+3
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_HORA  // Si ZERO está activo, se llama la subrutina de MODIFICAR_HORA
    GOTO    MODIFICAR_MIN   // Si no está activo, se queda MODIFICAR_MIN

INCREMENTO_MIN:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea	
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    INC_MIN_2	    // Si no está presionado se llama la subrutina de INC_MIN_2
    GOTO    MODIFICAR_MIN   // Se regresa a MODIFICAR_MIN
    
DECREMENTO_MIN:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea	
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    DEC_MIN	    // Si no está presionado se llama la subrutina de DEC_MIN
    GOTO    MODIFICAR_MIN   // Se regresa a MODIFICAR_MIN

MODIFICAR_HORA:
    BANKSEL IOCB
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    BANKSEL PORTA
    BCF	    TMR1ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    
    BSF	    PORTA, 6	    // Se activa el indicador que se está modiicando el display1 (horas)
    BCF	    PORTA, 7	    // Se desactiva el indicador que se está modiicando el display2 (minutos)
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_HORA // Si está presionado, ir a subrutina de incremento de horas
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_HORA // Si está presionado, ir a subrutina de decremento de minutos
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    HORA_UNI, W	    // Se mueve valor de HORA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    HORA_DECE, W    // Se mueve valor de HORA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    MINUTO_UNI, W   // Se mueve valor de MINUTO_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    MINUTO_DECE, W  // Se mueve valor de MINUTO_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   0		    // XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    HORA	    // Si ZERO está activo, se llama la rutina de HORA
    GOTO    MODIFICAR_HORA  // Si no está activo, se queda MODIFICAR_HORA
    
INCREMENTO_HORA:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    INC_HORA_3	    // Si no está presionado se llama la subrutina de INC_HORA_3
    GOTO    MODIFICAR_HORA  // Se regresa a MODIFICAR_HORA

DECREMENTO_HORA:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea	
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    DEC_HORA	    // Si no está presionado se llama la subrutina de DEC_HORA
    GOTO    MODIFICAR_HORA  // Se regresa a MODIFICAR_HORA

;-------------------------------------------- MODO FECHA  -------------------------------------------;
FECHA:
    BANKSEL PORTA
    BTFSS   TMR1ON	    // Analiza si TMR1ON está activado, se salta una línea
    BSF	    TMR1ON	    // Si no está activado, lo activa
    
    BSF	    PORTA, 1	    // Se enciende led indicador de modo HORA
    BCF	    PORTA, 0
    BCF	    PORTA, 2
    BCF	    PORTA, 6
    BCF	    PORTA, 7
    // Apaga todos los les indicadores de los estados
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    DIA_UNI, W	    // Se mueve valor de DIA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    DIA_DECE, W	    // Se mueve valor de DIA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    MES_UNI, W	    // Se mueve valor de MES_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    MES_DECE, W	    // Se mueve valor de MES_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   1		    // XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_DIA   // Si ZERO está activo, se llama la subrutina de MODIFICAR_DIA
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_MES   // Si ZERO está activo, se llama la subrutina de MODIFICAR_MES
    
    GOTO    loop	    // Regresar a revisar

MODIFICAR_DIA:
    BANKSEL IOCB
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    BANKSEL PORTA
    BCF	    TMR1ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    
    BSF	    PORTA, 6	    // Se activa el indicador que se está modiicando el display1 (dias)
    BCF	    PORTA, 7	    // Se desactiva el indicador que se está modiicando el display2 (mes)
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_DIA  // Si está presionado, ir a subrutina de incremento de dia
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_DIA  // Si está presionado, ir a subrutina de decremento de mes
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    DIA_UNI, W	    // Se mueve valor de DIA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    DIA_DECE, W	    // Se mueve valor de DIA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    MES_UNI, W	    // Se mueve valor de MES_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    MES_DECE, W	    // Se mueve valor de MES_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_MES   // Si ZERO está activo, se llama la subrutina de MODIFICAR_MES
    GOTO    MODIFICAR_DIA   // Si no está activo, se queda MODIFICAR_DIA
    
INCREMENTO_DIA:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    INC_DIA_2	    // Si no está presionado se llama la subrutina de INC_DIA_2
    GOTO    MODIFICAR_DIA   // Se regresa a MODIFICAR_DIA

DECREMENTO_DIA:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea	
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    DEC_DIA	    // Si no está presionado se llama la subrutina de DEC_DIA
    GOTO    MODIFICAR_DIA   // Se regresa a MODIFICAR_DIA
    
MODIFICAR_MES:
    BANKSEL IOCB
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    BANKSEL PORTA
    BCF	    TMR1ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    
    BSF	    PORTA, 7	    // Se activa el indicador que se está modiicando el display2 (mes)
    BCF	    PORTA, 6	    // Se desactiva el indicador que se está modiicando el display1 (dias)
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_MES  // Si está presionado, ir a subrutina de incremento de mes
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_MES  // Si está presionado, ir a subrutina de decremento de mes
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    DIA_UNI, W	    // Se mueve valor de DIA_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    DIA_DECE, W	    // Se mueve valor de DIA_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    MES_UNI, W	    // Se mueve valor de MES_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    MES_DECE, W	    // Se mueve valor de MES_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   0		    // XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    FECHA	    // Si ZERO está activo, se llama la subrutina de FECHA
    GOTO    MODIFICAR_MES   // Si no está activo, se queda MODIFICAR_MES
    
INCREMENTO_MES:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    INC_MES_2	    // Si no está presionado se llama la subrutina de INC_MES_2
    GOTO    MODIFICAR_MES   // Se regresa a MODIFICAR_MES
    
DECREMENTO_MES:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea	
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    CALL    DEC_MES	    // Si no está presionado se llama la subrutina de DEC_MES
    GOTO    MODIFICAR_MES   // Se regresa a MODIFICAR_MES
;-------------------------------------------- MODO TIMER  -------------------------------------------;  
TIMER:
    BANKSEL PORTA
    BTFSS   TMR1ON	    // Analiza si TMR1ON está activado, se salta una línea
    BSF	    TMR1ON	    // Si no está activado, lo activa
    
    MOVF    B_ON_OFF, W	    // Se mueve valor de EDITAR a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   1		    // XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    CALL    ENCENDER // Si ZERO está activo, se llama la subrutina de MODIFICAR_SEGST
    
    MOVF    B_ON_OFF, W	    // Se mueve valor de EDITAR a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    CALL    APAGAR3  // Si ZERO está activo, se llama la subrutina de MODIFICAR_MINT
    
    BTFSC   BANDERA_FORZAR_APAGAR, 0
    CALL    FORZAR_APAGAR
    
    BSF	    PORTA, 2	    // Se enciende led indicador de modo TIMER
    BCF	    PORTA, 0
    BCF	    PORTA, 1
    BCF	    PORTA, 6
    BCF	    PORTA, 7
    // Apaga todos los les indicadores de los estados
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    MINTMR_UNI, W   // Se mueve valor de MINTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    MINTMR_DECE, W  // Se mueve valor de MINTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    SEGTMR_UNI, W   // Se mueve valor de SEGTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    SEGTMR_DECE, W  // Se mueve valor de SEGTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de EDITAR a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   1		    // XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_SEGST // Si ZERO está activo, se llama la subrutina de MODIFICAR_SEGST
    
    MOVF    EDITAR, W	    // Se mueve valor de EDITAR a W 
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_MINT  // Si ZERO está activo, se llama la subrutina de MODIFICAR_MINT
    
    GOTO    loop	    // Regresar a revisar
FORZAR_APAGAR:
    BTFSS   PORTB, 0	    // Analiza si RB5 está presionado, si no está se salta una línea
    CALL    APAGAR_ALARMA // Si está presionado, ir a subrutina de incremento de minutos
    RETURN
    
APAGAR_ALARMA:
    BANKSEL PORTA
    BCF	    TMR2ON	    // Si no está activado, lo DESactiva
    BCF	    PORTA, 3	    //  
    BCF	    BANDERA_FORZAR_APAGAR, 0
    BCF	    BANDERA_ALARMA, 0
    CLRF    B_ON_OFF
    CLRF    PORTE
    RETURN
ENCENDER:
    BANKSEL PORTA
    MOVF    SEGTMR_UNI, W
    ADDWF   SEGTMR_DECE, W
    ADDWF   MINTMR_UNI, W
    ADDWF   MINTMR_DECE, W
    BTFSC   ZERO
    GOTO    SALIR_ENCENDER
    BANKSEL PORTA
    BTFSS   TMR2ON	    // Analiza si TMR1ON está activado, se salta una línea
    BSF	    TMR2ON	    // Si no está activado, lo activa
    
    BCF	    BANDERA_ALARMA, 0
    BSF	    PORTA, 3	    // SE ENCIENDE LED DE QUE ESTA ENCENDIDO EL TIMER
    SALIR_ENCENDER:
    RETURN
    
APAGAR3:
    BANKSEL PORTA
    BCF	    TMR2ON	    // Si no está activado, lo DESactiva
    BCF	    PORTA, 3	    // SE ENCIENDE LED DE QUE ESTA ENCENDIDO EL TIMER
    RETURN    
    
MODIFICAR_SEGST:
    BANKSEL IOCB    
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    BANKSEL PORTA
    BCF     TMR2ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    
    
    BANKSEL PORTA
    CLRF    B_ON_OFF
    CLRF    PORTE
    
    BSF	    PORTA, 7	    // Se activa el indicador que se está modiicando el display2 (segundos)
    BCF	    PORTA, 6	    // Se desactiva el indicador que se está modiicando el display1 (minutos)
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_SEGST// Si está presionado, ir a subrutina de incremento de segundos
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_SEGST// Si está presionado, ir a subrutina de decremento de segundos
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    MINTMR_UNI, W   // Se mueve valor de MINTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    MINTMR_DECE, W  // Se mueve valor de MINTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    SEGTMR_UNI, W   // Se mueve valor de SEGTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    SEGTMR_DECE, W  // Se mueve valor de SEGTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   2		    // XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    MODIFICAR_MINT  // Si ZERO está activo, se llama la subrutina de MODIFICAR_HORA
    
    GOTO    MODIFICAR_SEGST // Si no está activo, se queda MODIFICAR_MIN
INCREMENTO_SEGST:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    INCF    SEGUNDOSTMR	    // Se incrementa en 1 la variable SEGUNDOSTMR
    MOVF    SEGUNDOSTMR, W  // Se mueve SEGUNDOSTMR a W
    MOVWF   SEGUNDOSTMR2    // Se mueve W a SEGUNDOSTMR2
    SUBLW   60		    // Se resta	W a 60 (60-W)
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    CLRF    SEGUNDOSTMR	    // SEGUNDOSTMR se limpia
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    CLRF    SEGUNDOSTMR2    // SEGUNDOSTMR2 se limpia
    CALL    INC_SEGST	    // Si no está presionado se llama la subrutina de INC_SEGST
    GOTO    MODIFICAR_SEGST // Se regresa a MODIFICAR_SEGST
    
DECREMENTO_SEGST:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    DECF    SEGUNDOSTMR	    // Se decrementa en 1 la variable SEGUNDOSTMR
    MOVF    SEGUNDOSTMR, W  // Se mueve SEGUNDOSTMR a W
    SUBLW   -1
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVLW   59		    // Si la activa, se mueve 59 a W
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVWF   SEGUNDOSTMR
    
    
    CALL    DEC_SEGST	    // Si no está presionado se llama la subrutina de DEC_SEGST
    GOTO    MODIFICAR_SEGST // Se regresa a MODIFICAR_SEGST
    
MODIFICAR_MINT:
    BANKSEL IOCB
    BCF	    IOCB, 4	    // Se desactiva IOCB de RB4, para que no pueda cambiar de modo a menos que esté en EDITAR:MOSTRAR
    
    //BANKSEL PORTA
    //BCF	    TMR1ON	    // Se desactiva TRM1ON, para pausar el TMR1ON
    BANKSEL PORTA
    BSF	    PORTA, 6	    // Se activa el indicador que se está modiicando el display1 (minutos)
    BCF	    PORTA, 7	    // Se desactiva el indicador que se está modiicando el display2 (segundos)
    
    CLRF    B_ON_OFF
    CLRF    PORTE
    
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    INCREMENTO_MINT // Si está presionado, ir a subrutina de incremento de minutos
    
    BTFSS   PORTB, 1	    // Analiza si RB1 está presionado, si no está se salta una línea
    GOTO    DECREMENTO_MINT // Si está presionado, ir a subrutina de decremento de minutos
    
    CLRF    DISPLAY	    // DISPLAY se limpia
    MOVF    MINTMR_UNI, W   // Se mueve valor de MINTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY	    // Se guarda en nueva variable display1
    
    MOVF    MINTMR_DECE, W  // Se mueve valor de MINTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+1	    // Se guarda en nueva variable display2
    
    MOVF    SEGTMR_UNI, W   // Se mueve valor de SEGTMR_UNI a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+2	    // Se guarda en nueva variable display1
    
    MOVF    SEGTMR_DECE, W  // Se mueve valor de SEGTMR_DECE a W
    CALL    TABLA	    // Se busca valor a cargar en PORTC
    MOVWF   DISPLAY+3	    // Se guarda en nueva variable display2
    
    MOVF    EDITAR, W	    // Se mueve valor de MODO a W
    BCF	    ZERO	    // Se limpia la bandera de ZERO
    XORLW   0		    // XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO	    // Analiza si ZERO está apagado, se salta una línea
    GOTO    TIMER	    // Si ZERO está activo, se llama la rutina de HORA
    GOTO    MODIFICAR_MINT  // Si no está activo, se queda MODIFICAR_MINT

INCREMENTO_MINT:
    // Antirebotes
    BTFSS   PORTB, 0	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    INCF    MINUTOSTMR	    // Se incrementa en 1 la variable SEGUNDOSTMR
    MOVF    MINUTOSTMR, W  // Se mueve SEGUNDOSTMR a W
    MOVWF   MINUTOSTMR2    // Se mueve W a SEGUNDOSTMR2
    SUBLW   100		    // Se resta	W a 60 (60-W)
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    CLRF    MINUTOSTMR	    // SEGUNDOSTMR se limpia
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    CLRF    MINUTOSTMR2    // SEGUNDOSTMR2 se limpia
    CALL    INC_MINT	    // Si no está presionado se llama la subrutina de INC_SEGST
    GOTO    MODIFICAR_MINT // Se regresa a MODIFICAR_SEGST
    
DECREMENTO_MINT:
    // Antirebotes
    BTFSS   PORTB, 1	    // Analiza si RB0 está presionado, si no está se salta una línea
    GOTO    $-1		    // Si está presionado, se queda en un pequeño loop hasta que se deje de presionar
    DECF    MINUTOSTMR	    // Se decrementa en 1 la variable SEGUNDOSTMR
    MOVF    MINUTOSTMR, W  // Se mueve SEGUNDOSTMR a W
    SUBLW   -1		    // Se resta	W a -1 (-1-W)
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVLW   99		    // Si la activa, se mueve 59 a W
    BTFSC   ZERO	    // Analiza si la operación anterior activó ZERO, si no salta una línea
    MOVWF   MINUTOSTMR
    
    
    CALL    DEC_MINT	    // Si no está presionado se llama la subrutina de DEC_SEGST
    GOTO    MODIFICAR_MINT // Se regresa a MODIFICAR_SEGST
    
;--------------------------------- SUBRUTINAS DE INCREMENTO/DECREMENTO  ---------------------------------;
;----------------------------------- SUBRUTINAS DE INCREMENTO MINUTOS  ----------------------------------;
INC_MIN_2:    
    INCF    MINUTO_UNI		// Se incrementa en 1 la variable MINUTOS_UNI
    MOVF    MINUTO_UNI, W	// Se mueve el valor de MINUTOS_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    MINUTO_UNI		// Si está encedidO, MINUTO_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    MINUTO_DECE		// Si está encedido, se incrementa en 1 la variable MINUTO_DECE
    MOVF    MINUTO_DECE, W	// Se mueve el valor de MINUTO_DECE a W
    SUBLW   6			// Se resta W a 6 (6-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    MINUTO_DECE		// Si está encedid0, MINUTO_DECE se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    RESET_HORAS_MIN_2		// Si está encedido, se llama la subrutina para obtener las unidades y decenas de hora (AQUI IBA INC_HORA_2)
    
    RETURN
    
RESET_HORAS_MIN_2:
    CLRF    MINUTO_UNI		// Se limpia MINUTO_UNI
    CLRF    MINUTO_DECE		// Se limpia MINUTO_DECE
    RETURN
;----------------------------------- SUBRUTINAS DE DECREMENTO MINUTOS  ----------------------------------;
DEC_MIN:
    DECF    MINUTO_UNI		// Se decrementa en 1 la variable MINUTO_UNI
    CALL    UNDER_MIN		// Se llama a la subrutina de underflow
    RETURN
    
UNDER_MIN:
    BCF	    ZERO		// Se limpia la bandera de ZERO
    MOVLW   -1			// Se mueve la literal -1 a W
    SUBWF   MINUTO_UNI, W	// Se resta -1 a MINUTO_UNI (MINUTO_UNI-(-1))
    BTFSS   ZERO		// Analiza si ZERO está encendido, si no está se salta una línea
    RETURN			// Si está apagado (significa que MINUTO_UNI aún es positivo), regresa
    DECF    MINUTO_DECE		// Si está encendido, se decrementa en 1 la variable MINUTO_DECE (pues MINUTO_UNI tendrá -1) 
    MOVLW   9			// Se mueve la literal 9 a W
    MOVWF   MINUTO_UNI		// Se mueve W a MINUTO_UNI (de esta manera MINUTO_UNI que tenía -1, 
				// tendrá el valor de 9 correcto por underflow)
    BCF	    ZERO		// Se limpia la bandera de ZERO
    MOVLW   -1			// Se mueve la literal -1 a W
    SUBWF   MINUTO_DECE, W	// Se resta -1 a MINUTO_DECE (MINUTO_DECE-(-1))
    BTFSS   ZERO		// Analiza si ZERO está encendido, si no está se salta una línea
    RETURN			// Si está apagado (significa que MINUTO_DECE aún es positivo), regresa
    MOVLW   5			// Se mueve la literal 9 a W
    MOVWF   MINUTO_DECE		// Se mueve W a MINUTO_DECE (de esta manera MINUTO_DECE que tenía -1, 
				// tendrá el valor de 5 correcto por underflow) (TOTAL 59-)
    RETURN
;------------------------------------- SUBRUTINAS DE INCREMENTO HORAS ------------------------------------;   
INC_HORA_3:
    INCF    HORA_UNI		// Se incrementa en 1 la variable HORA_UNI
    MOVF    HORA_UNI, W		// Se mueve el valor de HORA_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    HORA_UNI		// Si está encedida, HORA_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    HORA_DECE		// Si está encedida, se incrementa en 1 la variable HORA_DECE
    MOVF    HORA_DECE, W	// Se mueve el valor de HORA_DECE a W
    SUBLW   2			// Se resta W a 2 (2-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    HORA24_3		// Si está encedida, se llama la subrutina para obtener las 24 horas completa
    
    RETURN

HORA24_3:
    MOVF    HORA_UNI, W		// Se mueve el valor de HORA_UNI a W
    SUBLW   4			// Se resta W a 4 (4-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    RESET_HORAS_MIN_3	// Si está encedida, se llama la subrutina de poner en cero horas y minutos (se cumplio el dia)
    
    RETURN
    
RESET_HORAS_MIN_3:
    CLRF    HORA_UNI		// Se limpia HORA_UNI
    CLRF    HORA_DECE		// Se limpia HORA_DECE
   
    RETURN
;----------------------------------- SUBRUTINAS DE DECREMENTO MINUTOS  ----------------------------------;    
DEC_HORA:
    DECF    HORA_UNI		// Se decrementa en 1 la variable HORA_UNI
    CALL    UNDER_HORA		// Se llama a la subrutina de underflow
    RETURN
    
UNDER_HORA:
    BCF	    ZERO		// Se limpia la bandera de ZERO
    MOVLW   -1			// Se mueve la literal -1 a W
    SUBWF   HORA_UNI, W		// Se resta -1 a HORA_UNI (HORA_UNI-(-1))
    BTFSS   ZERO		// Analiza si ZERO está encendido, si no está se salta una línea
    RETURN			// Si está apagado (significa que HORA_UNI aún es positivo), regresa
    DECF    HORA_DECE		// Si está encendido, se decrementa en 1 la variable HORA_DECE (pues HORA_DECE tendrá -1) 
    MOVLW   3			// Se mueve la literal 3 a W
    MOVWF   HORA_UNI		// Se mueve W a HORA_UNI (de esta manera HORA_UNI que tenía -1, 
				// tendrá el valor de 3 correcto por underflow)
    BCF	    ZERO		// Se limpia la bandera de ZERO
    MOVLW   -1			// Se mueve la literal -1 a W
    SUBWF   HORA_DECE, W	// Se resta -1 a HORA_DECE (HORA_DECE-(-1))
    BTFSS   ZERO		// Analiza si ZERO está encendido, si no está se salta una línea
    RETURN			// Si está apagado (significa que HORA_DECE aún es positivo), regresa
    MOVLW   2			// Se mueve la literal 2 a W
    MOVWF   HORA_DECE		// Se mueve W a HORA_DECE (de esta manera HORA_DECE que tenía -1, 
				// tendrá el valor de 2 correcto por underflow) (TOTAL 23)
    RETURN
;------------------------------------- SUBRUTINAS DE INCREMENTO DIA ------------------------------------; 
INC_DIA_2:  
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    MOVF    DIA_UNI, W		// Se mueve el valor de DIA_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    DIA_UNI		// Si está encedida, DIA_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
         
    CLRF    CONTADORMES		// Se limpia CONTADORMES
    CLRF    CANTIDADMES10	// Se limpia CANTIDADMES10
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    ADDWF   CONTADORMES, F	// Se añade W a CONTADORMES, y se guarda CONTADORMES
    EVALUARMESDECE2:
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    ADDWF   CONTADORMES, F	// Se añade W a CONTADORMES, y se guarda CONTADORMES
    
    INCF    CANTIDADMES10	// Se incrementa en 1 la variable CANTIDADMES10
    MOVF    CANTIDADMES10, W	// Se mueve el valor de CANTIDADMES10 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea
    GOTO    EVALUARMESDECE2	// Si está apagado, se regresa a la etiqueta de 
				// EVALUARMESDECE2 para sumar 10 veces el valor de MES_DECE 
    MOVF    CONTADORMES, W	// Se mueve el valor de CONTADORMES a W   
    CALL    TABLA_DE_DIAS	// Se busca valor de contador mes para determinar los dias
    MOVWF   VAL_DIAS_TABLA	// Se guarda el valor de la tabla en VAL_DIAS_TABLA
    
    CLRF    CONTADORDIAS	// Se limpia CONTADORDIAS
    CLRF    CANTIDADDIAS10	// Se limpia CANTIDADDIAS10
    MOVF    DIA_UNI, W		// Se mueve el valor de DIA_UNI a W
    ADDWF   CONTADORDIAS, F	// Se añade W a CONTADORDIAS, y se guarda CONTADORDIAS
    EVALUARDIADECE2:
    MOVF    DIA_DECE, W		// Se mueve el valor de DIA_DECE a W 
    ADDWF   CONTADORDIAS, F	// Se añade W a CONTADORDIAS, y se guarda CONTADORDIAS 
    
    INCF    CANTIDADDIAS10	// Se incrementa en 1 la variable CANTIDADDIAS10
    MOVF    CANTIDADDIAS10, W	// Se mueve el valor de CANTIDADDIAS10 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea
    GOTO    EVALUARDIADECE2	// Si está apagado, se regresa a la etiqueta de 
				// EVALUARDIADECE2 para sumar 10 veces el valor de MES_DECE 
    MOVF    CONTADORDIAS, W	// Se mueve el valor de DIA_UNI a W
    SUBWF   VAL_DIAS_TABLA	// Se resta CONTADORDIAS a VAL_DIAS_TABLA (VAL_DIAS_TABLA-CONTADORDIAS)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    REINICIAR_DIAS_2	// Si está apagado, ir a REINICIAR_DIAS_2
    RETURN
    
REINICIAR_DIAS_2:
    CLRF    DIA_UNI		// DIA_UNI se limpia
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    CLRF    DIA_DECE		// DIA_DECE se limpia
    
    RETURN
;------------------------------------- SUBRUTINAS DE DECREMENTO DIA ------------------------------------;    
DEC_DIA:
    CLRF    CONTADORMES_4	// Se limpia CONTADORMES_4
    CLRF    CANTIDADMES10_4	// Se limpia CANTIDADMES10_4
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    ADDWF   CONTADORMES_4, F	// Se añade W a CONTADORMES_4, y se guarda CONTADORMES_4
    EVALUARMESDECE4:
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    ADDWF   CONTADORMES_4, F	// Se añade W a CONTADORMES_4, y se guarda CONTADORMES_4
    
    INCF    CANTIDADMES10_4	// Se incrementa en 1 la variable CANTIDADMES10_4
    MOVF    CANTIDADMES10_4, W	// Se mueve el valor de CANTIDADMES10_4 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea
    GOTO    EVALUARMESDECE4	// Si está apagado, se regresa a la etiqueta de 
				// EVALUARMESDECE4 para sumar 10 veces el valor de MES_DECE
    MOVF    CONTADORMES_4, W	// Se mueve el valor de CONTADORMES_4 a W   
    CALL    TABLA_DET_MES	// Se busca valor de contador mes para determinar el mes
    MOVWF   VAL_MES2_TABLA	// Se guarda el valor de la tabla en VAL_MES2_TABLA
    
    CLRF    CONTADORDIAS_3	// Se limpia CONTADORDIAS_3
    CLRF    CANTIDADDIAS10_3	// Se limpia CANTIDADDIAS10_3
    MOVF    DIA_UNI, W		// Se mueve el valor de DIA_UNI a W
    ADDWF   CONTADORDIAS_3, F	// Se añade W a CONTADORDIAS_3, y se guarda CONTADORDIAS_3
    EVALUARDIADECE3:
    MOVF    DIA_DECE, W		// Se mueve el valor de DIA_DECE a W 
    ADDWF   CONTADORDIAS_3, F	// Se añade W a CONTADORDIAS_3, y se guarda CONTADORDIAS_3 
    
    INCF    CANTIDADDIAS10_3	// Se incrementa en 1 la variable CANTIDADDIAS10_3
    MOVF    CANTIDADDIAS10_3, W	// Se mueve el valor de CANTIDADDIAS10_3 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea
    GOTO    EVALUARDIADECE3	// Si está apagado, se regresa a la etiqueta de 
				// EVALUARDIADECE3 para sumar 10 veces el valor de MES_DECE 
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   1			// XOR entre W y 1, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_ENERO		// Si ZERO está activo, se llama la subrutina de MES_ENERO
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   2			// XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_FEBRERO		// Si ZERO está activo, se llama la subrutina de MES_FEBRERO
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   3			// XOR entre W y 3, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_MARZO		// Si ZERO está activo, se llama la subrutina de MES_MARZO
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   4			// XOR entre W y 4, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_ABRIL		// Si ZERO está activo, se llama la subrutina de MES_ABRIL
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   5			// XOR entre W y 5, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_MAYO		// Si ZERO está activo, se llama la subrutina de MES_MAYO    
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   6			// XOR entre W y 6, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_JUNIO		// Si ZERO está activo, se llama la subrutina de MES_JUNIO    
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   7			// XOR entre W y 7, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_JULIO		// Si ZERO está activo, se llama la subrutina de MES_JULIO    
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   8			// XOR entre W y 8, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_AGOSTO		// Si ZERO está activo, se llama la subrutina de MES_AGOSTO    
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   9			// XOR entre W y 9, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_SEPTIEMBRE	// Si ZERO está activo, se llama la subrutina de MES_SEPTIEMBRE
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   10			// XOR entre W y 10, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_OCTUBRE		// Si ZERO está activo, se llama la subrutina de MES_OCTUBRE
        
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   11			// XOR entre W y 11, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_NOVIEMBRE	// Si ZERO está activo, se llama la subrutina de MES_NOVIEMBRE
    
    MOVF    VAL_MES2_TABLA, W	// Se mueve el valor de VAL_MES2_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   12			// XOR entre W y 12, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES_DICIEMBRE	// Si ZERO está activo, se llama la subrutina de MES_DICIEMBRE
    RETURN
;------------------------------- SUBRUTINAS DE DECREMENTO SEGUN MESES ------------------------------;
;----------------------------------------------- ENERO ---------------------------------------------;
MES_ENERO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASENERO
   
    RETURN 
    
;----------------------------------------------- FEBRERO ---------------------------------------------;    
MES_FEBRERO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES2	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES2:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS28		// Si da cero, ir a DIASFEBRERO

    RETURN   
;----------------------------------------------- MARZO ---------------------------------------------;    
MES_MARZO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES3	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES3:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASMARZO

    RETURN   

;----------------------------------------------- ABRIL ---------------------------------------------;    
MES_ABRIL:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES4	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES4:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS30		// Si da cero, ir a DIASABRIL

    RETURN   

;----------------------------------------------- MAYO ---------------------------------------------;    
MES_MAYO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES5	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES5:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASMAYO

    RETURN   
;----------------------------------------------- JUNIO ---------------------------------------------;    
MES_JUNIO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES6	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES6:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS30		// Si da cero, ir a DIASJUNIO

    RETURN   
;----------------------------------------------- JULIO ---------------------------------------------;    
MES_JULIO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES7	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES7:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASJULIO

    RETURN   

    
;----------------------------------------------- AGOSTO ---------------------------------------------;    
MES_AGOSTO:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES8	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES8:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASAGOSTO

    RETURN   

    
;----------------------------------------------- SEPTIEMBRE ---------------------------------------------;    
MES_SEPTIEMBRE:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES9	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES9:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS30	// Si da cero, ir a DIASSEPTIEMBRE
    RETURN   

;----------------------------------------------- OCTUBRE ---------------------------------------------;    
MES_OCTUBRE:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES10	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES10:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31		// Si da cero, ir a DIASOCTUBRE

    RETURN   
;----------------------------------------------- NOVIEMBRE ---------------------------------------------;    
MES_NOVIEMBRE:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES11	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES11:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS30	// Si da cero, ir a DIASNOVIEMBRE
   
    RETURN   
;----------------------------------------------- DICIEMBRE ---------------------------------------------;    
MES_DICIEMBRE:
    DECF    CONTADORDIAS_3	// Se decrementa en 1 la variable CONTADORDIAS_3
    BANKSEL PORTA
    CLRF    DIA_UNI		// Se limpia DIA_UNI
    CLRF    DIA_DECE		// Se limpia DIA_DECE

    MOVF    CONTADORDIAS_3, W	// Se mueve el valor de CONTADORDIAS_3 a W
    MOVWF   CONTADORDIAS_3	// Se mueve W a CONTADORDIAS_3 (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_DECE		// Se incrementa en 1 la variable DIA_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    DIA_DECE		// Si no está encedida, se decrementa en 1 la variable DIA_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   10			// Se mueve 10 a W
    ADDWF   CONTADORDIAS_3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADES12	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADES12:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   CONTADORDIAS_3, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    DIA_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   CONTADORDIAS_3, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
   
    MOVF    DIA_UNI, W		// Se mueve DIA_UNI a W
    ADDWF   DIA_DECE, W		// Se añade el valor de W a DIA_DECE y se guarda en W
    BTFSC   ZERO		// Se verifica si la suma de ambas variables dio cero (si no da cero regresa)
    CALL    DIAS31	// Si da cero, ir a DIASDICIEMBRE

    RETURN   
;----------------------------------------------- DIAS MESES ---------------------------------------------;
DIAS31:
    MOVLW   3			// Se mueve la literal 3 a W
    MOVWF   DIA_DECE		// Se mueve W a DIA_DECE
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   DIA_UNI		// Se mueve W a DIA_UNI
    RETURN
    
DIAS30:
    MOVLW   3			// Se mueve la literal 3 a W
    MOVWF   DIA_DECE		// Se mueve W a DIA_DECE
    MOVLW   0			// Se mueve la literal 1 a W
    MOVWF   DIA_UNI		// Se mueve W a DIA_UNI
    RETURN
    
DIAS28:
    MOVLW   2			// Se mueve la literal 3 a W
    MOVWF   DIA_DECE		// Se mueve W a DIA_DECE
    MOVLW   8			// Se mueve la literal 1 a W
    MOVWF   DIA_UNI		// Se mueve W a DIA_UNI
    RETURN
;------------------------------------ SUBRUTINAS DE INCREMENTO MESES -----------------------------------;
INC_MES_2:
    CLRF    DIA_UNI		// DIA_UNI se limpia
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    CLRF    DIA_DECE		// DIA_DECE se limpia
    
    INCF    MES_UNI		// Se incrementa en 1 la variable MES_UNI
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CLRF    MES_UNI		// MES_UNI se limpia
    BTFSC   ZERO		// Analiza si ZERO está encendido, se salta una línea
    INCF    MES_DECE		// Se incrementa en 1 la variable MES_DECE
    
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    SUBLW   1			// Se resta W a 1 (1-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    CALL    MES12_2		// Se llama la subrutina para obtener los 12 meses completos
    
    RETURN
    
MES12_2:
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    SUBLW   3			// Se resta W a 3 (3-W)
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea 
    CALL    RESET_MES_DIA_2	// Se llama la subrutina de poner en cero mes y dias (se cumplio el año)
    
    RETURN
    
RESET_MES_DIA_2:
    CLRF    DIA_UNI		// DIA_UNI se limpia
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI 
    CLRF    DIA_DECE		// DIA_DECE se limpia
    CLRF    MES_UNI		// MES_UNI se limpia
    INCF    MES_UNI		// Se incrementa en 1 la variable MES_UNI
    CLRF    MES_DECE		// MES_DECE se limpia

    RETURN
;----------------------------------- SUBRUTINAS DE DECREMENTO MES  ----------------------------------;     
DEC_MES:
    CLRF    CONTADORMES_2	// Se limpia CONTADORMES_2
    CLRF    CANTIDADMES10_2	// Se limpia CANTIDADMES10_2
    MOVF    MES_UNI, W		// Se mueve el valor de MES_UNI a W
    ADDWF   CONTADORMES_2, F	// Se añade W a CONTADORMES_2, y se guarda CONTADORMES_2
    EVALUARMESDECE3:
    MOVF    MES_DECE, W		// Se mueve el valor de MES_DECE a W
    ADDWF   CONTADORMES_2, F	// Se añade W a CONTADORMES_2, y se guarda CONTADORMES_2
    
    INCF    CANTIDADMES10_2	// Se incrementa en 1 la variable CANTIDADMES10_2
    MOVF    CANTIDADMES10_2, W	// Se mueve el valor de CANTIDADMES10_2 a W
    SUBLW   10			// Se resta W a 10 (10-W)
    BTFSS   ZERO		// Analiza si ZERO está encendido, se salta una línea
    GOTO    EVALUARMESDECE3	// Si está apagado, se regresa a la etiqueta de 
				// EVALUARMESDECE3 para sumar 10 veces el valor de MES_DECE*/
    
    DECF    CONTADORMES_2, F	// Se decrementa en 1 la variable MES_UNI
    MOVF    CONTADORMES_2, W	// Se mueve el valor de CONTADORMES_2 a W   
    CALL    TABLA_DE_MES	// Se busca valor de contador mes para determinar el mes
    MOVWF   VAL_MES_TABLA	// Se guarda el valor de la tabla en VAL_MES_TABLA

    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   0			// XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_12		// Si ZERO está activo, se llama la rutina de MES_12
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   11			// XOR entre W y 11, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_11		// Si ZERO está activo, se llama la rutina de MES_11
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   10			// XOR entre W y 10, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_10		// Si ZERO está activo, se llama la rutina de MES_10
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   9			// XOR entre W y 9, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_9		// Si ZERO está activo, se llama la rutina de MES_9
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   8			// XOR entre W y 8, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_8		// Si ZERO está activo, se llama la rutina de MES_8
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   7			// XOR entre W y 7, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_7		// Si ZERO está activo, se llama la rutina de MES_7
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   6			// XOR entre W y 6, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_6		// Si ZERO está activo, se llama la rutina de MES_6
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   5			// XOR entre W y 5, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_5		// Si ZERO está activo, se llama la rutina de MES_5
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   4			// XOR entre W y 4, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_4		// Si ZERO está activo, se llama la rutina de MES_4
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   3			// XOR entre W y 3, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_3		// Si ZERO está activo, se llama la rutina de MES_3
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de VAL_MES_TABLA a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   2			// XOR entre W y 2, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_2		// Si ZERO está activo, se llama la rutina de MES_2
    
    MOVF    VAL_MES_TABLA, W	// Se mueve valor de MODO a W
    BCF	    ZERO		// Se limpia la bandera de ZERO
    XORLW   1			// XOR entre W y 0, si los valores son iguales ZER0=1, de lo contrario es ZER0=0
    BTFSC   ZERO		// Analiza si ZERO está apagado, se salta una línea
    GOTO    MES_1		// Si ZERO está activo, se llama la rutina de MES_1
    REGRESAR4:
    CLRF    DIA_UNI		// DIA_UNI se limpia
    INCF    DIA_UNI		// Se incrementa en 1 la variable DIA_UNI
    CLRF    DIA_DECE		// DIA_DECE se limpia
    RETURN

MES_12:
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   2			// Se mueve la literal 2 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

MES_11:
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

MES_10:
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
        
MES_9:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   9			// Se mueve la literal 9 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
    
MES_8:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   8			// Se mueve la literal 8 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
    
MES_7:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   7			// Se mueve la literal 7 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
    
MES_6:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   6			// Se mueve la literal 6 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
    
MES_5:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   5			// Se mueve la literal 5 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4
    
MES_4:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   4			// Se mueve la literal 4 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

MES_3:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   3			// Se mueve la literal 3 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

MES_2:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   2			// Se mueve la literal 2 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

MES_1:
    MOVLW   0			// Se mueve la literal 0 a W
    MOVWF   MES_DECE		// Se mueve W a MES_DECE
    MOVLW   1			// Se mueve la literal 1 a W
    MOVWF   MES_UNI		// Se mueve W a MES_UNI
    GOTO    REGRESAR4

;-------------------------------- SUBRUTINAS DE INCREMENTO SEGUNDOS  -------------------------------;
INC_SEGST:
    BANKSEL PORTA
    CLRF    SEGTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    SEGTMR_DECE		// Se limpia SEGTMR_DECE

    MOVF    SEGUNDOSTMR2, W	// Se mueve el valor de SEGUNDOSTMR a W
    MOVWF   SEGUNDOSTMR2		// Se mueve W a SEGUNDOSTMR (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   SEGUNDOSTMR2, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR
    INCF    SEGTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    SEGTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   SEGUNDOSTMR2, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADESSEG	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESSEG:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   SEGUNDOSTMR2, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    SEGTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    SEGTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   SEGUNDOSTMR2, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
    RETURN
;-------------------------------- SUBRUTINAS DE DECREMENTO SEGUNDOS  -------------------------------;
DEC_SEGST:
    BANKSEL PORTA
    MOVF    SEGUNDOSTMR, W
    MOVWF   SEGUNDOSTMR3
    
    CLRF    SEGTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    SEGTMR_DECE		// Se limpia SEGTMR_DECE

    MOVLW   10			// Se mueve 10 a W
    SUBWF   SEGUNDOSTMR3, F	// Se resta W a SEGUNDOSTMR y se guarda en SEGUNDOSTMR
    INCF    SEGTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    SEGTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   SEGUNDOSTMR3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo
    CALL    OBTENER_UNIDADESSEG2	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESSEG2:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   SEGUNDOSTMR3, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR2
    INCF    SEGTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    SEGTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR2
    MOVLW   1			// Se mueve 1 a W
    ADDWF   SEGUNDOSTMR3, F	// Se añade 1 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo (en este caso, cero)
    RETURN
;-------------------------------- SUBRUTINAS DE INCREMENTO SEGUNDOS  -------------------------------;
INC_MINT:
    BANKSEL PORTA
    CLRF    MINTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    MINTMR_DECE		// Se limpia SEGTMR_DECE

    MOVF    MINUTOSTMR2, W	// Se mueve el valor de SEGUNDOSTMR a W
    MOVWF   MINUTOSTMR2		// Se mueve W a SEGUNDOSTMR (actualiza)
    MOVLW   10			// Se mueve 10 a W
    SUBWF   MINUTOSTMR2, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR
    INCF    MINTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    MINTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   MINUTOSTMR2, F	// Se añaden los 10 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo
    CALL    OBTENER_UNIDADESMIN	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESMIN:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   MINUTOSTMR2, F	// Se resta W a CONTADORDIAS_3 y se guarda en CONTADORDIAS_3
    INCF    MINTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    MINTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de CONTADORDIAS_3
    MOVLW   1			// Se mueve 1 a W
    ADDWF   MINUTOSTMR2, F	// Se añade 1 a lo que tenga en ese momento negativo en CONTADORDIAS_3 para que sea positivo (en este caso, cero)
    RETURN
;-------------------------------- SUBRUTINAS DE DECREMENTO SEGUNDOS  -------------------------------;
DEC_MINT:
    BANKSEL PORTA
    MOVF    MINUTOSTMR, W
    MOVWF   MINUTOSTMR3
    
    CLRF    MINTMR_UNI		// Se limpia SEGTMR_UNI
    CLRF    MINTMR_DECE		// Se limpia SEGTMR_DECE

    MOVLW   10			// Se mueve 10 a W
    SUBWF   MINUTOSTMR3, F	// Se resta W a SEGUNDOSTMR y se guarda en SEGUNDOSTMR
    INCF    MINTMR_DECE		// Se incrementa en 1 la variable SEGTMR_DECE
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW 
				// (si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida, se regresa 4 instrucciones atrás
    DECF    MINTMR_DECE		// Si no está encedida, se decrementa en 1 la variable SEGTMR_DECE
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR
    MOVLW   10			// Se mueve 10 a W
    ADDWF   MINUTOSTMR3, F	// Se añaden los 10 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo
    CALL    OBTENER_UNIDADESMIN2	// Se llama la subrutina para obtener las unidades
    
    RETURN
OBTENER_UNIDADESMIN2:
    MOVLW   1			// Se mueve 1 a W
    SUBWF   MINUTOSTMR3, F	// Se resta W a SEGUNDOSTMR2 y se guarda en SEGUNDOSTMR2
    INCF    MINTMR_UNI		// Se incrementa en 1 la variable DIA_UNI
    BTFSC   STATUS, 0		// Se verifica si está apagada la bandera de BORROW
				//(si está apagada quiere decir que la resta obtuvo un valor negativo)
				// si está encendida quiere decir que hay un valor positivo
    GOTO    $-4			// Si está encedida se regresa 4 instrucciones atras
    DECF    MINTMR_UNI		// Si no está encedida, se decrementa en 1 la variable DIA_UNI
				// para compensar el incremento de más que se hace
				// al momento en que se reevalua el valor de SEGUNDOSTMR2
    MOVLW   1			// Se mueve 1 a W
    ADDWF   MINUTOSTMR3, F	// Se añade 1 a lo que tenga en ese momento negativo en SEGUNDOSTMR2 para que sea positivo (en este caso, cero)
    RETURN
END