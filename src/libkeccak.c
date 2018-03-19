// Initial implementation of using the libkeccak library

#include <stdint.h>
#include <stdio.h>
#include "KeccakHash.h"
#include "KeccakSpongeWidth1600.h"
#include "KeccakP-1600-SnP.h"

// default chunk size
#define bufferSize 65536

int hexencode(const void* data_buf, size_t dataLength, char* result, size_t resultSize)
{
   const char hexchars[] = "0123456789abcdef";
   const uint8_t *data = (const uint8_t *)data_buf;
   size_t resultIndex = 0;
   size_t x;

    for(x=0; x<dataLength; x++) {
        if (resultIndex >= resultSize) return 1;   /* indicate failure: buffer too small */
        result[resultIndex++] = hexchars[(data[x] / 16) % 16];
        if (resultIndex >= resultSize) return 1;   /* indicate failure: buffer too small */
        result[resultIndex++] = hexchars[data[x] % 16];
   }
   if(resultIndex >= resultSize) return 1;   /* indicate failure: buffer too small */
   result[resultIndex] = 0;
   return 0;   /* indicate success */
}

int main(int argc, char ** argv)
{
	// Take the input argument as a file to read in
	if(argc < 2)
	{
		fprintf(stderr, "error: first argument must be the filename\n");
		return 1;
	}

	char * fileName = argv[1];

	// Settings for sha3-512
	int rate = 576;
	int capacity = 1024;
	int hashbitlen = 512;
	int delimitedSuffix = 0x06;
	Keccak_HashInstance instance;

	// Setup the sponge
	if(KeccakWidth1600_SpongeInitialize(&instance.sponge, rate, capacity))
	{
		fprintf(stderr, "error: invalid parameters to Keccak_HashInitialize\n");
		return 1;
	}

    instance.fixedOutputLength = hashbitlen;
    instance.delimitedSuffix = delimitedSuffix;


	// Open the file for reading
	FILE *fp;
	fp = fopen(fileName, "rb");
    if (fp == NULL) {
        fprintf(stderr, "error: file '%s' could not be opened\n", fileName);
        return 1;
    }

	size_t read;
	// Buffer for updating the hash
	unsigned char buffer[bufferSize];
	// Buffer for printing the hex encoded hash result off
	char display[bufferSize*2+1];

	// Read all the bytes of the file in chunks of bufferSize and update the hash each time
	do {
		read = fread(buffer, 1, bufferSize, fp);
		if (read > 0)
		{
			Keccak_HashUpdate(&instance, buffer, read*8);
		}
	} while(read>0);

	// Close the file
	fclose(fp);

	// Run the final hash
	Keccak_HashFinal(&instance, buffer);

	// Encode the result as hex so it can be printed off
	if (hexencode(buffer, (hashbitlen+7)/8, display, bufferSize*2)) {
        fprintf(stderr, "error: failed to convert to hex\n");
        return -1;
    }

    // Print off the result
    printf("%s  %s\n", display, fileName);
	return 0;
}