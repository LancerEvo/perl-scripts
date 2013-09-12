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

# from import, we shall get the following information
$HOSTNAME="%HOST%";
$TIASTOPO="%TIASTOPO%";
$OID_PORT="%OIDPORT%";
$IDM_HOME="%IDM_HOME%";
$JAVA_HOME="%JAVA_HOME%";
$MW_HOME="%MW_HOME%";
$OIDHOST="%OIDHOST%";
$WLPORT="%WLPORT%";
$WAS_HOME="%WAS_HOME%";
$WAS_DMGR_PROFILE_HOME="%WAS_DMGR_PROFILE_HOME%";
$APPSERVER_TYPE="%APPSERVER_TYPE%";
$DBHOST="%DBHOST%";
$DBPORT="%DBPORT%";
$ORACLE_SID="%ORACLE_SID%";
$CONNECTION_STRING="%CONNECTION_STRING%";
$OIM_DB_SCHEMA_USERNAME="OIM_DB_SCHEMA_USERNAME";
$CELL_HOME_LOCATION="%CELL_HOME_LOCATION%";
$PREPARE_OIM="%PREPARE_OIM%";
$PREPARE_OAM="%PREPARE_OAM%";
$PREPARE_OPAM="%PREPARE_OPAM%";
$PRECONFIG="%PRECONFIG%";
$PREPARE_WAS="%PREPARE_WAS%";
$WAS_CONSOLE_PORT="%WAS_CONSOLE_PORT%";
$WAS_USER="%WAS_USER%";
$WAS_PWD="%WAS_PWD%";
$OPSS_configIDStore="%OPSS_configIDStore%";
# for OUD
$OUD_PORT="%OUDPORT%";
$OUD_ADMIN_PORT="%OUDADMINPORT%";
$OUD_HOST="%OUDHOST%";
$OUD_INSTANCE_HOME="%OUD_INSTANCE_HOME%";
$IDSTORE_KEYSTORE_FILE="%IDSTORE_KEYSTORE_FILE%";
$IDSTORE_KEYSTORE_PASSWORD="%IDSTORE_KEYSTORE_PASSWORD%";
######## Initialize TIASTOPO Variables #################
$OVD_PORT="";
$ODSM_PORT="";
$DIP_PORT="";
$OIF_PORT="";
$OID_SSL_PORT="";

# if support preInstallAction and postInstallAction, extra logic to be added
$preInstallAction="";
$postInstallAction="";

# from runtime, we shall get the following information
# for backward compatability, WORKDIR for the install will be different from runtime ( TODO ??)
$WORKDIR=""; 
$AUTO_HOME="";
$AUTO_WORK="";
$TASK_ID="";

# from export, we shall export the following information
#$EXIT_STATUS="FAILURE"; 
$EXIT_STATUS="SUCCESS"; 
$tiastopo_tsc="";
$tiastopo_prp="";
$SHUTDOWN_SCRIPT="";

# the exit_value for this program
$exit_value=0;

