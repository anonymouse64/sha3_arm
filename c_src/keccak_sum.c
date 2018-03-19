// Example executable of using the libkeccak wrapper library

#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdlib.h>

#include "libkeccak.h"

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

	// start timer
    struct timespec start;
    struct timespec stop;
    struct timespec result;

    clock_gettime(CLOCK_MONOTONIC, &start);

	char * fileName = argv[1];

	// Open the file for reading
	FILE *fp;
	fp = fopen(fileName, "rb");
    if (fp == NULL) {
        fprintf(stderr, "error: file '%s' could not be opened\n", fileName);
        return 1;
    }

    // Get the total size of the file
	struct stat st; 
    if (stat(fileName, &st))
    {
    	fprintf(stderr, "error: file '%s' could not be stat'd for file size\n", fileName);
        return 1;
    }
    size_t fileSize = st.st_size;
    uint8_t * fileData = (uint8_t *) calloc(sizeof(uint8_t), fileSize);
    if(!fileData)
    {
    	fprintf(stderr, "error: failed to allocate memory for reading file '%s'\n", fileName);
    	return 1;
    }

	size_t read = 0;
	read = fread(fileData, 1, fileSize, fp);
	if (read != fileSize)
	{
    	fprintf(stderr, "error: file '%s' could not be read\n", fileName);
		return 1;
	}

	// Close the file
	fclose(fp);

	// Now actually run the hash
	int res = KeccakSHA3_512Hash(fileData, fileSize);
	switch(res)
	{
		case LIBKECCAK_NO_ERROR:
			break;
		case LIBKECCAK_INIT_ERROR:
			fprintf(stderr, "error: failed to initialize sponge\n");
			goto endfail;
		case LIBKECCAK_HASH_UPDATE_ERROR:
			fprintf(stderr, "error: failed to absorb bytes into the sponge\n");
			goto endfail;
		case LIBKECCAK_HASH_FINAL_ERROR:
			fprintf(stderr, "error: failed to squeeze the sponge\n");
		default:
		endfail:
			return 1;
	}

	// Now stop the timer and calculate the total time elapsed and the hash rate
    clock_gettime(CLOCK_MONOTONIC, &stop);
    if ((stop.tv_nsec - start.tv_nsec) < 0) {
        result.tv_sec = stop.tv_sec - start.tv_sec - 1;
        result.tv_nsec = stop.tv_nsec - start.tv_nsec + 1000000000;
    } else {
        result.tv_sec = stop.tv_sec - start.tv_sec;
        result.tv_nsec = stop.tv_nsec - start.tv_nsec;
    }

    double totalTime = result.tv_sec + (result.tv_nsec / 1000000000.0);
	double hashRate =  (fileSize / 1048576.0) / totalTime;

	// Buffer for printing the hex encoded hash result off
	char display[512*2+1];

	// Encode the result as hex so it can be printed off
	if (hexencode(fileData, (512+7)/8, display, fileSize)) {
        fprintf(stderr, "error: failed to convert to hex\n");
        return -1;
    }

    // Print off the result
    printf("%s  %s\n", display, fileName);
    printf("Calculated in %3f sec, %5.2f MBps\n", totalTime, hashRate);
	return 0;
}