#!/usr/bin/perl
use strict;
use warnings;

BEGIN
{
  unshift(@INC,"/scratch/tiguo/autohome/plib");
}
require DTE;

my $line = DTE::readin_text_file("input.txt");

chomp($line);

print $line;

