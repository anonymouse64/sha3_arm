# SHA3 Keccak Library

This library is a Golang wrapper for the libkeccak functions implemented here : https://github.com/gvanas/KeccakCodePackage. It provides 3-5 times faster performance (on specicially ARM) than the current implementation of the SHA3 functionality implemented here : https://godoc.org/golang.org/x/crypto/sha3. It does this by using the hand tuned assembly available in the KeccakCodePackage.

## Building

As this package is a Go wrapper around assembly, it uses cgo, and as such you must have a recent C compiler and CMake available. The first step is to build libkeccak (this is something that I intend to do automatically in CMake, but haven't implemented quite yet).

## Supported platforms

### Linux
This has been tested with Ubuntu 17.10 on x86. It has comparable performance to the native go implementation however, so there's not much advantage to using it over the standard library.

### Mac OS X
This hasn't been tested on Mac, but should work so long as libkeccak compiles properly.

### ARM 
This has been tested on Raspberry Pi 3 v1.2 running Raspbian with gcc 6.3, as well on Raspberry Pi 2 B running Ubuntu Server 17.10 with gcc 7.2. Older versions of gcc may not link the static libkeccak library correctly.

### Windows
It may be possible to build libkeccak on Windows (perhaps using msys or WSL), but I haven't tried it, so for now Windows is not supported. However, the Go code should still work if one is somehow able to get libkeccak to compile properly on Windows.