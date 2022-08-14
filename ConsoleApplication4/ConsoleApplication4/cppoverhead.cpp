#include "cppoverhead.h"



//decode an image encoded with lzss, lengths being indicated by a negative value instead of a flag.
void decode(int *code, uint8_t *out, int size) {
	int offsetOut = 0;
	int offsetRead = 0;
	while (offsetRead < size) {
		int val = code[offsetRead];
		if (val >= 0) {				//if it's just a literal
			out[offsetOut++] = val;
			offsetRead++;
		}
		else {						//in my code a negative value indicates a pattern
			int distance = code[offsetRead + 1];
			int diffdist = offsetOut - distance;
			for (int i = 0; i < -val; i++) {
				out[offsetOut++] = out[diffdist++];
			}
			offsetRead += 2;
		}
	}
}

//verify that two arrays are equal. print the result in cout
int verify(uint8_t *orig, uint8_t *decoded, int size) {
	for (int i = 0; i < size; i++) {
		if (orig[i] != decoded[i]) {
			std::cout << "error in lzss on value number : " << i << std::endl;
			return 0;
		}
	}
	std::cout << "no issues for lzss !" << std::endl;
	return 1;
}


//argmin over a positive sum of int
int argmin(int n, int *array) {
	int max = pow(2, 16);
	int argmin = 0;
	for (int i = 0; i < n; i++) {
		if (max > array[i]) {
			max = array[i];
			argmin = i;
		}
	}
	return argmin;
}

//supposing the file has had a line of zeros added at the beginning
//filters an array of byte pixels according to PNG standard
void filter(int w, int h, uint8 *data) {
	int extra =3*( w*3 > h*3 ? w*3 + 1 : h*3 + 1);
	uint8_t *filtered = new uint8_t[w*3];//will store the filtered values into it to compute sabs.
	//need a buffer to momentarily acces previous line even after overwriting the line in data
	uint8_t *buffer = (uint8_t*)malloc(2 * 3*w*sizeof(uint8_t));//first half : previous line ; second half : current line.
	for (int i = 0; i < w*3; i++) {
		buffer[i] = 0;
	}//fill first half with zeros
	for (int line = 0; line < h; line++) {
		int sums[5];
		//compute sum over f0 (no filtering)
		sums[0] = sabs(w*3, extra + data + (line*w*3));
		//compute sum over f1
		f1(w*3, extra + data + (line*w * 3), filtered);
		sums[1] = sabs(w*3, filtered);
		//compute sum over f2
		f2(w * 3, extra + data + (line*w * 3), filtered);
		sums[2] = sabs(w*3, filtered);
		//compute sum over f3
		f3(w * 3, extra + data + (line*w * 3), filtered);
		sums[3] = sabs(w*3, filtered);
		//compute sum over f4
		f4(w * 3, extra + data + (line*w * 3), filtered);
		sums[4] = sabs(w*3, filtered);

		//get argmin over sums
		int am = argmin(5, sums);
		//overwrite scanline with best filtered version
		std::copy(extra + data + line * w*3, extra + data + (line + 1) * w*3, buffer + w*3);//retrieve current value into buffer
		switch (am) {
		case 1:
			data[line + line * w*3] = 1;
			f1(w*3, buffer + w*3, line + 1 + data + ((line)*w*3));
			break;
		case 2:
			data[line + (line)*w*3] = 2;
			f2(w*3, buffer + w*3, line + 1 + data + ((line)*w*3));
			break;
		case 3:
			data[line + line * w*3] = 3;
			f3(w*3, buffer + w*3, line + 1 + data + ((line)*w*3));
			break;
		case 4:
			data[line + (line)*w*3] = 4;
			f4(w*3, buffer + w*3, line + 1 + data + (line *w*3));
			break;
		default://if argmin is 0, no filtering is advised; if argmin is not normal (which normally can't happen) do the same
			//write the unfiltered value
			data[line + line * w * 3] = 0;
			std::copy(buffer + w*3, buffer + 2 * w*3, line + 1 + data + ((line)*w*3));
			break;
		}
		//put current value into first half of buffer for next iteration.
		std::copy(buffer + w*3, buffer + 2 * w*3, buffer);
	}
}

