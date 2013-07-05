#!/usr/local/bin/perl
# 
# $Header: dte/DTE/scripts/as11_idm/11.1.1.6.0/prepare.pl /main/11 2012/09/24 20:17:41 wazheng Exp $
#
# prepare.pl
# 
# Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
#      prepare.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    jiaozhu    09/02/12 - Creation of the file for the idmConfigTool test
#    Lancer.Guo 07/04/13 - change input of DISABLEOVDACCESSCONFIG and ovdConfigUpgrade
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
$HOSTNAME="%HOST%";
$ORACLE_HOME="%ORACLE_HOME%";
$MW_HOME="%MW_HOME%";
$IAM_DOMAIN_HOME="%IAM_DOMAIN_HOME%";
$WLS_PWD="%WLS_PWD%";
$JAVA_HOME="%JAVA_HOME%";
$OIM_MDS="%OIM_MDS%";
$OIDHOST="%OIDHOST%";
$OID_PORT="OID_PORT";
$IDM_ORACLE_HOME="%IDM_ORACLE_HOME%";
$IDM_DOMAIN_HOME="%IDM_DOMAIN_HOME%";
$WLS_USER="%WLS_USER%";
$WLS_ADMIN_PORT="%WLS_ADMIN_PORT%";
$IDM_DOMAIN_NAME="%IDM_DOMAIN_NAME%";
$COMMON_ORACLE_HOME="%COMMON_ORACLE_HOME%";
$OAM_only_inputfile="%OAM_only_inputfile%";
$UPDATASSOFILE="%UPDATASSOFILE%";
$CONFIGOIMFILE="%CONFIGOIMFILE%";
$OVD_input="%OVD_input%";
$Script_Validate_OAMIDstore="%Script_Validate_OAMIDstore%";
$Script_ValidateWebGateAgent="%Script_ValidateWebGateAgent%";
$OVD_NAME="%OVD_NAME%";
$OVD_PORT="%OVD_PORT%";
$OVD_ADMIN_PORT="%OVD_ADMIN_PORT%";
$OVD_HOSTNAME="OVD_HOSTNAME";
$OVD_INSTANCEHOME="%OVD_INSTANCEHOME%";
$OHS_PORT="%OHS_PORT%";
$OIM_HOST="%OIM_HOST%";
$OIM_PORT="%OIM_PORT%";
# from runtime, we shall get the following information
$WORKDIR=""; 
$AUTO_HOME="";
$AUTO_WORK="";
$ENVFILE="";

# from export, we shall export the following information
# if the variable is already in import list, comment it out
$EXIT_STATUS="FAILURE"; 

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

############### generate input files #########
generate_inputFile_configPolicyStore();
generate_inputFile_preConfigIDStore();
generate_inputFile_prepareIDStore_fusion();
generate_inputFile_prepareIDStore_oam();
generate_inputFile_prepareIDStore_oim();
generate_inputFile_prepareIDStore_wls();
generate_inputFile_prepareIDStore_all();
generate_inputFile_postProvConfig();
############## generate password file #########
generate_idm_config_password();
generate_inputFile_disableOVDAccessConfig();
generate_inputFile_ovdConfigUpgrade();
generate_inputFile_validateOAM11g();
generate_inputFile_validateIDSTORE();
generate_inputFile_validateOIM11g();
generate_inputFile_validatePOLICYStore();
############# generate python script to reassociate security store #########
generate_python_script_ReassociateSecurityStore();

############## generate properties file #########
GenScript_CHECKPROVIDERWLST();
GenScript_CHECKPARAMOFOVDPROVIDER();
generate_config_properties();


############### Populate Export file  ##############
populate_export_file();