################# Program Main Logic ################
parse_import_file();
parse_runtime_file();
parse_tiastopo_file();
install();
print_test_parameter();
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
      if($tmp_token[0] eq "HOSTNAME" ) {
        $HOSTNAME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "TIASTOPO" ) {
        $TIASTOPO = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "IDM_HOME" ) {
        $IDM_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OID_PORT" ) {
        $OID_PORT = $tmp_token[1];
        if($OID_PORT eq "") {
              $OID_PORT = 3060;
		}
      }
      elsif ($tmp_token[0] eq "JAVA_HOME" ) {
        $JAVA_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "MW_HOME" ) {
        $MW_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OIDHOST" ) {
        $OIDHOST = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "WAS_HOME" ) {
        $WAS_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "WAS_DMGR_PROFILE_HOME" ) {
        $WAS_DMGR_PROFILE_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "APPSERVER_TYPE" ) {
        $APPSERVER_TYPE = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "DBHOST" ) {
        $DBHOST = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "DBPORT" ) {
        $DBPORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "CONNECTION_STRING" ) {
        $CONNECTION_STRING = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "ORACLE_SID" ) {
        $ORACLE_SID = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OIM_DB_SCHEMA_USERNAME" ) {
        $OIM_DB_SCHEMA_USERNAME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "CELL_HOME_LOCATION" ) {
        $CELL_HOME_LOCATION = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "PREPARE_OIM" ) {
        $PREPARE_OIM = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "PREPARE_OAM" ) {
        $PREPARE_OAM = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "PREPARE_OPAM" ) {
        $PREPARE_OPAM = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "PRECONFIG" ) {
        $PRECONFIG = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "PREPARE_WAS" ) {
       $PREPARE_WAS = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "WAS_CONSOLE_PORT" ) {
        $WAS_CONSOLE_PORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "WAS_USER" ) {
        $WAS_USER = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "WAS_PWD" ) {
        $WAS_PWD = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OPSS_configIDStore" ) {
       $OPSS_configIDStore = $tmp_token[1];
      }
	  elsif ($tmp_token[0] eq "OUD_PORT" ) {
        $OUD_PORT = $tmp_token[1];
        if($OUD_PORT eq "") {
              $OUD_PORT = 1389;
        }
      }
	  elsif ($tmp_token[0] eq "OUD_ADMIN_PORT" ) {
        $OUD_ADMIN_PORT = $tmp_token[1];
        if($OUD_ADMIN_PORT eq "") {
              $OUD_ADMIN_PORT = 1444;
        }
      }
      elsif ($tmp_token[0] eq "OUD_HOST" ) {
        $OUD_HOST = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OUD_INSTANCE_HOME" ) {
        $OUD_INSTANCE_HOME = $tmp_token[1];
      }
      else {
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

sub parse_tiastopo_file
{
  if ( open(IN, "$TIASTOPO") )
  {
    while(my $my_line = <IN>)
    {
      chomp $my_line;
      $my_line =~ s/^\s+//;
      $my_line =~ s/\s+$//;

      my @tmp_token = split("=",$my_line);
      if($tmp_token[0] eq "OVD_PORT" ) {
        $OVD_PORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "ODSM_PORT" ) {
        $ODSM_PORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "DIP_PORT" ) {
        $DIP_PORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OIF_PORT" ) {
        $OIF_PORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "ADMINSERVER_PORT" ) {
        $WLPORT = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OID_SSL_PORT" ) {
        $OID_SSL_PORT = $tmp_token[1];
        if($OID_SSL_PORT eq ""){
             $OID_SSL_PORT = 3131;
           }
      }
      else {
        ; # ignored
      }
    }
    close (IN);
  }
  else
  {
    print "ERROR: failed to open $TIASTOPO\n";
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

sub IDMInputFileGen_PolicyStore
{
  my ($operation, $MSname) = (@_);

  $FileforPlicyStore = "${WORKDIR}${DIRSEP}FileforPlicyStore.conf";

  if ( ! open (FILE, ">$FileforPlicyStore") )
  {
    print "ERROR: failed to write to $FileforPlicyStore\n";
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
  return $FileforPlicyStore ;
}

sub InputFileGen_preConfigIDStore
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_preConfigIDStore = "${WORKDIR}${DIRSEP}InputFileGen_preConfigIDStore.conf";

  if ( ! open (FILE, ">$InputFileGen_preConfigIDStore") )
  {
    print "ERROR: failed to write to $InputFileGen_preConfigIDStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OUD_HOST\n";
    print FILE "IDSTORE_PORT : $OUD_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
	print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";

    close (FILE);
  }
  return $InputFileGen_preConfigIDStore ;
}

sub InputFileGen_prepareIDStore_OAM
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_prepareIDStore_OAM = "${WORKDIR}${DIRSEP}InputFileGen_prepareIDStore_OAM.conf";

  if ( ! open (FILE, ">$InputFileGen_prepareIDStore_OAM") )
  {
    print "ERROR: failed to write to $InputFileGen_prepareIDStore_OAM\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OUD_HOST\n";
    print FILE "IDSTORE_PORT : $OUD_PORT\n";
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
	print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";
    close (FILE);
  }
  return $InputFileGen_prepareIDStore_OAM;
}

sub InputFileGen_prepareIDStore_OIM
{
  my ($operation, $MSname) = (@_);
  
  $InputFileGen_prepareIDStore_OIM = "${WORKDIR}${DIRSEP}InputFileGen_prepareIDStore_OIM.conf";
  
  if ( ! open (FILE, ">$InputFileGen_prepareIDStore_OIM") )
  {
    print "ERROR: failed to write to $InputFileGen_prepareIDStore_OIM\n";
    $exit_value = 1;
  } 
  else
  {
    print FILE "IDSTORE_HOST : $OUD_HOST\n";
    print FILE "IDSTORE_PORT : $OUD_PORT\n";
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
    print FILE "OIM_DB_URL:jdbc:oracle:thin:\@${DBHOST}:${DBPORT}:$ORACLE_SID\n";
    print FILE "OIM_DB_SCHEMA_USERNAME: $OIM_DB_SCHEMA_USERNAME\n";
    print FILE "OIM_WAS_CELL_CONFIG_DIR: $CELL_HOME_LOCATION/fmwconfig\n";
    print FILE "IDSTORE_PASSWD : welcome1\n"; 
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";
    close (FILE);
  } 
  return $InputFileGen_prepareIDStore_OIM;
}

sub InputFileGen_prepareIDStore_WAS
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_prepareIDStore_WAS = "${WORKDIR}${DIRSEP}InputFileGen_prepareIDStore_WAS.conf";

  if ( ! open (FILE, ">$InputFileGen_prepareIDStore_WAS") )
  {
    print "ERROR: failed to write to $InputFileGen_prepareIDStore_WAS\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "IDSTORE_HOST : $OUD_HOST\n";
    print FILE "IDSTORE_PORT : $OUD_PORT\n";
    print FILE "IDSTORE_BINDDN: cn=orcladmin\n";
    print FILE "IDSTORE_USERNAMEATTRIBUTE: cn\n";
    print FILE "IDSTORE_LOGINATTRIBUTE: uid\n";
    print FILE "IDSTORE_USERSEARCHBASE: cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_SEARCHBASE: dc=us,dc=oracle,dc=com\n";
    print FILE "IDSTORE_GROUPSEARCHBASE: cn=Groups,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_SHARES_IDSTORE: true\n";
    print FILE "IDSTORE_WASADMINUSER: wasadmin\n";
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";
    close (FILE);
  }
  return $InputFileGen_prepareIDStore_WAS;
}

sub InputFileGen_validate_IDStore
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_validate_IDStore = "${WORKDIR}${DIRSEP}InputFileGen_validate_IDStore.conf";

  if ( ! open (FILE, ">$InputFileGen_validate_IDStore") )
  {
    print "ERROR: failed to write to $InputFileGen_validate_IDStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "idstore.type: OUD\n";
    print FILE "idstore.host: $OUD_HOST\n";
    print FILE "idstore.port: $OUD_PORT\n";
    print FILE "idstore.sslport: $OID_SSL_PORT\n";
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
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";
    close (FILE);
  }
  return $InputFileGen_validate_IDStore;
}

sub InputFileGen_validate_POLICYStore
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_validate_POLICYStore = "${WORKDIR}${DIRSEP}InputFileGen_validate_POLICYStore.conf";

  if ( ! open (FILE, ">$InputFileGen_validate_POLICYStore") )
  {
    print "ERROR: failed to write to $InputFileGen_validate_POLICYStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "POLICYSTORE_HOST: $OIDHOST\n";
    print FILE "POLICYSTORE_PORT: $OID_PORT\n";
    print FILE "POLICYSTORE_SECURE_PORT: $OID_SSL_PORT\n";
    print FILE "POLICYSTORE_IS_SSL_ENABLED: FALSE\n";
    print FILE "POLICYSTORE_READ_WRITE_USERNAME : cn=PolicyRWUser,cn=Users,dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_PASSWORD : welcome1\n";
    print FILE "POLICYSTORE_SEEDING: true\n";
    print FILE "POLICYSTORE_JPS_ROOT_NODE : cn=jpsroot\n";
    print FILE "POLICYSTORE_DOMAIN_NAME: dc=us,dc=oracle,dc=com\n";
    print FILE "POLICYSTORE_JPS_CONFIG_DIR :\n";
    print FILE "POLICYSTORE_CRED_MAPPING_FILE_LOCATION :\n";
    print FILE "POLICYSTORE_ADF_CRED_FILE_LOCATION :\n";
    print FILE "POLICYSTORE_STRIPE_FSCM :\n";
    print FILE "POLICYSTORE_STRIPE_CRM:\n";
    print FILE "POLICYSTORE_STRIPE_HCM:\n";
    print FILE "POLICYSTORE_STRIPE_SOA_INFRA:\n";
    print FILE "POLICYSTORE_STRIPE_APM:\n";
    print FILE "POLICYSTORE_STRIPE_ESSAPP:\n";
    print FILE "POLICYSTORE_STRIPE_B2BUI:\n";
    print FILE "POLICYSTORE_STRIPE_OBI:\n";
    print FILE "POLICYSTORE_STRIPE_WEBCENTER :\n";
    print FILE "POLICYSTORE_STRIPE_IDCCS :\n";
    print FILE "POLICYSTORE_CRED_STORE:\n";
    close (FILE);
  }
  return $InputFileGen_validate_POLICYStore;
}

