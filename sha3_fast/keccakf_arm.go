// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build arm,!appengine,!gccgo

package sha3_fast

// /*This uses CMake generator expressions to use/link against the library that is built for the assembly, keccakf1600 */
// #cgo CFLAGS: -fno-pie -no-pie -I$<TARGET_PROPERTY:keccakf1600,INCLUDE_DIRECTORIES>
// #cgo LDFLAGS: -no-pie $<TARGET_FILE:keccakf1600>
// #include <stdlib.h>
// #include "KeccakF1600ARM.h"
import "C"

// To detect what version of arm we are running on we need to get goarm from the runtime
//go:linkname goarm runtime.goarm
var goarm uint8

// If NEON is available, use the NEON implementation, otherwise fallback on
// generic implementation
func keccakF1600(a *[25]uint64) {
	if goarm >= 7 {
		C.KeccakF1600((*_Ctype_ulonglong)(&a[0]))
	} else {
		keccakF1600Generic(a)
	}
}
