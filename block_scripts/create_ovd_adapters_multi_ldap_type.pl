#!/usr/local/bin/perl
#
#    NAME
#      create_ovd_adapters.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <This script is used to create user_oid adapter,changelog adapter and configure them for OVD-OID.>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    jiaozhu    12/21/11 - Creation of the file for the oim-oam-ovd-oid integration


use File::Copy;
use File::Basename;

#Usage import.txt export.txt runtime.txt

# use BEGIN block to add DTE.pm into @INC
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

######## Initialize Global Variables #################

# from import list, we shall get the following information
$HOSTNAME="%HOSTNAME%";
$INSTANCE_HOME="%INSTANCE_HOME%";
$LDAP_HOST="%LDAP_HOST%";
$LDAP_USER_NAME="%LDAP_USER_NAME%";
$LDAP_PASSWORD="%LDAP_PASSWORD%";
$TARGET_DN_FILTER="%TARGET_DN_FILTER%";
$ADAPTER_TYPE="%ADAPTER_TYPE%";
$OVD_COMPONENT_NAME="%OVD_COMPONENT_NAME%";
$LDAP_PORT="%LDAP_PORT%";
$USER_OID_ADAPTER_ROOT="%USER_OID_ADAPTER_ROOT%";
$BACKEND_LDAP_NAME_SPACE="%BACKEND_LDAP_NAME_SPACE%";
$CHANGE_LOG_ADAPTER_ROOT="%CHANGE_LOG_ADAPTER_ROOT%";
$configOVD="%configOVD%";
$OVD_LDAP_PORT="%OVD_LDAP_PORT%";
$OVD_LDAP_HOST="%OVD_LDAP_HOST%";
$OVD_LDAP_PASSWORD="%OVD_LDAP_PASSWORD%";
$ORACLE_HOME="%ORACLE_HOME%";
$MW_HOME="%MW_HOME%";
$JAVA_HOME="%JAVA_HOME%";
$LDAP1_DIRECTORY_TYPE="%LDAP1_DIRECTORY_TYPE%";
$LDAP1_LDAP_PASSWORD="%LDAP1_LDAP_PASSWORD%";
$LDAP1_LDAP_USER_NAME="%LDAP1_LDAP_USER_NAME%";
# from runtime, we shall get the following information
$WORKDIR=""; 
$AUTO_HOME="";
$AUTO_WORK="";
$ENVFILE="";

# from export, we shall export the following information
# if the variable is already in import list, comment it out
#$HOSTNAME  - same as import
$EXIT_STATUS="FAILURE"; 

$tiastopo_tsc="";
$tiastopo_prp="";
$SHUTDOWN_SCRIPT="";

# the exit_value for this program
$exit_value=0;


################# Program Main Logic ################

############### Parse Import File  ###############
parse_import_file();


############### Parse Runtime File  ###############
parse_runtime_file();



############### set PLATFORM related info
set_platform_info();


############### set the default values for some variables if not already set###################
process_tokens();

############### Do Operation #########
if ($configOVD eq "true")
{
   	gen_input_file_config_OVD();
        runidmtoolConfigOVD();
#        validateCreateadpter();
        
}
else
{
	operation();
}
############### Populate Export file  ##############
populate_export_file();

exit $exit_value;

