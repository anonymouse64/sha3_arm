
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

# Need to link against the libkeccak library with no pie, as newer gcc versions
# don't allow .text to be specified in relocatable code, which is produced by default
target_link_libraries(keccak_sum PUBLIC keccak)

# Install the executable
install(TARGETS keccak_sum keccak
	ARCHIVE DESTINATION lib
	RUNTIME DESTINATION bin
	PUBLIC_HEADER DESTINATION include)