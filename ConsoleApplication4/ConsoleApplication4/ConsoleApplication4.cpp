#include "cppoverhead.h"
#include "time.h"
#include "IO.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"


extern "C" int encodeliteral(int size, int *input, uint8_t *output);

//program will allocate one more line than the size indicates, and fill it with zeros

//for the filtering, i'm choosing to store all the data into memory, to avoid excessive i/o repetition by reading from/writing to file multiple times.

//for the deflate algorithm it's the same since the window is sliding.


int main()
{
	srand(time(NULL));

	//														filtering test


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


	//														opening images with stb, applying lzss
	/*int w, h;
	int chan;
	uint8_t *image = stbi_load("images/5.png", &w, &h, &chan, 3);
	std::cout << "dimensions of image : w,h = " << w << ", " << h;
	std::cout << "\nlast values : " << "\n";
	for (int i = w*h*3 - 5; i < w*h*3; i++) {
		std::cout << (int)image[i] << ", ";
	}std::cout << std::endl;

	int *dst = new int[w*h * 3];
	int lgth = lzss(w*h*3, image, dst);
	std::cout << "lgth : " << lgth/4 << " and last value is : \n";
	for (int i = lgth/4-5; i < lgth/4; i++) {
		std::cout << dst[i]<<", ";
	}std::cout << std::endl;

	uint8_t *dst2 = new uint8_t[w*h * 3];
	decode(dst, dst2, w*h * 3);
	verify(image, dst2, w*h * 3);
	*/

	//													testing prefix codes
	int size;
	int data[] = { 10,2,50,-3,2,230,-3,1 };				//some lzss-encoded data
	uint8_t desired[] = { 58,50,98,2,31,48,29,66 };			//the desired output from prefix encoding.
	uint8_t out[2];
	encodeliteral(2, data, out);
	std::cout << "result of prefix encoding : " << std::endl;
	for (int i = 0; i < 2; i++) {
		std::cout << (int)out[i] << ", ";
	}std::cout<<std::endl;
}