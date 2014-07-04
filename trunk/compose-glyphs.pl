#! /usr/bin/perl -w

use strict;

my %strokes;

sub handle ($);

sub handle ($) {
  my ($line) = @_;
  if (m/^\.stroke\s+(\w+)\s+/) {
    die "dupliccate stroke '$1'" if exists $strokes{$1};
    $strokes{$1} = [map {hex} split /\s+/, $'];
    print "# $_";
  } elsif (m/^\.compose\s+([\dabcdefABCDEF]+)\s*:\s*/) {
    my $code = hex $1;
    my @elements = split /\s+/, $';
    my @result;
    for my $element (@elements) {
      my $stroke = $strokes{$element};
      die "unknown stroke $element" unless defined $stroke;
      push @result, 0 until @result >= @$stroke;
      $result[$_] |= $stroke->[$_] for 0 .. $#$stroke;
    }
    printf "%02X", $code;
    printf " %02X", $_ for @result;
    print "\n";
  } elsif (m/^\.include\s+/) {
    my $filename = $';
    chomp $filename;
    my $fh;
    open $fh, '<', $filename
      or die "$filename: open for reading: $!";
    while (<$fh>) {
      handle $_;
    }
    close $fh;
  } else {
    print;
  }
}

die "No input?" unless @ARGV;
die "Too many arguments" if @ARGV > 2;

print "### !!! Generated from $ARGV[0] by compose-glyphs.pl\n";
print "\n";

while (<>) {
  handle $_;
}
