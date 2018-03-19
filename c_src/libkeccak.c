// Initial implementation of wrapping the libkeccak library

#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include "KeccakHash.h"
#include "KeccakSpongeWidth1600.h"
#include "KeccakP-1600-SnP.h"
#include "libkeccak.h"


// Performs hashing of the specified data array
// the output is written in place to the data array
// up to length of 512
int KeccakSHA3_Hash(uint8_t * data, size_t dataSize, int type)
{
	// Set the settings depending on the algorithm to use
	int rate;
	int capacity;
	int hashbitlen;
	switch(type) 
	{
		case LIBKECCAK_ALG_SHA3_512:
			rate = 576;
			capacity = 1024;
			hashbitlen = 512;
			break;
		case LIBKECCAK_ALG_SHA3_384:
			rate = 832;
			capacity = 768;
			hashbitlen = 384;
			break;
		case LIBKECCAK_ALG_SHA3_256:
			rate = 1088;
			capacity = 512;
			hashbitlen = 256;
			break;
		case LIBKECCAK_ALG_SHA3_224:
			rate = 1152;
			capacity = 448;
			hashbitlen = 224;
			break;
		default:
			return LIBKECCAK_INVALID_ARGS;
	}
	// For FIPS202
	int delimitedSuffix = 0x06;
	Keccak_HashInstance instance;

	// Setup the sponge
	instance.fixedOutputLength = hashbitlen;
	instance.delimitedSuffix = delimitedSuffix;
	if(Keccak_HashInitialize(&instance,
		rate,
		capacity,
		hashbitlen,
		delimitedSuffix))
	{
		return LIBKECCAK_INIT_ERROR;
	}

	// Add the bytes to the sponge
	if(Keccak_HashUpdate(&instance, data, dataSize*8))
	{
		return LIBKECCAK_HASH_UPDATE_ERROR;
	}

	// Run the final hash
	if(Keccak_HashFinal(&instance, data))
	{
		return LIBKECCAK_HASH_FINAL_ERROR;
	}

	return LIBKECCAK_NO_ERROR;
}
