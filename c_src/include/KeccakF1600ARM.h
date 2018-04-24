#include <stdint.h>

// state must be 1600 bits - i.e. 25 uint64_t's
void KeccakF1600( uint64_t state[25] , uint64_t constants[24] ); 
