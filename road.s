		AREA datos,DATA
;vuestras variables y constantes
VICIntEnable 	EQU 0xFFFFF010
VICIntEnClr 	EQU 0xFFFFF014
VICVectAddr0	EQU 0xFFFFF100
VICVectAddr		EQU 0xFFFFF030

ancho_ctra		DCD 7 ;ancho entre columnas
teclado_so		DCD 0
timer_so		DCD 0
clock			DCD 0 ;contador de centesimas de segundo
vel 			DCD 8 ;velocidad de movimiento (en centesimas s.)
cont 			DCD 0 
	
;instante siguiente movimiento
dirx 			DCB 0 ;direccion mov. caracter ‘H’ (-1 izda.,0 stop,1 der.)
diry 			DCB 0 ;direccion mov. caracter ‘H’ (-1 arriba,0 stop,1 abajo) 
terminar		DCB 0 ;indicador fin de programa (si vale 1)
	
T0_IR           EQU	0xE0004000
RDAT 			EQU	0xE0010000
PANT			EQU 0x40007E00	; dirección de primera posición de pantalla
FIN_PANT		EQU 0x40007FFF	; dirección de última posición de pantalla
MASK			EQU 0xFFFFFF00	; máscara de bits
DCHA			EQU 0x00000055	; rango del aleatorio para ir a la derecha
IZQDA			EQU 0x000000AA	; rango del aleatorio para ir a la izquierda
SEMILLA			EQU 1

		AREA codigo,CODE
		EXPORT inicio				; forma de enlazar con el startup.s
		IMPORT srand				; para poder invocar SBR srand
		IMPORT rand					; para poder invocar SBR rand
		
; invocar a la subrutina srand que tiene 1 parámetro (semilla de aleatorios) y ningún resultado		
inicio	mov r0, #SEMILLA
		ldr r10, =0x40007FEC		; dirección inicial del coche
		PUSH {r0}					; apilar registro del parámetro que pasa por valor
		bl srand					; llamar a la SBR del fichero rand.s
		add sp, sp, #4				; sp+4 para apuntar a la nueva cima
		
