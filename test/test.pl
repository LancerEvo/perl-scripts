#!/usr/bin/perl
use strict;
use warnings;

my $my_line="OUD_PORT=%OUDPORT%";
chomp $my_line;
$my_line =~ s/^\s+//;
$my_line =~ s/\s+$//;
my @tmp_token = split("=",$my_line);
print $tmp_token[0];
print $tmp_token[1];