sub GenScript_AssociateSecurityStoreWLST 
{ 
  $Script_AssociateSecurityStoreWLST = "${WORKDIR}${DIRSEP}Script_AssociateSecurityStoreWLST.cfg";
  
  if ( ! open (FILE, ">$Script_AssociateSecurityStoreWLST") )
  {
    print "ERROR: failed to write to $Script_AssociateSecurityStoreWLST\n";
    $exit_value = 1;
  }
  else
  {
  print FILE "#!/usr/bin/expect -f\n";
  print FILE "spawn $MW_HOME/oracle_common/common/bin/wlst.sh\n";  
  print FILE "set timeout -1\n";
  print FILE "expect {\n";
  print FILE "  -timeout -1\n";
  print FILE "  \"wls:/offline> \" { send \"connect (\\\"weblogic\\\", \\\"welcome1\\\", \\\"t3://$OIDHOST:$WLPORT\\\")\r\"; exp_continue }\n";
  print FILE "  -re \".*serverConfig> \" { send \"reassociateSecurityStore(domain=\\\"IDMDomain\\\", admin=\\\"cn=orcladmin\\\",password=\\\"welcome1\\\", ldapurl=\\\"ldap://$OIDHOST:$OID_PORT\\\",servertype=\\\"OID\\\", jpsroot=\\\"cn=jpsroot\\\")\r\"; }\n";
  print FILE "}\n";
  print FILE "expect {\n";
  print FILE "  -re \".*serverConfig> \" {send \"exit()\r\"; exp_continue}\n";
  print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit !!! AssociateSecurityStoreWLST\"; return }\n";
  print FILE "}\n";
  print FILE "expect eof\n";
  close (FILE);
  `chmod 755 $Script_AssociateSecurityStoreWLST`;
  }
  return $Script_AssociateSecurityStoreWLST;
}

sub IDMconfigScriptGen_preConfigIDStore
{
  my ($operation, $MSname) = (@_);

  $script_preConfigIDStore = "${WORKDIR}${DIRSEP}preConfigIDStore.cfg";

  if ( ! open (FILE, ">$script_preConfigIDStore") )
  {
    print "ERROR: failed to write to $script_preConfigIDStore\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -preConfigIDStore input_file=$InputFileGen_preConfigIDStore log_level=ALL log_file=${WORKDIR}${DIRSEP}preConfigIDStore.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $script_preConfigIDStore`
  }
  return $script_preConfigIDStore ;
}

sub ScriptGen_prepareIDStore_OAM
{
  my ($operation, $MSname) = (@_);

  $ScriptGen_prepareIDStore_OAM = "${WORKDIR}${DIRSEP}ScriptGen_prepareIDStore_OAM.cfg";

  if ( ! open (FILE, ">$ScriptGen_prepareIDStore_OAM") )
  {
    print "ERROR: failed to write to $ScriptGen_prepareIDStore_OAM\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -prepareIDStore mode=OAM input_file=$InputFileGen_prepareIDStore_OAM log_level=ALL log_file=${WORKDIR}${DIRSEP}prepareIDStore_OAM.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for oblixanonymous:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for oblixanonymous:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for oamAdminUser:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for oamAdminUser:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for oamSoftwareUser:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for oamSoftwareUser:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit prepareIDStore_OAM!!\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $ScriptGen_prepareIDStore_OAM`
  }
  return $ScriptGen_prepareIDStore_OAM;
}

sub ScriptGen_prepareIDStore_OIM
{
  my ($operation, $MSname) = (@_);

  $ScriptGen_prepareIDStore_OIM = "${WORKDIR}${DIRSEP}ScriptGen_prepareIDStore_OIM.cfg";

  if ( ! open (FILE, ">$ScriptGen_prepareIDStore_OIM") )
  {
    print "ERROR: failed to write to $ScriptGen_prepareIDStore_OIM\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -prepareIDStore mode=OIM input_file=$InputFileGen_prepareIDStore_OIM log_level=ALL log_file=${WORKDIR}${DIRSEP}prepareIDStore_OIM.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for OIM_DB_SCHEMA_PASSWORD:\" { send \"$OIM_DB_SCHEMA_USERNAME\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for OIM_DB_SCHEMA_PASSWORD:\" { send \"$OIM_DB_SCHEMA_USERNAME\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for oimadminuser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for oimadminuser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for xelsysadm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for xelsysadm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit prepareIDStore_OIM!!\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $ScriptGen_prepareIDStore_OIM`
  }
  return $ScriptGen_prepareIDStore_OIM;
}

sub ScriptGen_prepareIDStore_WAS
{
  my ($operation, $MSname) = (@_);

  $ScriptGen_prepareIDStore_WAS = "${WORKDIR}${DIRSEP}ScriptGen_prepareIDStore_WAS.cfg";

  if ( ! open (FILE, ">$ScriptGen_prepareIDStore_WAS") )
  {
    print "ERROR: failed to write to $ScriptGen_prepareIDStore_WAS\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -prepareIDStore mode=WAS input_file=$InputFileGen_prepareIDStore_WAS log_level=ALL log_file=${WORKDIR}${DIRSEP}prepareIDStore_WLS.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for wasadmin:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for wasadmin:\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for weblogic_idm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for weblogic_idm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit prepareIDStore_WAS!!\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $ScriptGen_prepareIDStore_WAS`
  }
  return $ScriptGen_prepareIDStore_WAS;
}

sub IDM_validate_IDSTORE_POLICYSTORE
{
    $ReturnResult_IDSTORE = `$IDM_HOME/idmtools/bin/idmConfigTool.sh -validate component=IDSTORE input_file=$InputFileGen_validate_IDStore`;
    $ReturnResult_POLICYSTORE = `$IDM_HOME/idmtools/bin/idmConfigTool.sh -validate component=POLICYSTORE input_file=$InputFileGen_validate_POLICYStore`;
    $posIDSTORE = index($ReturnResult_IDSTORE,"Validation finished");
    $posPOLICYSTORE = index($ReturnResult_POLICYSTORE,"Validation finished");

    print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^\$ReturnResult_IDSTORE ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
    print "$ReturnResult_IDSTORE\n";
    print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^\$ReturnResult_POLICYSTORE^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
    print "$ReturnResult_POLICYSTORE\n";
    print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^\$posIDSTORE^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
    print "$posIDSTORE\n";
    print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^\$posPOLICYSTORE^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
    print "$posPOLICYSTORE\n";
    print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";

    if ($posIDSTORE > -1 && $posPOLICYSTORE >-1)
    {
	$exit_value = 0;
        $EXIT_STATUS="SUCCESS";
    }
    else
    {
	$exit_value = 1;
    }
}

