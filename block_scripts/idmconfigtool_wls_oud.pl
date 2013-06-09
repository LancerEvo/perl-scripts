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
$IDM_HOME="%IDM_HOME%";
$JAVA_HOME="%JAVA_HOME%";
$MW_HOME="%MW_HOME%";
$WLPORT="%WLPORT%";
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
$EXIT_STATUS="FAILURE"; 
$tiastopo_tsc="";
$tiastopo_prp="";
$SHUTDOWN_SCRIPT="";

# the exit_value for this program
$exit_value=0;

parse_import_file();
parse_runtime_file();
parse_tiastopo_file();
install();
print_test_parameter();
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
      if($tmp_token[0] eq "HOSTNAME" ) {
        $HOSTNAME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "TIASTOPO" ) {
        $TIASTOPO = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "IDM_HOME" ) {
        $IDM_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OUD_PORT" ) {
        $OUD_PORT = $tmp_token[1];
        #use default value
        if($OUD_PORT eq "") {
              $OUD_PORT = 1389;
	  	}
      }
      elsif ($tmp_token[0] eq "OUD_ADMIN_PORT" ) {
        $OUD_ADMIN_PORT = $tmp_token[1];
        #use default value
        if($OUD_ADMIN_PORT eq "") {
              $OUD_ADMIN_PORT = 1444;
        }
      }
      elsif ($tmp_token[0] eq "JAVA_HOME" ) {
        $JAVA_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "MW_HOME" ) {
        $MW_HOME = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OUD_HOST" ) {
        $OUD_HOST = $tmp_token[1];
      }
      elsif ($tmp_token[0] eq "OUD_INSTANCE_HOME" ) {
		$OUD_INSTANCE_HOME = $tmp_token[1];
      }
      else {
		; # ignored
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
    print FILE "IDSTORE_PASSWD : welcome1\n"; 
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";
    close (FILE);
  } 
  return $InputFileGen_prepareIDStore_OIM;
}

sub InputFileGen_prepareIDStore_WLS
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_prepareIDStore_WLS = "${WORKDIR}${DIRSEP}InputFileGen_prepareIDStore_WLS.conf";

  if ( ! open (FILE, ">$InputFileGen_prepareIDStore_WLS") )
  {
    print "ERROR: failed to write to $InputFileGen_prepareIDStore_WLS\n";
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
    print FILE "IDSTORE_WLSADMINUSER: weblogic_idm\n";
    print FILE "IDSTORE_WLSADMINGROUP: wlsadmingroup\n";
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";

    close (FILE);
  }
  return $InputFileGen_prepareIDStore_WLS;
}

