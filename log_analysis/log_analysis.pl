#!/usr/bin/perl
#   DESCRIPTION
#       Log file analysis.
#		Parse log file to see if there's any error message.
#
#   Input
#       Log file full path and name.
#
#   MODIFIED            (MM/DD/YY) 
#       Lancer Guo       09/09/13
#       Lancer Guo       09/12/13
#
#   Version: 0.2
#
#   ChangeLog
#       0.1 Newly developed. Basic functions achieved.
#       0.2 Add function: process all files under a given directory.
#			Add function: receive a file handler as input

use strict;
use warnings;

my $error_reg=('error|fail|severe');

# check a given log file.
# param: file full path and name.
sub check_file {
	my $file = shift;
	my @contents = _read_file_to_array($file);
	foreach my $line (@contents){
		if ($line =~ m/$error_reg/i) {
  			_print_error($file, $line);
		}
	}
}

# check all files under a directory.
# param: directory path.
sub check_directory {
	my $directory = shift;
	my @files = _list_all_files_under_directory($directory);
	foreach my $file (@files){
		if (-f $directory."/".$file ){
        	check_file($directory."/".$file);
    	}
	}
}

# check already opend input stream.
# param: input stream.
sub check_input_stream {
	my $in = shift;
    my @contents = <$in>;
    foreach my $line (@contents){
        if ($line =~ m/$error_reg/i) {
            _print_error($in, $line);
        }
    }
}

# output error message
sub _print_error {
	my $file = shift;
	my $line = shift;
	print "!!! Found error message:\nFile: $file\n$line";	
}

# Read log file into array
sub _read_file_to_array {
    my $file = shift;
    open my $in, "<", $file or die "Can't open file \"$file\": $!";
    my @res = <$in>;
    close $in or die "$in: $!";
    return @res;
}

# get all files under a directory
sub _list_all_files_under_directory {
	my $directory = shift;
	opendir my $dir, $directory or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;
	return @files;
}

# how to use
sub main {
	my $log_file = "/scratch/tiguo/repo/perl-scripts/log_analysis/log.txt";
	my $log_directory = "/scratch/tiguo/repo/perl-scripts/log_analysis/logs";
	#check single log file
	check_file($log_file);
	#check all files under a directory
	check_directory($log_directory);
	#check input stream
    open my $in, "<", $log_file or die "Can't open file \"$log_file\": $!";
	check_input_stream($in);
    close $in or die "$in: $!";
}

main();
