#include "crc.h"

/* Make the table for a fast CRC. */
void make_crc_table(unsigned long *crc_table)
{
	unsigned long c;
	int n, k;

	for (n = 0; n < 256; n++) {
		c = (unsigned long)n;
		for (k = 0; k < 8; k++) {
			if (c & 1)
				c = 0xedb88320L ^ (c >> 1);
			else
				c = c >> 1;
		}
		crc_table[n] = c;
	}
}

/* Update a running CRC with the bytes buf[0..len-1]--the CRC
   should be initialized to all 1's, and the transmitted value
   is the 1's complement of the final running CRC (see the
   crc() routine below)). */

unsigned long update_crc(unsigned long crc, unsigned char *buf,
	int len)
{
	unsigned long c = crc;
	int n;
	unsigned long crc_table[256];
	make_crc_table(crc_table);
	for (n = 0; n < len; n++) {
		c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
	}
	return c;
}

/* Return the CRC of the bytes buf[0..len-1]. */
unsigned long crc(unsigned char *buf, int len)
{
	return update_crc(0xffffffffL, buf, len) ^ 0xffffffffL;
}

//should rename the file since this isn't crc
unsigned int adler32(uint8_t *data, int data_len) {
	// compute adler32 on input
	unsigned int s1 = 1, s2 = 0;
	int j = 0;
	for (int i = 0; i < data_len; i++) {
		s1 += data[i]; s2 += s1;
	}
	s1 %= 65521; s2 %= 65521;
	return (s2 << 16) | s1;
}