sub print_test_parameter
{
  #exec("ifconfig");
  print "###################################################################\n";
  print "$OVD_PORT \n";
  print "$ODSM_PORT\n";
  print "$DIP_PORT\n";
  print "$OIF_PORT\n";
  print "$ENV{PATH}\n";
  print "$ENV{JAVA_HOME}\n";  
  print "$ENV{'MW_HOME'}\n";
  print "$ENV{'ORACLE_HOME'}\n";
  print "$ENV{'WAS_HOME'}\n";
  print "$ENV{'APPSERVER_TYPE'}\n";
  print "$ENV{'WAS_DMGR_PROFILE_HOME'}\n";

  $cmd3 = '$JAVA_HOME';
  $info = `echo $cmd3`;
  print "!!!!!uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu!!!!!!!$info\n";
  
  print "&&&&&&&&&&&&&  $PRECONFIG  ----  $PREPARE_OIM  ----- $PREPARE_WAS ----- $PREPARE_OAM ------$PREPARE_OPAM-&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& \n";
  if( $PRECONFIG eq "true" ) {
     $Result_preconfigIDstore = `$script_preConfigIDStore`;
     sleep 30;
     print "==========================================================";
     print "&&&&&&&&&&&&&Below is the result for Result_preconfigIDstore !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_preconfigIDstore \n"; 
   }
  if($PREPARE_OIM eq "true") {
     $Result_prepareIDstore_OIM = `$ScriptGen_prepareIDStore_OIM`;
     sleep 30;
     print "==========================================================";
     print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_OIM !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_OIM \n";
   }
  if($PREPARE_WAS eq "true") {
     $Result_prepareIDstore_WAS = `$ScriptGen_prepareIDStore_WAS`;
     sleep 30;
     print "==========================================================";
     print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_WAS !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_WAS \n";
    
   } 
  if($PREPARE_OAM eq "true") {
    $Result_prepareIDstore_OAM = `$ScriptGen_prepareIDStore_OAM`;
    sleep 30;
    print "==========================================================";
    print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_OAM !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_OAM \n";
   }  
}

sub getKeystoreFileAndKeystorePassword {
    $IDSTORE_KEYSTORE_FILE = $OUD_INSTANCE_HOME."/config/admin-keystore";
    $IDSTORE_KEYSTORE_PASSWORD_FILE = $OUD_INSTANCE_HOME."/config/admin-keystore.pin";
    $IDSTORE_KEYSTORE_PASSWORD = DTE::readin_text_file($IDSTORE_KEYSTORE_PASSWORD_FILE);
    chomp($IDSTORE_KEYSTORE_PASSWORD);
}

sub install
{
  set_platform_info();
  # unset some env variables that might fail install
  unset_unwanted_env_variables();
  getKeystoreFileAndKeystorePassword();
  IDMInputFileGen_PolicyStore();
  InputFileGen_preConfigIDStore();
  InputFileGen_prepareIDStore_OAM();
  InputFileGen_prepareIDStore_OIM();
  InputFileGen_prepareIDStore_WAS();
  InputFileGen_validate_IDStore();
  InputFileGen_validate_POLICYStore();
  IDMconfigScriptGen_preConfigIDStore();
  ScriptGen_prepareIDStore_OAM();
  ScriptGen_prepareIDStore_OIM();
  ScriptGen_prepareIDStore_WAS();
  
	postInstallAction();
} 

sub set_platform_info
{
  $PLATFORM = DTE::getOS();

  if ( $PLATFORM eq 'nt' ) {
    $DIRSEP = '\\';
    $PATHSEP =';';
  }
  else {
    $DIRSEP = '/' ;
    $PATHSEP = ':';
  }
}

sub checkOraFiles
{
	$runasroot = "/usr/local/packages/aime/ias/run_as_root";
	if(-e "/etc/oracle") 
	{
		$cmd = "$runasroot rm -rf /etc/oracle";
		`$cmd`;
		print "Attempted: $cmd \n";	
	}

	if(-e "/etc/oraInst.loc") 
	{
		$cmd = "$runasroot rm /etc/oraInst.loc";
		`$cmd`;
		print "Attempted: $cmd \n";	
	}
}

sub checkGroupOfCurrentUser
{
  return 0 if($PLATFORM ne 'linux');

  $info = `id -nG`;

  chomp $info;
        @groups = split(/\s/, $info );
        foreach $group (@groups)
        {
                return 0 if ($group eq 'dba');
        }
  DTE::create_text_file("${WORKDIR}${DIRSEP}UserNotInDBAGroup.dif", "Warning: In case of db install failure, check if the user is part of dba group");
  return 1;
}

sub process_tokens
{
  my $rnum = int(rand(9999));
  my $sid = "db"."$rnum";

  if ( ($ORACLE_SID ne "") and ($ORACLE_SID ne "%SID%" ) ) {
    $sid = $ORACLE_SID;
  }

  $DOMAIN_NAME = $HOSTNAME;
  $DOMAIN_NAME =~ s/^[^.]+\.//g;

  if ($ORACLE_HOME eq "%OH%" ) {
    $ORACLE_HOME="${AUTO_WORK}${DIRSEP}${sid}";
  }

  if ($ORACLE_HOME_NAME eq "%OHN%" ) {
    $ORACLE_HOME_NAME = $sid;
  }

  $ORACLE_BASE = dirname($ORACLE_HOME);

  if ($ORACLE_SID eq "%SID%" ) {
    $ORACLE_SID = $sid;
  }

  if ($GLOBAL_DB_NAME eq "%SID%" ) {
    $GLOBAL_DB_NAME = "${sid}"; # in some case user wants to have the same
  }
  elsif ($GLOBAL_DB_NAME eq "%GDBNAME%" ) {
    $GLOBAL_DB_NAME = "${sid}.${DOMAIN_NAME}";
  }

  if ($INVENTORY_LOC eq "%INVLOC%" ) {
    $INVENTORY_LOC = "${WORKDIR}${DIRSEP}oraInventory";
  }

  if ($VERSION eq "%VERSION%" ) {
    $VERSION = "11.2.0.3.0";
  }

  if ( $DB_PORT eq "%DB_PORT%" and $SOFTWARE_ONLY eq 'true' ) {
    $DB_PORT = NextAvailablePort();  # a random number
  }
}

sub set_shiphome_info
{
  if ( $PLATFORM eq 'nt' ) {	
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}stage${DIRSEP}products.xml";
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}stage${DIRSEP}products.xml" unless (-e $FROM_LOCATION);
    $INSTALL_EXE = "${SHIPHOME}${DIRSEP}install${DIRSEP}oui.exe";
    $INSTALL_EXE = "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}install${DIRSEP}oui.exe" unless (-e $INSTALL_EXE);
    $TIME_OUT=0; 
  }
  elsif ( $PLATFORM eq 'linux' ) {
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}stage${DIRSEP}products.xml";
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}stage${DIRSEP}products.xml" unless (-e $FROM_LOCATION);
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}runInstaller";
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}runInstaller" unless (-e $INSTALL_EXE);
    $INSTALL_EXE= "$INSTALL_EXE -ignoreSysPrereqs  -ignorePrereq";
    $TIME_OUT=0;
  }
  elsif ( $PLATFORM eq 'hpux' ) { 
      print "/usr/local/packages/aime/install/run_as_root \"rm -rf /etc/oratab\"";
      system("/usr/local/packages/aime/install/run_as_root \"rm -rf /etc/oratab\"");
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}stage${DIRSEP}products.xml";
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}stage${DIRSEP}products.xml" unless (-e $FROM_LOCATION);
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}runInstaller";
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}runInstaller" unless (-e $INSTALL_EXE);
    $TIME_OUT=0;
  }
  else {
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}stage${DIRSEP}products.xml";
    $FROM_LOCATION = "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}stage${DIRSEP}products.xml" unless (-e $FROM_LOCATION);
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}runInstaller";
    $INSTALL_EXE= "${SHIPHOME}${DIRSEP}Disk1${DIRSEP}runInstaller" unless (-e $INSTALL_EXE);
    $INSTALL_EXE= "$INSTALL_EXE -ignoreSysPrereqs  -ignorePrereq";
    $TIME_OUT=0;
  }
}

