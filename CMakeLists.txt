cmake_minimum_required (VERSION 3.5)
project(GoKeccakSumLib)

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

add_subdirectory(c_src)

