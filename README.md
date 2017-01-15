# Crystal Bigram Quoter

Creates quotes based on markov chains. Designed to run very quickly.

# Build

    crystal build generate-sav-file.cr
	crystal build make-quote.cr
	
# Run

    ./generate-sav-file 33.txt.utf-8
	./make-quote

`generate-sav-file` will make a file called "bigrams.save" which has the pre-processed markov tree. `make-quote` reads in that file and produces a quote.