exit $exit_value;
 
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
      elsif ($token eq "ORACLE_HOME" ) {
        $ORACLE_HOME = $value;
      }
      elsif ($token eq "MW_HOME" ) {
        $MW_HOME = $value;
      }
      elsif ($token eq "IAM_DOMAIN_HOME" ) {
        $IAM_DOMAIN_HOME = $value;
      }
      elsif ($token eq "JAVA_HOME" ) {
        $JAVA_HOME = $value;
      }
      elsif ($token eq "OIM_MDS" ) {
        $OIM_MDS = $value;
      }
      elsif ($token eq "WLS_PWD" ) {
        $WLS_PWD = $value;
      }
      elsif ($token eq "OIDHOST" ) {
        $OIDHOST = $value;
      }
      elsif ($token eq "OID_PORT" ) {
        $OID_PORT = $value;
      }
      elsif ($token eq "OHS_PORT" ) {
        $OHS_PORT = $value;
      }
      elsif ($token eq "OIM_HOST" ) {
        $OIM_HOST = $value;
      }
      elsif ($token eq "OIM_PORT" ) {
        $OIM_PORT = $value;
      }
      elsif ($token eq "OVD_NAME" ) {
        $OVD_NAME = $value;
      }	
      elsif ($token eq "OVD_PORT" ) {
        $OVD_PORT = $value;
        if($OVD_PORT eq ""){
           $OVD_PORT = 6501;
        }
      }
      elsif ($token eq "OVD_ADMIN_PORT" ) {
        $OVD_ADMIN_PORT = $value;
        if($OVD_ADMIN_PORT eq ""){
           $OVD_ADMIN_PORT = 8899;
        }
      }
      elsif ($token eq "OVD_HOSTNAME" ) {
        $OVD_HOSTNAME = $value;
      }
      elsif ($token eq "OVD_INSTANCEHOME" ) {
        $OVD_INSTANCEHOME = $value;
      }
      elsif ($token eq "IDM_ORACLE_HOME" ) {
        $IDM_ORACLE_HOME = $value;
      }
      elsif ($token eq "IDM_DOMAIN_HOME" ) {
        $IDM_DOMAIN_HOME = $value;
      }
      elsif ($token eq "WLS_USER" ) {
        $WLS_USER = $value;
      }
      elsif ($token eq "WLS_ADMIN_PORT" ) {
        $WLS_ADMIN_PORT = $value;
      }   
      elsif ($token eq "IDM_DOMAIN_NAME" ) {
        $IDM_DOMAIN_NAME = $value;
      }
      elsif ($token eq "COMMON_ORACLE_HOME" ) {
        $COMMON_ORACLE_HOME = $value;
      }
      elsif ($token eq "OAM_only_inputfile" ) {
        $OAM_only_inputfile = $value;
      }
      elsif ($token eq "UPDATASSOFILE" ) {
        $UPDATASSOFILE = $value;
      }	
      elsif ($token eq "CONFIGOIMFILE" ) {
        $CONFIGOIMFILE = $value;
      }
      elsif ($token eq "OVD_input" ) {
        $OVD_input = $value;
      }
      elsif ($token eq "Script_Validate_OAMIDstore" ) {
        $Script_Validate_OAMIDstore = $value;
      }
      elsif ($token eq "Script_ValidateWebGateAgent" ) {
        $Script_ValidateWebGateAgent = $value;
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

sub process_tokens
{
  if ( $JAVA_HOME eq "%JAVA_HOME%" || $JAVA_HOME eq "" ) {
	$JAVA_HOME = "/net/adcnas418/export/farm_fmwqa/java/linux64/jdk6";
  }

  if ( $WLS_USER eq "%WLS_USER%" || $WLS_USER eq "" ) {
	$WLS_USER = "weblogic";
  }

  if ( $WLS_PWD eq "%WLS_PWD%" || $WLS_PWD eq "" ) {
	$WLS_PWD = "welcome1";
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
    print EXPFILE "TESTDATA_FOLDER=$WORKDIR\n";
    print EXPFILE "ConfigPropertiesFile=$config_properties\n";
    print EXPFILE "reassociateSecurityStorePY=$reassociateSecurityStore_py\n";
    print EXPFILE "PWDFile=$idm_config_pwd\n";
    print EXPFILE "InputFile_configPolicyStore=$InputFile_configPolicyStore\n";
    print EXPFILE "InputFile_preConfigIDStore=$InputFile_preConfigIDStore\n";
    print EXPFILE "InputFile_prepareIDStore_fusion=$InputFile_prepareIDStore_fusion\n";
    print EXPFILE "InputFile_prepareIDStore_OAM=$InputFile_prepareIDStore_OAM\n";
    print EXPFILE "InputFile_prepareIDStore_OIM=$InputFile_prepareIDStore_OIM\n";
    print EXPFILE "InputFile_prepareIDStore_WLS=$InputFile_prepareIDStore_WLS\n";
    print EXPFILE "outputfile_configPolicyStore=configPolicyStore.auto.out\n";
    print EXPFILE "outputfile_preConfigIDStore=preConfigIDStore.auto.out\n";
	print EXPFILE "outputfile_prepareIDStore_oam=prepareIDStore.oam.auto.out\n";
	print EXPFILE "outputfile_prepareIDStore_oim=prepareIDStore.oim.auto.out\n";
	print EXPFILE "outputfile_prepareIDStore_wls=prepareIDStore.wls.auto.out\n";
	print EXPFILE "outputfile_prepareIDStore_fusion=prepareIDStore.fusion.auto.out\n";
    close (EXPFILE);
  }
}

sub set_platform_info
{
  $PLATFORM = DTE::getOS();

  if ( $PLATFORM eq 'nt' ) {
  	$LDAP_CMD = "LDAPConfigPreSetup.bat";
  	$IDM_CMD = "idmConfigTool.bat";
  	$COPY_CMD = "COPY";
  	$MOVE_CMD = "MOVE";
    $DIRSEP = '\\';
    $PATHSEP =';';
    $UNZIP = "\"C:\\Program Files\\WinZip\\wzunzip.exe\" -yb -o";
  }
  else {
  	$LDAP_CMD = "LDAPConfigPreSetup.sh";
  	$IDM_CMD = "idmConfigTool.sh";
  	$COPY_CMD = "cp";
  	$MOVE_CMD = "mv";
    $DIRSEP = '/' ;
    $PATHSEP = ':';
    $UNZIP = '/usr/bin/unzip -o';
  }
}


sub generate_inputFile_preConfigIDStore
{
  $InputFile_preConfigIDStore = "${WORKDIR}${DIRSEP}preConfigIDStore.conf";
  if ( ! open (FILE, ">$InputFile_preConfigIDStore") )
  {
    print "ERROR: failed to write to $InputFile_preConfigIDStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
    close (FILE);
  }
}

sub generate_inputFile_prepareIDStore_fusion
{
  $InputFile_prepareIDStore_fusion = "${WORKDIR}${DIRSEP}prepareIDStore.fusion.conf";

  if ( ! open (FILE, ">$InputFile_prepareIDStore_fusion") )
  {
    print "ERROR: failed to write to $InputFile_prepareIDStore_fusion\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_READONLYUSER: IDROUser\n";
    print FILE "IDSTORE_READWRITEUSER: IDRWUser\n";
    print FILE "IDSTORE_SUPERUSER: weblogic_fa\n";
    close (FILE);
  }
}


sub gen_input_file_config_oam_4oim
{
                chdir("${WORKDIR}${DIRSEP}");
                printMessage ("Now the current dir is " . getcwd() . "\n");

                $input_file_config_oam_4oim = "${WORKDIR}${DIRSEP}configOAM.config";

                if ( ! open(OFILE, "> $input_file_config_oam_4oim" ) )
                {
                        print "\nCannot write to output file: $input_file_config_oam_4oim\n";
                        $exit_value = 1;
                }
                print OFILE "###configOAM\n";
                        print OFILE "WLSHOST: $HOSTNAME\n";
                        print OFILE "WLSPORT: $WLS_ADMIN_PORT\n";
                        print OFILE "WLSADMIN: $WLS_USER\n";
                        print OFILE "WLSPASSWD: $WLS_PWD\n";
                        print OFILE "IDSTORE_HOST: $IDSTORE_HOST\n";
                        print OFILE "IDSTORE_PORT: $IDSTORE_PORT\n";
                        print OFILE "IDSTORE_DIRECTORYTYPE: $IDSTORE_DIRECTORYTYPE\n";
                        print OFILE "IDSTORE_BINDDN: $IDSTORE_BINDDN\n";
                        print OFILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
                        print OFILE "IDSTORE_LOGINATTRIBUTE: uid\n";
                        print OFILE "IDSTORE_USERSEARCHBASE: $IDSTORE_USERSEARCHBASE\n";
                        print OFILE "IDSTORE_SEARCHBASE: $IDSTORE_SEARCHBASE\n";
                        print OFILE "IDSTORE_GROUPSEARCHBASE: $IDSTORE_GROUPSEARCHBASE\n";
                        print OFILE "IDSTORE_OAMSOFTWAREUSER: oamSoftwareUser\n";
                        print OFILE "IDSTORE_OAMADMINUSER: oamAdminUser\n";
                        print OFILE "PRIMARY_OAM_SERVERS: ${OAM_HOSTNAME}:${ACCESS_PORT}\n";
                        print OFILE "WEBGATE_TYPE: ohsWebgate10g\n";
                        print OFILE "ACCESS_GATE_ID: $ACCESS_GATE_ID\n";
                        print OFILE "OAM11G_WG_DENY_ON_NOT_PROTECTED: false\n";
                        print OFILE "OAM11G_IDM_DOMAIN_OHS_HOST: $OHS_HOSTNAME\n";
                        print OFILE "OAM11G_IDM_DOMAIN_OHS_PORT: $OHS_PORT\n";
                        print OFILE "OAM11G_IDM_DOMAIN_OHS_PROTOCOL: http\n";
                        print OFILE "OAM_TRANSFER_MODE: OPEN\n";
                        print OFILE "OAM11G_OAM_SERVER_TRANSFER_MODE: OPEN\n";
                        print OFILE "OAM11G_IDM_DOMIN_LOGOUT_URLS: /console/jsp/common/logout.jsp,/em/targetauth/emaslogout.jsp,/oamsso/logout.html,/cgi-bin/logout.pl\n";
                        print OFILE "OAM11G_OIM_WEBGATE_PASSWD: $OAM11G_OIM_WEBGATE_PASSWD\n";
                        print OFILE "OAM11G_SERVER_LOGIN_ATTRIBUTE: uid\n";
                        print OFILE "COOKIE_DOMAIN: $COOKIE_DOMAIN\n";
                        print OFILE "OAM11G_IDSTORE_ROLE_SECURITY_ADMIN: OAMAdministrators\n";
                        print OFILE "OAM11G_SSO_ONLY_FLAG: true\n";
                        print OFILE "OAM11G_OIM_INTEGRATION_REQ: false\n";
                        print OFILE "OAM11G_IMPERSONATION_FLAG: true\n";
                        print OFILE "OAM11G_SERVER_LBR_HOST:$OAM11G_SERVER_LBR_HOST\n";
                        print OFILE "OAM11G_SERVER_LBR_PORT:$OAM11G_SERVER_LBR_PORT\n";
                        print OFILE "OAM11G_SERVER_LBR_PROTOCOL:http\n";
                        print OFILE "COOKIE_EXPIRY_INTERVAL: 120\n";
                        print OFILE "OAM11G_OIM_OHS_URL: http://${OHS_HOSTNAME}:${OHS_PORT}/\n";
                        print OFILE "ADMIN_SERVER_USER_PASSWORD: $WLS_PWD\n";
                        print OFILE "COOKIE_EXPIRY_INTERVAL: 3600\n";
                        print OFILE "OAM11G_IDSTORE_NAME: OAMIDStore\n";
                print OFILE "\n";
                close(OFILE);
                return $input_file_config_oam_4oim;
}


sub generate_inputFile_prepareIDStore_all
{
  $InputFile_prepareIDStore_ALL = "${WORKDIR}${DIRSEP}prepareIDStore.all.conf";
  if ( ! open (FILE, ">$InputFile_prepareIDStore_ALL") )
  {
    print "ERROR: failed to write to $InputFile_prepareIDStore_ALL\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "OAM11G_IDSTORE_ROLE_SECURITY_ADMIN:OAMAdministrators\n";
    print FILE "IDSTORE_OAMSOFTWAREUSER:oamSoftwareUser\n";
    print FILE "IDSTORE_OAMADMINUSER:oamAdminUser\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_READONLYUSER: IDROUser\n";
    print FILE "IDSTORE_READWRITEUSER: IDRWUser\n";
    print FILE "IDSTORE_SUPERUSER: weblogic_fa\n";
    print FILE "IDSTORE_OIMADMINUSER: oimadminuser\n";
    print FILE "IDSTORE_OIMADMINGROUP: OIMAdministrators\n";
    print FILE "IDSTORE_WLSADMINUSER: weblogic_idm\n";
    print FILE "IDSTORE_WLSADMINGROUP: wlsadmingroup\n";
    print FILE "IDSTORE_OAAMADMINUSER: oaamAdminUser\n";
    close (FILE);
  }
}



sub generate_inputFile_postProvConfig
{
  $InputFile_postProvConfig = "${WORKDIR}${DIRSEP}postProvConfig.conf";
  if ( ! open (FILE, ">$InputFile_postProvConfig") )
  {
    print "ERROR: failed to write to $InputFile_postProvConfig\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_HOST : $OIDHOST\n";
    print FILE "POLICYSTORE_PORT : $OID_PORT\n";
    print FILE "POLICYSTORE_BINDDN: cn=orcladmin\n";
    print FILE "POLICYSTORE_READWRITEUSER: PolicyRWUser\n";
    print FILE "OIM_T3_URL : t3://$OIM_HOST:$OIM_PORT\n";
    print FILE "POLICYSTORE_CONTAINER: cn=jpsroot\n";
    print FILE "OIM_SYSTEM_ADMIN : abcdef\n";
    print FILE "OVD_HOST : $OVD_HOSTNAME\n";
    print FILE "OVD_PORT : $OVD_PORT\n";
    print FILE "OVD_BINDDN : cn=orcladmin\n";
    close (FILE);
  }
}



sub generate_inputFile_prepareIDStore_oam
{
  $InputFile_prepareIDStore_OAM = "${WORKDIR}${DIRSEP}prepareIDStore.oam.conf";
  if ( ! open (FILE, ">$InputFile_prepareIDStore_OAM") )
  {
    print "ERROR: failed to write to $InputFile_prepareIDStore_OAM\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "OAM11G_IDSTORE_ROLE_SECURITY_ADMIN:OAMAdministrators\n";
    print FILE "IDSTORE_OAMSOFTWAREUSER:oamSoftwareUser\n";
    print FILE "IDSTORE_OAMADMINUSER:oamAdminUser\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
    close (FILE);
  }
}

sub generate_inputFile_prepareIDStore_oim
{
  $InputFile_prepareIDStore_OIM = "${WORKDIR}${DIRSEP}prepareIDStore.oim.conf";
  if ( ! open (FILE, ">$InputFile_prepareIDStore_OIM") )
  {
    print "ERROR: failed to write to $InputFile_prepareIDStore_OIM\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_OIMADMINUSER: oimadminuser\n";
    print FILE "IDSTORE_OIMADMINGROUP:OIMAdministrators\n";
    close (FILE);
  }
}

sub generate_inputFile_prepareIDStore_wls
{
  $InputFile_prepareIDStore_WLS = "${WORKDIR}${DIRSEP}prepareIDStore.wls.conf";
  if ( ! open (FILE, ">$InputFile_prepareIDStore_WLS") )
  {
    print "ERROR: failed to write to $InputFile_prepareIDStore_WLS\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OIDHOST\n";
    print FILE "IDSTORE_PORT : $OID_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "IDSTORE_WLSADMINUSER: weblogic_idm\n";
    print FILE "IDSTORE_WLSADMINGROUP: wlsadmingroup\n";
    close (FILE);
  }
}

sub generate_inputFile_configPolicyStore
{
  $InputFile_configPolicyStore = "${WORKDIR}${DIRSEP}configPolicyStore.conf";
  if ( ! open (FILE, ">$InputFile_configPolicyStore") )
  {
    print "ERROR: failed to write to $InputFile_configPolicyStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "POLICYSTORE_HOST : $OIDHOST\n";
    print FILE "POLICYSTORE_PORT : $OID_PORT\n";
    print FILE "POLICYSTORE_BINDDN: cn=orcladmin\n";
    print FILE "POLICYSTORE_READONLYUSER: PolicyROUser\n";
    print FILE "POLICYSTORE_READWRITEUSER: PolicyRWUser\n";
    print FILE "POLICYSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_CONTAINER: cn=jpsroot\n";
    close (FILE);
  }
}

sub generate_inputFile_disableOVDAccessConfig
{
  $InputFile_disableOVDAccessConfig = "${WORKDIR}${DIRSEP}disableOVDAccessConfig.conf";
  if ( ! open (FILE, ">$InputFile_disableOVDAccessConfig") )
  {
    print "ERROR: failed to write to $InputFile_disableOVDAccessConfig\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "ovd.host : $OVD_HOSTNAME\n";
    print FILE "ovd.port : $OVD_ADMIN_PORT\n";
    print FILE "ovd.binddn: cn=orcladmin\n";
    print FILE "ovd.ssl: true\n";
    print FILE "ovd.password: welcome1\n";
    close (FILE);
  }
}

sub generate_inputFile_ovdConfigUpgrade
{
  $InputFile_ovdConfigUpgrade = "${WORKDIR}${DIRSEP}ovdConfigUpgrade.conf";
  if ( ! open (FILE, ">$InputFile_ovdConfigUpgrade") )
  {
    print "ERROR: failed to write to $InputFile_ovdConfigUpgrade\n";
    $exit_value = 1;
  } 
  else
  {
    print FILE "ovd.host : $OVD_HOSTNAME\n";
    print FILE "ovd.port : $OVD_ADMIN_PORT\n";
    print FILE "ovd.binddn: cn=orcladmin\n";
    print FILE "ovd.ssl: true\n";
    print FILE "ovd.password: welcome1\n";
    close (FILE);
  }
}

sub generate_inputFile_validateOAM11g
{
  $InputFile_validateOAM11g = "${WORKDIR}${DIRSEP}validateOAM11g.conf";
  if ( ! open (FILE, ">$InputFile_validateOAM11g") )
  {
    print "ERROR: failed to write to $InputFile_validateOAM11g\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "admin_server_host:$HOSTNAME\n";
    print FILE "admin_server_port:$WLS_ADMIN_PORT\n";
    print FILE "admin_server_user:weblogic\n";
    print FILE "admin_server_user_password:welcome1\n";
    print FILE "IDSTORE_HOST:$OVD_HOSTNAME\n";
    print FILE "IDSTORE_PORT:$OVD_PORT\n";
    print FILE "IDSTORE_IS_SSL_ENABLED:false\n";
    print FILE "OAM11G_ACCESS_SERVER_HOST:$HOSTNAME\n";
    print FILE "OAM11G_ACCESS_SERVER_PORT:5575\n";
    print FILE "OAM11G_IDSTORE_ROLE_SECURITY_ADMIN:OAMAdministrators\n";
    print FILE "OAM11G_OIM_OHS_URL:http://$HOSTNAME:$OHS_PORT\n";
    print FILE "OAM11G_OIM_INTEGRATION_REQ:true\n";
    print FILE "OAM11G_OAM_ADMIN_USER:oamadminuser\n";
    print FILE "OAM11G_SSO_ONLY_FLAG:true\n";
    print FILE "OAM11G_OAM_ADMIN_USER_PASSWD:welcome1\n";
    close (FILE);
  }
}


sub generate_inputFile_validateIDSTORE
{
  $InputFile_validateIDSTORE = "${WORKDIR}${DIRSEP}validateIDSTORE.conf";
  if ( ! open (FILE, ">$InputFile_validateIDSTORE") )
  {
    print "ERROR: failed to write to $InputFile_validateIDSTORE\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "idstore.type: OID\n";
    print FILE "idstore.host:$OIDHOST\n";
    print FILE "idstore.port:$OID_PORT\n";
    print FILE "idstore.sslport: 3131\n";
    print FILE "idstore.ssl.enabled: false\n";
    print FILE "idstore.super.user: cn=weblogic_idm,cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.readwrite.username: cn=IDRWUser,cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.readonly.username: cn=IDROUser,cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.user.base: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.group.base: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.seeding: true\n";
    print FILE "idstore.post.validation: false\n";
    print FILE "idstore.admin.group: cn=OAMAdministrators,cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.admin.group.exists: true\n";
    print FILE "idstore.readonly.password: Welcome1\n";
    print FILE "idstore.readwrite.password: Welcome1\n";
    close (FILE);
  }
}

sub generate_inputFile_validateOIM11g
{
  $InputFile_validateOIM11g = "${WORKDIR}${DIRSEP}validateOIM11g.conf";
  if ( ! open (FILE, ">$InputFile_validateOIM11g") )
  {
    print "ERROR: failed to write to $InputFile_validateOIM11g\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "admin_server_host:$HOSTNAME\n";
    print FILE "admin_server_port:$WLS_ADMIN_PORT\n";
    print FILE "admin_server_user:weblogic\n";
    print FILE "admin_server_user_password:welcome1\n";
    print FILE "oam_host:$HOSTNAME\n";
    print FILE "oam_nap_port:5575\n";
    print FILE "idm.keystore.file: idm.keystore.file\n";
    print FILE "idm.keystore.password:welcome1\n";
    print FILE "idstore.user.base:cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "idstore.group.base:cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "oim_is_ssl_enabled:false\n";
    print FILE "OIM_HOST:$OIM_HOST\n";
    print FILE "OIM_PORT:$OIM_PORT\n";
    print FILE "OIM_T3_URL:t3://$OIM_HOST:$OIM_PORT\n";
    print FILE "OIM_FRONT_END_URL: http://$OIM_HOST:$OIM_PORT\n";
    close (FILE);

  }
}


sub generate_inputFile_validatePOLICYStore
{
  $InputFile_validatePOLICYStore = "${WORKDIR}${DIRSEP}validatePOLICYStore.conf";
  if ( ! open (FILE, ">$InputFile_validatePOLICYStore") )
  {
    print "ERROR: failed to write to $InputFile_validatePOLICYStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "POLICYSTORE_HOST:$OIDHOST\n";
    print FILE "POLICYSTORE_PORT:$OID_PORT\n";
    print FILE "POLICYSTORE_SECURE_PORT:3131\n";
    print FILE "POLICYSTORE_IS_SSL_ENABLED:FALSE\n";
    print FILE "POLICYSTORE_READ_WRITE_USERNAME:cn=PolicyRWUser,cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_PASSWORD:welcome1\n";
    print FILE "POLICYSTORE_SEEDING:true\n";
    print FILE "POLICYSTORE_JPS_ROOT_NODE:cn=jpsroot\n";
    print FILE "POLICYSTORE_DOMAIN_NAME:dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_JPS_CONFIG_DIR:\n";
    print FILE "POLICYSTORE_CRED_MAPPING_FILE_LOCATION:\n";
    print FILE "POLICYSTORE_ADF_CRED_FILE_LOCATION:\n";
    print FILE "POLICYSTORE_STRIPE_FSCM:\n";
    print FILE "POLICYSTORE_STRIPE_CRM:\n";
    print FILE "POLICYSTORE_STRIPE_HCM:\n";
    print FILE "POLICYSTORE_STRIPE_SOA_INFRA:\n";
    print FILE "POLICYSTORE_STRIPE_APM:\n";
    print FILE "POLICYSTORE_STRIPE_ESSAPP:\n";
    print FILE "POLICYSTORE_STRIPE_B2BUI:\n";
    print FILE "POLICYSTORE_STRIPE_OBI:\n";
    print FILE "POLICYSTORE_STRIPE_WEBCENTER:\n";
    print FILE "POLICYSTORE_STRIPE_IDCCS:\n";
    print FILE "POLICYSTORE_CRED_STORE:\n";
    close (FILE);

  }
}
sub generate_idm_config_password
{
  $idm_config_pwd = "${WORKDIR}${DIRSEP}idm_passwd.txt";

  if ( ! open(FILE, "> $idm_config_pwd" ) ) {
    print "\nCannot write to output file: $idm_config_pwd\n";
    $exit_value = 1;
  }
        print FILE "IDSTORE_PASSWD: welcome1\n";
        print FILE "IDSTORE_PWD_OIDSCHEMA: welcome1\n";
        print FILE "IDSTORE_PWD_READONLYUSER: welcome1\n";
        print FILE "IDSTORE_PWD_READWRITEUSER: welcome1\n";
        print FILE "IDSTORE_PWD_SUPERUSER: welcome1\n";
        print FILE "IDSTORE_PWD_OAMSOFTWAREUSER: welcome1\n";
        print FILE "IDSTORE_PWD_OAMADMINUSER: welcome1\n";
        print FILE "IDSTORE_PWD_OAMOBLIXUSER: welcome1\n";
        print FILE "IDSTORE_PWD_WLSADMINUSER: welcome1\n";
        print FILE "IDSTORE_PWD_OIMADMINUSER: Welcome1\n";
        print FILE "IDSTORE_PWD_XELSYSADMIN: Welcome1\n";
        print FILE "IDSTORE_PWD_OAAMADMINUSER: Welcome1\n";
        print FILE "IDSTORE_PWD_WLSADMINUSER: Welcome1\n";
        print FILE "OVD_PASSWD: welcome1\n";
        print FILE "OIM_SYSTEM_ADMIN_PWD: welcome1\n";
        print FILE "POLICYSTORE_PASSWD: welcome1\n";
        print FILE "POLICYSTORE_PWD_READWRITEUSER: welcome1\n";
        print FILE "POLICYSTORE_PWD_READONLYUSER: welcome1\n";
        print FILE "SSO_ACCESS_GATE_PASSWORD: Welcome1\n";
        print FILE "SSO_KEYSTORE_JKS_PASSWORD: Welcome1\n";
        print FILE "SSO_GLOBAL_PASSPHRASE: welcome1\n";
        print FILE "IDSTORE_ADMIN_PASSWD: welcome1\n";
        print FILE "MDS_DB_SCHEMA_PASSWORD: ${OIM_MDS}\n";
        print FILE "WLSPASSWD: ${WLS_PWD}\n";
        print FILE "OAM11G_IDM_DOMAIN_WEBGATE_PASSWD: welcome1\n";
        
        print FILE "\n";
        close(FILE);
}

sub generate_config_properties
{
	$PLATFORM = DTE::getOS();
	
  $config_properties = "${WORKDIR}${DIRSEP}config.properties";
  if ( ! open (FILE, ">$config_properties") )
  {
    print "ERROR: failed to write to $InputFile_preConfigIDStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "idmtools.os.name=$PLATFORM\n";
    print FILE "idmtools.idmCmd.linux=idmConfigTool.sh\n";
    print FILE "idmtools.idmCmd.nt=idmConfigTool.bat\n";
    print FILE "idmtools.failstring=failed|fail|error|exception\n";
    print FILE "idmtools.workdir=$WORKDIR\n";
    print FILE "idmtools.commonOracleHome=$COMMON_ORACLE_HOME\n";
    print FILE "idmtools.ovdName=$OVD_NAME\n";
    print FILE "idmtools.ovdInstanceHome=$OVD_INSTANCEHOME\n";
    print FILE "idmtools.ovdhost=$OVD_HOSTNAME\n";
    print FILE "idmtools.idm_domainhome=$IDM_DOMAIN_HOME\n";
    print FILE "idmtools.iam_domainhome=$IAM_DOMAIN_HOME\n";
    print FILE "########################inputfile name list################################################\n";
    print FILE "idmtools.inputfile.preConfigIDStore=${WORKDIR}${DIRSEP}preConfigIDStore.conf\n";
    print FILE "idmtools.inputfile.configPolicyStore=${WORKDIR}${DIRSEP}configPolicyStore.conf\n";
    print FILE "idmtools.inputfile.prepareIDStore.oam=${WORKDIR}${DIRSEP}prepareIDStore.oam.conf\n";
    print FILE "idmtools.inputfile.prepareIDStore.oim=${WORKDIR}${DIRSEP}prepareIDStore.oim.conf\n";
    print FILE "idmtools.inputfile.prepareIDStore.wls=${WORKDIR}${DIRSEP}prepareIDStore.wls.conf\n";
    print FILE "idmtools.inputfile.prepareIDStore.fusion=${WORKDIR}${DIRSEP}prepareIDStore.fusion.conf\n";
    print FILE "idmtools.inputfile.prepareIDStore.all=${WORKDIR}${DIRSEP}prepareIDStore.all.conf\n";
    print FILE "idmtools.inputfile.configOAMOnly=$OAM_only_inputfile\n";
    print FILE "idmtools.inputfile.OVD_input=$OVD_input\n";
    print FILE "idmtools.inputfile.UPDATASSOFILE=$UPDATASSOFILE\n";
    print FILE "idmtools.inputfile.CONFIGOIMFILE=$CONFIGOIMFILE\n";
    print FILE "idmtools.inputfile.disableOVDAccessConfig=$InputFile_disableOVDAccessConfig\n";
    print FILE "idmtools.inputfile.ovdConfigUpgrade=$InputFile_ovdConfigUpgrade\n";
    print FILE "idmtools.inputfile.postProConfig=$InputFile_postProvConfig\n";
    print FILE "idmtools.inputfile.validateOAM11g=$InputFile_validateOAM11g\n";
    print FILE "idmtools.inputfile.validateIDSTORE=$InputFile_validateIDSTORE\n";
    print FILE "idmtools.inputfile.validateOIM11g=$InputFile_validateOIM11g\n";
    print FILE "idmtools.inputfile.validatePOLICYStore=$InputFile_validatePOLICYStore\n";
    print FILE "########################output file name list##############################################\n";
    print FILE "idmtools.outputfile.preConfigIDStore=preConfigIDStore.auto.out\n";
    print FILE "idmtools.outputfile.configPolicyStore=configPolicyStore.auto.out\n";
    print FILE "idmtools.outputfile.prepareIDStore.oam=prepareIDStore.oam.auto.out\n";
    print FILE "idmtools.outputfile.prepareIDStore.oim=prepareIDStore.oim.auto.out\n";
    print FILE "idmtools.outputfile.prepareIDStore.wls=prepareIDStore.wls.auto.out\n";
    print FILE "idmtools.outputfile.prepareIDStore.fusion=prepareIDStore.fusion.auto.out\n";
    print FILE "########################pwd file name######################################################\n";
    print FILE "idmtools.pwdfile=${WORKDIR}${DIRSEP}idm_passwd.txt\n";
    print FILE "########################ldap server info########################\n";
    print FILE "idmtools.ldapUrl=ldap://${OIDHOST}:${OID_PORT}\n";
    print FILE "idmtools.ldap.username=cn=orcladmin\n";
    print FILE "idmtools.ldap.password=welcome1\n";
    print FILE "idmtools.ldap.base=dc=us,dc=oracle,dc=com\n";
    print FILE "########################environment variables which running idmConfigTool needs#############\n";       
    print FILE "idmtools.mwHome=$MW_HOME\n";
    print FILE "idmtools.oracleHome=$ORACLE_HOME\n";
    print FILE "idmtools.javaHome=$JAVA_HOME\n";
    print FILE "########################python script to reassociate security store#############\n";       
    print FILE "idmtools.pythonScript.reassociateSS=$reassociateSecurityStore_py\n";
    print FILE "idmtools.ValidateOAMIDStore=$Script_Validate_OAMIDstore\n";
    print FILE "idmtools.ValidateWebGateAgent=$Script_ValidateWebGateAgent\n";
    print FILE "idmtools.checkprovider=$Script_Checkprovider_WLST\n";
    print FILE "idmtools.checkParamofOVDprovider=$Script_checkParamofOVDprovider\n";
    print FILE "\n";
    close (FILE);
  }
  $EXIT_STATUS="SUCCESS"; 
}


sub GenScript_CHECKPROVIDERWLST
{
  $Script_Checkprovider_WLST = "${WORKDIR}${DIRSEP}Script_Checkprovider_WLST.cfg";

  if ( ! open (FILE, ">$Script_Checkprovider_WLST") )
  {
    print "ERROR: failed to write to $Script_Checkprovider_WLST \n";
    $exit_value = 1;
  }
  else
  {
  print FILE "#!/usr/bin/expect -f\n";
  print FILE "spawn ${ORACLE_HOME}/common/bin/wlst.sh\n";
  print FILE "set timeout -1\n";
  print FILE "expect {\n";
  print FILE "  -timeout -1\n";
  print FILE "  \"wls:/offline> \" { send \"connect (\\\"weblogic\\\", \\\"welcome1\\\", \\\"t3://$HOSTNAME:$WLS_ADMIN_PORT\\\")\r\"; exp_continue }\n";
  print FILE "  -re \".*serverConfig> \" { send \"cd('SecurityConfiguration/WLS_IDM/Realms/myrealm/AuthenticationProviders')\r\"; }\n";
  print FILE "}\n";
  
  print FILE "expect {\n";
  print FILE "  -re \".*serverConfig.* \" {send \"ls()\r\";}\n";
  print FILE "}\n";
  print FILE "expect {\n";
  print FILE "  -re \".*serverConfig.* \" {send \"exit()\r\"; exp_continue}\n";
  print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit !!! AssociateSecurityStoreWLST\"; return }\n";
  print FILE "}\n";
  print FILE "expect eof\n";
  close (FILE);
  `chmod 755 $Script_Checkprovider_WLST`;
  }
  return $Script_Checkprovider_WLST;
}

sub GenScript_CHECKPARAMOFOVDPROVIDER
{   
  $Script_checkParamofOVDprovider = "${WORKDIR}${DIRSEP}Script_checkParamofOVDprovider.cfg";
    
  if ( ! open (FILE, ">$Script_checkParamofOVDprovider") )
  { 
    print "ERROR: failed to write to $Script_checkParamofOVDprovider \n";
    $exit_value = 1;
  } 
  else
  { 
  print FILE "#!/usr/bin/expect -f\n";
  print FILE "spawn ${ORACLE_HOME}/common/bin/wlst.sh\n";
  print FILE "set timeout -1\n";
  print FILE "expect {\n";
  print FILE "  -timeout -1\n";
  print FILE "  \"wls:/offline> \" { send \"connect (\\\"weblogic\\\", \\\"welcome1\\\", \\\"t3://$HOSTNAME:$WLS_ADMIN_PORT\\\")\r\"; exp_continue}\n";
  print FILE "  -re \".*serverConfig> \" { send \"listOSSOProviderParams(name=\\\"OVDAuthenticator\\\",param=\\\"all\\\")\r\"; }\n";
  print FILE "}\n";
  print FILE "expect {\n";
  print FILE "  -re \"wls:/WLS_IDM/serverConfig.*\" {send \"exit()\r\"; exp_continue}\n";
  print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit !!! AssociateSecurityStoreWLST\"; return }\n";
  print FILE "}\n";
  print FILE "expect eof\n";
  close (FILE);
  `chmod 755 $Script_checkParamofOVDprovider`;
  }
  return $Script_checkParamofOVDprovider;
}

sub generate_python_script_ReassociateSecurityStore{
  $reassociateSecurityStore_py = "${WORKDIR}${DIRSEP}reassociateSecurityStore.py";
  if ( ! open (FILE, ">$reassociateSecurityStore_py") ) 
  {
    print "ERROR: failed to write to $reassociateSecurityStore_py\n"; 
    $exit_value = 1;
  }
  else 
  {   
	print FILE "#!/usr/bin/python\n";
  	print FILE "\n";
  	print FILE "import os, sys\n";
  	print FILE "\n";
  	print FILE "try:\n";
  	print FILE "    MW_HOME = \"${MW_HOME}\"\n";
  	print FILE "    ORACLE_HOME = \"${IDM_ORACLE_HOME}\"\n";
  	print FILE "    DOMAIN_HOME = \"${IDM_DOMAIN_HOME}\"\n";
  	print FILE "    if MW_HOME is None:\n";
  	print FILE "        sys.exit(\"Error: Please set the environment variable MW_HOME\")\n";
  	print FILE "    if ORACLE_HOME is None:\n";
  	print FILE "        sys.exit(\"Error: Please set the environment variable ORACLE_HOME\")\n";
  	print FILE "    if DOMAIN_HOME is None:\n";
  	print FILE "        sys.exit(\"Error: Please set the environment variable DOMAIN_HOME\")\n";
  	print FILE "except (KeyError), why:\n";
  	print FILE "    sys.exit(\"Error: Missing Environment Variables \" + str(why))\n";
    print FILE "connect('${WLS_USER}','${WLS_PWD}','t3://${HOSTNAME}:${WLS_ADMIN_PORT}')\n";
    print FILE "reassociateSecurityStore(domain='${IDM_DOMAIN_NAME}', admin='cn=orcladmin',password='welcome1', ldapurl='ldap://${OIDHOST}:${OID_PORT}',servertype='OID', jpsroot='cn=jpsroot')\n";
    print FILE "os.system('sleep 60')\n";
    print FILE "disconnect()\n";
    print FILE "exit()\n";
    close (FILE);
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
      if ( $line =~ /Operation Completed/ ) {
        $EXIT_STATUS="SUCCESS";
      }
    }
}


