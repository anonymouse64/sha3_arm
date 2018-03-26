// Example executable of using the KeccakF1600 permute function 

#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdlib.h>


// state must be 1600 bits - i.e. 25 uint64_t's
extern void KeccakF1600( void *state ); 

int main(int argc, char ** argv)
{
	uint64_t state[25];
	for(int i = 0; i < 25; i++)
	{
		state[i] = i;
	}

	KeccakF1600((void *) state);

	for(int i = 0; i < 25; i++)
	{
		printf("state[%d] = %" PRIu64 "\n",i, state[i]);
	}
	return 0;
}