################# Program Subroutines ################
sub parse_import_file
{
  if ( open(IN, "$importfile") )
  {
    while(my $my_line = <IN>) 
    {
      chomp $my_line;
      $my_line =~ s/^\s+//;
      $my_line =~ s/\s+$//;

      my @tmp_token = split("=",$my_line);

      # need to handle if the value contains '=' itself
      my $token = $tmp_token[0] ;
      my $value = $my_line ;
      $value =~ s/$token\s*=\s*//g ;
      print "value=$value\n";

      if($token eq "HOSTNAME" ) {
        $HOSTNAME = $value;
      }     
      elsif ($token eq "INSTANCE_HOME" ) {
        $INSTANCE_HOME = $value;
      }
      elsif ($token eq "LDAP_HOST" ) {
        $LDAP_HOST = $value;
      }
      elsif ($token eq "LDAP_USER_NAME" ) {
        $LDAP_USER_NAME = $value;
      }
      elsif ($token eq "LDAP_PASSWORD" ) {
        $LDAP_PASSWORD = $value;
      }
      elsif ($token eq "TARGET_DN_FILTER" ) {
        $TARGET_DN_FILTER = $value;
      }
      elsif ($token eq "ADAPTER_TYPE" ) {
        $ADAPTER_TYPE = $value;
      }
      elsif ($token eq "OVD_COMPONENT_NAME" ) {
        $OVD_COMPONENT_NAME = $value;
      }
      elsif ($token eq "LDAP_PORT" ) {
        $LDAP_PORT = $value;
        if($LDAP_PORT eq ""){
        $LDAP_PORT = 3060;
        }
      }
      elsif ($token eq "OVD_LDAP_PORT" ) {
        $OVD_LDAP_PORT = $value;
        if($OVD_LDAP_PORT eq ""){
        $OVD_LDAP_PORT = 8899;
        }
      }
      elsif ($token eq "configOVD" ) {
        $configOVD = $value;
      }
      elsif ($token eq "ORACLE_HOME" ) {
        $ORACLE_HOME = $value;
      }
      elsif ($token eq "MW_HOME" ) {
        $MW_HOME = $value;
      }
      elsif ($token eq "JAVA_HOME" ) {
        $JAVA_HOME = $value;
      }
      elsif ($token eq "OVD_LDAP_HOST" ) {
        $OVD_LDAP_HOST = $value;
      }
      elsif ($token eq "OVD_LDAP_PASSWORD" ) {
        $OVD_LDAP_PASSWORD = $value;
      }
      elsif ($token eq "LDAP1_LDAP_PASSWORD" ) {
        $LDAP1_LDAP_PASSWORD = $value;
      }
      elsif ($token eq "LDAP1_DIRECTORY_TYPE" ) {
        $LDAP1_DIRECTORY_TYPE = $value;
		if("%LDAP1_DIRECTORY_TYPE%" eq $LDAP1_DIRECTORY_TYPE){
			$LDAP1_DIRECTORY_TYPE = "OID";
		}
      }
      elsif ($token eq "LDAP1_LDAP_USER_NAME" ) {
        $LDAP1_LDAP_USER_NAME = $value;
      }
      elsif ($token eq "USER_OID_ADAPTER_ROOT" ) {
        $USER_OID_ADAPTER_ROOT = $value;
      }
      elsif ($token eq "BACKEND_LDAP_NAME_SPACE" ) {
        $BACKEND_LDAP_NAME_SPACE = $value;
      }  
      elsif ($token eq "CHANGE_LOG_ADAPTER_ROOT" ) {
        $CHANGE_LOG_ADAPTER_ROOT = $value;
      }
      else {
        # any param in the import file, create a variable & assign the value
        print "New variable is defined: \$$token = $value\n";
        ${$token} = $value;
      }
    }
    close (IN);
  }
  else
  {
    print "ERROR: failed to open $importfile\n";
    $exit_value = 1;
  }
}

sub parse_runtime_file
{
  if ( open(IN, "$runtimefile") )
  {
    while(my $my_line = <IN>) 
    {
      chomp $my_line;
      $my_line =~ s/^\s+//;
      $my_line =~ s/\s+$//;

      my @tmp_token = split("=",$my_line);
      if($tmp_token[0] eq "WORKDIR" ) {
        $WORKDIR = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "AUTO_HOME" ) {
        $AUTO_HOME = $tmp_token[1];
      } 
      elsif ($tmp_token[0] eq "AUTO_WORK" ) {
        $AUTO_WORK = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "TASK_ID" ) {
        $TASK_ID = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "ENVFILE" ) {
        $ENVFILE = $tmp_token[1];
      }
      else {
	; # ignored
      }
    }
    close (IN);
  }
  else
  {
    print "ERROR: failed to open $runtimefile\n";
    $exit_value = 1;
  }
}

sub set_platform_info
{
  $PLATFORM = DTE::getOS();

  if ( $PLATFORM eq 'nt' ) {
    $DIRSEP = '\\';
    $PATHSEP =';';
    $UNZIP = "\"C:\\Program Files\\WinZip\\wzunzip.exe\" -yb -o";
  }
  else {
    $DIRSEP = '/' ;
    $PATHSEP = ':';
    $UNZIP = 'unzip -o';
  }
  if ( $PLATFORM eq 'linux' ) {
    $UNZIP = '/usr/bin/unzip -o';
  }
  if ( $PLATFORM eq 'aix' ) {
    $UNZIP = '/usr/local/bin/unzip -o';
  }
}

