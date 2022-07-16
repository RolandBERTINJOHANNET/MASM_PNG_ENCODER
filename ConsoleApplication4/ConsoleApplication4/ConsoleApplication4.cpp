#include "IO.h"

//program will allocate one more line than the size indicates, and fill it with zeros

//for the filtering, i'm choosing to store all the data into memory, to avoid excessive i/o repetition by reading/writing to file multiple times.

//for the deflate algorithm it's the same since the window is sliding.
typedef unsigned char uint8;

extern "C" int f1(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f2(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f3(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f4(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int sabs(int linelength, uint8 *lineStartDst);

//argmin over a positive sum of int
int argmin(int n, int *array) {
	int max = pow(2,16);
	int argmin = 0;
	for (int i = 0; i < n; i++) {
		if (max > array[i]) {
			max = array [i];
			argmin = i;
		}
	}
	return argmin;
}

//supposing the file has had a line of zeros added at the beginning
//for now not informing on type of filter at beginning of each scanline.
void filter(int w, int h, uint8 *data) {
	uint8 *filtered = new uint8[w];//will store the filtered values into it to compute sabs.
	for (int line = 1; line < h; line++) {
		int sums[5];
		//compute sum over f0 (no filtering)
		sums[0] = sabs(w, data + (line*w));
		//compute sum over f1
		f1(w, data + (line*w), filtered);
		sums[1] = sabs(w, filtered);
		//compute sum over f2
		f2(w, data + (line*w), filtered);
		sums[2] = sabs(w, filtered);
		//compute sum over f3
		f3(w, data + (line*w), filtered);
		sums[3] = sabs(w, filtered);
		//compute sum over f4
		f4(w, data + (line*w), filtered);
		sums[4] = sabs(w, filtered);

		//get argmin over sums
		int am = argmin(5, sums);
		//overwrite scanline with best filtered version
		//need a buffer to momentarily acces previous line even after overwriting the line in data
		uint8 *buffer = new uint8[2 * w];//first half : previous line ; second half : current line.
		std::copy(data + line * w, data + (line+1) * w,buffer+w);//retrieve current value into buffer
		switch (am) {
			case 1:
				f1(w, buffer + w, data + (line*w));
				break;
			case 2:
				f2(w, buffer+w, data + (line*w));
				break;
			case 3:
				f3(w, buffer + w, data + (line*w));
				break;
			case 4:
				f4(w, buffer + w, data + (line*w));
				break;
			default://if argmin is 0, no filtering is advised; if it is not normal (which normally can't happen) do the same
				break;
		}
		//put current value into first half of buffer for next iteration.
		std::copy(data + line * w, data + (line + 1) * w, buffer);
	}
}







int main()
{
	//															reading from the file
	char filename[] = "example.txt";
	int w, h;
	if (!read_width_height(filename, &w, &h))std::cout << "problem reading image size" << std::endl;
	uint8 *src = new uint8[w*h];
	if(!read(filename, w, h, src))std::cout << "problem reading data" << std::endl;
	std::cout << "width : " << w << std::endl;
	std::cout << "height : " << h << std::endl;
	for (int i = 0; i < 16; i++) {
		std::cout << (int)src[i] << ", ";
	}std::cout << std::endl;
	//															filtering
	filter(w, h, src);
	//															output to a different file for now
	char outfilename[] = "out.txt";
	if (!write(outfilename, w, h, src))std::cout << "problem writing to the output file" << std::endl;
	//															read the result from that file and display it for debugging
	std::cout << "-------------------------- now checking the result --------------------------" << std::endl;
	if (!read_width_height(outfilename, &w, &h))std::cout << "problem reading image size" << std::endl;
	if (!read(outfilename, w, h, src))std::cout << "problem reading data" << std::endl;
	std::cout << "width : " << w << std::endl;
	std::cout << "height : " << h << std::endl;
	for (int i = 0; i < 16; i++) {
		std::cout << (int)src[i] << ", ";
	}std::cout << std::endl;
}