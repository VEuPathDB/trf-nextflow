#!/usr/bin/env perl
use strict;
use warnings;

my $in = $ARGV[0];
my $out = $ARGV[1];
open(FILE, $in) or die "cannot open file $in for reading: $!";
open(OUT, ">$out") or die "cannot open file $out for writing: $!";

my $sequence;
my $count = 1;

while(<FILE>) {
    chomp;

    if($count++ % 1000 == 0) {
        print STDERR "Processed $count lines of data file";
    }

    next if(!$_);

    if(/Sequence: (\S+)/) {
        $sequence = $1;
    }
    elsif(/Parameters: ((?:\d+\s*)+)/) {
        next;
    }
    else {
        next if(!$sequence);

        my @data = split(' ', $_);

        my $start = $data[0] - 1; #NOTE:  bedgraph format is zero based half open

        print OUT "$sequence\t$start\t$data[1]\n";
    }
}

close(FILE);
close OUT;


1;
