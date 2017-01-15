# Each top row is:
# 1 byte: Length of word UInt8
# 30 bytes: word for this row
# 4 bytes: Sum of weights of all nested words UInt32
# 4 bytes: Number of nested words
#
# 39 bytes total

# Each nested row is:
# 1 byte: Length of word UInt8
# 30 bytes: word for this row
# 4 bytes: Weight UInt32
# 4 bytes: Offset of this word UInt32
#
# Also 39 bytes, nice

require "./punctuation"

words = ["!start!"]
File.each_line(ARGV[0]) do |line|
  line.split(" ").each do |word_|
    word = word_.strip
    next if word.strip.empty?
    if PunctuationChars.includes? word[-1] && word.size > 1
      words << word[0..-1]
      words << word[-1].to_s
    else
      words << word
    end
  end
end

puts "words length is #{words.size}"

bigrams = Hash(String, Hash(String, UInt32)).new#(Hash(String,Int32).new(0))
#bigrams = {} of String => Hash(String, Int32)

words[0...-1].zip(words[1..-1]) do |prev_word, next_word|
  prev_word = "!start!" if PunctuationStrings.includes? prev_word
  bigrams[prev_word] = Hash(String, UInt32).new unless bigrams.has_key? prev_word
  bigrams[prev_word][next_word] = 0u32 unless bigrams[prev_word].has_key? next_word
  bigrams[prev_word][next_word] += 1
end

puts "bigrams length is #{bigrams.size}"

word_offsets = {} of String => UInt32

current_offset = 0u32

bigrams.each do |word, next_words|
  word_offsets[word] = current_offset
  current_offset += (next_words.size+1) * ROW_SIZE
end

def ppos(f : File)
  f.flush
  puts f.pos
end

File.open("bigrams.save", "w") do |f|
  expected_offset = 0
  #ppos f
  bigrams.each do |word, next_words|
    #puts "writing #{word}"
    f.flush
    raise "Unexpected offset" unless f.pos == expected_offset && expected_offset == word_offsets[word]
    f.write_byte word.bytesize.to_u8
    #ppos f
    f.print word
    #f.print "\x00" * (30 - word.size)
    (30 - word.size).times do
      f.write_byte 0u8
    end
    #ppos f
    sum_of_weights = next_words.map(&.last).sum
    sum_of_weights.to_u32.to_io( io: f, format: IO::ByteFormat::LittleEndian)
    next_words.size.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
    expected_offset += 39
    #f.flush
    #puts "expected is #{expected_offset}, actual is #{f.pos}"
    next_words.to_a.sort_by(&.last).reverse.each do |word, weight|
      f.write_byte word.bytesize.to_u8
      f.print word
      (30 - word.size).times do
        f.write_byte 0u8
      end
      weight.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
      word_offsets[word].to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
      expected_offset += 39
    end
  end
  #word_offsets.each do |word, offset|
  #  offset.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
  #end
  #word_offsets.size.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
end
      
#max_word_length = 0

#words.each do |word|
#  if word.bytesize > max_word_length
#    max_word_length = word.bytesize
#  end
#end

#puts max_word_length
