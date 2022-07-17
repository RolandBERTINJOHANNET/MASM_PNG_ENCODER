#include <stdio.h>
#include <iostream>

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