sub getPrimaryGroupName
{
  	return 'dba' if ( $PLATFORM eq 'nt' ); 
	
	$str = `id`;
	chomp $str;
	$str =~ /gid=[^\(]*\(([^\)]*)/;
	return $1;
}

sub generate_rsp_file
{
  $rspFile = "${WORKDIR}${DIRSEP}db.rsp";

  if ( ! open(OFILE, "> $rspFile" ) ) {
    print "\nCannot write to output file: $rspFile\n";
    $exit_value = 1;
  }
  print OFILE "oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0\n";

if ( $SOFTWARE_ONLY eq 'true' ) {
print OFILE "oracle.install.option=INSTALL_DB_SWONLY\n";
  }
  else {
    print OFILE "oracle.install.option=INSTALL_DB_AND_CONFIG\n";
  }

	$primaryGroupName = &getPrimaryGroupName();
	print "primary group name = $primaryGroupName \n";

  print OFILE "ORACLE_HOSTNAME=$HOSTNAME\n\n";
  print OFILE "UNIX_GROUP_NAME=$primaryGroupName\n";
  print OFILE "INVENTORY_LOCATION=$INVENTORY_LOC\n";
  print OFILE "SELECTED_LANGUAGES=en\n";
  print OFILE "ORACLE_BASE=$ORACLE_BASE\n";
  print OFILE "ORACLE_HOME=$ORACLE_HOME\n";
  print OFILE "oracle.install.db.InstallEdition=$INSTALL_TYPE\n";
  print OFILE "#oracle.install.db.optionalComponents=\n";
  print OFILE "oracle.install.db.DBA_GROUP=dba\n";
  print OFILE "oracle.install.db.OPER_GROUP=dba\n";
  print OFILE "oracle.install.db.CLUSTER_NODES=\n";
  print OFILE "oracle.install.db.config.starterdb.type=GENERAL_PURPOSE\n";
  print OFILE "oracle.install.db.config.starterdb.globalDBName=$GLOBAL_DB_NAME\n";
  print OFILE "oracle.install.db.config.starterdb.characterSet=$DB_CHARSET\n";
  print OFILE "oracle.install.db.config.starterdb.SID=$ORACLE_SID\n";
  print OFILE "oracle.install.db.config.starterdb.memoryLimit=1156\n";
  print OFILE "oracle.install.db.config.starterdb.memoryOption=true\n";
  print OFILE "oracle.install.db.config.starterdb.installExampleSchemas=true\n";
  print OFILE "oracle.install.db.config.starterdb.enableSecuritySettings=true\n";
  print OFILE "oracle.install.db.config.starterdb.password.ALL=$SYS_PASSWORD\n";
  print OFILE "oracle.install.db.config.starterdb.password.SYS=\n";
  print OFILE "oracle.install.db.config.starterdb.password.SYSTEM=\n";
  print OFILE "oracle.install.db.config.starterdb.password.SYSMAN=\n";
  print OFILE "oracle.install.db.config.starterdb.password.DBSNMP=\n";
  print OFILE "oracle.install.db.config.starterdb.control=DB_CONTROL\n";
  print OFILE "oracle.install.db.config.starterdb.gridcontrol.gridControlServiceURL=\n";
  print OFILE "oracle.install.db.config.starterdb.automatedBackup.enable=false\n";
  print OFILE "oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE\n";
  print OFILE "oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=${ORACLE_BASE}${DIRSEP}oradata\n";
  print OFILE "oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=\n";
  print OFILE "oracle.install.db.config.asm.diskGroup=\n";
  print OFILE "oracle.install.db.config.asm.ASMSNMPPassword=\n";
  print OFILE "MYORACLESUPPORT_USERNAME=\n";
  print OFILE "MYORACLESUPPORT_PASSWORD=\n";
  print OFILE "DECLINE_SECURITY_UPDATES=true\n";
  print OFILE "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false\n";
  print OFILE "PROXY_HOST=\n";
  print OFILE "PROXY_PORT=\n";
  print OFILE "PROXY_USER=\n";
  print OFILE "PROXY_PWD=\n";
  print OFILE "oracle.install.db.EEOptionsSelection=false\n";
  print OFILE "COLLECTOR_SUPPORTHUB_URL=\n";
  print OFILE "oracle.installer.autoupdates.option=SKIP_UPDATES\n";
  print OFILE "oracle.installer.autoupdates.downloadUpdatesLoc=\n";
  print OFILE "AUTOUPDATES_MYORACLESUPPORT_USERNAME=\n";
  print OFILE "AUTOUPDATES_MYORACLESUPPORT_PASSWORD=\n";
  close(OFILE);
  return $rspFile;
}

sub oui_install
{

 delete $ENV{DISPLAY};
   $installLogDir2="";

  if ( $PLATFORM ne 'nt' ) {
    my $oraInstLoc = "${WORKDIR}${DIRSEP}oraInst.loc";

    if ( ! open(OFILE, "> $oraInstLoc") ) {
      print"\nCannot open writeable output file: $oraInstLoc\n";
      $exit_value = 1;
    }
    print OFILE "inventory_loc=${INVENTORY_LOC}\n";
    close(OFILE);

    $installLogDir="${INVENTORY_LOC}${DIRSEP}logs";
    $cmd="$INSTALL_EXE -invPtrLoc ${oraInstLoc} -force -silent -waitforcompletion -responseFile $rspFile";
    print "$cmd\n";
  }
  else { # Windows
    $installLogDir="${INVENTORY_LOC}${DIRSEP}logs";
    $installLogDir2="C:${DIRSEP}Program Files${DIRSEP}Oracle${DIRSEP}Inventory${DIRSEP}logs";
    $cmd="$INSTALL_EXE -force -silent -waitforcompletion -nowait  -responseFile $rspFile";
    print "$cmd\n";    
    my $oui_bat_file = "${WORKDIR}${DIRSEP}install.bat";

    if ( ! open(OFILE, "> $oui_bat_file") ) {
      print"\nFATAL ERROR: Cannot open writeable output file: $oui_bat_file\n";
      $exit_value = 1;
    }
    print OFILE "${cmd}\n";
    close(OFILE);

    $cmd="$oui_bat_file";
    print "$cmd\n";    
  }

  clean_up_install_log_dir($installLogDir);
	if($installLogDir2 ne "")
	{
  		clean_up_install_log_dir($installLogDir2);
	}
  if ( $PLATFORM eq 'aix' ) {
      system("cp -rf ${SHIPHOME}${DIRSEP}rootpre ${AUTO_WORK}${DIRSEP}");
      system("cp -rf ${SHIPHOME}${DIRSEP}rootpre.sh ${AUTO_WORK}${DIRSEP}");
      $rootprefile="${AUTO_WORK}${DIRSEP}myrootpre.sh";
      if ( open(RPRE, ">$rootprefile") ) {
	 print RPRE "#!/bin/ksh\n";
	 print RPRE "export ROOTPRE_DIR=${AUTO_WORK}\n";
         print RPRE "${AUTO_WORK}${DIRSEP}rootpre.sh\n";
	 close(RPRE);
      }
      print "/usr/local/packages/aime/install/run_as_root \"ksh ${AUTO_WORK}${DIRSEP}myrootpre.sh\"";
      system("/usr/local/packages/aime/install/run_as_root \"ksh ${AUTO_WORK}${DIRSEP}myrootpre.sh\"");
      $ENV{SKIP_ROOTPRE} = 'TRUE';
      print "$cmd\n";
      system("$cmd");
  }
  else { # Other than aix
     print "SHLIB_PATH " . $ENV{SHLIB_PATH} . "\n";
     print "$cmd\n";
     system("$cmd");
  }
  print " ... will sleep $TIME_OUT hours ...\n";  
  sleep ( $TIME_OUT * 3600 );
  copy ($rspFile, "${ORACLE_HOME}${DIRSEP}install.rsp");
}

sub analyze_install_log
{
	my($installLogDir) = @_;

  my $foundFatalErr = 1;  # default to failure
  my $foundNonFatalErr = 0;  # for non fatal error

  my @successTemplates=(
	"INFO:\\s*Successfully executed the flow in SILENT mode",
	"INFO: Successfully executed the flow in SILENT mode",
	"Successfully executed the flow in SILENT mode",
  );

  my @ErrTemplates=(
    "Alert: There is not enough space on the volume",
    "Alert: Some of the configuration assistants failed",
    "Fatal error:",
    "This silent installation was unsuccessful",
    "The installation .* was unsuccessful",
    "One or more operating system patches are missing or not at the required level",
    "Error:\\*\\*\\* Alert:",                
    "Error in invoking target",
    "File not found",
    "java\.lang\.NoClassDefFoundError",
    "java\.lang\.NullPointerException",
    "java\.io\.IOException",
    "^Error:",
    "failed to start",
  );
  my @expectedTemplate = (
    "Exception String: File not found",
    "Error in invoking target",
    "File not found:.*machine.config",
    "The installation of Oracle Database 10g was unsuccessful.",
    "oracleexception is java\.lang\.NullPointerException",
  );

  $errOutFile = "${WORKDIR}${DIRSEP}silentInstall.err" ;

  my @logList = DTE::get_file_list($installLogDir,"installActions.*log");

  if ( $#logList < 0 ) {  # OUI must have failed to start
     $foundFatalErr = 1;
  }
  elsif ( open(OUT, "> $errOutFile" ) ) {
    my $log_id="";
    foreach my $logfile ( @logList ) {

      my $fulllogname="${installLogDir}${DIRSEP}${logfile}" ;

      copy ($fulllogname, "${ORACLE_HOME}${DIRSEP}installActions${log_id}.log");
      copy ($fulllogname, "${WORKDIR}${DIRSEP}installActions${log_id}.log");

      print "analyzing log file $fulllogname ...\n";

      if ( open(IN, "$fulllogname") ) {

        while( $my_line = <IN> ) {
          chomp $my_line;

          foreach my $et ( @ErrTemplates ) {
            if ( $my_line =~ /$et/ )  {
              my $expected = 0;
                print OUT "ErrTemplate ERROR: $my_line\n";
              foreach my $ext ( @expectedTemplate ) {
		if ( $my_line =~ /$ext/ )  {
		  $expected = 1;
                  last ;
	        }
	      }
	      if ( ! $expected ) {
		$foundNonFatalErr = 1;
                print OUT "ERROR: $my_line\n";
	      }
	    }
          }

          foreach my $et ( @successTemplates ) {
            if ( $my_line =~ /$et/ )  {
	      print "Find string in $fulllogname: $et\n";
	      $foundFatalErr = 0;
	    }
          }
        }
        close (IN);
      }
      else {
        print "Can not read from $fulllogname\n";
      }
      $log_id="_1"."$log_id";
    }
    close (OUT) ;
  }
  else {
    print "Can not write to $errOutFile\n";
    $exit_value = 1;
  }

  if ( $foundFatalErr == 0 ) {
    if ( $foundNonFatalErr == 0 ) {
      $EXIT_STATUS="SUCCESS";
    }
    else {
      $EXIT_STATUS="ACCEPTABLE";
    }
  }
  else {
    $EXIT_STATUS="FAILURE";
  }

  if ( ! -e "$SHIPHOME" ) {
    DTE::create_text_file("${WORKDIR}${DIRSEP}shiphomeNotExist.dif", "Error: shiphome $SHIPHOME does not exist or visible!");
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
    print EXPFILE "ORACLE_HOME=$ORACLE_HOME\n";
    print EXPFILE "ORACLE_HOME_NAME=$ORACLE_HOME_NAME\n";
    print EXPFILE "INVENTORY_LOC=$INVENTORY_LOC\n";
    print EXPFILE "ORACLE_SID=$ORACLE_SID\n";
    print EXPFILE "GLOBAL_DB_NAME=$GLOBAL_DB_NAME\n";
    print EXPFILE "CONNECTION_STRING=${HOSTNAME}:${DB_PORT}:${ORACLE_SID}\n";
    print EXPFILE "INSTALL_TYPE=$INSTALL_TYPE\n";
    print EXPFILE "DB_CHARSET=$DB_CHARSET\n";
    print EXPFILE "SYS_PASSWORD=$SYS_PASSWORD\n";
    print EXPFILE "DB_PORT=$DB_PORT\n";
    print EXPFILE "tiastopo.tsc=$tiastopo_tsc\n";
    print EXPFILE "tiastopo.prp=$tiastopo_prp\n";
    print EXPFILE "SHUTDOWN_SCRIPT=$SHUTDOWN_SCRIPT\n";
    print EXPFILE "BLOCK_ID=$TASK_ID\n";
    print EXPFILE "BLOCK_TYPE=InstallOnly\n";
    close (EXPFILE);
  }
}

sub clean_up_install_log_dir
{
  my ($installLogDir) = @_ ;

  if ( ! -d $installLogDir ) {  # do nothing
      return ;
  }

  my $timestamp = DTE::currentTimestamp();

  my $targetDir="$installLogDir"."_save_"."$timestamp";
  if ( ! -d "$targetDir" ) {
    DTE::MKDIR ( $targetDir ) ;
  }

  my @files = DTE::get_file_list($installLogDir, '.*') ;

  foreach my $f (@files) {
      my $file = "${installLogDir}${DIRSEP}${f}";
      my $target = "${targetDir}${DIRSEP}${f}";
      #print "move $file $target\n";
      copy ($file, $target);
      unlink($file);
  }
}

sub createInitOra
{
	if ( $SOFTWARE_ONLY eq 'false' ) {  # do nothing!
    	   return;
  	}	

	$DBS_DIR = "${ORACLE_HOME}${DIRSEP}dbs";
	$origInit = "${DBS_DIR}${DIRSEP}init.ora";
	$newInit  = "${DBS_DIR}${DIRSEP}init${ORACLE_SID}.ora";

	print "creating $newInit \n";
	open(INFILE, $origInit);
	open(OUTFILE, $newInit);

	while($line = <INFILE>)
	{
		chomp($line); 
		$line =~ s/\<ORACLE_BASE\>/$ORACLE_BASE/g
			unless($line =~ /^\s*#/);
		print OUTFILE "$line\n";
	}

	close(INFILE);
	close(OUTFILE);
}

sub gen_utilities
{
	createInitOra();
 # generate ENV file in ORACLE_HOME dir
 my $envFile = "${ORACLE_HOME}${DIRSEP}ohenv.csh";
 if ( $PLATFORM eq 'nt' ) {
    $envFile = "${ORACLE_HOME}${DIRSEP}ohenv.bat";      
 }

 if ( ! (-f $envFile) ) { # generate the file only if not exist yet
  if ( open ( FILE, "> $envFile" ) ) {
   $newpath="${ORACLE_HOME}${DIRSEP}bin${PATHSEP}${ORACLE_HOME}${DIRSEP}jdk${DIRSEP}bin";
   
   if ( $PLATFORM eq 'nt' ) {
     print FILE "set ORACLE_SID=${ORACLE_SID}\n";

     print FILE "set ORACLE_HOME=${ORACLE_HOME}\n";
     print FILE "set PATH=${newpath}${PATHSEP}\%PATH\%\n";
   }
   else {
     print FILE "setenv ORACLE_SID ${ORACLE_SID}\n";
     print FILE "setenv ORACLE_HOME ${ORACLE_HOME}\n";
     print FILE "setenv LD_LIBRARY_PATH ${ORACLE_HOME}${DIRSEP}lib\n";
     print FILE "setenv SHLIB_PATH  ${ORACLE_HOME}${DIRSEP}lib${PATHSEP}$ORACLE_HOME${DIRSEP}network${DIRSEP}lib${PATHSEP}${SHLIB_PATH}${PATHSEP}${OMS_ROOT}${PATHSEP}${OMS_ROOT}${DIRSEP}lib32${PATHSEP}${OMS_ROOT}${DIRSEP}lib${PATHSEP}${ORACLE_HOME}${DIRSEP}jdk${DIRSEP}jre${DIRSEP}lib${DIRSEP}PA_RISC2.0W${DIRSEP}hotspot${PATHSEP}${ORACLE_HOME}${DIRSEP}jdk${DIRSEP}jre${DIRSEP}lib${DIRSEP}PA_RISC2.0W${PATHSEP}${ORACLE_HOME}${DIRSEP}lib\n";
     print FILE "setenv PATH ${newpath}${PATHSEP}\$\{PATH\}\n";
   }
   close ( FILE );
  }
 }

 $shutsqlFile = "${ORACLE_HOME}${DIRSEP}.shutdowndb.sql";
 $starsqlFile = "${ORACLE_HOME}${DIRSEP}.startupdb.sql";

 if ( ! (-f $shutsqlFile) ) { # generate the file only if not exist yet

   if ( open ( SQLFILE, "> $shutsqlFile" ) ) {
     print SQLFILE "set echo on\n";
     print SQLFILE "connect sys/${SYS_PASSWORD} as sysdba\n";
     print SQLFILE "shutdown abort\n";
     print SQLFILE "exit\n";
     close (SQLFILE);
   }
 }

 if ( ! (-f $starsqlFile) ) { # generate the file only if not exist yet

   if ( open ( SQLFILE, "> $starsqlFile" ) ) {
     print SQLFILE "set echo on\n";
     print SQLFILE "connect sys/${SYS_PASSWORD} as sysdba\n";
     print SQLFILE "startup\n";
     print SQLFILE "exit\n";
     close (SQLFILE);
   }
 }

 $SHUTDOWN_SCRIPT = "${ORACLE_HOME}${DIRSEP}shutdown.csh";
 if ( $PLATFORM eq 'nt' ) {
    $SHUTDOWN_SCRIPT = "${ORACLE_HOME}${DIRSEP}shutdown.bat";      
 }

 if ( ! (-f $SHUTDOWN_SCRIPT) ) { # generate the file only if not exist yet

  if ( open ( FILE, "> $SHUTDOWN_SCRIPT" ) ) {

   if ( $PLATFORM eq 'nt' ) {
     print FILE "call ${envFile}\n";

     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}emctl stop dbconsole\n";
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}sqlplus /nolog <${shutsqlFile}\n";
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}lsnrctl stop\n";

     # stop oracle services if any
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}ocssd.exe stop\n";
     print FILE "call net stop OracleDBConsole${ORACLE_SID} /Y\n";
     #print FILE "call net stop OracleCSService /Y\n";
     print FILE "call net stop OracleService${ORACLE_SID} /Y\n";
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}isqlplusctl.bat stop\n";
     # remove css service to help patchset
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}ocssd.exe remove\n";
   }
   else {  # UNIX
     print FILE "#!/bin/csh -x\n";
     print FILE "source ${envFile}\n";
     print FILE "if ( -e ${ORACLE_HOME}/oradata/${ORACLE_SID} ) then\n";
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}emctl stop dbconsole\n";
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}isqlplusctl stop\n";
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}sqlplus /nolog <${shutsqlFile}\n";
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}lsnrctl stop\n";
     print FILE "endif\n";
   }
   close ( FILE );
   chmod 0755, $SHUTDOWN_SCRIPT;
  }
 }

 # generate script to start instance
 my $startupFile = "${ORACLE_HOME}${DIRSEP}startup.csh";
 if ( DTE::getOS() eq 'nt' ) {
    $startupFile = "${ORACLE_HOME}${DIRSEP}startup.bat";      
 }

 if ( ! (-f $startupFile) ) { # generate the file only if not exist yet
  if ( open ( FILE, "> $startupFile" ) ) {

   if ( DTE::getOS() eq 'nt' ) {
     print FILE "call ${envFile}\n";

     # start oracle services for DB if any
     print FILE "call net start OracleService${ORACLE_SID}\n";
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}isqlplusctl.bat start\n";

     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}lsnrctl start\n";
     print FILE "call ${ORACLE_HOME}${DIRSEP}bin${DIRSEP}sqlplus /nolog <${starsqlFile}\n";
   }
   else {  # UNIX

     print FILE "#!/bin/csh -x\n";
     print FILE "source ${envFile}\n";
     
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}lsnrctl start\n";
     print FILE "${ORACLE_HOME}${DIRSEP}bin${DIRSEP}sqlplus /nolog <${starsqlFile}\n";
   }
   close ( FILE );
   chmod 0755, $startupFile;
  }
 }

 $tiastopo_tsc = "${WORKDIR}${DIRSEP}tiastopo.tsc";
 if ( open ( FILE, "> $tiastopo_tsc" ) ) {
   print FILE "set DB_HOST ${HOSTNAME}\n";
   print FILE "set DB_PORT ${DB_PORT}\n";
   print FILE "set DB_SID ${ORACLE_SID}\n";
   print FILE "set DB_GDBNAME ${GLOBAL_DB_NAME}\n";
   print FILE "set DB_ORACLE_HOME ${ORACLE_HOME}\n";
   print FILE "set DB_SYS_PASSWORD ${SYS_PASSWORD}\n";
   close ( FILE );
 }

 $tiastopo_prp = "${WORKDIR}${DIRSEP}tiastopo.prp";
 if ( open ( FILE, "> $tiastopo_prp" ) ) {
   print FILE "DB_HOST=${HOSTNAME}\n";
   print FILE "DB_PORT=${DB_PORT}\n";
   print FILE "DB_SID=${ORACLE_SID}\n";
   print FILE "DB_GDBNAME=${GLOBAL_DB_NAME}\n";
   print FILE "DB_ORACLE_HOME=${ORACLE_HOME}\n";
   print FILE "DB_SYS_PASSWORD=${SYS_PASSWORD}\n";
   close ( FILE );
 }

 $UTPfile = "${WORKDIR}${DIRSEP}UTPblock.prp";
 if ( open ( FILE, "> $UTPfile" ) ) {
   print FILE "DB_HOST=${HOSTNAME}\n";
   print FILE "DB_PORT=${DB_PORT}\n";
   print FILE "DB_SID=${ORACLE_SID}\n";
   print FILE "DB_GDBNAME=${GLOBAL_DB_NAME}\n";
   print FILE "DB_ORACLE_HOME=${ORACLE_HOME}\n";
   print FILE "DB_SYS_PASSWORD=${SYS_PASSWORD}\n";
   print FILE "BLOCK_ID=$TASK_ID\n";
   close ( FILE );
 }
}

