#!/usr/local/bin/perl
#
#    NAME
#      idmConfigTool_configOAM_4OIM_single_domain.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      for single domain.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    Lancer Guo  06/24/13
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

# from import list, we shall get the following information
$HOSTNAME="%HOST%";
$ORACLE_HOME="%ORACLE_HOME%";
$MW_HOME="%MW_HOME%";
$JAVA_HOME="%JAVA_HOME%";
$WLS_DOMAIN_HOME="%WLS_DOMAIN_HOME%";
$WLS_HOSTNAME="%WLS_HOSTNAME%";
$WLS_CONSOLE_PORT="%WLS_CONSOLE_PORT%";
$WLS_USER="%WLS_USER%";
$WLS_PWD="%WLS_PWD%";
$IDSTORE_HOST="%IDSTORE_HOST%";
$IDSTORE_PORT="%IDSTORE_PORT%";
$IDSTORE_DIRECTORYTYPE="%IDSTORE_DIRECTORYTYPE%";
$IDSTORE_BINDDN="%IDSTORE_BINDDN%";
$IDSTORE_USERSEARCHBASE="%IDSTORE_USERSEARCHBASE%";
$IDSTORE_SEARCHBASE="%IDSTORE_SEARCHBASE%";
$IDSTORE_GROUPSEARCHBASE="%IDSTORE_GROUPSEARCHBASE%";
$OAM_HOSTNAME="%OAM_HOSTNAME%";
$ACCESS_PORT="%ACCESS_PORT%";
$ACCESS_GATE_ID="%ACCESS_GATE_ID%";
$OHS_PORT="%OHS_PORT%";
$OAM11G_OIM_WEBGATE_PASSWD="%OAM11G_OIM_WEBGATE_PASSWD%";
$OAM11G_SERVER_LBR_HOST="%OAM11G_SERVER_LBR_HOST%";
$OAM11G_SERVER_LBR_PORT="%OAM11G_SERVER_LBR_PORT%";
$OHS_HOSTNAME="%OHS_HOSTNAME%";
$COOKIE_DOMAIN="%COOKIE_DOMAIN%";

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

parse_import_file();
parse_runtime_file();
set_platform_info();
process_tokens();
if ($PLATFORM eq 'nt')
 {
  $WLST_CMD = "wlst.cmd";
  $LDAP_CMD = "LDAPConfigPostSetup.bat";
  $IDM_CMD = "idmConfigTool.bat";
  $COPY_CMD = "COPY";
  $MOVE_CMD = "MOVE";
 }
else
 {
  $WLST_CMD = "wlst.sh";
  $LDAP_CMD = "LDAPConfigPostSetup.sh";
  $IDM_CMD = "idmConfigTool.sh";
  $COPY_CMD = "cp";
  $MOVE_CMD = "mv";
 }
