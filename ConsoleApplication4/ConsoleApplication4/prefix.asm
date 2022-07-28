.model flat,c
.data
offsetout dword 0
codesize BYTE 0
.code
encodeliteral		proc
			push ebp
			mov ebp,esp
			push ebx
			push esi
			push edi

			;check that size makes sense    (using ebx for size to do a shift using cl later)
			mov ebx, DWORD PTR [ebp+8]
			cmp ebx,0
			jle DONE

			;get the in and out array pointers
			mov esi,DWORD PTR [ebp+12]
			mov edi,DWORD PTR [ebp+16]

			;we're going to push the codes into al (serves as a buffer) and flush it into the output array everytime we've written 8 bits
			mov ch,0							;ch will count how much has been pushed into al (the buffer)

lp:			;outer loop : encoding one input value
literal:	;label for clarity (we're treating a literal)
			cmp BYTE PTR [esi],144				;if it's a literal under 144, code it that way
			mov cl,BYTE PTR [esi]				;get the offset from base value for this kind of code
			sub cl,0
			movzx edx,cl						;add it to edx
			add edx,00110000b					;add  the base code to edx
			mov BYTE PTR [codesize],8			;set the codesize variable to 8 since we're writing an 8-bit symbol
			jmp advance					;label just for readability
			
advance:	;push the contents of edx into eax, checking each time that eax isn't full
			mov cl,32
			sub cl,BYTE PTR [codesize]			;get the number of non-code bits in edx
			shl edx,cl							;shift them away
			mov cl,BYTE PTR [codesize]			;prepare cl to serve as loop index
@@:
			shl al,1
			shl edx,1
			jnc skipinc							;if it's not a 1, don't add a 1 to eax, just shift it
			inc al
skipinc:	inc ch
			cmp ch,8							;check that al has not been filled
			jae write							;if it has, write it to memory
litloop1:	dec cl
			cmp cl,0
			ja @B								;keep looping till we've pushed as many bits as the code length
			jmp otloop

write:		;if the buffer (al) is full, write it to memory and empty it.
			add edi,DWORD PTR [offsetout]
			mov BYTE PTR [edi],al
			sub edi,DWORD PTR [offsetout]
			mov ch,0							;reset the number of bytes written
			mov al,0							;reset al to 0
			inc DWORD PTR [offsetout]			;increment the out pointer
			jmp litloop1						;get back to the loop

otloop:		;outerloop
			add esi,4
			dec ebx
			cmp ebx,0
			ja lp

DONE:			
			pop edi
			pop esi
			pop ebx
			pop ebp
			ret
encodeliteral		endp
end