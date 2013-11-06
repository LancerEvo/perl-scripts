#!/usr/bin/perl
use strict;
use warnings;

my $jobid = shift;
if ($jobid !~ /[0-9]/) {
	print "job id must be integer!\n";
	exit -1;
} 

my @res = `/ade_autofs/ade_infra/AIME_MAIN_LINUX.rdd/LATEST/dte/DTE3/bin/getJobInfo -t $jobid | grep -E "Machine|ADE View"`;

$res[0] =~ m/([a-z0-9]*\.us\.oracle\.com)/;
my $host = $1;

$res[1] =~ m/ade\/(.*)_.*/;
my $user = $1;

my $pwd;
if ($user eq "aime1"){
	$pwd = "coolkid1";
} elsif ($user eq "aime"){
	$pwd = "2cool";
}

if ( ! open (FILE, ">/scratch/tiguo/github/shell-scripts/login.sh") ){
    print "ERROR: failed to write to login.sh\n";
} else {
	print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn ssh $user\@$host\n";
    print FILE "expect {\n";
    print FILE "\"(yes/no)?\" {\n";
    print FILE "send \"yes\r\"\n";
    print FILE "expect \"password:\" { send \"$pwd\r\" }\n";
    print FILE "}\n";
    print FILE "\"password:\" { send \"$pwd\r\" }\n";
    print FILE "}\n";
    print FILE "interact\n";
	`chmod 755 /scratch/tiguo/github/shell-scripts/login.sh`
}
close FILE;
