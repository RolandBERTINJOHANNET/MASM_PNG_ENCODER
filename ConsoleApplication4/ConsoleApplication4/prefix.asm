.model flat,c
.data
codesize BYTE 0		;used to store how big the code written in edx (ie how much to shift into the buffer)
code dword 0
;arrays to facilitate encoding lengths
binslen dword 258,227,195,163,131,115,99,83,67,59,
			51,43,35,31,27,23,19,17,15,13,
			11,10,9,8,7,6,5,4,3,1
codeslen dword 285,284,283,282,281,280,279,278,277,276,275,274,273,
			272,271,270,269,268,267,266,265,264,263,262,261,260,259,258,257,256
extraslen byte 0,5,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0
;arrays to facilitate encoding distances
binsdist dword 24577,16385,12289,8193,6145,4097,3073,2049,1537,1025,769,513,385,
				257,193,129,97,65,49,33,25,17,13,9,7,5,4,3,2,1
codesdist dword 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16,
				15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,0
extrasdist byte 13,13,12,12,11,11,10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,0,0

isdist byte 0		;keeps track of when we're reading a distance
lpindex dword 0		;index for the big loop
lenbuffer dword 0	;used to store the length while we use edx to get the code
membuffer dword 0	;used to store memory adresses from esi while using esi for something else
revoradv dword 0	;0 if we're packing bytes in reverse, one otherwise. (used under the write tag)
extrasize byte 0	;just like codesize, but for the extra bits, which we write in non-reverse order.
isfinished byte 1	;0 if we've already written the end-of-block 256.
.code
prefixencode		proc					;encodes a list of lzss-processed ints with prefix codes
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
			;extra bits are pushed by shifting left, prefix codes are pushed by shifting right.
			mov ecx,DWORD PTR [ebp+20]					;retrieve bitoffset
			mov ch,BYTE PTR [ecx]						;ch will count how much has been pushed into al (the buffer)

			mov al,BYTE PTR [edi]						;push the unfinished byte to al (if this is the first chunk, ch=0 so value is pushed out)


lp:			;outer loop : encoding one input value
			cmp BYTE PTR [isdist],0;determine if we're treating a distance or a literal/length
			jne distance
			;if we're here, we're treating a literal/length
			cmp dword PTR [esi],0				;determine if we're treating a literal or a length
			jl len

			;if we're here, we're treating a literal
			mov cl,BYTE PTR [esi]				;get value of literal we're treating
			cmp BYTE PTR [esi],144
			jae lit9bit							;if it's above 144 it must be coded on 9 bits
			;if we're here, we're coding a literal on 8 bits (below 144)
			sub cl,0							;get the offset from base value for this kind of code
			movzx edx,cl						;add it to edx
			add edx,00110000b					;add  the base code to edx
			shl edx,24							;shift the result to the left of the register
			mov BYTE PTR [codesize],8			;set the codesize variable to 8 since we're writing an 8-bit symbol
			mov	BYTE PTR [extrasize],0
			jmp reverse
lit9bit:
			sub cl,144							;get the offset from base value for this kind of code
			movzx edx,cl						;add it to edx
			add edx,110010000b					;add  the base code to edx
			mov BYTE PTR [codesize],9			;set the codesize variable to 9 since we're writing an 9-bit symbol
			mov	BYTE PTR [extrasize],0
			shl edx,23							;shift the result to the left of the register
			jmp reverse

len:		;encode a length
			mov BYTE PTR [isdist],1				;set to 1 so that next value read is interpreted as distance
			mov edx,0
			sub edx,DWORD PTR [esi]				;get absolute value of length (it is retrieved negative)
			cmp edx,115							;if it's above 115 it must be on 8 bits
			jae len8bit
len7bit:	;coding a length on 7 bits.
			;loop over the hardcoded binslen arrays to find the code and nb of extra bits
			mov ebx,0							;use ebx to loop (start at 6 since below 115)
@@:			mov DWORD PTR [membuffer],esi		;store esi for later retrieval
			mov esi,OFFSET binslen
			cmp edx,DWORD PTR [esi+ebx*4]
			jl skipbin7b						;if not in this bin, skip to next iteration
			mov DWORD PTR [lenbuffer],edx		;store edx to a buffer for later retrieval.
			mov esi,OFFSET codeslen				;now we're in the right bin
			mov edx,DWORD PTR [esi+ebx*4]		;at ebx-th element, we have the code for this bin -write it to low bits of edx.
			sub edx,256							;subtract from it the base value from which we start counting.
			shl edx,25							;shift code to the end of the register.
			
			mov esi,OFFSET extraslen			;if in this bin, put the pointer to extrasdist in esi
			mov cl,BYTE PTR [esi+ebx]			;write the number of extra bits into extrasize.
			mov BYTE PTR [extrasize],cl

			mov esi,OFFSET binslen
			sub edx,DWORD PTR [esi+ebx*4]		;write -(start of bin) into low bits of edx
			mov esi,DWORD PTR [membuffer]
			add edx,DWORD PTR [lenbuffer]				;add to it the distance value

			mov BYTE PTR [codesize],7			;set the codesize to 7 for distances
			jmp reverse
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
			mov DWORD PTR [lenbuffer],edx		;store edx to a buffer for later retrieval.
			mov esi,OFFSET codeslen			;now we're in the right bin
			mov edx,DWORD PTR [esi+ebx*4]		;at ebx-th element, we have the code for this bin -write it to low bits of edx.
			sub edx,280							;subtract from it the base value from which we start counting
			add edx,11000000b					;add to it the base bits for this kind of code.
			shl edx,24							;shift code to the end of the register.
			
			mov esi,OFFSET extraslen			;if in this bin, put the pointer to extrasdist in esi
			mov cl,BYTE PTR [esi+ebx]			;write the number of extra bits into extrasize.
			mov BYTE PTR [extrasize],cl

			mov esi,OFFSET binslen
			sub edx,DWORD PTR [esi+ebx*4]		;write -(start of bin) into low bits of edx
			mov esi,DWORD PTR [membuffer]
			add edx,DWORD PTR [lenbuffer]		;add to it the distance value

			mov BYTE PTR [codesize],8			;set the codesize to 8 for this kind of length
			jmp reverse
