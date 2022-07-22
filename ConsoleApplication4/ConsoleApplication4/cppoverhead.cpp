#include "cppoverhead.h"
#include <stdio.h>
#include <cmath>
#include <algorithm>


//argmin over a positive sum of int
int argmin(int n, int *array) {
	int max = pow(2, 16);
	int argmin = 0;
	for (int i = 0; i < n; i++) {
		if (max > array[i]) {
			max = array[i];
			argmin = i;
		}
	}
	return argmin;
}

//supposing the file has had a line of zeros added at the beginning
//for now not informing on type of filter at beginning of each scanline.
void filter(int w, int h, uint8 *data) {
	int extra = w > h ? w + 1 : h + 1;
	uint8 *filtered = new uint8[w];//will store the filtered values into it to compute sabs.
	//need a buffer to momentarily acces previous line even after overwriting the line in data
	uint8 *buffer = new uint8[2 * w];//first half : previous line ; second half : current line.
	for (int i = 0; i < w; i++) {
		buffer[i] = 0;
	}//fill first half with zeros
	for (int line = 0; line < h; line++) {
		int sums[5];
		//compute sum over f0 (no filtering)
		sums[0] = sabs(w, extra + data + (line*w));
		//compute sum over f1
		f1(w, extra + data + (line*w), filtered);
		sums[1] = sabs(w, filtered);
		//compute sum over f2
		f2(w, extra + data + (line*w), filtered);
		sums[2] = sabs(w, filtered);
		//compute sum over f3
		f3(w, extra + data + (line*w), filtered);
		sums[3] = sabs(w, filtered);
		//compute sum over f4
		f4(w, extra + data + (line*w), filtered);
		sums[4] = sabs(w, filtered);

		//get argmin over sums
		int am = argmin(5, sums);
		//overwrite scanline with best filtered version
		std::copy(extra + data + line * w, extra + data + (line + 1) * w, buffer + w);//retrieve current value into buffer
		switch (am) {
		case 1:
			data[line + line * w] = 1;
			f1(w, buffer + w, line + 1 + data + ((line)*w));
			break;
		case 2:
			data[line + (line)*w] = 2;
			f2(w, buffer + w, line + 1 + data + ((line)*w));
			break;
		case 3:
			data[line + line * w] = 3;
			f3(w, buffer + w, line + 1 + data + ((line)*w));
			break;
		case 4:
			data[line + (line)*w] = 4;
			f4(w, buffer + w, line + 1 + data + (line *w));
			break;
		default://if argmin is 0, no filtering is advised; if it is not normal (which normally can't happen) do the same
			//write the unfiltered value
			std::copy(buffer + w, buffer + 2 * w, line + 1 + data + ((line)*w));
			break;
		}
		//put current value into first half of buffer for next iteration.
		std::copy(buffer + w, buffer + 2 * w, buffer);
	}
}