use warnings;
use File::Copy;
use File::Basename;
use POSIX qw(tzset);
use Time::Local;

my $now = localtime();
print $now."\n";