gen_input_file_config_oam_4oim();
run_idm_config_tool_config_oam();
change_ldap_provider_from_oid_to_ovd();
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
      elsif ($token eq "ORACLE_HOME" ) {
        $ORACLE_HOME = $value;
      }
      elsif ($token eq "MW_HOME" ) {
        $MW_HOME = $value;
      }
      elsif ($token eq "JAVA_HOME" ) {
        $JAVA_HOME = $value;
      }
      elsif ($token eq "WLS_DOMAIN_HOME" ) {
        $WLS_DOMAIN_HOME = $value;
      }
      elsif ($token eq "WLS_HOSTNAME" ) {
        $WLS_HOSTNAME = $value;
      }
            elsif ($token eq "WLS_CONSOLE_PORT" ) {
        $WLS_CONSOLE_PORT = $value;
      }
      elsif ($token eq "WLS_USER" ) {
        $WLS_USER = $value;
      }
      elsif ($token eq "WLS_PWD" ) {
        $WLS_PWD = $value;
      }
      elsif ($token eq "IDSTORE_HOST" ) {
        $IDSTORE_HOST = $value;
      }
      elsif ($token eq "IDSTORE_PORT") {
		$IDSTORE_PORT = $value;
      }
      elsif ($token eq "IDSTORE_DIRECTORYTYPE" ) {
        $IDSTORE_DIRECTORYTYPE = $value;
      }
      elsif ($token eq "IDSTORE_BINDDN" ) {
        $IDSTORE_BINDDN = $value;
      }
      elsif ($token eq "IDSTORE_USERSEARCHBASE" ) {
        $IDSTORE_USERSEARCHBASE = $value;
      }
      elsif ($token eq "IDSTORE_SEARCHBASE" ) {
        $IDSTORE_SEARCHBASE = $value;
      }
      elsif ($token eq "IDSTORE_GROUPSEARCHBASE" ) {
        $IDSTORE_GROUPSEARCHBASE = $value;
      }
      elsif ($token eq "OAM_HOSTNAME" ) {
        $OAM_HOSTNAME = $value;
      }
      elsif ($token eq "ACCESS_PORT" ) {
        $ACCESS_PORT = $value;
      }
      elsif ($token eq "ACCESS_GATE_ID" ) {
        $ACCESS_GATE_ID = $value;
      }
      elsif ($token eq "OHS_PORT" ) {
        $OHS_PORT = $value;
      }
      elsif ($token eq "OAM11G_OIM_WEBGATE_PASSWD" ) {
        $OAM11G_OIM_WEBGATE_PASSWD = $value;
      }
      elsif ($token eq "OAM11G_SERVER_LBR_HOST" ) {
        $OAM11G_SERVER_LBR_HOST = $value;
      }
      elsif ($token eq "OAM11G_SERVER_LBR_PORT" ) {
        $OAM11G_SERVER_LBR_PORT = $value;
      }
      elsif ($token eq "OHS_HOSTNAME" ) {
        $OHS_HOSTNAME = $value;
      }
       elsif ($token eq "COOKIE_DOMAIN" ) {
        $COOKIE_DOMAIN = $value;
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
  if ( $WLS_DOMAIN_HOME eq "%WLS_DOMAIN_HOME%" || $WLS_DOMAIN_HOME eq "" ) {
	$WLS_DOMAIN_HOME = "${MW_HOME}${DIRSEP}user_projects${DIRSEP}domains${DIRSEP}WLS_IDM";
  }

  if ( $WLS_USER eq "%WLS_USER%" || $WLS_USER eq "" ) {
	$WLS_USER = "weblogic";
  }

  if ( $WLS_PWD eq "%WLS_PWD%" || $WLS_PWD eq "" ) {
	$WLS_PWD = "welcome1";
  }

  if ( $IDSTORE_BINDDN eq "%IDSTORE_BINDDN%" || $IDSTORE_BINDDN eq "" ) {
	$IDSTORE_BINDDN = "cn=orcladmin";
  }

  if ( $IDSTORE_USERSEARCHBASE eq "%IDSTORE_USERSEARCHBASE%" || $IDSTORE_USERSEARCHBASE eq "" ) {
	$IDSTORE_USERSEARCHBASE = "cn=Users,dc=us,dc=oracle,dc=com";
  }

  if ( $IDSTORE_SEARCHBASE eq "%IDSTORE_SEARCHBASE%" || $IDSTORE_SEARCHBASE eq "" ) {
	$IDSTORE_SEARCHBASE = "dc=us,dc=oracle,dc=com";
  }

  if ( $IDSTORE_GROUPSEARCHBASE eq "%IDSTORE_GROUPSEARCHBASE%" || $IDSTORE_GROUPSEARCHBASE eq "" ) {
	$IDSTORE_GROUPSEARCHBASE = "cn=Groups,dc=us,dc=oracle,dc=com";
  }

  if ( $ACCESS_PORT eq "%ACCESS_PORT%" || $ACCESS_PORT eq "" ) {
	$ACCESS_PORT = "5575";
  }

  if ( $ACCESS_GATE_ID eq "%ACCESS_GATE_ID%" || $ACCESS_GATE_ID eq "" ) {
	$ACCESS_GATE_ID = "WG10g_IDM";
  }

  if ( $OAM11G_OIM_WEBGATE_PASSWD eq "%OAM11G_OIM_WEBGATE_PASSWD%" || $OAM11G_OIM_WEBGATE_PASSWD eq "" ) {
	$OAM11G_OIM_WEBGATE_PASSWD = "welcome1";
  }

  if ( $OAM11G_SERVER_LBR_HOST eq "%OAM11G_SERVER_LBR_HOST%" || $OAM11G_SERVER_LBR_HOST eq "" ) {
	$OAM11G_SERVER_LBR_HOST = "${OAM_HOSTNAME}";
  }

  if ( $OHS_HOSTNAME eq "%OHS_HOSTNAME%" || $OHS_HOSTNAME eq "" ) {
	$OHS_HOSTNAME = "${OAM_HOSTNAME}";
  }

  if ( $OHS_PORT eq "%OHS_PORT%" || $OHS_HOSTNAME eq "" ) {
	$OHS_PORT = "7777";
  }

  if ( $COOKIE_DOMAIN eq "%COOKIE_DOMAIN%" || $COOKIE_DOMAIN eq "" ) {
	$COOKIE_DOMAIN = ".us.oracle.com";
  }

}

sub printMessage
{
    print @_;
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
    close (EXPFILE);
  }
}

