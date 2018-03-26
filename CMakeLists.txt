cmake_minimum_required (VERSION 3.5)
project(GoKeccakSumLib)

include("cmake/Golang.cmake")

# find libkeccak - if not found add as target
if(LIBKECCAK_LOCATION)
	find_path (LIBKECCAK_HEADERS
		NAMES "KeccakHash.h"
		PATHS ${LIBKECCAK_LOCATION} ${LIBKECCAK_LOCATION}/include ${LIBKECCAK_LOCATION}/libkeccak.a.headers
	)
	if(NOT LIBKECCAK_HEADERS)
		message(FATAL_ERROR "Libkeccak headers not found")
	endif()

	message(STATUS "Found libkeccak headers at ${LIBKECCAK_HEADERS}")

	find_library(LIBKECCAK_LIBRARY
		NAMES libkeccak.a
		PATHS ${LIBKECCAK_LOCATION} ${LIBKECCAK_LOCATION}/lib ${LIBKECCAK_LOCATION}/lib64
	)

	if(NOT LIBKECCAK_LIBRARY)
		message(FATAL_ERROR "Libkeccak library not found")
	endif()

	message(STATUS "Found libkeccak library at ${LIBKECCAK_LIBRARY}")

else()
	# TODO : auto-download and build libkeccak
	message(FATAL_ERROR "Libkeccak library location not specified")
endif()

# For the example executable + static library targets
add_subdirectory(c_src)

ADD_GO_PACKAGE_FOLDER(TARGET sha3_pkg
					MAIN_FOLDER sha3
					IMPORT_PATH github.com/anonymouse64/sha3_arm
					# This is so that the cgo directives can use CMake variables to refer to where to find libkeccak, etc.
					CONFIGURE_FILES sha3/sha3.go
					# These are necessary so that we can link against the assembly code, which isn't position independent
					BUILD_ENVIRONMENT CGO_CFLAGS_ALLOW="-no-pie" CGO_LDFLAGS_ALLOW="-no-pie"
	)

# For the cgo project add the build target for the sha3 executable
ADD_GO_INSTALLABLE_PROGRAM(TARGET sha3
							MAIN_SOURCE cmd/sha3/main.go
							IMPORT_PATH github.com/anonymouse64/sha3_arm
							# These are necessary so that we can link against the assembly code, which isn't position independent
							BUILD_ENVIRONMENT CGO_CFLAGS_ALLOW="-no-pie" CGO_LDFLAGS_ALLOW="-no-pie"
	)

# Make the sha3 executable depend on the package
add_dependencies(sha3 sha3_pkg)

# Add the keccak function example program for testing
ADD_GO_INSTALLABLE_PROGRAM(TARGET keccakf1600_permute
							MAIN_SOURCE cmd/keccakf1600_permute/main.go
							IMPORT_PATH github.com/anonymouse64/sha3_arm
	)
