#! /usr/bin/perl -w

use strict;

print while <DATA>;

# The clean approach would be to generate character 00 for U+2800 'BRAILLE
# PATTERN BLANK', too.  Unfortunately, the showcase file generated from the
# resulting font makes Apple's pstopdf crash, apparently because of a 'full'
# 256-character font, possibly because it doesn't contain any ASCII characters.
# As a workaround, we'll leave one character out of the font, and invite the
# user to use a space character from a suitable similarly sized font as the
# substitute for U+2800.

print "\n";
for my $i (1 .. 255) {
  printf ".compose %02X:", $i;
  for my $dot (1 .. 8) {
    if ($i & (1 << ($dot - 1))) {
      print " $dot";
    }
  }
  print "\n";
}
__END__
### !!! Generated by generate-braille.pxf.cg.pl

charset braille.cs

aspect-ratio 6:5
horizontal-compression 1/2
circular-dots
# This baseline is chosen mainly so that the 12 bit rows would align with
# Epson's customary 12-row output.  A good case might also be made that the
# baseline should really be 4 or 1 instead.
baseline 5

.stroke 1 C00 000 C00 000 000 000 000 000 000 000 000 000
.stroke 2 180 000 180 000 000 000 000 000 000 000 000 000
.stroke 3 030 000 030 000 000 000 000 000 000 000 000 000
.stroke 4 000 000 000 000 000 C00 000 C00 000 000 000 000
.stroke 5 000 000 000 000 000 180 000 180 000 000 000 000
.stroke 6 000 000 000 000 000 030 000 030 000 000 000 000
.stroke 7 006 000 006 000 000 000 000 000 000 000 000 000
.stroke 8 000 000 000 000 000 006 000 006 000 000 000 000
