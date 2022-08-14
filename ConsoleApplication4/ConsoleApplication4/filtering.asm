.model flat,c
.data
PW WORD 0
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

	;do the first 3 values (first pixel) without filtering.
	mov ah,0
lp1bis:
	mov dh,[ebx]
	mov [esi],dh
	inc esi
	inc ebx
	dec ecx
	inc ah
	cmp ah,3
	jl lp1bis

	;loop over the array,computing differences
lp1:
	mov dl,[ebx]
	sub ebx,3			;3 following lines : access value for this channel on last pixel
	mov al,[ebx]
	add ebx,3
	sub dl,al
	mov [esi],dl
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

	;for the first 3 values, subtract up/2 from current value
	mov al,0
lp3bis:
	mov dl,[ebx]
	sub ebx,ecx
	mov ah,[ebx]
	add ebx,ecx
	shr ah,1
	sub dl,ah
	mov [esi],dl
	inc esi
	inc al
	inc ebx
	cmp al,3
	jl lp3bis

	

	;loop over the array, grabbing upper-line value thanks to ecx
	;computing the average into dl
	;we have to divide each average component to avoid getting a value greater than 256 from the addition.
	;since we're dividing+rounding twice, we risk losing 2 ones, so we use the carry flag after shifts to see if we're rounding
lp3:
	xor dh,dh		;storing how much we lose by rounding into dh -- if we lose twice, we need to add one to the average.
	mov al,[ebx]	;get current value
	mov ah,[ebx-3]	;get value from previous pixel
	shr ah,1		;divide it by 2 preparing for average
	jnc @F
	inc dh
@@:	sub ebx,ecx
	mov dl,[ebx]	;get previous scanline value
	shr dl,1		;divide it by 2 preparing for average
	jnc @F			;if we lost precision by rounding, add one to dh
	inc dh
@@:	add ebx,ecx
	add dl,ah		;compute average of U and l (they are already divided)
	shr dh,1
	add dl,dh		;if dh is two (meaning we divided two odd numbers by two), we need to add 2/2=1 to the average.
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

lpbis4:	;for the first 3 values (first pixel), only the up pixels will have a value ; p will be UP, UP will minimize it so this is like f2.
	mov dl,[ebx]	;retrieve current value
	sub ebx,ecx
	mov ah,[ebx]	;access upper pixel value
	add ebx,ecx
	sub dl,ah		;sub UP from current
	mov [esi],dl	;write result
	inc esi
	inc ebx
	inc al
	cmp al,3
	jl lpbis4

	

	;loop over the array, grabbing upper-line value thanks to ecx, keeping former value into ah and UL value in dh and U value in dl
	mov dh,0		;UL starts as 0 , just as L
lp4:
	mov al,[ebx]	;get current value (L)
	sub ebx,ecx
	mov dl,[ebx]	;get previous scanline value (U)
	mov dh,[ebx-3]
	add ebx,ecx
	mov ah,[ebx-3];get previous pixel value
	;store current U,L,UL values before overwriting the ah,dh,dl registers (using full dx to compute P)
	mov [U],dl
	mov [UL],dh
	mov [L],ah
	;compute the p into [P]
	movzx dx,[U]
	mov [PW],dx		;compute p=U+L-UL
	movzx dx,[L]
	add [PW],dx		;compute p=U+L-UL
	;if (U+L) is below (UL), PW (unsigned) will modulo to a high value so we just set PW to 0, which will force choosing the smallest of U,L,UL.
	movzx dx,[UL]
	cmp [PW],dx
	jae sb
	mov [PW],0
	jmp sk
sb:	sub [PW],dx		;compute p=U+L-UL
sk: ;P is to be the byte version of PW, to allow the following operations without too many memory transfers.
	cmp [PW],255
	jle nm
	mov [P],255		;if PW was over 255, we set new P to 255
	jmp nn
nm:	mov dx,[PW]
	mov [P],dl		;otherwise, set P to the lower byte of PW
	;absolute difference between p and each u,l,uv, using [BEST] as a buffer
nn:	mov dl,[U]			;between p and u
	mov [BEST],dl
	sub dl,[P]
	cmp dl,[BEST]
	jbe @F			;if inferior, diff is absolute
	mov [BEST],dl				;otherwise, needs to be inverted (ex : 206 turns into 50)
	mov dl,255
	sub dl,[BEST]
	add dl,1
@@:
	mov ah,[L]		;between p and l
	mov [BEST],ah
	sub ah,[P]
	cmp ah,[BEST]
	jbe @F			;if inferior, diff is absolute
	mov [BEST],ah				;otherwise, needs to be inverted (ex : 206 turns into 50)
	mov ah,255
	sub ah,[BEST]
	add ah,1
@@:	
	mov dh,[UL]		;between p and ul
	mov [BEST],dh
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
	ja @F
	cmp ah,dh
	ja @F
	mov ah,[L]
	mov [BEST],ah
	jmp cmp_done
@@:	cmp dl,dh
	ja @F
	mov dl,[U]
	mov [BEST],dl
	jmp cmp_done
@@:	mov dh,[UL]
	mov [BEST],dh
	jmp cmp_done
cmp_done:
	mov dl,[BEST]
	sub al,dl		;subtract the PAETH value from the current value
	mov [esi],al	;write the result to memory
	
	add ebx,1		;loop back
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