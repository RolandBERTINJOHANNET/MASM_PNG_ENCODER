#pragma once

#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <cmath>
#include <algorithm>

typedef unsigned char uint8;

extern "C" int f1(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f2(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f3(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f4(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int sabs(int linelength, uint8 *lineStartDst);
extern "C" int lzss(int size, uint8 *src, int *dst);


void decode(int *code, uint8_t *out, int size);
int verify(uint8_t *orig, uint8_t *decoded, int size);


//argmin over a positive sum of int
int argmin(int n, int *array);

//supposing the file has had a line of zeros added at the beginning
//for now not informing on type of filter at beginning of each scanline.
void filter(int w, int h, uint8 *data);