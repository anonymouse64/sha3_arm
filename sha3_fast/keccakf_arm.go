// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build arm,!appengine,!gccgo

//go:generate asm2go -as arm-linux-gnueabihf-as -file asm_src/keccakf_arm.s -gofile keccakf_arm.go -out keccakf_arm.s -as-opts -march=armv7-a -as-opts -mfpu=neon-vfpv4

package sha3_fast

import "unsafe"

// To detect what version of arm we are running on we need to get goarm from the runtime
//go:linkname goarm runtime.goarm
var goarm uint8

var constants = [24]uint64{
	0x0000000000000001,
	0x0000000000008082,
	0x800000000000808a,
	0x8000000080008000,
	0x000000000000808b,
	0x0000000080000001,
	0x8000000080008081,
	0x8000000000008009,
	0x000000000000008a,
	0x0000000000000088,
	0x0000000080008009,
	0x000000008000000a,
	0x000000008000808b,
	0x800000000000008b,
	0x8000000000008089,
	0x8000000000008003,
	0x8000000000008002,
	0x8000000000000080,
	0x000000000000800a,
	0x800000008000000a,
	0x8000000080008081,
	0x8000000000008080,
	0x0000000080000001,
	0x8000000080008008,
}

// this is a pool of bytes that is big enough to hold all of
// the constants with enough available padding to align it on an 16-byte boundary
var alignmentPool [24*8 + 16]byte

// the pointer to the actual constant, which is in aligned memory
var constantAlignedPtr *[24]uint64

// alignConstants takes the constants for keccak and aligns them on an 16-byte boundary
// somewhere inside alignmentPool and assigns the start of the aligned constants
// to constantAlignedPtr
func alignConstants() {
	initialAddr := (uintptr)(unsafe.Pointer(&constants))
	// check if we are aligned properly already
	if initialAddr%16 == 0 {
		// already aligned
		constantAlignedPtr = &constants
		return
	}

	// We have to do some moving around
	startOfAlignmentPool := (uintptr)(unsafe.Pointer(&alignmentPool))
	startOfAlignedSegment := startOfAlignmentPool%16 + startOfAlignmentPool
	if startOfAlignedSegment%16 != 0 {
		panic("not aligned")
	}

	// Cast the start of the aligned segment to an appropriate pointer
	constantAlignedPtr = (*[24]uint64)(unsafe.Pointer(startOfAlignedSegment))

	// Now copy the constants into the aligned array
	copy((*constantAlignedPtr)[:], constants[:])
}

func init() {
	//alignConstants()
}

//go:noescape
// This function is implemented in keccakf_arm.s
func KeccakF1600(state *[25]uint64, constants *[24]uint64)

// If NEON is available, use the NEON implementation, otherwise fallback on
// generic implementation
func keccakF1600(a *[25]uint64) {
	if goarm >= 7 {
		KeccakF1600(a, constantAlignedPtr)
	} else {
		keccakF1600Generic(a)
	}
}
