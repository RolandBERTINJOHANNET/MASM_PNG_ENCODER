.model flat,c
.data
bestdist dword 0
curdist dword 0
curlen dword 0
bestlen dword 1
offsetout dword 0
.code
lzss	proc
		push ebp
		mov ebp,esp
		push ebx
		push edi
		push esi


		;retrieve length, input array
		mov esi,[ebp+12]
		mov ecx,[ebp+8]

		mov DWORD PTR [offsetout],0

		;check length
		xor eax,eax
		cmp ecx,0
		jle done

		;write the first literal to the output array
		movzx eax,BYTE PTR [esi]
		mov edi,[ebp+16]
		mov [edi],eax
		add DWORD PTR [offsetout],4
		;loop over the inupt array
		mov ebx,1
		dec ecx
lp:
		;sequentially loop over the last 32786 elts in input array, looking for a match
		;ebx is the main loop indicator (how far we've encoded)
		;edx is the look loop index (the start of the patterns we're looking at)
		;curlen is the pattern loop index (size of current pattern)

		;here we initialize edx and curdist for the search given ebx
		mov edx,ebx
		cmp edx,32767
		;save how far back we moved	into curdist
		ja @F
		mov [curdist],ebx				;if we oversubbed, distance backwards is only as far as we've read (ebx)
		mov edx,0					;if we are less than 32768 bytes into the array
@@:		jbe @F							;if not, distance backwards starts at 32768
		mov [curdist],32767
		sub edx,32767
look:									;pointless label, just for clarity
pattern:
										;now check if the symbols at esi+ebx+curlen and esi+edx+curlen match
@@:		add esi,ebx						;these three lines just access memory at esi+ebx+curlen
		add esi,DWORD PTR [curlen]
		mov ah,BYTE PTR [esi]
		sub esi,ebx
		add esi,edx					;these 2 lines access memory at esi+edx+curlen	(restoring esi is done after the jumps)
		cmp ah,BYTE PTR [esi]
		jne nomatch						;if the values don't match, break out of pattern loop
		sub esi,edx					;(putting these after the jmp because EFL changes from the sub, can't put it before the jump)
		sub esi,DWORD PTR [curlen]
		inc DWORD PTR [curlen]			;if there's a match, immediately increment curlen
		;otherwise, if length is over 3 and over the current best length, update the memory variables
		cmp DWORD PTR [curlen],3
		jl @F						;dont update if not above 3.....
		mov eax,DWORD PTR [curlen]
		cmp eax,DWORD PTR [bestlen]
		jl @F						;......or if not better than previously established length
		mov eax,DWORD PTR [curlen]				;update length memory variable
		mov [bestlen],eax						;using eax as a buffer for mem-to-mem transfer
		mov eax,DWORD PTR[curdist]						;same for the distance variable
		mov	[bestdist],eax

		;pattern loop
@@:		
		;check that we are not reading further than the allocated source array
		;compute into eax the difference between (ebx+curlen) and source array size
		mov eax,[ebp+8]
		sub eax,DWORD PTR [curlen]
		sub eax,ebx
		cmp eax,0								;check that we aren't reading past the end offset (that eax >0)
		jl outerloop								;if we're over the limit, write whatever pattern we have as it reaches the end, then exit (ecx will be 0)
		cmp DWORD PTR [curlen],258
		jl pattern						;continue if under 258 (the max len as defined in RFC 1951)
		jmp lookback					;if we get through the conditions, we must skip the esi adjustment at nomatch

		

nomatch:	;skip to here if non-matching patterns
		sub esi,edx					;putting these after the jmp because EFL changes immediately after the cmp above
		sub esi,DWORD PTR [curlen]
		inc DWORD PTR [curlen]			;if there's a match, immediately increment curlen

lookback:		;lookback loop
		mov DWORD PTR [curlen],0		;prepare curlen for a new pattern
		add edx,1
		sub dword ptr [curdist],1		;as we increment the look offset (edx), we must also decrement the distance backwards
		cmp edx,ebx						;stop if we've arrived at the adress we're examining
		jl look

outerloop:		;parsing loop
		;depending on bestlen, we either write the len,dist couple (case 1) or just the literal(case 2)
		cmp DWORD PTR [bestlen],3
		jl writelit
						;case 2 :write the found len,dist couple in their respective output arrays (using eax as buffer)
		mov edi,[ebp+16]
		add edi,DWORD PTR [offsetout]
		mov eax,0
		sub eax,DWORD PTR [bestlen]
		mov [edi],eax							;write the length negative so the prefix encoder can detect it's not a literal
		add edi,4
		mov eax,DWORD PTR [bestdist]
		mov [edi],eax							;write the distance
		add DWORD PTR [offsetout],8
		jmp @F							;don't write the literal
writelit:				;case 2 :write just the literal
		add esi,ebx
		movzx eax,BYTE PTR [esi]
		sub esi,ebx
		mov edi,[ebp+16]
		add edi,DWORD PTR [offsetout]
		mov [edi],eax
		add DWORD PTR [offsetout],4		;increment offset for the array we wrote in
@@:		
		;increase ebx by the length of pattern found (and decrease ecx by that amount because I made the loop rely on ecx..)
		add ebx,DWORD PTR [bestlen]
		sub ecx, DWORD PTR [bestlen]
		;reset all lengths
		mov DWORD PTR [bestlen],1			;setting it to 1 doesn't change anything if match found ; if not, helps increase ebx by default
		mov DWORD PTR [curlen],0
		mov DWORD PTR [curdist],0				
		mov DWORD PTR [bestdist],0
		cmp ecx,0
		ja lp

done:
		mov eax,dword ptr [offsetout]		;return how far into the array we came
		pop esi
		pop edi
		pop ebx
		pop ebp
		ret
lzss	endp
end