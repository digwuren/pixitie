#! /usr/bin/ruby

require 'getoptlong'

# There are 8 Bradford fonts.  The format seems to be one byte of header
# followed by 21-byte glyph data; the first 3 bytes of each glyph block seem to
# be glyph header, probably containing proportional printing data; the
# following 18 bytes contain two 9-byte column blocks apparently intended for
# interleaving as a double vertical density character.  I'm assuming that the
# intended pitch is 10cpi, which at 120dpi means the glyph data should be
# followed by three blank columns.

# Font 1 is a basic serif font.
# Font 2 is a basic serifless font with rounded corners.
# Font 3 is a basic serifless font without rounded corners.
# Font 4 is a 'draft' font.
# Font 5 is a 'semidraft' font.
# Font 6 is a slanted serifless font.
# Font 7 is a decorative "computer" font.
# Font 8 is a small caps version of font 3.

def weave_two b1, b2
  raise 'Assertion failed' if b1 < 0 or b2 < 0
  outbit = 1
  output = 0
  while b1 != 0 or b2 != 0 do
    output |= outbit if b2 & 1 != 0
    b2 >>= 1
    outbit <<= 1
    output |= outbit if b1 & 1 != 0
    b1 >>= 1
    outbit <<= 1
  end
  return output
end

$charset = 'bradford.cs'
$dump = false

GetoptLong::new(
  ['--baseline', '-b', GetoptLong::REQUIRED_ARGUMENT],
  ['--charset', '-c', GetoptLong::REQUIRED_ARGUMENT],
  ['--dump', '-d', GetoptLong::NO_ARGUMENT]
).each do |opt, arg|
  case opt
  when '--baseline' then $baseline = arg
  when '--charset' then $charset = arg
  when '--dump' then $dump = true
  end
end

font_data = $stdin.read
unless font_data[0 .. 3] == "\x5F\x00\x15\x00" then
  raise "Invalid magic"
end

if $dump then
  (0x20 .. 0x7E).each do |charcode|
    char_offset = 4 + 21 * (charcode - 0x20)
    printf '[%04X] $%02X:', char_offset, charcode
    puts
    print ' '
    (0 .. 8).each do |subofs|
      printf ' %02X', font_data[char_offset + subofs]
    end
    puts
    print ' '
    (9 .. 17).each do |subofs|
      printf ' %02X', font_data[char_offset + subofs]
    end
    puts
    (18 .. 20).each do |subofs|
      printf ' %02X', font_data[char_offset + subofs]
    end
    puts
  end
  exit
end

raise 'no --baseline given' unless $baseline

puts "charset #$charset"
puts
puts "circular-dots"
puts "aspect-ratio 6:5"
puts "horizontal-compression 1/2"
puts "vertical-compression 1/2"
puts "baseline #$baseline"
puts
(0x20 .. 0x7E).each do |charcode|
  char_offset = 4 + 21 * (charcode - 0x20)
  block1 = font_data[char_offset ... char_offset + 9]
  block2 = font_data[char_offset + 9 ... char_offset + 18]
  block = (0 .. 8).map{|i| weave_two block1[i], block2[i]}
  block.push 0, 0, 0
  printf "%02X", charcode
  block.each do |column|
    printf " %04X", column
  end
  puts
end
