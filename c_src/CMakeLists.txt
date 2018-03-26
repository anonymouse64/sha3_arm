
# Compile the main library
add_library(keccak STATIC libkeccak.c)

# Add the headers to the library target
set_target_properties(keccak PROPERTIES PUBLIC_HEADER "include/libkeccak.h")

# Include the libkeccak headers
target_include_directories(keccak PUBLIC ${LIBKECCAK_HEADERS})
target_include_directories(keccak PUBLIC include)

# Need to link against the libkeccak library with no pie, as newer gcc versions
# don't allow .text to be specified in relocatable code, which is produced by default
target_link_libraries(keccak PUBLIC -no-pie ${LIBKECCAK_LIBRARY})

# Compile the executable
add_executable(keccak_sum keccak_sum.c)

# Add the assembly example
add_library(keccakf1600 STATIC KeccakF1600_arm.S)
target_compile_options(keccakf1600 PUBLIC -march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4)
set_target_properties(keccakf1600 PROPERTIES PUBLIC_HEADER "include/KeccakF1600ARM.h")


add_executable(keccakf1600_example KeccakF1600_example.c )
target_link_libraries(keccakf1600_example PUBLIC keccakf1600)


set(KECCAKF1600_HEADERS $<TARGET_PROPERTY:keccakf1600,PUBLIC_HEADER>)
set(KECCAKF1600_LIBRARY $<TARGET_FILE:keccakf1600>)

message(STATUS "KeccakF1600 headers are : ${KECCAKF1600_HEADERS}")
message(STATUS "KeccakF1600 library is : ${KECCAKF1600_LIBRARY}")

# Need to link against the libkeccak library with no pie, as newer gcc versions
# don't allow .text to be specified in relocatable code, which is produced by default
target_link_libraries(keccak_sum PUBLIC keccak)

# Install the executable
install(TARGETS keccak_sum keccak
	ARCHIVE DESTINATION lib
	RUNTIME DESTINATION bin
	PUBLIC_HEADER DESTINATION include)