sub gen_input_file_config_oam_4oim
{
		chdir("${WORKDIR}${DIRSEP}");
		printMessage ("Now the current dir is " . getcwd() . "\n");

		$input_file_config_oam_4oim = "${WORKDIR}${DIRSEP}configOAM.4OIM.config";

		if ( ! open(OFILE, "> $input_file_config_oam_4oim" ) ) 
		{
			print "\nCannot write to output file: $input_file_config_oam_4oim\n";
			$exit_value = 1;
		}
	        print OFILE "###configOAM4OIM\n";
			print OFILE "WLSHOST: $WLS_HOSTNAME\n";
			print OFILE "WLSPORT: $WLS_CONSOLE_PORT\n";
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
			print OFILE "IDSTORE_SYSTEMIDBASE: cn=systemids,dc=us,dc=oracle,dc=com\n";
			print OFILE "POLICYSTORE_SHARES_IDSTORE: true\n";
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
			print OFILE "OAM11G_OIM_INTEGRATION_REQ: true\n";
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

sub run_idm_config_tool_config_oam
{
        $ENV{'ORACLE_HOME'} = $ORACLE_HOME;
        $ENV{'MW_HOME'} = $MW_HOME;
        $ENV{'JAVA_HOME'} = $JAVA_HOME;

        printMessage ("ORACLE_HOME = $ENV{'ORACLE_HOME'}\n");
        printMessage ("MW_HOME = $ENV{'MW_HOME'}\n");
        printMessage ("JAVA_HOME = $ENV{'JAVA_HOME'}\n");
        
        $script_config_oam_4oim = "${WORKDIR}${DIRSEP}script_config_oam_4oim.cfg";
		if ( ! open (FILE, ">$script_config_oam_4oim") )
		{
			print "ERROR: failed to write to $script_config_oam_4oim\n";
			$exit_value = 1;
		}
	  	else
	  	{
	    	print FILE "#!/usr/bin/expect -f\n";
		    print FILE "spawn ${ORACLE_HOME}${DIRSEP}idmtools${DIRSEP}bin${DIRSEP}${IDM_CMD} -configOAM input_file=${input_file_config_oam_4oim} log_level=ALL log_file=${WORKDIR}${DIRSEP}configOAM.4OIM.out dump_params=true\n";
		    print FILE "set timeout 30\n";
		    print FILE "expect {\n";
		    print FILE "  -timeout 60\n";
		    print FILE "  \"Enter ID Store Bind DN password :\" { send \"welcome1\\r\"; exp_continue }\n";
		    print FILE "  \"Enter User Password for IDSTORE_PWD_OAMSOFTWAREUSER:\" { send \"welcome1\\r\"; exp_continue }\n";
		    print FILE "  \"Confirm User Password for IDSTORE_PWD_OAMSOFTWAREUSER:\" { send \"welcome1\\r\"; exp_continue }\n";
		    print FILE "  \"Enter User Password for IDSTORE_PWD_OAMADMINUSER:\" { send \"welcome1\\r\"; exp_continue }\n";
		    print FILE "  \"Confirm User Password for IDSTORE_PWD_OAMADMINUSER:\" { send \"welcome1\\r\"; exp_continue }\n";
		    print FILE "  timeout { puts \"timeout exit\"; return }\n";
		    print FILE "  eof { puts \" \$expect_out(buffer) system prompt match! successfully exit\"; return }\n";
		    print FILE "  }\n";
		    close (FILE);
		    runSystem("chmod 755 $script_config_oam_4oim");
		    runSystem($script_config_oam_4oim);
		  }
}

sub change_ldap_provider_from_oid_to_ovd
{
		chdir("${WLS_DOMAIN_HOME}${DIRSEP}config${DIRSEP}fmwconfig");
		printMessage ("Now the current dir is " . getcwd() . "\n");
  		runSystem("${COPY_CMD} oam-config.xml oam-config.xml.org.auto");
  		
		$oam_config_xml = "${WLS_DOMAIN_HOME}${DIRSEP}config${DIRSEP}fmwconfig${DIRSEP}oam-config.xml";
		printMessage("oam-config.xml is $oam_config_xml");
	
  		if ( ! open(HND, "$oam_config_xml" ) ) {
			print "\nCan't open $oam_config_xml: $!\n";
			$exit_value = 1;
		} 	
	  		@fileArr = <HND>;
	  		close(HND);

  		foreach my $line ( @fileArr ) {
        	$line =~ s/<Setting Name="LDAP_PROVIDER" Type="xsd:string">OID/<Setting Name="LDAP_PROVIDER" Type="xsd:string">OVD/g;
  		}
  		
  		if ( ! open(HND, "> $oam_config_xml" ) ) {
			print "\nCant open for writing $oam_config_xml: $!\n";
			$exit_value = 1;
		} 
			print HND @fileArr;
			close(HND);	 		
}

