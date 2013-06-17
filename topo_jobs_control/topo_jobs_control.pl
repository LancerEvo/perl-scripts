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
#		0.3 Set timezone at the beginning so that the time in logs is correct.
#			Automatically reload commands if chaged.
#			Move some params to config files.

use strict;
use warnings;
use File::Copy;
use File::Basename;
use POSIX qw(tzset);
use Time::Local;
use threads;
use threads::shared;

# symbols
my $BACKSLASH = '\\';
my $SHARP = '#';

# variables definition
my $CONFIG_FILE_NAME='config';
my @commands;
my @configs;
my @command_array :shared;
my %config;
my $commands_last_modified_time=0;

sub set_timezone {
	$ENV{TZ} = $config{"TIMEZONE"};
	tzset();
}

# wait to scheduled time
sub wait_till_scheduled_time {
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
            sleep $config{"CHECK_NEW_LABEL_PERIOD"};
        } else {
            sleep $config{"CHECK_NEW_LABEL_PERIOD"};
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

sub get_file_modified_time {
    my $file = shift;
    return (stat($file))[9];
}

sub file_modified {
    my $file = shift;
    if ($commands_last_modified_time == 0){
        $commands_last_modified_time  = get_file_modified_time($file);
        return 0;
    } else {
        my $t = get_file_modified_time($file);
        if($t!=$commands_last_modified_time){
            return 1;
        } else {
            return 0;
        }
    }
}

sub auto_reload_commands {
    my $log = $_[0];
    my $child_pid = fork();
    if ( $child_pid == 0 ) {
        open (STDOUT, ">>$log") || warn ("auto_reload_commands: Could not open $log for stdout.\n");
        open (STDERR, ">&STDOUT")   || warn ("auto_reload_commands: Can't dup stdout");
        while(1){
            if(file_modified($config{'COMMANDS_FILE_NAME'})){
                {
                    lock(@command_array);
                    @commands = read_file_to_array($config{'COMMANDS_FILE_NAME'});
                    @command_array = ();
                    generate_commands();
                }
				my $now = localtime();
                print "== $now == commands have been reloaded automatically.\n";
                $commands_last_modified_time  = get_file_modified_time($config{'COMMANDS_FILE_NAME'});
            }
            sleep $config{'AUTO_RELOAD_COMMANDS_INTERVAL'};
        }
        # shall never execute the following statement, but if $command
        # does not exist, exec() will come to this point!!!
        exit 1;
    } else {
        return $child_pid;
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
    if (-e $config{'LABEL_LOCAL_CACHE'}) {
        open my $in, "<", $config{'LABEL_LOCAL_CACHE'} or die "Can't open label_cache: $!";
        $last_label = <$in>;
        close $in;
        if ($last_label eq ""){
            $last_label = get_latest_label($config{'SERIE'});
            update_label_local_catch($last_label);
        }
    } else {
        $last_label = get_latest_label($config{'SERIE'});
        update_label_local_catch($last_label);
    }
    return $last_label;
}

sub update_label_local_catch {
    my $label = shift;
    open my $OUT, ">", $config{'LABEL_LOCAL_CACHE'} or die "Can't open label_cache: $!";
    print $OUT $label;
    close $OUT;
}

sub get_latest_label {
    my @labels = `ade showlabels -series $config{'SERIE'}`;
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
		run_command_bg($cmd, $config{'FARM_OUTPUT'});
    }
}

sub run_commands_test {
	foreach my $cmd (@command_array){
		print_log($cmd);
    }
}

sub print_log{
	my $msg = shift;
	my $now = localtime();
	open my $OUT, ">>", $config{'MAIN_LOG'} or die "Can't open label_cache: $!";
	print $OUT "================".$now."================\n\n";
	print $OUT $msg."\n\n";
	print $OUT "================================================\n\n";
    close $OUT;
}

sub main {
    @configs = read_file_to_array($CONFIG_FILE_NAME);
    load_config();
	set_timezone();
    @commands = read_file_to_array($config{'COMMANDS_FILE_NAME'});
    generate_commands();
	auto_reload_commands($config{'AUTO_RELOAD_COMMANDS_LOG'});

	if ($config{"MODE"} == 1){
		periodically_check_label();	
	} elsif ($config{"MODE"} == 2) {
    	wait_till_scheduled_time();
	}
}

main();