sub process_tokens
{
  if ( $USER_OID_ADAPTER_ROOT eq "%USER_OID_ADAPTER_ROOT%" || $USER_OID_ADAPTER_ROOT eq "" ) {
	$USER_OID_ADAPTER_ROOT = "dc=us,dc=oracle,dc=com";
  }

  if ( $BACKEND_LDAP_NAME_SPACE eq "%BACKEND_LDAP_NAME_SPACE%" || $BACKEND_LDAP_NAME_SPACE eq "" ) {
	$BACKEND_LDAP_NAME_SPACE = "dc=us,dc=oracle,dc=com";
  }

  if ( $CHANGE_LOG_ADAPTER_ROOT eq "%CHANGE_LOG_ADAPTER_ROOT%" || $CHANGE_LOG_ADAPTER_ROOT eq "" ) {
	$CHANGE_LOG_ADAPTER_ROOT = "cn=changelog";
  } 
}

sub printMessage
{
    print @_;
}

sub runSystem
{
    printMessage ("SYSTEM COMMAND = ");
    printMessage (@_);
    printMessage ("\n");
    my @output = `@_`;
   
    foreach my $line (@output) {
      printMessage ($line);
      chomp($line);
      if ( $line =~ /starting opmn managed processes/ and $line !~ /The request parameters did not match any components/) {
        $EXIT_STATUS="SUCCESS";
      }
    }
}

sub populate_export_file
{
  if ( ! open (EXPFILE, ">$exportfile") ) 
  {
    print "ERROR: failed to write to $exportfile\n"; 
    $exit_value = 1;
  }
  else 
  {   
    print EXPFILE "HOSTNAME=$HOSTNAME\n";
    print EXPFILE "EXIT_STATUS=$EXIT_STATUS\n";
    print EXPFILE "BLOCK_ID=$TASK_ID\n";
    print EXPFILE "configOVDFile=$input_file_config_OVD\n";
    close (EXPFILE);
  }
}

sub gen_input_file_config_OVD
{
                chdir("${WORKDIR}${DIRSEP}");
                printMessage ("Now the current dir is " . getcwd() . "\n");

                $input_file_config_OVD = "${WORKDIR}${DIRSEP}configOVD.props";

                if ( ! open(OFILE, "> $input_file_config_OVD" ) )
                {
                        print "\nCannot write to output file: $input_file_config_OVD\n";
                        $exit_value = 1;
                }
                print OFILE "ovd.host: $OVD_LDAP_HOST\n";
                print OFILE "ovd.port: $OVD_LDAP_PORT\n";
                print OFILE "ovd.binddn: $LDAP_USER_NAME\n";
                print OFILE "ovd.password: $OVD_LDAP_PASSWORD\n";
                print OFILE "ovd.ssl: true\n";
                print OFILE "ldap1.type: $LDAP1_DIRECTORY_TYPE\n";
                print OFILE "ldap1.host: $LDAP_HOST\n";
                print OFILE "ldap1.port: $LDAP_PORT\n";
                print OFILE "ldap1.binddn: $LDAP1_LDAP_USER_NAME\n";
                print OFILE "ldap1.password: $LDAP1_LDAP_PASSWORD\n";
                print OFILE "ldap1.ssl: false\n";
                print OFILE "ldap1.base: dc=us,dc=oracle,dc=com\n";
                print OFILE "ldap1.ovd.base: dc=us,dc=oracle,dc=com\n";
                print OFILE "usecase.type: single\n";
                print OFILE "\n";
                close(OFILE);
                return $input_file_config_OVD;
}

sub validateCreateadpter
 
{
         
	$DEST_FILE = "${INSTANCE_HOME}${DIRSEP}config${DIRSEP}OVD${DIRSEP}${OVD_COMPONENT_NAME}${DIRSEP}adapters.os_xml";
        print $DEST_FILE;
        if ( open(IN, "$DEST_FILE") )
  {
    while(my $my_line = <IN>)
    {
      chomp $my_line;
      if ($my_line =~ m/.*CHANGELOG_OID.*/ || $my_line =~ m/.*USER_OID.*/) {
             print "88888888888888888888888888888888888888888888888888888888888888888888888888888888888888\n";      
      }
      else {
        ; # ignored
      }
    }
    close (IN);
  } 
  else
  {
    print "ERROR: failed to open $runtimefile\n";
    $exit_value = 1;
  } 	

}