sub preInstallAction
{
  print "Sorry, preInstallAction is not supported for now !\n";
}

sub postInstallAction
{
  # 
  my $postact_type = "";
  my $postact_script = "";
  my $postact_params = "";

  if ( $postInstallAction eq "" ) {
    return ;
  }
  # with extra parameters
  if ( $postInstallAction =~ /\[([^]]+)\]\s*\[([^]]+)\]\s*\[([^]]+)\]/ )
  {
     $postact_type = $1;
     $postact_script = $2;
     $postact_params = $3;
  }
  elsif ( $postInstallAction =~ /\[([^]]+)\]\s*\[([^]]+)\]/ )
  {
     $postact_type = $1;
     $postact_script = $2;
  }
  else 
  {
    print "ERROR: invalid postInstallAction format \'$postInstallAction\' !\n";
    $exit_value = 1;
    return;
  }

  if ( $postact_type ne "perl" && $postact_type ne "java" )
  {
    print "ERROR: invalid postInstallAction interpreter \'$postact_type\' ! Only \'perl\' and \'java\' are supported.\n";
    $exit_value = 1;
    return;
  }

  if ( $postact_script =~ /^%AUTO_HOME%\S+/ )
  {
    $postact_script =~ s/^%AUTO_HOME%/${AUTO_HOME}/ ;
  }
  elsif ( $postact_script =~ /^%ADE_VIEW_ROOT%\S+/ )
  {
    $postact_script =~ s/^%ADE_VIEW_ROOT%/$ENV{ADE_VIEW_ROOT}/ ;
  }

  if ( ! (-f $postact_script) )
  {
    print "ERROR: postInstallAction executable \'$postact_script\' does not exist !\n";
    $exit_value = 1;
    return;
  }
  else 
  {
    print "Running postInstallAction executable $postact_script now :\n";
    my $cmd = "$postact_type $postact_script $tiastopo_prp $postact_params";
    print "$cmd\n";
    system("$cmd");
  }
}

