package sha3

// #cgo CFLAGS: -fno-pie -no-pie -I/home/ijohnson/git/canonical/KeccakCodePackage/bin/asmX86-64/libkeccak.a.headers
// #cgo LDFLAGS: -no-pie /home/ijohnson/git/canonical/KeccakCodePackage/bin/asmX86-64/libkeccak.a
// #include <stdlib.h>
// #include "KeccakHash.h"
// #include "KeccakSpongeWidth1600.h"
// #include "KeccakP-1600-SnP.h"
import "C"
import (
	"fmt"
	"unsafe"
)

// For FIPS202 standard
const (
	fipsDelimiter = 0x06
)

type Sha3FastHasher struct {
	Rate            int
	Capacity        int
	Hashbitlen      int
	DelimitedSuffix int
	instance        C.Keccak_HashInstance
	lasthashedbytes unsafe.Pointer
}

func NewKeccak512() *Sha3FastHasher {
	hashers := make([]Sha3FastHasher, 1)
	hashers[0] = Sha3FastHasher{
		Rate:            576,
		Capacity:        1024,
		Hashbitlen:      512,
		DelimitedSuffix: fipsDelimiter,
	}

	// If this fails we have to panic cause we can't return an error
	if res := C.Keccak_HashInitialize(
		&hashers[0].instance,
		_Ctype_uint(hashers[0].Rate),
		_Ctype_uint(hashers[0].Capacity),
		_Ctype_uint(hashers[0].Hashbitlen),
		_Ctype_uchar(hashers[0].DelimitedSuffix),
	); res != 0 {
		panic("failed to initialize hasher")
	}
	return &hashers[0]
}

// Write function absorbs bytes into the sponge
func (h *Sha3FastHasher) Write(b []byte) (n int, err error) {
	if h.lasthashedbytes != nil {
		C.free(h.lasthashedbytes)
	}
	byteLen := C.size_t(len(b))
	bytes := C.CBytes(b)
	h.lasthashedbytes = bytes
	res := C.Keccak_HashUpdate(
		&h.instance,
		(*_Ctype_uchar)(h.lasthashedbytes),
		byteLen*8,
	)
	if res != 0 {
		return 0, fmt.Errorf("failed to update hash")
	}
	return len(b), nil
}

// Sum appends the current hash to b and returns the resulting slice.
// It does not change the underlying hash state.
// TODO: currently this doesn't obey the second part of the function, i.e.
// it does currently change the underlying hash state if b isn't nil
func (h *Sha3FastHasher) Sum(b []byte) []byte {
	// check if b is nil, in which case we just run on the state we have accumulated
	if b != nil {
		// need to duplicate the state and then write these bytes to it
		// before summing it
		h.Write(b)
	}
	// Allocate data for the output buffer - need to take the ceiling of the
	// hashbitlen / 8 for the size of it
	outputlen := (h.Hashbitlen + 7) / 8
	// fmt.Printf("bytes addr: %#v\n", bytes)
	res := C.Keccak_HashFinal(
		&h.instance,
		(*_Ctype_uchar)(h.lasthashedbytes),
	)
	if res != 0 {
		return nil
	}
	// copy the c memory to go memory
	return C.GoBytes(h.lasthashedbytes, _Ctype_int(outputlen))
}

// Reset resets the hasher's internal state to its initial state.
func (h *Sha3FastHasher) Reset() {
	// TODO: implement the state part of this
}

// Size returns the number of bytes Sum will return.
func (h *Sha3FastHasher) Size() int {
	return h.Hashbitlen / 8
}

// BlockSize returns the hash's underlying block size.
// The Write method must be able to accept any amount
// of data, but it may operate more efficiently if all writes
// are a multiple of the block size.
func (h *Sha3FastHasher) BlockSize() int {
	return h.Rate / 8
}