sub InputFileGen_prepareIDStore_fusion
{
  my ($operation, $MSname) = (@_);

  $InputFileGen_prepareIDStore_fusion = "${WORKDIR}${DIRSEP}InputFileGen_prepareIDStore_fusion.conf";

  if ( ! open (FILE, ">$InputFileGen_prepareIDStore_fusion") )
  {
    print "ERROR: failed to write to $InputFileGen_prepareIDStore_fusion\n";
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
    print FILE "IDSTORE_READONLYUSER: IDROUser\n";
    print FILE "IDSTORE_READWRITEUSER: IDRWUser\n";
    print FILE "IDSTORE_SUPERUSER: weblogic_fa\n";
    print FILE "IDSTORE_ADMIN_PORT: $OUD_ADMIN_PORT\n";
    print FILE "IDSTORE_KEYSTORE_FILE: $IDSTORE_KEYSTORE_FILE\n";
    print FILE "IDSTORE_KEYSTORE_PASSWORD: $IDSTORE_KEYSTORE_PASSWORD\n";

    close (FILE);
  }
  return $InputFileGen_prepareIDStore_fusion;
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

sub ScriptGen_prepareIDStore_WLS
{
  my ($operation, $MSname) = (@_);

  $ScriptGen_prepareIDStore_WLS = "${WORKDIR}${DIRSEP}ScriptGen_prepareIDStore_WLS.cfg";

  if ( ! open (FILE, ">$ScriptGen_prepareIDStore_WLS") )
  {
    print "ERROR: failed to write to $ScriptGen_prepareIDStore_WLS\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -prepareIDStore mode=WLS input_file=$InputFileGen_prepareIDStore_WLS log_level=ALL log_file=${WORKDIR}${DIRSEP}prepareIDStore_WLS.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for weblogic_idm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for weblogic_idm:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit prepareIDStore_WLS!!\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $ScriptGen_prepareIDStore_WLS`
  }
  return $ScriptGen_prepareIDStore_WLS;
}

sub ScriptGen_prepareIDStore_fusion
{
  my ($operation, $MSname) = (@_);

  $ScriptGen_prepareIDStore_fusion = "${WORKDIR}${DIRSEP}ScriptGen_prepareIDStore_fusion.cfg";

  if ( ! open (FILE, ">$ScriptGen_prepareIDStore_fusion") )
  {
    print "ERROR: failed to write to $ScriptGen_prepareIDStore_fusion\n";
    $exit_value = 1;
  }
  else
  {
    print FILE "#!/usr/bin/expect -f\n";
    print FILE "spawn $IDM_HOME/idmtools/bin/idmConfigTool.sh -prepareIDStore mode=fusion input_file=$InputFileGen_prepareIDStore_fusion log_level=ALL log_file=${WORKDIR}${DIRSEP}prepareIDStore_fusion.out dump_params=true\n";
    print FILE "set timeout -1\n";
    print FILE "expect {\n";
    print FILE "  -timeout -1\n";
    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for IDROUser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for IDROUser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for IDRWUser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for IDRWUser:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Enter User Password for weblogic_fa:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  \"Confirm User Password for weblogic_fa:\" { send \"Welcome1\\r\"; exp_continue }\n";
    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit prepareIDStore_fusion!!\"; return }\n";
    print FILE "  }\n";
    close (FILE);
    `chmod 755 $ScriptGen_prepareIDStore_fusion`
  }
  return $ScriptGen_prepareIDStore_fusion;
}

sub print_test_parameter
{
  print "###################################################################\n";
  print "$OVD_PORT \n";
  print "$ODSM_PORT\n";
  print "$DIP_PORT\n";
  print "$OIF_PORT\n";
  print "$ENV{PATH}\n";
  print "$ENV{JAVA_HOME}\n";  
  $cmd3 = '$JAVA_HOME';
  $info = `echo $cmd3`;
  print "!!!!!uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu!!!!!!!$info\n";
  
  $ResultIDM = `$script_Idmconfigtool`; 
  print "==========================================================\n";
  print "&&&&&&&&&&&&&Below is the result for Idmtool for config policy store !&&&&&&&&&&&&&&  $ResultIDM \n";
  print "&&&&&&&&&&&&&Below is the result for wlst associate !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_wlstSecurityAssociate \n";
  $Result_preconfigIDstore = `$script_preConfigIDStore`;
  print "==========================================================";
  print "&&&&&&&&&&&&&Below is the result for Result_preconfigIDstore !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_preconfigIDstore \n";
  $Result_prepareIDstore_OIM = `$ScriptGen_prepareIDStore_OIM`;
  print "==========================================================";
  print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_OIM !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_OIM \n";
  $Result_prepareIDstore_WLS = `$ScriptGen_prepareIDStore_WLS`;
  print "==========================================================";
  print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_WLS !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_WLS \n";
  $Result_prepareIDstore_fusion = `$ScriptGen_prepareIDStore_fusion`;
  print "==========================================================";
  print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_fusion !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_fusion \n";
  $Result_prepareIDstore_OAM = `$ScriptGen_prepareIDStore_OAM`;
  print "==========================================================";
  print "&&&&&&&&&&&&&Below is the result for Result_prepareIDstore_OAM !&&&&&&&&&&&&&&&&&&&&&&&&&&&&    $Result_prepareIDstore_OAM \n";
  sleep 30;
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

  getKeystoreFileAndKeystorePassword();
  unset_unwanted_env_variables();
  InputFileGen_preConfigIDStore();
  InputFileGen_prepareIDStore_OAM();
  InputFileGen_prepareIDStore_OIM();
  InputFileGen_prepareIDStore_WLS();
  InputFileGen_prepareIDStore_fusion();
  
  IDMconfigScriptGen_preConfigIDStore();
  ScriptGen_prepareIDStore_OAM();
  ScriptGen_prepareIDStore_OIM();
  ScriptGen_prepareIDStore_WLS();
  ScriptGen_prepareIDStore_fusion();
  
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

sub populate_export_file
{
  if ($exit_value == 0){
    $EXIT_STATUS = "SUCCESS";
  }

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

sub preInstallAction
{
  print "Sorry, preInstallAction is not supported for now !\n";
}

#############################################################################
# postInstallAction can be a simple perl or java executable in the format
#  of [<interpreter language>][<full path of executable>][<extra params>].
#  For example:
#        [perl][%AUTO_HOME%scripts/ias/10.1.3.0.0/my_post_act.pl]
#        [java][%ADE_VIEW_ROOT%ias/utl/my_post_act.jar][abc def]
#  During runtime, token AUTO_HOME and ADE_VIEW_ROOT will be replaced based
#  on run time environment and the postInstallAction is called as follows:
#     <lang> <full path of executable> <tiastopo.prp> <extra params> 
#  For example:
#    perl /scratch/aime/auto/scripts/ias/10.1.3.0.0/my_post_act.pl tiastopo.prp
#############################################################################
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

sub unset_unwanted_env_variables
{
   # the following env variable might fail OUI silent install
   delete $ENV{ORACLE_HOME};
   delete $ENV{JAVA_HOME};
   delete $ENV{MW_HOME};
   $ENV{JAVA_HOME} = $JAVA_HOME;
   $ENV{MW_HOME} = $MW_HOME;
   $ENV{ORACLE_HOME} = $IDM_HOME;

   my $envDump = "${WORKDIR}${DIRSEP}preInstallEnv.txt";
   print "Dump ENV to file $envDump right before OUI install\n";
   DTE::dumpEnvFile($envDump);
}
