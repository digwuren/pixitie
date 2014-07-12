#! /usr/bin/perl -w

use strict;
use Getopt::Std;

# Convert a BDF font into a PXF font.  Very crude tool, but it sometimes works.
#
# You'll have to add a charset manually.  If the PXF does not contain any
# charset directive, Pixitie will attempt to load charset data from a resource
# of the same name as the font, with .cs instead of .pxf, and will complain if
# it does not exist.

our %opts;
getopts('c:', \%opts); # supplies the charset directive for the generated PXF

die "No input?" unless @ARGV;
die "Too many arguments" if @ARGV >= 2;

my ($input_filename) = @ARGV;

my %chars;
my $pixels_above_baseline = 0;
my $pixels_below_baseline = 0;

sub max (@) {
  die unless @_;
  my $value = shift;
  while (@_) {
    $value = $_[0] if $_[0] > $value;
    shift;
  }
  return $value;
}

my $curchar;
while (<>) {
  chomp;
  s/\s*$//;
  next if m/^(STARTFONT|FONT|SIZE|FONTBOUNDINGBOX|CHARS|STARTCHAR|SWIDTH|COMMENT)\b/;
  last if m/^ENDFONT$/;
  if (m/^STARTPROPERTIES\b/) {
    while (<>) {
      last if m/^ENDPROPERTIES\b/;
    }
    next;
  }
  next if m/^\s*$/;
  if (m/^ENCODING\s+(\d+)$/) {
    die "duplicate charcode" if exists $chars{$1};
    die "unexpected ENCODING" if defined $curchar;
    $curchar = $chars{$1} = {
        ENCODING => $1,
    };
  } elsif (m/^DWIDTH\s+(\d+)\s+(\d+)$/) {
    die "duplicate DWIDTH" if exists $curchar->{DWIDTH};
    $curchar->{DWIDTH} = {
      X => $1,
      Y => $2,
    };
    die "non-horizontal width" unless $curchar->{DWIDTH}->{Y} == 0;
  } elsif (m/^BBX\s+(\d+)\s+(\d+)\s+(-?\d+)\s+(-?\d+)$/) {
    die "duplicate BBX" if exists $curchar->{BBX};
    $curchar->{BBX} = {
      WIDTH => $1,
      HEIGHT => $2,
      LEFT => $3,
      BOTTOM => $4,
    };
  } elsif (m/^BITMAP$/) {
    die "missing BBX" unless exists $curchar->{BBX};
    die "missing DWIDTH" unless exists $curchar->{DWIDTH};
    my @bitmap;
    while (<>) {
      chomp;
      last if m/^ENDCHAR$/;
      die "parse error" unless m/^[\dabcdef]+$/i;
      my $row = unpack 'B*', pack 'H*', $_;
      $row .= '0' while length($row) < $curchar->{DWIDTH}->{X};
      unless (substr($row, $curchar->{DWIDTH}->{X}) =~ m/^0*$/) {
        die "pixels outside glyph's exclusive occupation zone";
      }
      push @bitmap, substr($row, 0, $curchar->{DWIDTH}->{X});
    }
    $curchar->{BITMAP} = [@bitmap];
    die "invalid bitmap size" unless @bitmap == $curchar->{BBX}->{HEIGHT};
    $pixels_above_baseline = max $pixels_above_baseline, $curchar->{BBX}->{HEIGHT} + $curchar->{BBX}->{BOTTOM};
    $pixels_below_baseline = max $pixels_below_baseline, - $curchar->{BBX}->{BOTTOM};
    undef $curchar;
  } else {
    die "parse error near \"$_\"";
  }
}

my $output_glyph_height = $pixels_above_baseline + $pixels_below_baseline;
$output_glyph_height += (-$output_glyph_height) & 3; # round to full hex digits
die "Too tall glyphs" if $output_glyph_height > 31;

print "### !!! Generated by bdf2pxl.pl from $input_filename\n";
print "\n";
print "charset $opts{c}\n" if exists $opts{c};
print "baseline ", $output_glyph_height - $pixels_above_baseline, "\n";
print "\n";

for my $code (sort {$a <=> $b} keys %chars) {
  my $char = $chars{$code};
  printf "%02X", $char->{ENCODING};
  my @rows = @{$char->{BITMAP}};
  my $blank_row = '0' x $char->{DWIDTH}->{X};
  for my $i (1 .. $pixels_above_baseline - ($char->{BBX}->{HEIGHT} + $char->{BBX}->{BOTTOM})) {
    unshift @rows, $blank_row;
  }
  push @rows, $blank_row while @rows < $output_glyph_height;
  for my $i (0 .. $char->{DWIDTH}->{X} - 1) {
    my $column = join '', map{substr $_, $i, 1} @rows;
    print ' ', unpack "H" . ($output_glyph_height / 4), pack 'B*', $column;
  }
  print "\n";
}
