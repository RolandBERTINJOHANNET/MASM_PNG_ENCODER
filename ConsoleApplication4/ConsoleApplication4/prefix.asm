.model flat,c
.data
codesize BYTE 0
code dword 0
binslen dword 258,227,195,163,131,115,99,83,67,59,
			51,43,35,31,27,23,19,17,15,13,
			11,10,9,8,7,6,5,4,3
codeslen dword 285,284,283,282,281,280,279,278,277,276,275,274,273,
			272,271,270,269,268,267,266,255,264,263,262,261,260,259,258,257

extraslen byte 0,5,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0
isdist byte 0		;keeps track of when we're reading a distance
lpindex dword 0		;index for the loop over bins
lenbuffer dword 0	;used to store the length while we use edx to get the code
membuffer dword 0	;used to store memory adresses from esi while using esi for something else
.code
encodeliteral		proc					;encodes a list of lzss-processed ints with prefix codes
			push ebp
			mov ebp,esp
			push ebx
			push esi
			push edi

			xor eax,eax

			;check that size makes sense    
			mov ebx, DWORD PTR [ebp+8]
			cmp ebx,0
			jle DONE
			mov DWORD PTR [lpindex],ebx			;(using variable for size to free registers for the more frequent operations)

			;get the in and out array pointers
			mov esi,DWORD PTR [ebp+12]
			mov edi,DWORD PTR [ebp+16]

			;we're going to push the codes into al (serves as a buffer) and flush it into the output array everytime we've written 8 bits
			mov ch,0							;ch will count how much has been pushed into al (the buffer)

lp:			;outer loop : encoding one input value
			cmp BYTE PTR [isdist],0;determine if we're treating a distance or a literal/length
			jne distance
			;if we're here, we're treating a literal/length
			cmp dword PTR [esi],0				;determine if we're treating a literal or a length
			jl len

			;if we're here, we're treating a literal
			mov cl,BYTE PTR [esi]				;get value of literal we're treating
			cmp BYTE PTR [esi],144
			jae lit9bit						;if it's above 144 it must be coded on 9 bits
			;if we're here, we're coding a literal on 8 bits (below 144)
			sub cl,0							;get the offset from base value for this kind of code
			movzx edx,cl						;add it to edx
			add edx,00110000b					;add  the base code to edx
			mov BYTE PTR [codesize],8			;set the codesize variable to 8 since we're writing an 8-bit symbol
			jmp advance
lit9bit:
			sub cl,144							;get the offset from base value for this kind of code
			movzx edx,cl						;add it to edx
			add edx,110010000b					;add  the base code to edx
			mov BYTE PTR [codesize],9			;set the codesize variable to 9 since we're writing an 9-bit symbol
			jmp advance

len:		;encode a length
			mov edx,0
			sub edx,DWORD PTR [esi]				;get absolute value of length (it is retrieved negative)						!!!!!
			cmp edx,115							;if it's above 115 it must be on 8 bits
			jae len8bit
			;coding a length on 7 bits.
			;loop over the hardcoded binslen arrays to find the code and nb of extra bits
			mov ebx,0							;use ebx to loop (start at 6 since below 115)
@@:			mov DWORD PTR [membuffer],esi		;store esi for later retrieval
			mov esi,OFFSET binslen
			cmp edx,DWORD PTR [esi+ebx*4]
			jl skipbin7b						;if not in this bin, skip to next iteration
			sub edx,DWORD PTR [esi+ebx*4]		;if in this bin, get offset from start of bin
			mov DWORD PTR [lenbuffer],edx
			mov esi,OFFSET codeslen
			mov edx,DWORD PTR [esi+ebx*4]		;at ebx-th element, we have the code for this bin
			sub edx,256							;subtract from the code the base value from which we start counting				!!!!!
			add edx,0							;add the base bits for this kind of code
			mov esi,OFFSET extraslen			;put the pointer to extraslen in esi
			mov cl,BYTE PTR [esi+ebx]			;write the number of extra bits into cl.
			mov esi, DWORD PTR [membuffer]		;restore esi, we're done using it to access the arrays
			shl edx,cl							;shift edx by the number of extra bits
			add edx,DWORD PTR [lenbuffer]		;write the length-from-binstart offset into those bits
			add cl,7
			mov BYTE PTR [codesize],cl			;set the codesize to 7+extrabits
			jmp advance
skipbin7b:	mov esi, DWORD PTR [membuffer]		;restore esi
			inc ebx
			cmp ebx,LENGTHOF binslen
			jl @B

len8bit:	;code a len on 8 bits
			;loop over the hardcoded binslen arrays to find the code and nb of extra bits
			mov ebx,0							;use ebx to loop
@@:			mov DWORD PTR [membuffer],esi		;store esi for later retrieval
			mov esi,OFFSET binslen
			cmp edx,DWORD PTR [esi+ebx*4]
			jl skipbin8b						;if not in this bin, skip to next iteration
			sub edx,DWORD PTR [esi+ebx*4]		;if in this bin, get offset from start of bin
			mov DWORD PTR [lenbuffer],edx
			mov esi,OFFSET codeslen
			mov edx,DWORD PTR [esi+ebx*4]		;at ebx-th element, we have the code for this bin
			sub edx,280							;subtract from the code the base value from which we start counting				!!!!!
			add edx,11000000b					;add the base bits for this kind of code
			mov esi,OFFSET extraslen			;put the pointer to extraslen in esi
			mov cl,BYTE PTR [esi+ebx]			;write the number of extra bits into cl.
			mov esi, DWORD PTR [membuffer]		;restore esi, we're done using it to access the arrays
			shl edx,cl							;shift edx by the number of extra bits
			add edx,DWORD PTR [lenbuffer]		;write the length-from-binstart offset into those bits
			add cl,8
			mov BYTE PTR [codesize],cl			;set the codesize to 7+extrabits
			jmp advance
skipbin8b:	mov esi, DWORD PTR [membuffer]		;restore esi
			inc ebx
			cmp ebx,LENGTHOF binslen
			jl @B

distance:


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
			mov BYTE PTR [edi],al
			mov ch,0							;reset the number of bytes written
			mov al,0							;reset al to 0
			inc edi								;increment the out pointer
			jmp litloop1						;get back to the loop

otloop:		;outerloop
			add esi,4
			dec DWORD PTR [lpindex]
			cmp DWORD PTR [lpindex],0
			ja lp
			;if we're done, we need to write the last bits that weren't written to memory yet
			mov cl,8							;shift away all the zeroes at the left that are not code bits (8-ch, ch being how many we've written)
			sub cl,ch
			shl al,cl							;do the shift
			mov BYTE PTR [edi],al				;write the result to memory
			

DONE:			
			pop edi
			pop esi
			pop ebx
			pop ebp
			ret
encodeliteral		endp
end