sub runSystem
{
    $myregexp = qr/.*Failed.*|.*FAILED.*|.*fail.*|.*Error.*|.*error.*|.*ERROR.*|.*exception.*|.*Exception.*/;
    printMessage ("SYSTEM COMMAND = ");
    printMessage (@_);
    printMessage ("\n");
    my @output = `@_`;
    $lindexoutput = @output;
    if ($lindexoutput == 0){
        $EXIT_STATUS="SUCCESS";
    }   
    foreach my $line (@output) {
      printMessage ($line);
      chomp($line);
      if ($line =~ m/$myregexp/ ) {
        $EXIT_STATUS="FAILURE"; 
      }else{
        $EXIT_STATUS="SUCCESS";
      }

    }
    print "============== $EXIT_STATUS ========================="
}

sub runidmtoolConfigOVD
{
	       $ENV{'ORACLE_HOME'} = $ORACLE_HOME;
               $ENV{'MW_HOME'} = $MW_HOME;
               $ENV{'JAVA_HOME'} = $JAVA_HOME;                
               runSystem("${ORACLE_HOME}${DIRSEP}idmtools${DIRSEP}bin${DIRSEP}idmConfigTool.sh -configOVD input_file=$input_file_config_OVD log_level=ALL log_file=configOVD1.out dump_params=true");
               my $cmd_stop = "${INSTANCE_HOME}${DIRSEP}bin${DIRSEP}opmnctl stopproc ias-component=${OVD_COMPONENT_NAME}";
               my $cmd_start = "${INSTANCE_HOME}${DIRSEP}bin${DIRSEP}opmnctl startproc ias-component=${OVD_COMPONENT_NAME}";
               print ("\nRestart OVD Server:\n");
               runSystem($cmd_stop);
               sleep (10);
               runSystem($cmd_start);
               sleep (10);
               print ("\n");  

}
sub operation
{
  ## Copy appropriate Template Adatper file to WORK Directory and 
  ##      replace place holders with corresponding values.
 
  $DEST_FILE = "${INSTANCE_HOME}${DIRSEP}config${DIRSEP}OVD${DIRSEP}${OVD_COMPONENT_NAME}${DIRSEP}adapters.os_xml";
  $targetAdpFile = "${WORKDIR}${DIRSEP}adapters.os_xml";
  $templateAdpFile = ${scriptDir} . "${DIRSEP}ovd_adap_template${DIRSEP}adapters_ldap.os_xml";
  
  my %tokentable;

  $tokentable{'%LDAP_HOST%'}=$LDAP_HOST;
  $tokentable{'%LDAP_USER_NAME%'}=$LDAP_USER_NAME;
  $tokentable{'%LDAP_PASSWORD%'}=$LDAP_PASSWORD;
  $tokentable{'%LDAP_PORT%'}=$LDAP_PORT;
  $tokentable{'%USER_OID_ADAPTER_ROOT%'}=$USER_OID_ADAPTER_ROOT;
  $tokentable{'%BACKEND_LDAP_NAME_SPACE%'}=$BACKEND_LDAP_NAME_SPACE;
  $tokentable{'%CHANGE_LOG_ADAPTER_ROOT%'}=$CHANGE_LOG_ADAPTER_ROOT;
  $tokentable{'%TARGET_DN_FILTER%'}=$TARGET_DN_FILTER;
  
  DTE::replace_token_in_file($templateAdpFile,$targetAdpFile,%tokentable);

  ## Copy modified adapter file to OVD's Instance Home
  print "\nDestination Instance Home to copy: $DEST_FILE\n";
  print "*********************************** $targetAdpFile\n";
  copy ($targetAdpFile,$DEST_FILE) or print "\nAdapter file cannot be copied to Destination Instance Home: $!" ;

  ## Restart OVD Server at the end
  my $cmd_stop = "${INSTANCE_HOME}${DIRSEP}bin${DIRSEP}opmnctl stopproc ias-component=${OVD_COMPONENT_NAME}";
  my $cmd_start = "${INSTANCE_HOME}${DIRSEP}bin${DIRSEP}opmnctl startproc ias-component=${OVD_COMPONENT_NAME}";
  print ("\nRestart OVD Server:\n"); 
  runSystem($cmd_stop);
  sleep (10);
  runSystem($cmd_start);
  sleep (10);
  print ("\n");
}

