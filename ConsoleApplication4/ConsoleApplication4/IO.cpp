#include <stdio.h>
#include <iostream>
#include "IO.h"

int read(const char *filename, int widthdata, int heightdata, unsigned char *data) {
	FILE *f;
	if (fopen_s(&f, filename, "r"))return 0;
	fread(data, 1, 8, f);//discard header
	fread(data, 1, widthdata*heightdata, f);
	fclose(f);
	return 1;
}
int read_width_height(const char *filename, int *widthdata, int *heightdata) {
	FILE *f;
	if (fopen_s(&f, filename, "r"))return 0;
	fread(widthdata, sizeof(int), 1, f);
	fread(heightdata, sizeof(int), 1, f);
	fclose(f);
	return 1;
}

int write(char *filename, int widthdata, int heightdata, unsigned char *data) {
	FILE *f;
	if (fopen_s(&f, filename, "wb"))return 0;
	fwrite(&widthdata, sizeof(int), 1, f);
	fwrite(&heightdata, sizeof(int), 1, f);
	fwrite(data, 1, widthdata*heightdata, f);
	fclose(f);
	return 1;
}



void writeppm(char  nom_image[], uint8_t *pt_image, int w, int h){
	FILE *file;
	if(fopen_s(&file,nom_image,"wb"))std::cout<<"could not open the file for output (writeppm)"<<std::endl;
	fprintf_s(file, "P6\n%d %d\n255\n", w, h);
	//write data
	std::cout << "last 100 values : " << std::endl;
	for (int i = 0; i < 100; i++) {
		std::cout << (int)pt_image[w*h * 3 - 200 + i] << ", ";
	}std::cout << std::endl;
	
	std::cout << fwrite((uint8_t*)pt_image, sizeof(uint8_t), w*h * 3, file) << std::endl;
	fclose(file);
}