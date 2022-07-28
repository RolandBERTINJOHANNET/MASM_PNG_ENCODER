#include <stdio.h>
#include <iostream>

int read(const char *filename, int widthdata, int heightdata, unsigned char *data);
int read_width_height(const char *filename, int *widthdata, int *heightdata);
int write(char *filename, int widthdata, int heightdata, unsigned char *data);
void writeppm(char  nom_image[], uint8_t *pt_image, int w, int h);