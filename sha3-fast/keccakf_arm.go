// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build arm,!appengine,!gccgo

package sha3_fast

// #cgo CFLAGS: -fno-pie -no-pie -I
// #cgo LDFLAGS: -no-pie /home/ijohnson/git/canonical/sha3_arm/build/c_src
// #include <stdlib.h>
// #include "KeccakF1600ARM.h"
import "C"

import (
	_ "unsafe"
)

// To detect what version of arm we are running on we need to get goarm from the runtime
//go:linkname goarm runtime.goarm
var goarm uint8

// If NEON is available, use the NEON implementation, otherwise fallback on
// generic implementation
func keccakF1600(a *[25]uint64) {
	if goarm > 7 {
		C.KeccakF1600(a)
	} else {
		keccakF1600Generic(a)
	}
}

// These functions are implemented in keccakf_arm.s.
//go:noescape
func keccakF1600Neon(a *[25]uint64)
