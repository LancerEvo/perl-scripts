#!/usr/bin/perl
#	DESCRIPTION
#		Run multiple topologies at a specific time.
#	Input
#		topos.txt
#	MODIFIED		(MM/DD/YY) 
#	Lancer Guo		05/13/13
#	Version: 0.1
#	ChangeLog
#		0.1	newly developed

use strict;
use warnings;
use File::Copy;
use File::Basename;
use POSIX qw(tzset);
use Time::Local;

# check the input parameters.
# params:
# 	input file
#	scheduled time(year month day hour minute)
#	timezone(optional. default GMT+8).
sub check_input_params {
    my $argc = @ARGV;
    if ($argc<6) {
        print "! Missing one parameter <full path of the input file> <year> <month> <day> <hour> <min>.\n";
        print " Usage: ./topo_jobs_control.pl topos.txt 2013 5 13 13 00\n";
        print "! Exit.\n";
    }
}

# symbols
my $BACKSLASH = '\\';

# variables definition
my $input_file_name = $ARGV[0];
my @input;
my @command_array;

my $year = $ARGV[1];
my $mon = $ARGV[2];
my $day = $ARGV[3];
my $hour = $ARGV[4];
my $min = $ARGV[5];
my $sec = 0;

# set timezone
if (defined($ARGV[6])){
	$ENV{TZ} = $ARGV[6];
	print "Set timezone to ".$ARGV[6]."\n";
} else {
	$ENV{TZ} = 'Asia/Shanghai';
	print "No timezone selected. Using default GMT+8 Asia/Shanghai\n";
}
tzset();

# convert scheduled time to epoch seconds
my $due = timelocal($sec, $min, $hour, $day, $mon-1, $year);

# wait to scheduled time
sub wait_till_scheduled_time {
	my $due = shift;
	my $now = time;
	if ($due<$now) {
		print "scheduled time has already passed! exit.\n";
		exit();
	} else {
		sleep $due-$now;
	}
}

# read input
sub read_input_file {
	open my $in, "<", @_ or die "Can't open input.txt: $!";
	@input = <$in>;
    close $in or die "$in: $!";	
}

# generate commands to be ran from input file
sub generate_commands {
	my $cmd = '';
    foreach my $line (@input) {
        chomp $line;
	
		if (_is_empty($line)){
			next;
		}
		
		if (_end_with_backslash($line)){
			$line = _trim_backslash($line);
			$cmd = $cmd.$line;
			next;
		} else {
			# last line of a topo run command
			# run in background
			$cmd = $cmd.$line;
			push(@command_array, $cmd);
			$cmd = '';
			next;
		}
    }
}

sub run_command_bg {
	my ($command, $child_pid);

	if ( scalar(@_) == 1 ) {
		$command = $_[0];
		$child_pid = fork();
		if ( $child_pid == 0 ) {
			exec ($command) || warn ("run_command: Could not exec $command.\n");
			# shall never execute the following statement, but if $command
			# does not exist, exec() will come to this point!!!
			exit 1;
		} else {
			return $child_pid;
		}
	} else {
		warn ("Could not execute run_command_bg() due to incorrect parameters.\n");
 	}
}

sub _is_empty {
	my $line = shift;
	if ($line eq "") {
		return 1;
	}
	return 0;
}

sub _end_with_backslash {
	my $line = shift;
	if (substr($line, -1, 1) eq $BACKSLASH){
		return 1;
	}
	return 0;
}

sub _trim_backslash {
    my $line = shift;
	return substr($line, 0, -1);
}

sub main{
    check_input_params();
    read_input_file($input_file_name);
    generate_commands();
    wait_till_scheduled_time($due);
    foreach my $cmd (@command_array){
		run_command_bg($cmd);
	}
	print "success!\n";
}

main();
