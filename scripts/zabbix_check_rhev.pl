#!/usr/bin/perl -w

#########################################################
#                                                       #
#  Name:    zabbix_check_rhev                           #
#                                                       #
#  Version: 0.1.0                                       #
#  Created: 2014-06-08                                  #
#  Last Update: 2014-06-08                              #
#  License: GPLv3 - http://www.gnu.org/licenses         #
#  Copyright: (c)2014 Zabbix check_rhev devlopment team #
#  URL: https://github.com/ovido/zabbix_check_rhev      #
#                                                       #
#########################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;
use XML::Simple;

# for debugging only
use Data::Dumper;

# Configuration
# all values can be overwritten via command line options
my $rhevm_timeout	= 15;         # default timeout
my $rhevm_api		= "/api";
my $rhevm_port		= 443;

# Variables
my $prog       = "zabbix_check_rhev";
my $version    = "0.1.0";
my $projecturl = "https://github.com/ovido/zabbix_check_rhev";
my $cookie     = "/var/tmp";   # default path to cookie file

my ($o_rhevm_host, $o_rhevm_port, $rhevm_user, $rhevm_pwd, $o_ca_file, $o_auth, $o_auth_file) = undef;
my ($o_help, $o_version, $o_timeout, $o_item) = undef;
my ($o_rhev_host, $o_rhev_vm) = undef;

# possible items
my @statistics = qw( 'memory.installed' 'memory.used' 'cpu.current.guest' 'cpu.current.hypervisor' 'cpu.current.total' );


#----------------------------------------------------------------
# The main program start here.

# parse command line options
parse_options();

if (defined $o_rhev_vm){
  # get vm id
  my $id = get_result("/vms?search=name%3D$o_rhev_vm","vm","id");
  # get item
  my $item = get_result("/vms/$id/statistics", "statistic", $o_item);
  print $item . "\n";
  exit 0;
}


#----------------------------------------------------------------

=head1 METHODS

#----------------------------------------------------------------

=head2 parse_options

=head3 SYNOPSIS

 parse_options()
 
=head3 DESCRIPTION
 
Parse command line parameters.

=cut

sub parse_options {
	
  Getopt::Long::Configure ("bundling");
  GetOptions(
    'h' 	=> \$o_help,			'help' => \$o_help,
    'H:s'	=> \$o_rhevm_host, 		'hostname:s' => \$o_rhevm_host,
    'p:i'	=> \$o_rhevm_port, 		'port:i' => \$o_rhevm_port,
    'A:s'	=> \$rhevm_api, 		'api:s' => \$rhevm_api,
    'V' 	=> \$o_version,			'version' => \$o_version,
    't:i'	=> \$rhevm_timeout,		'timeout:i' => \$rhevm_timeout,
    'a:s'	=> \$o_auth,			'authorization:s' => \$o_auth,
    'f:s'	=> \$o_auth_file,		'authfile:s' => \$o_auth_file,
    'R:s' => \$o_rhev_host, 		'host:s' => \$o_rhev_host,
    'M:s' => \$o_rhev_vm, 			'vm:s' => \$o_rhev_vm,
    'i:s'	=> \$o_item, 			'item:s' => \$o_item,
     								'ca-file:s' => \$o_ca_file,
  );

  # process options
  print_help()		if defined $o_help;
  print_version()	if defined $o_version;

  die "Host or VM is missing.\n" unless ( defined $o_rhev_host || defined $o_rhev_vm);

  # Get username and password via parameters or via file
  # format must be username@domain:password
  if (defined( $o_auth )){
    my @auth = split(/:/, $o_auth);
    die "RHEV Username/Domain is missing.\n" unless $auth[0];
    die "RHEV Password is missing.\n" unless $auth[1];
    $rhevm_user = $auth[0];
    $rhevm_pwd = $auth[1];
    my @tmp_auth = split(/@/, $auth[0]);
    die "RHEV Username is missing.\n" unless $tmp_auth[0];
    die "RHEV Domain is missing.\n" unless $tmp_auth[1];
  }else{
    die "Please provide credentials either via -a or -f option.\n" unless defined $o_auth_file;
    # get auth from file
    open (AUTHFILE, $o_auth_file) || die "Can't open auth file $o_auth_file!\n";
    while (<AUTHFILE>){
      # remove white spaces
      $_ =~ s/\s+//g;
      chomp $_;
      if ($_ =~ /^username=/){
        $rhevm_user = $_; # =~ s/username=//;
        $rhevm_user =~ s/username=//;
        my @tmp_auth = split(/@/, $rhevm_user);
        die "RHEV Username is missing.\n" unless $tmp_auth[0];
        die "RHEV Domain is missing.\n" unless $tmp_auth[1];
      }elsif ($_ =~ /^password=/){
        $rhevm_pwd = $_; # =~ s/password=//;
        $rhevm_pwd =~ s/password=//;
        die "RHEV Password is missing.\n" unless ($rhevm_pwd);
      }elsif ($_ =~ /^hostname=/){
        $o_rhevm_host = $_; # =~ s/hostname=//;
        $o_rhevm_host =~ s/hostname=//;
      }
    }
    close (AUTHFILE);
    die "Error getting values from auth file!\n" if (! $rhevm_user || ! $rhevm_pwd);
  }

  die "RHEV API Host is missing.\n" unless defined( $o_rhevm_host );

  if (defined $o_ca_file){
    die "Can't read Certificate Authority file: $o_ca_file!\n" unless -r $o_ca_file;
  }

}


