.model flat,c
.data
byteoffset dword 0
.code
writeheader			proc
			push ebp
			mov ebp,esp
			push ebx
			push edi

			xor ecx,ecx
			xor eax,eax

			;get byte offset
			mov edx,DWORD PTR [ebp+8]
			mov ch,byte ptr [edx]
			;get adress where to write
			mov edi,[ebp+12]
			;get BFINAL
			mov ah,BYTE PTR [ebp+16]
			
			xor ebx,ebx					;we're using bl to keep track of how many bits to push

			mov edx,0

			;write the header
			shl edx,2
			add edx,01b
			shl edx,1	;write BFINAL
			add dl,ah

			add bl,3	;we wrote 3 bits

			;retrieve unfinished byte at this adress, write it to al to continue packing
			add al,BYTE PTR [edi]				;write the unfinished byte to al


			;push this to al,writing whenever full
advance:	
			mov cl,bl							;prepare cl to serve as loop index
@@:
			shr al,1
			shr edx,1
			jnc skipinc							;if it's not a 1, don't add a 1 to eax, just shift it
			add al,128
skipinc:	inc ch
			cmp ch,8							;check that al has not been filled
			jae write							;if it has, write it to memory
litloop1:	dec cl
			cmp cl,0
			ja @B								;keep looping till we've pushed as many bits as the code length
			jmp done

write:		;if the buffer (al) is full, write it to memory and empty it.
			mov BYTE PTR [edi],al
			mov ch,0							;reset the number of bytes written
			mov al,0							;reset al to 0
			inc edi								;increment the out pointer
			jmp litloop1						;get back to the loop


done:		
			mov BYTE PTR [edi],al				;if we're done, write the unfinished byte at the adress we were going to write to
			mov eax,edi						;return the unfinished byte adress
			mov edx,[ebp+8]					;and the byte offset in the first argument
			movzx ecx,ch					;zero extend byte offset
			mov DWORD PTR [edx],ecx			;write it to output variable

			pop edi
			pop ebx
			pop ebp
			ret
writeheader			endp
end