
# Compile the executable
add_executable(libkeccak_example libkeccak.c)

# Include the libkeccak headers
target_include_directories(libkeccak_example PUBLIC ${LIBKECCAK_HEADERS})

# Need to link against the libkeccak library with no pie, as newer gcc versions
# don't allow .text to be specified in relocatable code, which is produced by default
target_link_libraries(libkeccak_example PUBLIC -no-pie ${LIBKECCAK_LIBRARY})

# Install the executable
install(TARGETS libkeccak_example
	RUNTIME DESTINATION bin)