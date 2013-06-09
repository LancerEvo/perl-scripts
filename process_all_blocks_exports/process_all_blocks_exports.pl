#!/usr/bin/perl
#	DESCRIPTION
#		Process multiple blocks' output file and generate a single output.
#	Input
#		<file>
#	Output
#		output.txt
#	MODIFIED		(MM/DD/YY) 
#	Lancer Guo		04/22/13
#	Version: 0.2
#	ChangeLog
#		0.1	newly developed
#		0.2 combined all core functions into one subroutine; comment added; subroutine names changed; and some minor tweaks.

use strict;
use warnings;
use File::Copy;
use File::Basename;

# defining variables
# spliting line in the input file
my $SPLIT_LINE = '---';
# the assignment sign in the input file
my $ASSIGN = '=';
# space sign
my $SPACE = ' ';
# colon sign, used to spliting output's INSTALL_ID and KEY
my $COLON = ':';
# the INSTALL_ID marks the start of a new block's output
my $START_OF_NEW_BLOCK = 'INSTALL_ID';
# the output file name
my $output_file = 'output.txt';
# KEYS you don't want in the output file.
my @NOT_IMPORTANT_PARAMS = (
	'DTE_PROXY_HOST',
	'DTE_PROXY_PORT',
	'DTE_PRODUCT',
	'DTE_RELEASE',
	'AUTO_HOME',
	'AUTO_WORK',
	'EXIT_STATUS',
);

# check the input parameter. if no file is specified, warning is generated and script exits.
check_input_params();
sub check_input_params {
    my $argc = @ARGV;
    if ($argc!=1) {
        print "! Missing one parameter <full path of the input file>.\n";
        print " Usage: ./process_all_blocks_exports.pl tiastopo.cfg\n";
        print "! Exit.\n";
    }
}

my $input_file = $ARGV[0];
my @input_array;
my %parsed_input_hash;

sub read_input_file {
	open my $in, "<", @_ or die "Can't open input.txt: $!";
	@input_array = <$in>;
    close $in or die "$in: $!";	
}

# the main routine
# parse each line of the input file
# skip over useless lines
# save install_id:key=value to hash
sub parse_input {
	my $install_id = '';
	foreach my $line (@input_array) {
		chomp $line;
		if (_is_line_can_be_omitted($line)) {
			next;
		}
	
		if (_is_start_of_new_block($line)) {
			my %kv = _get_key_val_from_line($line);
			_trim_install_id(\%kv);
			$install_id = $kv{'val'};
			next;
		}

		my %kv = _get_key_val_from_line($line);
		$parsed_input_hash{$install_id.$COLON.$kv{'key'}}=$kv{'val'};	
	}
}

sub _is_line_can_be_omitted {
	my $line = shift;
	if (_is_split_line($line)) {
		return 1;
	}
	if (_is_not_important_param($line)) {
		return 1;
	}
	return 0;
}

sub _is_split_line {
	my $line = shift;
	if (_contains($line, $SPLIT_LINE)) {
        return 1;
	}
	return 0;	
}

sub _is_not_important_param {
	my $line = shift;
	my @tmp = split($ASSIGN, $line);
	my $key = $tmp[0];
	if (grep {$key eq $_} @NOT_IMPORTANT_PARAMS ) {
		return 1;
	}
	return 0;
}

sub _is_start_of_new_block {
    my $line = shift;
    my %kv = _get_key_val_from_line($line);
	if (_contains($kv{'key'}, $START_OF_NEW_BLOCK)) {
		return 1;
	}
	return 0;
}

# detect if heystack contains needle
# _contains($heystack, $needle)
# both params are string.
sub _contains {
	my $haystack = shift;
	my $needle = shift;
	if (index($haystack, $needle) != -1) {
		return 1;
	}
	return 0;
}

# split line by = and save the former part as key and latter part as value.
sub _get_key_val_from_line {
	my $line = shift;
	my @tmp = split($ASSIGN, $line);
    my $key = $tmp[0];
	my $val = "";	
	if (@tmp>1){
	    $val = $tmp[1];
	}

	my %res = (
		'key'=>$key,
		'val'=>$val,
	);
	return %res;	
}

# deal with the INSTALL_ID line's spaces and stars.
sub _trim_install_id {
    my $kv  = shift;
    $$kv{'key'} = substr($$kv{'key'}, index($$kv{'key'}, $SPACE)+1);
    $$kv{'val'} = substr($$kv{'val'}, 0, index($$kv{'val'}, $SPACE));
}

sub write_to_file {
	open(my $out, ">", $output_file) or die "Can't open $output_file: $!";
	foreach my $key (sort(keys %parsed_input_hash)) {
        print $out $key;
        print $out $ASSIGN;
        print $out $parsed_input_hash{$key};
        print $out "\n";
    }
	close $out or die "$out: $!";
}

sub main{
	read_input_file($input_file);
	parse_input();
	write_to_file();
}

main();
