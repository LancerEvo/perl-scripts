#!/usr/local/bin/perl
use File::Copy;
use File::Basename;

BEGIN
{
  use File::Basename;
  use Cwd;

  $orignalDir = getcwd();

  $scriptDir = dirname($0);
  chdir($scriptDir);
  $scriptDir =  getcwd();

  $plibDir = "$scriptDir/../../../plib";
  chdir($plibDir);
  $plibDir = getcwd();

  # add $plibDir into INC
  unshift  (@INC,"$plibDir");

  chdir($orignalDir);
}

require DTE;

if ( $#ARGV < 2)
{
  print ("Usage: perl $0 import.txt export.txt runtime.txt\n");
  exit 1;
}

$importfile  = $ARGV[0];
$exportfile  = $ARGV[1];
$runtimefile = $ARGV[2];

%ImportParamTable = ();
%RuntimeParamTable = ();
%ExportParamTable = ();

$exit_value=0;

%RuntimeParamTable=DTE::parse_runtime_file($runtimefile);
%ImportParamTable = DTE::parse_import_file($importfile, %RuntimeParamTable);

$ExportParamTable{HOSTNAME} = $ImportParamTable{HOSTNAME};
$ExportParamTable{EXIT_STATUS}="SUCCESS";

operation();

DTE::populate_export_file($exportfile, %ExportParamTable);

exit $exit_value;

sub operation
{
    my $content =  $ImportParamTable{CONTENT};
    if ( $content eq '' || $content eq '%CONTENT%' ) {
      $content = "Hello World!";
    }
 
    my $filename = $RuntimeParamTable{WORKDIR} . "/" . "HelloWorld.txt";
    if ( ! open(FILE,">$filename") ) {
      print "ERROR: Unable to write to $filename!\n";
      $ExportParamTable{EXIT_STATUS}="FAILURE";
      $exit_value = 1;
    }
    print FILE "$content\n";
    close(FILE);
    $ExportParamTable{EXIT_STATUS}="SUCCESS";

    $ExportParamTable{FILE} = $filename;

    $exit_value = 0;
}