sub  unset_unwanted_env_variables
{
   # the following env variable might fail OUI silent install
   delete $ENV{'ORACLE_HOME'};
   delete $ENV{'JAVA_HOME'};
   delete $ENV{'MW_HOME'};
   delete $ENV{'WAS_HOME'};
   delete $ENV{'APPSERVER_TYPE'};
   delete $ENV{'WAS_DMGR_PROFILE_HOME'};
   $ENV{'JAVA_HOME'} = $JAVA_HOME;
   $ENV{'MW_HOME'} = $MW_HOME;
   $ENV{'ORACLE_HOME'} = $IDM_HOME;
   $ENV{'WAS_HOME'} = $WAS_HOME;
   $ENV{'APPSERVER_TYPE'} = $APPSERVER_TYPE;
   $ENV{'WAS_DMGR_PROFILE_HOME'} = $WAS_DMGR_PROFILE_HOME;

   my $envDump = "${WORKDIR}${DIRSEP}preInstallEnv.txt";
   print "Dump ENV to file $envDump right before OUI install\n";
   DTE::dumpEnvFile($envDump);
}

sub NextAvailablePort
{
  my $number = sprintf"%-3d", rand 10000;

  my $newport = 10000 + $number ;

  return $newport;
}

sub  get_db_port_from_listener_ora
{
  if ( $SOFTWARE_ONLY eq 'true' ) {  # do nothing!
    return;
  }

  my $orafile = "${ORACLE_HOME}${DIRSEP}network${DIRSEP}admin${DIRSEP}listener.ora";
  if ( ! open(TEMPI, "$orafile" ) ) {
    print "WARN: $orafile does not exist. Assume database listener port 1521 \n";
  }
  while (my $line = <TEMPI>) {
    chomp $line;

    #(ADDRESS = (PROTOCOL = TCP)(HOST = stacx43.us.oracle.com)(PORT = 1521))

    if ( $line =~ /.*ADDRESS.*TCP.*PORT\s*=\s*(\d+)/) {
      $DB_PORT = $1 ;
      print "DB_PORT = $DB_PORT\n";
    }
  }
}

