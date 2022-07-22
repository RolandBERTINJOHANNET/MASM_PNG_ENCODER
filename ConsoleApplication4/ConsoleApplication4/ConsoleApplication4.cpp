#include "IO.h"
#include "cppoverhead.h"
#include "time.h"

extern "C" int lzss(int size, uint8 *src, int *dst);

//program will allocate one more line than the size indicates, and fill it with zeros

//for the filtering, i'm choosing to store all the data into memory, to avoid excessive i/o repetition by reading from/writing to file multiple times.

//for the deflate algorithm it's the same since the window is sliding.

int main()
{
	srand(time(NULL));
	/*
	//															reading from the file
	char filename[] = "example.txt";
	int w, h;
	if (!read_width_height(filename, &w, &h))std::cout << "problem reading image size" << std::endl;
	int extra = w > h ? w + 1 : h + 1;//extra space for the byte sindicating filter types
	uint8 *src = new uint8[w*h + extra];
	//fill the extra with zeros for now
	for (int i = 0; i < extra; i++) {
		src[i] = 0;
	}
	if(!read(filename, w, h, extra + src))std::cout << "problem reading data" << std::endl;
	std::cout << "width : " << w << std::endl;
	std::cout << "height : " << h << std::endl;
	for (int i = extra; i < w*h + extra; i++) {
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
	for (int i = 0; i < h + w*h; i++) {
		std::cout << (int)src[i] << ", ";
	}std::cout << std::endl;
	*/
	uint8 src[20];
	for (int i = 0; i < 20; i++) {
		src[i] = rand() % 2;
	}
	std::cout << "size of array = " << (sizeof(src) / sizeof(uint8)) << std::endl;
	int dst[sizeof(src)];
	for (int i = 0; i < sizeof(src); i++) {
		std::cout << (int)src[i] << ", ";
	}std::cout << std::endl;
	lzss(sizeof(src), src,dst);

	std::cout << "lengths : " << std::endl;
	for (int i = 0; i < sizeof(src); i++) {
		std::cout << (int)dst[i] << ", ";
	}std::cout << std::endl;
	std::cout << "distances : " << std::endl;
	for (int i = 0; i < sizeof(src); i++) {
		std::cout << (int)dst[i] << ", ";
	}std::cout << std::endl;
}