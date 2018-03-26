//  +build !amd64,!arm appengine gccgo

package sha3_fast

// Use generic implementation
func keccakF1600(a *[25]uint64) {
	keccakF1600Generic(a)
}