#----------------------------------------------------------------

=head2 print_help

=head3 SYNOPSIS

 print_help()
 
=head3 DESCRIPTION
 
Print help text.

=cut

sub print_help(){
  print "\nRed Hat Enterprise Virtualization checks for Zabbix version $version\n";
  print "GPLv3 license, (c)2014   - Zabbix check_rhev development team\n";
  print "Usage: $0 -H <hostname> [-p <port>] -a <auth> | -f <authfile> [--ca-file <ca-file> \n";
  print "       [-A <api>] [-t <timeout>] -R <rhev host> | -M <vm> -i <item> \n";
  print <<EOT;

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -H, --hostname
    Host name or IP Address of RHEV Manager
-p, --port=INTEGER
    port number (default: $rhevm_port)
 -a, --authorization=AUTH_PAIR
    Username\@domain:password required for login to REST-API
 -f, --authfile=AUTH_FILE
    Format of file:
    username=Username\@Domain
    password=Password
    hostname=hostname.of.ovirt.server
 --ca-file=CA_FILE
    Path to RHEV CA for SSL certificate verification
 -A, --api
    REST-API path (default: $rhevm_api)
 -t, --timeout=INTEGER
    Seconds before connection times out (default: $rhevm_timeout)
 -R, --host
    RHEV Hypervisor name
 -M, --vm
    RHEV virtual machine name
 -i, --item
    Item to fetch from REST API
    see $projecturl or README for details

Send email to rkoch\@rk-it.at if you have questions regarding use
of this software. To submit patches of suggest improvements, send
email to rkoch\@rk-it.at
EOT

  exit 1;
}


#----------------------------------------------------------------

=head2 print_version

=head3 SYNOPSIS

 print_version()
 
=head3 DESCRIPTION
 
Display version of plugin and exit.

=cut

sub print_version{
  print "$prog $version\n";
  exit 1;
}


#----------------------------------------------------------------

=head2 rhev_connect

=head3 SYNOPSIS

 rhev_connect ( $api_url )
 
=item $api_url

URL of RHEV REST API
 
=head3 DESCRIPTION
 
Connect to RHEV Manager / oVirt Engine via REST-API
and fetch various values.
Returns hash.

=head3 EXAMPLE

  my $hash = rhev_connect( "https://rhevm/api" );

=cut