skipbin8b:	mov esi, DWORD PTR [membuffer]		;restore esi
			inc ebx
			cmp ebx,LENGTHOF binslen
			jl @B

distance:	;encode a distance
			mov BYTE PTR [isdist],0				;set to 0 so that next value read is interpreted as literal/length
			mov edx,DWORD PTR [esi]				;get value of distance

			;loop over the hardcoded binsdist array to find the 5-bit code and nb of extra bits
			mov ebx,0							;use ebx to loop
@@:			mov DWORD PTR [membuffer],esi		;store esi for later retrieval
			mov esi,OFFSET binsdist
			cmp edx,DWORD PTR [esi+ebx*4]
			jl skipbindst						;if not in this bin, skip to next iteration
			mov esi,OFFSET codesdist			;now we're in the right bin
			mov edx,DWORD PTR [esi+ebx*4]		;at ebx-th element, we have the code for this bin -write it to low bits of edx.
			shl edx,27							;shift code to the end of the register.
			
			mov esi,OFFSET extrasdist			;if in this bin, put the pointer to extrasdist in esi
			mov cl,BYTE PTR [esi+ebx]			;write the number of extra bits into extrasize.
			mov BYTE PTR [extrasize],cl

			mov esi,OFFSET binsdist
			sub edx,DWORD PTR [esi+ebx*4]		;write -(start of bin) into low bits of edx
			mov esi,DWORD PTR [membuffer]
			add edx,DWORD PTR [esi]				;add to it the distance value

			mov BYTE PTR [codesize],5			;set the codesize to 5 for distances
			jmp reverse
skipbindst:	mov esi, DWORD PTR [membuffer]		;restore esi
			inc ebx
			cmp ebx,LENGTHOF binsdist
			jl @B


reverse:	;push the contents of edx into eax leftward, checking each time that eax isn't full
			mov cl,BYTE PTR [codesize]			;prepare cl to serve as loop index
			mov [revoradv],0					;indicate that we're reversing so the write part will know to come back here

@@:
			shr al,1
			shl edx,1
			jnc skipincr							;if it's not a 1, don't add a 1 to eax, just shift it
			add al,128								;add a 1 at the end of al.
skipincr:	inc ch
			cmp ch,8			 					;check that al has not been filled
			jae write								;if it has, write it to memory
revloop:	dec cl
			cmp cl,0
			ja @B								;keep looping till we've pushed as many bits as the code length

			;we advance only if there are extrabits
			cmp BYTE PTR [extrasize],0
			jle otloop

			;if we advance, put the extras back in place (we shifted by codesize)
			mov cl,BYTE PTR [codesize]
			shr edx,cl
			

advance:	;push the contents of edx into eax rightwards, checking each time that eax isn't full
			mov cl, BYTE PTR [extrasize]
			mov [revoradv],1					;indicate that we're advancing so the write part will know to come back here
@@:
			shr al,1
			shr edx,1
			jnc skipinca						;if it's not a 1, don't add a 1 to eax, just shift it
			add al,128
skipinca:	inc ch
			cmp ch,8							;check that al has not been filled
			jae write							;if it has, write it to memory
advloop:	dec cl
			cmp cl,0
			ja @B								;keep looping till we've pushed as many bits as the code length
			jmp otloop


write:		;if the buffer (al) is full, write it to memory and empty it.
			mov BYTE PTR [edi],al
			mov ch,0							;reset the number of bytes written
			mov al,0							;reset al to 0
			inc edi								;increment the out pointer
			cmp [revoradv],0
			jne advloop							;get back to reverse or advance based on revoradv.
			jmp revloop

otloop:		;outerloop
			add esi,4
			dec DWORD PTR [lpindex]
			cmp DWORD PTR [lpindex],0
			jg lp
			;if we haven't already, we need to write a 256 to memory to mark the end of the block.
			cmp BYTE PTR [isfinished],0
			je @F				;if isfinished is 1, we have already written the 256. skip to end.
			mov edx,1			;in the arrays for length bins, 1 corresponds to 256
			mov BYTE PTR [isfinished],0
			jmp len7bit

			;if we're done, we need to return the last memory adress we wrote to (through eax) and how far into the byte we wrote (into last fun arg)
@@:			mov BYTE PTR [edi],al				;write the unfinished byte to memory where we'll fetch it back in the next call
			mov eax,edi				;prepare eax to return edi
			mov edx,[ebp+20]
			movzx ebx,ch			;zero extend the byte offset
			mov [edx],ebx			;write the byte offset into the last function argument
			

DONE:		
			pop edi
			pop esi
			pop ebx
			pop ebp
			ret
prefixencode		endp
end