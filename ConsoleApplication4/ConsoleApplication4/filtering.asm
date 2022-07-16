.model flat,c
.data
P BYTE 0
BEST BYTE 0
U BYTE 0
L BYTE 0
UL BYTE 0
.code

;performs SUB filtering on a full scanline (also known as type 1 filtering )
f1	proc
	push ebp
	mov ebp,esp
	push ebx
	push esi

	xor eax,eax

	;retrieve size and pointer to start of line
	mov ecx,[ebp+8]
	mov ebx,[ebp+12]
	mov esi,[ebp+16]

	;check that size makes sense, otherwise return the zero that is in eax
	cmp ecx,0
	jle done1

	;loop over the array,storing previous value into eax
	;a zero is already in eax to start with
lp1:
	mov dl,[ebx]
	mov dh,dl
	sub dh,al
	mov [esi],dh
	mov al,dl
	add ebx,1
	add esi,1
	loop lp1

	mov eax,1
done1:
	pop esi
	pop ebx
	pop ebp
	ret
f1	endp


;performs UP filtering on a full scanline (also known as type 2 filtering )
f2	proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
	push esi

	xor eax,eax

	;retrieve size and pointer to start of line
	mov ecx,[ebp+8]
	mov ebx,[ebp+12]
	mov esi,[ebp+16]

	;check that size makes sense, otherwise return the zero that is in eax
	cmp ecx,0
	jle done2

	;for the loop, set edi as end of scanline
	mov edi,ecx
	add edi,ebx

	;loop over the array, grabbing upper-line value thanks to ecx
lp2:
	mov al,[ebx]
	sub ebx,ecx
	mov dl,[ebx]
	add ebx,ecx
	sub al,dl
	mov [esi],al
	add ebx,1
	add esi,1
	cmp ebx,edi
	jl lp2

	mov eax,1
done2:
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret
f2	endp

;performs AVG filtering on a full scanline (also known as type 3 filtering )
f3	proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
	push esi

	xor eax,eax

	;retrieve size and pointer to start of line
	mov ecx,[ebp+8]
	mov ebx,[ebp+12]
	mov esi,[ebp+16]

	;check that size makes sense, otherwise return the zero that is in eax
	cmp ecx,0
	jle done3

	;for the loop, set edi as end of scanline
	mov edi,ecx
	add edi,ebx

	;loop over the array, grabbing upper-line value thanks to ecx, keeping former value into ah
	;computing the average into dl
lp3:
	mov al,[ebx]	;get current value
	sub ebx,ecx
	mov dl,[ebx]	;get previous scanline value
	add ebx,ecx
	add dl,ah		;compute average of U and l (step 1)
	shr dl,1		;compute average of U and l	(step 2)
	mov ah,al		;store current value for next iteration
	sub al,dl		;substract the average of U and L from current value
	mov [esi],al
	add ebx,1
	add esi,1
	cmp ebx,edi
	jl lp3

	mov eax,1
done3:
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret
f3	endp


;performs PAETH filtering on a full scanline (also known as type 4 filtering )
f4	proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
	push esi

	xor eax,eax

	;retrieve size and pointer to start of line
	mov ecx,[ebp+8]
	mov ebx,[ebp+12]
	mov esi,[ebp+16]

	;check that size makes sense, otherwise return the zero that is in eax
	cmp ecx,0
	jle done4

	;for the loop, set edi as end of scanline
	mov edi,ecx
	add edi,ebx

	;loop over the array, grabbing upper-line value thanks to ecx, keeping former value into ah and UL value in dh and U value in dl
	mov dh,0		;UL starts as 0 , just as L
lp4:
	mov al,[ebx]	;get current value (L)
	sub ebx,ecx
	mov dl,[ebx]	;get previous scanline value (U)
	add ebx,ecx
	;compute the p into [P]
	mov [P],dl		;compute p=U+L-UL
	add [P],ah		;compute p=U+L-UL
	sub [P],dh		;compute p=U+L-UL
	;store current U,L,UL values before overwriting the ah,dh,dl registers
	mov [U],dl
	mov [UL],dh
	mov [L],ah
	;absolute difference between p and each u,l,uv, using [BEST] as a buffer
	mov [BEST],dl		;between p and u
	sub dl,[P]
	cmp dl,[BEST]
	jbe @F			;if inferior, diff is absolute
	mov [BEST],dl				;otherwise, needs to be inverted (ex : 206 turns into 50)
	mov dl,255
	sub dl,[BEST]
	add dl,1
@@:
	mov [BEST],ah		;between p and l
	sub ah,[P]
	cmp ah,[BEST]
	jbe @F			;if inferior, diff is absolute
	mov [BEST],ah				;otherwise, needs to be inverted (ex : 206 turns into 50)
	mov ah,255
	sub ah,[BEST]
	add ah,1
@@:	
	mov [BEST],dh		;between p and ul
	sub dh,[P]
	cmp dh,[BEST]
	jbe @F			;if inferior, diff is absolute
	mov [BEST],dh				;otherwise, needs to be inverted (ex : 206 turns into 50)
	mov dh,255
	sub dh,[BEST]
	add dh,1
@@:

	;choose the best from U,L,UL. place it into [BEST]. Order of comparison : l,u,ul.
	cmp ah,dl
	jae @F
	cmp ah,dh
	jae @F
	mov ah,[L]
	mov [BEST],ah
	jmp cmp_done
@@:
	cmp dl,dh
	jbe @F
	mov dl,[UL]
	mov [BEST],dl
	jmp cmp_done
@@:
	mov dl,[U]
	mov [BEST],dl

cmp_done:
	mov dl,[BEST]
	mov ah,al		;store current value for next iteration
	sub al,dl		;subtract the PAETH value from the current value			!!!!
	mov [esi],al
	sub ebx,ecx
	mov dh,[ebx]	;store up-previous scanline value (UL) for next iteration
	add ebx,ecx
	add ebx,1
	add esi,1
	cmp ebx,edi
	jl lp4

	mov eax,1
done4:
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret
f4	endp

sabs	proc
	push ebp
	mov ebp,esp
	push ebx
	push edi

	xor eax,eax

	mov ecx,[ebp+8]
	mov ebx,[ebp+12]

	;check size
	cmp ecx,0
	jle done5

	;loop over, get absolute value if negative, and accumulate sum into eax (the sum will never be too big for a 32bit register)
abs:
	movzx edx,BYTE ptr[ebx]
	cmp edx,128
	jl @F
	mov edi,edx			;if negative, compute absolute
	mov edx,255
	sub edx,edi
	add edx,1
@@:
	add eax,edx
	add ebx,1
	loop abs

done5:
	pop edi
	pop ebx
	pop ebp
	ret
sabs	endp


end