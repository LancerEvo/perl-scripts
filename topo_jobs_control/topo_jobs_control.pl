#!/usr/bin/perl
#	DESCRIPTION
#		Topology contorl.
#		Run multiple topologies at a specific time.
#		Or run when new labels are found.
#
#	Input
#		config
#
#	MODIFIED			(MM/DD/YY) 
#		Lancer Guo		 05/13/13
#		Lancer Guo		 06/09/13
#
#	Version: 0.2
#
#	ChangeLog
#		0.1	Newly developed. Run commands at specified time. Timezone supported.
#		0.2	Add another mode. Run if new label found, with the new label.
#			Use config files instead of input parameters. Removed check parameter subroutine.

use strict;
use warnings;
use File::Copy;
use File::Basename;
use POSIX qw(tzset);
use Time::Local;

#BEGIN {
#	select(STDOUT);
#	$| = 1;
#}

# symbols
my $BACKSLASH = '\\';
my $SHARP = '#';

# variables definition
my $LABEL_LOCAL_CACHE = "label_cache";
my $SERIE = "IDM_MAIN_GENERIC";
my $commands_file_name = 'commands';
my $config_file_name = 'config';
my @commands;
my @configs;
my @command_array;
my %config;
my $farm_output="farm_output.txt";
my $logfile="log.txt";

# wait to scheduled time
sub wait_till_scheduled_time {
	# set timezone
	$ENV{TZ} = $config{"TIMEZONE"};
	tzset();
	# convert scheduled time to epoch seconds
	my $due = timelocal($config{"SEC"}, $config{"MIN"}, $config{"HOUR"}, $config{"DAY"}, $config{"MONTH"}-1, $config{"YEAR"});
	my $now = time;
	if ($due < $now) {
		print_log("scheduled time has already passed! exit.");
		exit();
	} else {
		sleep $due-$now;
		run_commands();
	}
}

sub replace_label {
    foreach my $cmd (@command_array){
		my $new = get_local_label()." ";
		$cmd=~ s/IDM_MAIN_GENERIC_[0-9,\.]*\s/$new/g;
    }
}

sub periodically_check_label {
    while(1){
        if (new_label_generated()){
            print_log("new label generated!");
			replace_label();
			#run_commands_test();
			run_commands();
            sleep $config{"PERIOD"};
        } else {
            sleep $config{"PERIOD"};
        }
    }
}

# read input
sub read_file_to_array {
	my $file = shift;
    open my $in, "<", $file or die "Can't open file \"$file\": $!";
    my @res = <$in>;
    close $in or die "$in: $!";
    return @res;
}

# generate commands to be ran from input file
sub generate_commands {
	my $cmd = '';
    foreach my $line (@commands) {
        chomp $line;
	
		if (_is_ignorable($line)){
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
	my ($command, $child_pid, $log);

	if ( $#_ == 1  || $#_ == 0 ){
		$command = $_[0];
		$log = $_[1] if $#_ == 1 ;
		$child_pid = fork();
		if ( $child_pid == 0 ) {
     		if ( $#_ == 1 )
     		{
     		   open (STDOUT, ">>$log") || warn ("run_command_bg: Could not open $log for stdout.\n");
     		   open (STDERR, ">&STDOUT")   || warn ("run_command_bg: Can't dup stdout");
     		}
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

sub _is_ignorable {
	my $line = shift;
	# white line can be ignored.
	if ($line eq "") {
		return 1;
	# comment line can be ignored too.
	} elsif (substr($line, 0, 1) eq $SHARP){
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

sub get_local_label {
    my $last_label = "";
    if (-e $LABEL_LOCAL_CACHE) {
        open my $in, "<", $LABEL_LOCAL_CACHE or die "Can't open label_cache: $!";
        $last_label = <$in>;
        close $in;
        if ($last_label eq ""){
            $last_label = get_latest_label($SERIE);
            update_label_local_catch($last_label);
        }
    } else {
        $last_label = get_latest_label($SERIE);
        update_label_local_catch($last_label);
    }
    return $last_label;
}

sub update_label_local_catch {
    my $label = shift;
    open my $OUT, ">", $LABEL_LOCAL_CACHE or die "Can't open label_cache: $!";
    print $OUT $label;
    close $OUT;
}

sub get_latest_label {
    my @labels = `ade showlabels -series $SERIE`;
    my $latest = $labels[-1];
    chomp $latest;
    return $latest;
}

sub new_label_generated {
    my $last_label = get_local_label();
    my $latest_label = get_latest_label();
    if ($last_label eq $latest_label){
        return 0;
    } else {
        update_label_local_catch($latest_label);
        return 1;
    }
}

sub load_config {
    my $cmd = '';
    foreach my $line (@configs) {
        chomp $line;
        if (_is_ignorable($line)){
            next;
        }
		my @kv = split('=', $line);
		my $key = $kv[0];
		my $val = $kv[1];
    	$config{$key} = $val; 
    }	
}

sub run_commands {
	foreach my $cmd (@command_array){
		print_log($cmd);
		run_command_bg($cmd, $farm_output);
    }
}

sub run_commands_test {
	foreach my $cmd (@command_array){
		print $cmd."\n";
    }
}

sub print_log{
	my $msg = shift;
	my $now = localtime();
	open my $OUT, ">>", $logfile or die "Can't open label_cache: $!";
	print $OUT "================".$now."================\n\n";
	print $OUT $msg."\n\n";
	print $OUT "================================================\n\n";
    close $OUT;
}

sub main {
    @commands = read_file_to_array($commands_file_name);
    @configs = read_file_to_array($config_file_name);
    generate_commands();
    load_config();

	if ($config{"MODE"} == 1){
		periodically_check_label();	
	} elsif ($config{"MODE"} == 2) {
    	wait_till_scheduled_time();
	}
}

main();
