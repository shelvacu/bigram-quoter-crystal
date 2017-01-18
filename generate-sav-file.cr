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
require "json"

words = ["!start!"]
File.each_line(ARGV[0]) do |line|
  line.split(" ").each do |word_|
    word = word_.strip
    next if word.strip.empty?
    if PunctuationChars.includes?(word[-1]) && (word.size > 1)
      words << word[0...-1]
      words << word[-1].to_s
    else
      words << word
    end
    #raise "This can't be right! #{word.inspect} #{words[-2..-1].inspect}" if words.last.ends_with?(".") && words.last.size > 1
  end
end

#puts "words length is #{words.size}"

bigrams = Hash(String, Hash(String, UInt32)).new

words[0...-1].zip(words[1..-1]) do |prev_word, next_word|
  prev_word = "!start!" if PunctuationStrings.includes? prev_word
  bigrams[prev_word] = Hash(String, UInt32).new unless bigrams.has_key? prev_word
  bigrams[prev_word][next_word] = 0u32 unless bigrams[prev_word].has_key? next_word
  bigrams[prev_word][next_word] += 1
end

#puts "bigrams length is #{bigrams.size}"

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

#puts bigrams.to_json

#exit

File.open("bigrams.save", "w") do |f|
  expected_offset = 0
  bigrams.each do |word, next_words|
    f.flush
    raise "Unexpected offset" unless f.pos == expected_offset && expected_offset == word_offsets[word]
    f.write_byte (word.bytesize.to_u8 | 0b1000_0000) # problems if word.bytesize > 127
    f.print word
    (MAX_WORD_SIZE - word.size).times do
      f.write_byte 0u8
    end
    sum_of_weights = next_words.map(&.last).sum
    sum_of_weights.to_u32.to_io( io: f, format: IO::ByteFormat::LittleEndian)
    next_words.size.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
    expected_offset += ROW_SIZE
    next_words.to_a.sort_by(&.last).reverse.each do |word, weight|
      f.write_byte word.bytesize.to_u8
      f.print word
      (MAX_WORD_SIZE - word.size).times do
        f.write_byte 0u8
      end
      weight.to_u32.to_io(io: f, format: IO::ByteFormat::LittleEndian)
      offset = word_offsets[word]?
      if offset.nil?
        0u32
      else
        word_offsets[word].to_u32
      end.to_io(io: f, format: IO::ByteFormat::LittleEndian)
      expected_offset += ROW_SIZE
    end
  end
end
