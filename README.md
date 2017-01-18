# Crystal Bigram Quoter

Creates quotes based on markov chains. Designed to run very quickly.

## Build

    crystal build generate-sav-file.cr
	crystal build make-quote.cr
	
## Run

    ./generate-sav-file 33.txt.utf-8
	./make-quote

`generate-sav-file` will make a file called "bigrams.save" which has the pre-processed markov tree. `make-quote` reads in that file and produces a quote.

## File format

The save file is a series of 64-byte rows. Each row consists of 

* A byte,
  * The most significant bit of which indicates what type of row this is
  * The other bytes indicate the length of the following the string.
* The word, null-padded to 55 bytes.
* 2 side-by-side unsigned 32-bit integers, little-endian.

There are two types of rows:

* Top rows have the MSB of the first byte set to 1. These rows are the head to a list of words that follow the word indicated in this row. The first int is the sum of all weights of following words, the second is the total number of following words.
* Nested rows have the MSB of the first byte set to 0. These rows make up the list of words that follow a word in the previous top row. The first number is the weight (which is also the number of occurances) and the second number is the offset in the file, or zero if the word has no corrosponding top row (such as punctuation).

The MSB of the first byte, the second int for top rows, and the word for top rows are all unused by the quote generator, and are simply for debugging purposes.

It is expected that the first row is the "!start!" top row, which indicates the beginning of a sentence.
