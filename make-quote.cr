require "./punctuation"

def read_word(fh : File)
  len = fh.read_byte
  raise "Unexpected EOF encountered" if len.nil?
  word_buf = Bytes.new(len)
  fh.read(word_buf)
  fh.skip(30 - len)
  num_a = fh.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
  num_b = fh.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

  return word_buf, num_a, num_b
end

def select_next(fh, weight_sum, num_words = nil)
  exit if weight_sum == 0
  selection = rand(weight_sum)
  so_far = 0
  loop do
    word, weight, offset = read_word(fh)
    so_far += weight
    if selection < so_far
      return word, offset
    end
  end
end
    

f = File.open("bigrams.save")

_ , wsum, _ = read_word(f) #reads in !start!, which we should not print out.
first_run = true
loop do
  word, offset = select_next(f, wsum)
  if word.size == 1 && PunctuationChars.any?{|c| c.ord == word[0]}
    STDOUT.write word
    exit
  end
  if !first_run
    print ' '
  end
  STDOUT.write word
  _, wsum, num_words = read_word(f)
  raise "No words to continue with" if num_words == 0
  first_run = false
end