; programar RSI_IRQ4 -> RSI_reloj
; programar RSI_IRQ7 -> RSI_teclado	
		ldr r0, =VICVectAddr0		; r0 = @vectorDireccionesRSI antiguas
		ldr r1, =teclado_so			; r1 = dirección donde se guardará RSI de teclado antiguo
		mov r2, #7
		ldr r3, [r0, r2, LSL #2]	; r3 = @teclado_so antigua
		str r3, [r1]
		
		ldr r4, =timer_so			; r4 = dirección donde se guardará RSI de timer antiguo
		mov r6, #4
		ldr r5, [r0, r6, LSL #2]	; r5 = @timer_so antigua
		str r5, [r4]		
		
		ldr r1, =RSI_tec			; r1 = @RSI_tec mía
		str r1, [r0, r2, LSL #2]	; Mem(@VIC[7*4]) = @RSI_tec mía
		
		ldr r1, =RSI_timer			; r1 = @RSI_timer mía
		str r1, [r0, r6, LSL #2]	; Mem(@VIC[4*4]) = @RSI_timer mío
		
; activar IRQ4,IRQ7
		ldr r0, =VICIntEnable
		ldr r1, =2_10010000			; set bits 4 y 7 de timer y teclado
		str r1, [r0]				; bits 4 y 7 activados para seleccionar teclado y timer en máscara Mem[@r0]=r1
		
; dibujar pantalla inicial
		mov r0, #'#'
		mov r3, #' '
		ldr r1, =PANT
		mov r2, #16				; r2 = número de filas de carretera
		
while	mov r4, #8				; r4 = espacios hasta la primera columna
blanco1 strb r3, [r1], #1		; ponemos espacios
		subs r4, r4, #1
		bne blanco1				; si espacios !=0 vuelve al bucle
		strb r0, [r1]			; escribe # en la columna 8
		ldr r4, =ancho_ctra
		ldr r4, [r4]			; r4 = espacios entre las 2 columnas
blanco2 strb r3, [r1, #1]!		; ponemos espacio s
		subs r4, r4, #1
		bne blanco2				; si ancho_ctra !=0 vuelve al bucle
		strb r0, [r1, #1]!		; ponemos segundo # en columna 16
		mov r4, #15				; r4 = espacios hasta fin de línea
blanco3 strb r3, [r1, #1]!		; ponemos espacios
		subs r4, r4, #1
		bne blanco3				; si espacios !=0 vuelve al bucle
		add r1, r1, #1			; pasa a la siguiente fila
		subs r2, r2, #1			; fila-- (queda una fila menos por poner)
		bne while				; mientras siga habiendo filas, se repite todo
		mov r2, #'H'
		sub r1, r1, #23			; se queda en la última fila
		strb r2, [r1, #3]		; escribe H en el medio		
		
; calcular instante siguiente movimiento
bucle	ldr r0, =clock
		ldr r1, =vel
		ldr r2, =cont
		
		ldrb r0, [r0]
		ldrb r1, [r1]
		ldrb r3, [r2]
		
		cmp r0, r3
		bne bucle			; vuelve al bucle si clock < cont
		
		add r3, r3, r1		; sumamos vel a cont
		strb r3, [r2]		; guardamos el nuevo valor de cont en memoria
		
; comprobar si se choca cuando el coche no se mueve
		sub r1, r10, #32	; casilla de arriba de la H
		ldrb r1, [r1]
		cmp r1, #'#'
		bne next 			; salta si no es un #

; se ha chocado y para el programa
parar	ldr r0, =terminar
		mov r0, #1			; pone terminar a 1
		mov r1, #' '
		strb r1, [r10]		; borra la casilla donde se ha chocado
		b fin_bucle

; baja la carretera: de abajo a arriba coge filas de 2 en 2 y copia la fila de arriba en la de abajo
next	ldr r0, =PANT
		ldr r1, =FIN_PANT
		sub r1, r1, #32		; r1 = final fila de arriba
copiar	ldrb r2, [r1]		; elemento de final fila de arriba
		cmp r2, #'H'
		beq skip			; salta si H en la fila de arriba
		
		ldrb r3, [r1, #32]	; elemento de la fila de abajo
		cmp r3, #'H'
		beq skip			; salta si H en la fila de abajo
		
		strb r2, [r1, #32]  ; elemento fila de abajo = elemento fila de arriba
		
skip	sub r1, r1, #1		; miras siguiente casilla
		cmp r1, r0
		bge copiar			; mientras queden filas vuelve al bucle copiar

; cambiar dirección de carretera
		sub sp, sp, #4		; apilar parámetro de resultado
		bl rand				; llamar a la SBR rand de rand.s
		POP {r0}			; desapilar resultado (número aleatorio)
			
		ldr r1, =MASK
		bic r0, r1			; pone todo a 0 menos los ocho últimos bits
		ldr r5, =DCHA
		ldr r4, =IZQDA
			
; detectar primer #
		ldr r1, =PANT
hashtag	ldrb r2, [r1], #1	; r2 = elemento en @PANT y @PANT+1
		cmp r2, #'#'
		bne hashtag			; salta si no es un #
		sub r1, r1, #1 		; en r1 tenemos la dirección del primer #
			
		ldr r2, =PANT
		add r2, r2, #31		; r2 = primera casilla de la segunda fila
		mov r3, r1
		add r3, r3, #8		; r3 = posición del segundo #
		cmp r3, r2
		beq bucle			; está en el límite de la pantalla
		
		cmp r0, r5
		ble mov_izqda		; aleatorio <= 0x55
		cmp r0, r4
		ble mov_dcha		; 0x55 < aleatorio <= 0xAA
		b bucle				; aleatorio > 0xAA

; mover carretera una posición a la derecha
mov_dcha  ; borrar lo anterior
		 mov r3, #' '
		 strb r3, [r1]	
		 strb r3, [r1, #8]
		; mover # a la derecha
		 mov r4, #'#'
		 strb r4, [r1, #1]
		 strb r4, [r1, #9]
		 
		 b bucle

; mover carretera una posición a la izquierda
mov_izqda 	; borrar lo anterior
			mov r3, #' '
			strb r3, [r1]	
			strb r3, [r1, #8]
			; mover # a la izquqierda
			mov r3, #'#'
			strb r3, [r1, #-1]
			strb r3, [r1, #7]
			 
			b bucle

;desactivar IRQ4,IRQ7
fin_bucle	ldr r2, =VICIntEnClr	; MÁSCARA: no permite que entren más interrupciones
			ldr r3, =2_10010000
			str r3, [r2]
			
			ldr r1, =teclado_so		; deja el teclado antiguo donde estaba antes
			ldr r3, [r1]
			mov r4, #7
			ldr r0, =VICVectAddr0
			str r3, [r0, r4, LSL #2]
			
			ldr r1, =timer_so		; deja el teclado antiguo donde estaba antes
			ldr r3, [r1]
			mov r4, #4
			str r3, [r0, r4, LSL #2]
		
fin			b fin
		
; Rutina de servicio a la interrupcion IRQ7 (teclado)
; al pulsar cada tecla llega petición de interrupción IRQ7
RSI_tec	sub lr, lr, #4
		PUSH {lr}
		mrs r14, spsr
		PUSH {r14}
		msr cpsr_c, #2_01010010
		
		PUSH {r0-r7}
		ldr r0, =RDAT
		ldrb r0, [r0]
		
		cmp r0, #'+'
		beq aumenta				; se duplica la velocidad
		cmp r0, #'-'
		beq reduce				; se divide a la mitad la velocidad
		
		bic r0, r0, #2_100000	; paso a mayúsculas
		cmp r0, #'Q'
		bne sigue
		
; poner terminar a 1 para que termine el programa
		ldr r0, =terminar	
		mov r1, #1
		strb r1, [r0]
		b fin_bucle
		
; no se ha pulsado la tecla de finalizar el programa (Q)
sigue	mov r2, #'H'
		mov r3, #' '

; buscamos donde se encuentra el coche y r10 guarda su dirección
		ldr r10, =PANT 
buscar	add r10, r10, #1
		ldrb r5, [r10]
		cmp r5, r2			; miramos si es el coche
		bne buscar

; miramos si se ha pulsado alguna tecla del programa
		cmp r0, #'J'
		moveq r1, #-1
		beq eje_x		; si se ha pulsado J se mueve a la izquierda
		cmp r0, #'L'	
		moveq r1, #1
		beq eje_x	    ; si se ha pulsado L se mueve a la derecha
		
		cmp r0, #'I'
		moveq r1, #-1
		beq subir		; si se ha pulsado I se mueve hacia arriba
		cmp r0, #'K'	
		moveq r1, #1	; si se ha pulsado K se mueve hacia abajo
		bne fin_RSI		; no se ha pulsado ninguna tecla del programa
		
; el coche se mueve arriba (1) o abajo (-1) y r10 tiene la dirección del coche
bajar	ldr r4, =FIN_PANT
		sub r4, r4, #32		; r4 es última dirección de penúltima fila
		cmp r10, r4			; miramos límite inferior de pantalla
		bgt fin_RSI			; salta si el coche está en última fila y quiere bajar
		b eje_y				; si no, sigue a eje_y
		
subir	ldr r4, =PANT
		add r4, r4, #32		; r4 es primera dirección de segunda fila
		cmp r10, r4			; miramos límite superior de pantalla
		blt fin_RSI			; salta si el coche está en primera fila y quiere subir		

eje_y	strb r3, [r10]		; borramos el coche
		mov r5, #32
		mul r6, r1, r5		; r6 = 1*32 ó -1*32
		
		add r10, r10, r6	; r10 es nueva dirección del coche
		ldrb r5, [r10]
		cmp r5, #'#'
		beq parar			; el coche se ha chocado
		strb r2, [r10]		; ponemos el coche en la nueva dirección
		b fin_RSI
		
; el coche se mueve a la derecha (1) o a la izquierda (-1) y r10 tiene la dirección del coche
eje_x 	strb r3, [r10]		; borramos el coche
		add r10, r10, r1	; nueva dirección del coche
		ldrb r5, [r10]
		cmp r5, #'#'
		beq parar			; el coche se ha chocado
		strb r2, [r10]		; ponemos el coche en la nueva dirección
		b fin_RSI

; duplicar velocidad
aumenta	ldr r1, =vel
		ldrb r0, [r1]	; r0=tiempo por fila
		cmp r0, #1		; velocidad máxima = 0,01 segundos
		beq fin_RSI		; no se puede aumentar más la velocidad
		LSR r0, #1		; tiempo por fila/2
		strb r0, [r1]
		b fin_RSI
		
; mitad de velocidad		
reduce	ldr r1, =vel	
	    ldrb r0, [r1]	; r1=tiempo por fila
	    cmp r0, #128	; velocidad mínima = 1,28 segundos
		beq fin_RSI		; no se puede reducir más la velocidad
	    LSL r0, #1 		; r0=tiempo por fila*2 para que tarde el doble
	    strb r0, [r1]
	    b fin_RSI
		
;desactivar RSI_teclado
fin_RSI	POP {r0-r7}
		msr cpsr_c, #2_11010010
		POP {r14}
		msr spsr_fsxc, r14
		ldr r14, =VICVectAddr
		str r14, [r14]
		POP {pc}^
		
;Rutina de servicio a la interrupcion IRQ4 (timer 0)
;Cada 0,01 s. llega una peticion de interrupcion
RSI_timer 	sub lr, lr, #4 
			PUSH {lr}
			mrs r14, spsr
			PUSH {r14}
			msr cpsr_c, #2_01010010
			
			PUSH {r0,r1}
			ldr r0, =T0_IR		; bajo la petición de interrupción
			mov r1, #1
			str r1, [r0]
			
			ldr r0, =clock
			ldrb r1, [r0]
			add r1, r1, #1		; clock++
			str r1, [r0]
			
 ;desactivar RSI_timer
			POP {r0,r1}

			msr cpsr_c, #2_11010010
			POP {r14}
			msr spsr_fsxc, r14
			ldr r14, =VICVectAddr
			str r14, [r14]
			POP {pc}^

			END