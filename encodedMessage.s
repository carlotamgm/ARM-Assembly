    AREA datos, DATA, READWRITE
serie   SPACE 2048; reserva espacio en memoria para 2048 bytes

    AREA prog, CODE, READONLY

    ENTRY
	ldr r1, =serie 
    mov r0, #0; inicializa i=0
    
buc	cmp r0, #1024; while(i<1024)
    bge fin
    strh r0, [r1], #2; dirección múltiplo de 2 = @+2
    add r0, r0, #1
    cmp r0, #1024; if(r0=1024)
	blt buc; if(r0<1024)
    
fin	b fin; fin de programa

    END ; fin de ensamblado