sub prepare_shiphome
{
  if ( $PLATFORM eq 'nt' ) {
    $label_server="??";
    $UNZIP="???";
  } 
  else {
    $label_server="/ade_autofs/ade_linux";
    $UNZIP="/usr/bin/unzip -o "; # overwrite files WITHOUT prompting
  }

  my $shiphome = $SHIPHOME;

  if ($shiphome =~ /^(RDBMS_[a-zA-Z0-9.]+_[a-zA-Z0-9]+)_([a-zA-Z0-9.]+)$/) {
    
    ($label_series, $label_date) = ($1, $2);

    # unzip <label>/install/shiphome/db.zip into the local location
    $dbzipfile = "${label_server}${DIRSEP}${label_series}.rdd${DIRSEP}${label_date}${DIRSEP}install${DIRSEP}shiphome${DIRSEP}db.zip";

    if ( ! -e $dbzipfile ) {
      print "ERROR: DB shiphome file does not exist! $dbzipfile\n";
    }
    else {
      $real_shiphome = "${AUTO_WORK}${DIRSEP}db_shiphome";
      DTE::MKDIR ($real_shiphome);
      $cmd = "$UNZIP $dbzipfile -d $real_shiphome";
      print "Running UNZIP now: $cmd\n";
      system("$cmd");
      $SHIPHOME = $real_shiphome;
      print "Now the DB shiphome is : $SHIPHOME\n";
    }
  }
}