sub rhev_connect{

  # construct URL
  my $rhevm_url = "https://" . $o_rhevm_host . ":" . $rhevm_port . $rhevm_api . $_[0];

  # connect to REST-API
  my $ra = LWP::UserAgent->new();
     $ra->timeout($rhevm_timeout);
     $ra->env_proxy;				# read proxy information from env variables
     
  # handle no_proxy settings for old LWP::UserAgent versions
  if ((LWP::UserAgent->VERSION < 6.0) && (defined $ENV{no_proxy})){
    if ($ENV{no_proxy} =~ $o_rhevm_host){
      delete $ENV{https_proxy} if defined $ENV{https_proxy};
      delete $ENV{HTTPS_PROXY} if defined $ENV{HTTPS_PROXY};
    }
  }

  # SSL certificate verification
  if (defined $o_ca_file){
    # check certificate
    $ra->ssl_opts(verfiy_hostname => 1, SSL_ca_file => $o_ca_file);
  }else{
    # disable SSL certificate verification
    if (LWP::UserAgent->VERSION >= 6.0){
      $ra->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);     # disable SSL cert verification
    }
  }

  my $rr = HTTP::Request->new(GET => $rhevm_url);

  # cookie authentication or basic auth
  my $cf = `echo "$o_rhevm_host-$rhevm_user" | base64`;
  chomp $cf;
  $rr->header('Prefer' => 'persistent-auth');
  my $re = undef;
  # check if cookie file exists
  if (-r $cookie . "/" . $cf){
    # cookie based authentication
    my $jsessionid = `cat $cookie/$cf`;
    chomp $jsessionid;
    $rr->header('cookie' => $jsessionid);
    $re = $ra->request($rr);
    # fall back to username and password if cookie auth was not successful
    if (! $re->is_success){
      $rr->authorization_basic($rhevm_user,$rhevm_pwd);
      $re = rest_api_connect($rr, $ra, $cookie . "/" . $cf);
    }
  }else{
    # authentication with username and password
    $rr->authorization_basic($rhevm_user,$rhevm_pwd);
    $re = rest_api_connect($rr, $ra, $cookie . "/" . $cf);
  }

  my $result = eval { XMLin($re->content) };
  die "Error in XML returned from RHEVM - enable debug mode for details.\n" if $@;
  return $result;

}


#***************************************************#
#  Function: rest_api_connect                       #
#---------------------------------------------------#
#  Connect to RHEV Manager via REST-API             #
#  ARG1: HTTP::Request                              #
#  ARG2: LWP::Useragent                             #
#  ARG3: Cookie                                     #
#***************************************************#

sub rest_api_connect{
  
  my $rr = $_[0];
  my $ra = $_[1];
  my $cookie = $_[2];
  
  my $re = $ra->request($rr);
  if (! $re->is_success){   
    print "Failed to connect to RHEVM-API or received invalid response.\n"; 
    if (-f $cookie){
      unlink $cookie;
    }
    exit 1;
  }

  # write cookie into file
  # Set-Cookie is only available when connecting with username and password
  if ($re->header('Set-Cookie')){
    my @jsessionid = split/ /,$re->header('Set-Cookie');
    chop $jsessionid[0];
    if (! open COOKIE, ">$cookie"){
      die "Can't open file $cookie for writing: $!\n";
    }else{
      print COOKIE $jsessionid[0];
      close COOKIE;
      chmod (0600, $cookie);
    }
  }
  
  return $re;
  
}


#***************************************************#
# Function get_result #
#---------------------------------------------------#
# Get the requestet information from API. #
# ARG1: API path #
# ARG2: XML component #
# ARG3: result #
#***************************************************#

sub get_result{
  my $xml = $_[1];
  my $search = $_[2];
  my $rref = rhev_connect($_[0]);
  
  if ($search ne "id"){
  	return $rref->{ $xml }{ $search }{ 'values' }{ 'value' }{ 'datum' };
  }else{
    return $rref->{ $xml }{ $search };
  }
}


exit 0
