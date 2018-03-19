

// error codes
#define LIBKECCAK_NO_ERROR 0
#define LIBKECCAK_INIT_ERROR 1
#define LIBKECCAK_HASH_UPDATE_ERROR 2
#define LIBKECCAK_HASH_FINAL_ERROR 3

/**
 * @brief      KeccakSHA3_512Hash performs a SHA3 hash of the bytes using length 512
 *
 * @param      data      The data
 * @param[in]  dataSize  The data size
 *
 * @return     LIBKECCAK_NO_ERROR if successful, or one of the following:
 * 				- LIBKECCAK_INIT_ERROR - failed to initialize
 * 				- LIBKECCAK_HASH_UPDATE_ERROR - failed to add the bytes to the sponge
 * 				- LIBKECCAK_HASH_FINAL_ERROR - failed to extract the output bytes
 */
int KeccakSHA3_512Hash(uint8_t * data, size_t dataSize);