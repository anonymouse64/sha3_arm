package main

import (
	"crypto/rand"
	"flag"
	"fmt"
	"hash"
	"io"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"

	// osutil "github.com/snapcore/snapd/osutil"
	// _ "golang.org/x/crypto/sha3"
	sha3 "github.com/anonymouse64/sha3_arm/sha3_fast"
)

const (
	hashDigestBufSize = 2 * 1024 * 1024
)

// FileDigest computes a hash digest of the file using the given hash.
// It also returns the file size.
func FileDigest(filename string, hash hash.Hash) ([]byte, uint64, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, 0, err
	}
	defer f.Close()
	// h := hash.New()
	size, err := io.CopyBuffer(hash, f, make([]byte, hashDigestBufSize))
	if err != nil {
		return nil, 0, err
	}
	return hash.Sum(nil), uint64(size), nil
}

func timeFileHash(hasher hash.Hash, file string) ([]byte, time.Duration) {
	// Get start time
	start := time.Now()

	// Compute the hash of the file
	hashRes, _, _ := FileDigest(file, hasher)

	// Return the hash result and the time since the start of the function
	return hashRes, time.Since(start)
}

func main() {
	// Setup flags
	fileStr := flag.String("file", "", "file to hash")
	randomSizeMB := flag.Int64("size", 10, "size of generated random file")
	unitStr := flag.String("unit", "s", "units to use (possible values : ns, us, ms, s)")
	// algStr := flag.String("alg", "sha3_512", "algorithm to use, sha3_512, sha3_384, sha3_256, or sha3_224")
	numIters := flag.Int("iter", 1, "number of iterations to run")
	avgTimes := flag.Bool("avg", false, "whether to average the time results or not")

	// Parse command line flags
	flag.Parse()

	// Check the units to use for output
	var timeVal time.Duration
	switch strings.ToLower(*unitStr) {
	case "ns":
		timeVal = time.Nanosecond
	case "us":
		timeVal = time.Microsecond
	case "ms":
		timeVal = time.Millisecond
	case "s":
		timeVal = time.Second
	default:
		log.Fatalf("error : invalid units specification %s\n", *unitStr)
	}

	// Check whether the file exists or not, if it doesn't that might be okay as we
	// might be generating a random file
	var fileExistsQ bool
	var fileSize int64
	if file, err := os.Stat(*fileStr); os.IsNotExist(err) {
		fileExistsQ = false
	} else {
		fileExistsQ = true
		// Also save the file size now that we have a file that exists
		fileSize = file.Size()
	}

	// Now check the type of file handling
	switch {
	case !fileExistsQ && *fileStr != "":
		// File was specified but doesn't exist - we can use err as it won't have been cleared yet
		log.Fatalf("error : file %s doesn't exist\n", *fileStr)
	case !fileExistsQ:
		// then don't use a file - generate one randomly
		fileSize = (*randomSizeMB) * 1048576
		randomBytes := make([]byte, fileSize)

		// Read this many bytes from the OS's random number generator
		_, err := rand.Read(randomBytes)

		// Make a new temp file
		tmpfile, err := ioutil.TempFile("", "sha3sum_example")
		if err != nil {
			log.Fatal(err)
		}

		// Clean up automatically
		defer os.Remove(tmpfile.Name())

		// Write out all the random bytes to the file
		if _, err := tmpfile.Write(randomBytes); err != nil {
			log.Fatal(err)
		}

		// Close the file as we want osutil.FileDigest to read the file
		if err := tmpfile.Close(); err != nil {
			log.Fatal(err)
		}

		// Can't take the address of .Name() method, so save it in a variable first
		var tempfileName string
		tempfileName = tmpfile.Name()
		fileStr = &tempfileName
	}

	// Run a single run and print out human readable form
	// First check what algorithm to use
	// hasherToUse := NewKeccak512()

	// Run the hash the specified number of iterations
	timeResults := make([]time.Duration, *numIters)
	var hashBytes []byte
	var timeRes time.Duration
	for i := 0; i < *numIters; i += 1 {
		hasherToUse := sha3.New512()
		hashBytes, timeRes = timeFileHash(hasherToUse, *fileStr)
		timeResults[i] = timeRes
	}

	// Print the hash and the file name
	fmt.Printf("%x %s\n", hashBytes, *fileStr)

	// Print the stats
	if *avgTimes {
		var timeAvg float64
		for _, timeRes := range timeResults {
			timeAvg += float64(timeRes)
		}
		timeAvg = timeAvg / float64(*numIters)

		fmt.Printf("Calculated in %3f sec, %5.2f MBps\n", timeAvg/float64(timeVal), float64(fileSize)/1048576/(timeAvg/float64(time.Second)))
	} else {
		// just print off the stats for each run
		for _, timeRes := range timeResults {
			fmt.Printf("Calculated in %3f sec, %5.2f MBps\n", float64(timeRes)/float64(timeVal), float64(fileSize)/1048576/(float64(timeRes)/float64(time.Second)))
		}
	}

}
