#pragma once

typedef unsigned char uint8;

extern "C" int f1(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f2(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f3(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f4(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int sabs(int linelength, uint8 *lineStartDst);

//argmin over a positive sum of int
int argmin(int n, int *array);

//supposing the file has had a line of zeros added at the beginning
//for now not informing on type of filter at beginning of each scanline.
void filter(int w, int h, uint8 *data);