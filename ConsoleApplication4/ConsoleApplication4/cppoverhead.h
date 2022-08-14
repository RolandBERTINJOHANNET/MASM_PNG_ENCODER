#ifndef CPP_OVERHEAD
#define CPP_OVERHEAD

#include <iostream>
#include <stdio.h>
#include <cmath>
#include <algorithm>
#include "crc.h"

typedef unsigned char uint8;

extern "C" int f1(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f2(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f3(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int f4(int linelength, uint8 *lineStartSrc, uint8 *lineStartDst);
extern "C" int sabs(int linelength, uint8 *lineStartDst);
extern "C" int lzss(int size, uint8 *src, int *dst);
//prefix encoding + writes the deflate block headers and ends
extern "C" uint8_t* prefixencode(int size, int *input, uint8_t *output, int *byteoffset);
extern "C" uint8_t* writeheader(int *byteoffset, uint8_t *outputcopy,uint8_t bfinal);

void decode(int *code, uint8_t *out, int size);
int verify(uint8_t *orig, uint8_t *decoded, int size);

//argmin over a positive sum of int
int argmin(int n, int *array);

//supposing the file has had a line of zeros added at the beginning
void filter(int w, int h, uint8 *data);

int my_encode_png(char *filename, int w, int h, uint8_t *data);

int my_encode_deflate(char *filename, int w, int h, uint8_t *data);

int deflate_chunk(int size, int *input, uint8_t *output);

int my_encode_zlib(int w, int h, uint8_t *data);

#endif //CPP_OVERHEAD