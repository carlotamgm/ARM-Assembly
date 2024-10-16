


	AREA codigo, CODE
			EXPORT ordena
; asumimos	registros r0= @T y r1= n

;SBR void ordena(int *T,int n)
			
ordena		PUSH {r11, lr}		;	apila @ret y fp
			mov fp, sp 			; 	fp=sp
			PUSH {r2}    		; 	apila registros
			sub r2, r1, #1 		;	r2=n-1
			mov r1, #0			;	r1 es 0
			
; qksort(T,0,n-1)

			PUSH {r0-r2}		; 	apilo regs con parámetros
			bl quicksort		; 	llama a la sbr y guarda @ret en r14
			
			add sp, sp, #12  	; 	sp se queda en r0

			POP {r2, r11, pc}	; 	desapila regs
								; 	desapila fp 
								; 	desapila @ret a r15=pc	
								; 	branch a @lr


;SBR quicksort

quicksort	
			PUSH {r0-r7, r11, lr};	apila registros
			add fp, sp, #32 	; 	fp=sp+32 pq sp está en r0(cima)
			
			ldr	r0, [fp, #8]	; 	r0=@fp+8 QUE ES @T
			ldr r1, [fp, #12]	; 	r1=@fp+12 es 0 QUE ES iz
			ldr r2, [fp, #16] 	;	r2 es n-1 QUE ES de
			mov r3, r1			;	i=iz; r3 es i
			mov r4, r2			;	j=de; r4 es j
			
			add r8, r1, r2		;	r8=iz+de
			mov r8, r8, lsr #1	;	r8=r8/2
			ldr r5, [r0, r8, lsl #2] ; r5 es @T+(iz+de)*4 = x
			
			
w2			ldr r7, [r0, r3, lsl #2]	;	r7=T[i] 
			cmp r7, r5			; 	if T[i]<x					while (T[i]<x) i=i+1;
								;	if T[i]>=x sigue al w3
			addlt r3, r3, #1	;	i++
			blt w2				;	salta al primer while

w3			ldr r6, [r0, r4, lsl #2]	;	r6=T[j] 			while (x<T[j]) j=j-1;
			cmp r5, r6			;	if x<T[j]
			sublt r4, r4, #1	;	j--
			blt w3				;	salta al segundo while: w3
			
if1			cmp r3, r4			; 								if(i<=j)
			bgt cond				; 							INTERCAMBIO:
			str r7, [r0, r4, lsl #2]	; 	Mem[@T[j]]=T[i]		w=T[i];T[i]=T[j];T[j]=w; 
			str r6, [r0, r3, lsl #2]	;	Mem[@T[i]]=T[j]
			
			add r3, r3, #1		; 	i++							i=i+1;j=j-1;
			sub r4, r4, #1		;	j--
			
w1			cmp r3, r4			;								while i<=j 
			ble w2				;	si se cumple, salta al primer while: w2

cond		cmp r1, r4			;	if iz<j sigue
			bge cond2			;	if iz>=j salta al fincond
			
			PUSH {r0, r1, r4}	;	apila registros
			bl quicksort		;	LLAMA A SBR RECURSIVAMENTE con (T,iz,j)
			add sp, sp, #12   	; 	sp se queda en r0 (cima)
			
cond2		cmp r3, r2			;	if i<de sigue
			bge fincond			;	if i>=de salta a fincond
			PUSH {r2}			;	apila registros en orden
			PUSH {r3}
			PUSH {r0}
			bl quicksort		;	LLAMA A SBR con (T,i,de)
			add sp, sp, #12   	; 	sp se queda en r0 (cima)

fincond		POP {r0-r7, r11, pc}; 	desapila regs, fp
								; 	desapila @ret a r15=pc y branch a @lr
			END
			