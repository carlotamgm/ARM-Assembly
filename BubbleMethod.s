		AREA data, DATA, READWRITE
M       EQU 7
N 		EQU 5
T  		DCB "nkongvfkobcfeqpbjufcxxfrewomnkgytvd"

		AREA codigo, CODE, READONLY
		ENTRY
		
		ldr r0, =N 			; r0=num filas
		ldr r1, =M			; r1=num cols
		ldr r2, =T			; r2=@T
		
		mov r3, #1			; r3=k=1
buc1	cmp r3, r1			; if k>M salta
		bgt fin
							;columna num 1 
		mov r4, #1			; r4=i=1
buc2	cmp r4, r0			; if i>N salta
		bgt buc1				
		
		sub r5, r0, #1		; r5=j=N-1
buc3	cmp r5, r4			;if r5<r4 salta
		blt finbuc2
		
if		sub r6, r5, #1; r6=r5-1=j-1
		
		ldrb r6, [r6, r2]		;r6=@r6+@r2=T[j-1]
		ldrb r7, [r5, r2]		;r7=@r5+@r2
		
		cmp r6, r7				;if r6<r7 salta
		blt finIf
		
		strb  r6,[r2, r5] ; Mem[r2+r5=@T+j]=r6 meter la letra en mem en la posición en la que estaba antes
		sub r6, r5, #1; r6=r5-1=j-1
		strb r7, [r2, r6]; Mem[r2+r6=@T+j-1]
						
finIf	sub r5, r5, #1	;r5=r5-1
		b buc3
		
finbuc2	add r4, r4, #1
    	b buc2
		
finbuc3	add r3, r3, #1
		add r4, r4, r0; r4=i+N filas para empezar en primera letra de columna sig. COMPROBARRRRR
		b buc1
		
fin b fin
	END