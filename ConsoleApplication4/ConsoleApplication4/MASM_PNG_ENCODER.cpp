
#define _CRT_SECURE_NO_WARNINGS

#include "cppoverhead.h"
#include "time.h"
#include "IO.h"


#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"


//debugging
void find_discrepencies(uint8_t *correct, uint8_t *generated, int w, int h) {
	for (int i = 0; i < w*h*3; i++) {
		if (correct[i] != generated[i]) {
			int len = 0;
			int j1 = i, j2 = i;
			std::cout << "discrepency at line " << i / (w * 3) << ", value " << i % (w * 3) << " or in image, value " << i << "\n";
			while (i<w*h*3 && correct[i] != generated[i]) {
				len++;
				i++;
			}
			std::cout << "values are : ";
			for (; j1 <= i; j1++) {
				std::cout << (int)generated[j1] << ", ";
			}std::cout << "\n";
			std::cout << " and should be : ";
			for (; j2 <= i; j2++) {
				std::cout << (int)correct[j2] << ", ";
			}std::cout << "\n";
		}
		else {
			//std::cout << "generated : " << (int)generated[i] << " correct : " << (int)correct[i] << std::endl;
		}
	}
}

void check_filter_types(uint8_t *filtered, int w, int h) {
	for (int i = 0; i < h*w*3; i+=w*3+1) {
		std::cout << "filter number " << i << " : " << (int)filtered[i] << std::endl;
	}
}

//program will allocate one more line than the size indicates, and fill it with zeros


int main()
{
	//srand(time(NULL));

	//														filtering test


	/*
	//															reading from the file
	int w, h;
	w = h = 5;
	int extra = w > h ? w + 1 : h + 1;//extra space for the byte sindicating filter types
	uint8 *src = new uint8[w*h + extra];
	//fill with synthetic data for testing
	for (int i = 0; i < w*h; i++) {
		src[i+extra] = rand()%5;
	}
	std::cout << "width : " << w << std::endl;
	std::cout << "height : " << h << std::endl;
	for (int i = 0; i < w*h + extra; i++) {
		std::cout << (int)src[i] << ", ";
	}std::cout << std::endl;
	//															filtering
	filter(w, h, src);
	std::cout << "width : " << w << std::endl;
	std::cout << "height : " << h << std::endl;
	for (int i = 0; i < extra + w*h; i++) {
		std::cout << (int)(char)src[i] << ", ";
	}std::cout << std::endl;
	*/
	
	//													testing prefix codes
	//uint8_t desired[] = { 58,50,98,2,31,48,29,66 };			//the desired output from prefix encoding.
	/*int data[] = { 215,3,-172,30112,-30,15151,-257,258 };				//some lzss-encoded data
	uint8_t out[13];
	int byteoffset;
	uint8_t *adr=prefixencode(8, data, out,&byteoffset);
	std::cout << "result of prefix encoding : " << std::endl;
	for (int i = 0; i < 13; i++) {
		std::cout << (int)out[i] << ", ";
	}std::cout<<std::endl;*/


	//	observing existing, correct png files
	/*
	int w, h;
	w = 800; h = 800;
	uint8_t *data = new uint8_t[w*h * 3];
	for (int i = 0; i < h; i++) {
		for (int j = 0; j < w; j++) {
			data[i * 3 * w + j * 3] = i * ((float)255/(float)h);
			data[i * 3 * w + j * 3 + 1]=j * ((float)255 / (float)w);
			data[i * 3 * w + j * 3 + 2] = (i+j) * ((float)(255)/float(w+h));
		}
	}
	stbi_write_png("testpng.png", w, h, 3, data, 3*w);
	*/
	
	//															testing the header functions
	/*int bitoffset=7;
	uint8_t *outputcopy = new uint8_t[4];
	for (int i = 0; i < 4; i++) {
		outputcopy[i] = 5;
	}
	outputcopy[0] = 111;
	outputcopy = writeheader(&bitoffset, outputcopy,1);
	std::cout << "bytes written : " << (int)*(outputcopy - 1) << ", " << (int)outputcopy[0] << std::endl;
	std::cout << "bit offset : " << bitoffset << std::endl;*/

	//////////////////////////////////////////////	finally testing my function
	//create some data
	/*int w, h;
	w = 800; h = 800;
	uint8_t *data = new uint8_t[w*h * 3];
	for (int i = 0; i < h; i++) {
		for (int j = 0; j < w; j++) {
			data[i * 3 * w + j * 3] = i * ((float)255 / (float)h);
			data[i * 3 * w + j * 3 + 1] = j * ((float)255 / (float)w);
			data[i * 3 * w + j * 3 + 2] = (i + j) * ((float)(255) / float(w + h));
			
			//for(int k=0;k<3;k++)data[i * 3 * w + j * 3 + k] = 255;
		}
	}*/
	//																			testing function on real images
	//opening images with stb
	int w, h;
	int chan;
	uint8_t *data= stbi_load("images/Capture6.png", &w, &h, &chan, 3);
	//uint8_t *generated = stbi_load("out.png", &w, &h, &chan, 3);

	//find_discrepencies(data, generated, w, h);
	/*
	*/
	//checking which filters were used
	int extra = 3 * (w * 3 > h * 3 ? w * 3 + 1 : h * 3 + 1);
	uint8 *src = new uint8[w*h * 3 + extra];
	std::copy(data, data + w * h * 3, src + extra);//copy the input array to this new array
	for (int i = 0; i < extra; i++)src[i] = 0;//fill the start with zeros (padding)
	filter(w, h, src);//						apply filtering
	
	check_filter_types(src, w, h);
	
	
	my_encode_png((char *)"out.png",w,h, data);
	
}