int my_encode_png(char *filename, int w, int h, uint8_t *data) {
	//reserve extra space for the extra bytes indicating filter type at the start of each scanline
	int extra = 3 * (w * 3 > h * 3 ? w * 3 + 1 : h * 3 + 1);
	uint8 *src = new uint8[w*h * 3 + extra];
	std::copy(data, data + w * h * 3, src + extra);//copy the input array to this new array
	for (int i = 0; i < extra; i++)src[i] = 0;//fill the start with zeros (padding)
	filter(w, h, src);//						apply filtering
	

	//compute adler32 on uncompressed data for the zlib wrapper later
	unsigned int ad32 = adler32(src, w*h * 3 + h);

	uint8_t *dst2 = new uint8_t[w*h * 3 + h];//		used just for debugging
	int *dst = new int[w*h * 3 + extra];
	int encoded_length = lzss(w*h * 3 + h, src, dst) / 4;//					lzss------divided by 4 since we want number of ints
	decode(dst, dst2, encoded_length);//				these two lines also just debugging
	verify(src, dst2, w*h * 3 + h);


	encoded_length = deflate_chunk(encoded_length, dst, data);			//prefix code and also packs everything into chunks


	//now write it to a file.
	FILE *f;
	fopen_s(&f, filename, "wb");
	//write the PNG signature :	137, 80, 78, 71, 13, 10, 26, 10			(decimal)
	uint8_t ucbuf[] = { 137, 80, 78, 71, 13, 10, 26, 10 };		//buffer for writing
	fwrite(ucbuf, 1, 8, f);

	//IDHR :	width + height + 73 72 68 82 (dec) + (long data field, see doc) + crc (on	chunk name and chunk data, not length.)
	//write
	uint8_t intreverser[] = { 0,0,0,13 };				//write 13---the block size. This reverser writes ints as 4 uchars, allows reversing them.
	fwrite(&intreverser, 1, 4, f);
	//buffer containing 73,72,68,82 (IDHR SIGNAURE) + (int)width, (int)height + depth 8,rgb,compression method 0,filter method 0,interlace 0
	uint8_t buffer[] = { 73,72,68,82,w >> 24,w >> 16,w >> 8,w,h >> 24,h >> 16,h >> 8,h,8,2,0,0,0 };
	//write everything
	fwrite(buffer, 1, 17, f);
	int crc_result = crc(buffer, 17);//compute the crc
	//reverse the crc
	intreverser[0] = crc_result >> 24; intreverser[1] = crc_result >> 16; intreverser[2] = crc_result >> 8; intreverser[3] = crc_result;
	fwrite(intreverser, 1, 4, f);//write the crc

	//get chunk length (=length of zlib stream : length of deflate bitstream + length of starter + length of adler32)
	const int len = encoded_length + 2 + 4;
	//reverse the len
	intreverser[0] = len >> 24; intreverser[1] = len >> 16; intreverser[2] = len >> 8; intreverser[3] = len;
	fwrite(intreverser, 1, 4, f);//write the len
	//now write the IDAT code + all the data into an unsigned char buffer
	uint8_t *buffer2 = new uint8_t[len+4];//need 4 more for the IDAT header
	buffer2[0] = 73; buffer2[1] = 68; buffer2[2] = 65; buffer2[3] = 84; buffer2[4] = 120; buffer2[5] = 94;//first four are IDAT code ; next two are zlib starter
	//add raw deflate data to header
	std::copy(data, data + encoded_length, buffer2 + 6);
	int offset = len;//offset for writing to the last 4 values in the buffer
	buffer2[offset] = ad32>>24; buffer2[offset+1] = ad32 >> 16; buffer2[offset+2] = ad32 >> 8; buffer2[offset+3] = ad32;//add the adler32 to this bitstream
	//might be an error to write it this way since it is unsigned
	fwrite(buffer2, 1, len + 4, f);//write all this (IDHR code + deflate bitstream inside of zlib wrapper) to the file
	crc_result = crc(buffer2, len + 4);//IDAT CRC		(on	chunk name and chunk data, not length.)
	//reverse the crc
	intreverser[3] = crc_result >> 24; intreverser[2] = crc_result >> 16; intreverser[1] = crc_result >> 8; intreverser[0] = crc_result;
	fwrite(intreverser, 1, 4, f);//write the crc
	//write iend buffer : 00 00 00 00 49 45 4E 44 AE 42 60 82  (hex)
	uint8_t iendbuf[] = { 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130 };
	fwrite(iendbuf, 1, 12, f);
	fclose(f);
	return 1;
}

int my_encode_deflate(char *filename, int w, int h, uint8_t *data) {
	//reserve extra space for the extra bytes indicating filter type at the start of each scanline
	int extra = 3 * (w * 3 > h * 3 ? w * 3 + 1 : h * 3 + 1);
	uint8 *src = new uint8[w*h * 3 + extra];
	std::copy(data, data + w * h * 3, src + extra);//copy the input array to this new array
	for (int i = 0; i < extra; i++)src[i] = 0;//fill the start with zeros (padding)
	filter(w, h, src);//						apply filtering


	//compute adler32 on uncompressed data for the zlib wrapper later
	unsigned int ad32 = adler32(src, w*h * 3 + h);

	uint8_t *dst2 = new uint8_t[w*h * 3 + h];//		used just for debugging
	int *dst = new int[w*h * 3 + extra];
	int encoded_length = lzss(w*h * 3 + h, src, dst) / 4;//					lzss------divided by 4 since we want number of ints
	decode(dst, dst2, encoded_length);//				these two lines also just debugging
	verify(src, dst2, w*h * 3 + h);


	encoded_length = deflate_chunk(encoded_length, dst, data);			//prefix code and also packs everything into chunks


	//now write it to a file.
	FILE *f;
	fopen_s(&f, filename, "wb");

	uint8_t *buffer2 = new uint8_t[encoded_length];
	//add raw deflate data
	std::copy(data, data + encoded_length, buffer2);
	fwrite(buffer2, 1, encoded_length, f);//write all this (IDHR code + deflate bitstream inside of zlib wrapper) to the file
	fclose(f);
	return 1;
}


//generates deflate chunks of data concatenated which make up the whole stream (input must be lzss processed)
int deflate_chunk(int size, int *input, uint8_t *output) {
	int *inputcopy = input;//keep the input pointers unchanged
	uint8_t *outputcopy = output;
	int len = size;//for keeping track of when the last chunk comes
	int byteoffset=0;//the first bit is at a byte boundary
	while (len > 30000000000) {
		outputcopy = writeheader(&byteoffset, outputcopy, 0);
		outputcopy = prefixencode(30000, inputcopy, outputcopy, &byteoffset);
		len -= 30000;
		inputcopy += 30000;
	}
	outputcopy=writeheader(&byteoffset, outputcopy,1);
	outputcopy = prefixencode(len, inputcopy, outputcopy, &byteoffset);
	outputcopy[0] = outputcopy[0] >> 8-byteoffset;			//shift the last byte by how much we needed to shift it (since this was the last call)
	return (outputcopy - output) + (byteoffset > 1 ? 1 : 0);
}