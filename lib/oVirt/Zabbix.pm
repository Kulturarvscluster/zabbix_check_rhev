#!/usr/bin/perl -w

#########################################################
#                                                       #
#  Name:    zabbix_discover_rhev                        #
#                                                       #
#  Version: 0.1.0                                       #
#  Created: 2014-07-28                                  #
#  Last Update: 2014-07-28                              #
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

package oVirt::Zabbix;

BEGIN {
    $VERSION = '1.000'; # Don't forget to set version and release
}  						# date in POD below!

use strict;
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;
use XML::Simple;
use YAML::Syck;

# for debugging only
use Data::Dumper;


sub new {
  my $invocant	= shift;
  my $class 	= ref($invocant) || $invocant;
  my %options	= @_;
    
  my $self 			= {
  	"config"		=> undef,
  	"cookie"		=> undef,
  	"auth_file"		=> undef,
  	"rhevm_timeout"	=> undef,
  	"rhevm_api"		=> undef,
  	"rhevm_port"	=> undef,
  	"rhevm_host"	=> undef,
  	"component"		=> undef,
  	"item"			=> undef,
  	"path"			=> undef,
  	"version"		=> undef,
  	"prog"			=> undef,
  };
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  # parameter validation
  # TODO!
  
  bless $self, $class;
  return $self;
}


#----------------------------------------------------------------

=head2 print_help

=head3 SYNOPSIS

 print_help( "version" => $version )
 
=item version

Version of this program.

=head3 DESCRIPTION
 
Print help text.

=head3 EXAMPLE

  print_help( "version" => "0.0.1" );

=cut

sub print_help(){

  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
	
  croak "Missing version in print_help() function." 	unless defined $self->{ 'version' };
  
  print "\nRed Hat Enterprise Virtualization checks for Zabbix version $self->{ 'version' }\n";
  print "GPLv3 license, (c)2014   - Zabbix check_rhev development team\n";
  print "Usage: $0 <hostname> <component> <name> <key>\n";
  print <<EOT;

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information

Send email to rkoch\@rk-it.at if you have questions regarding use
of this software. To submit patches of suggest improvements, send
email to rkoch\@rk-it.at
EOT

  exit 1;
}


#----------------------------------------------------------------

=head2 print_version

=head3 SYNOPSIS

 print_version( "prog" => $prog, "version" => $version )
 
=item prog

Name of this program.

=item version

Version of this program.

=head3 DESCRIPTION
 
Display version of plugin and exit.

=head3 EXAMPLE

  print_version( "prog"    => "zabbix_check_rhev3",
  				 "version" => "0.0.1" );

=cut

sub print_version{

  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
	
  croak "Missing program name in print_version() function." unless defined $self->{ 'prog' };
  croak "Missing version in print_version() function." 		unless defined $self->{ 'version' };
  
  print "$self->{ 'prog' } $self->{ 'version' }\n";
  exit 1;
}


#----------------------------------------------------------------

=head2 parse_authrc

=head3 SYNOPSIS

 parse_authrc ( "auth_file" => $authrc_file, "rhevm_host" => $rhevm_host, "rhevm_port" => $rhevm_port, "rhevm_api" => $rhevm_api, "rhevm_timeout" => $rhevm_timeout, "cookie" => $cookie )
 
=item authrc_file

Path to authrc config file

=item rhevm_host

Name of RHEV Manager host

=head3 DESCRIPTION
 
Opens an authrc config file and parses it's content.
Returns hash.

=head3 EXAMPLE

  my $config = parse_authrc( "auth_file"     => "/tmp/.authrc",
  							 "rhevm_host"    => "localhost" );

=cut

sub parse_authrc{
	
  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  croak "Missing authrc file in parse_authrc() function." 	unless defined $self->{ 'auth_file' };
  croak "Missing RHEV hostname in parse_authrc() function." unless defined $self->{ 'rhevm_host' };
  
  my $rhevm_host = $self->{ 'rhevm_host' };
  my $auth_file  = $self->{ 'auth_file' };

  # See authrc.sample for correct format
  $YAML::Syck::ImplicitTyping = 1;
  my $config = eval { LoadFile( $auth_file ) };
  croak "Failed to open/parse authrc file $auth_file.\n" if $@;
  
  # validate config file
  # missing hostname
  croak "Hostname $rhevm_host not defined in authrc file $auth_file.\n"	unless defined $config->{ $rhevm_host };
  # missing username
  croak "Missing RHEV Username.\n"	unless defined $config->{ $rhevm_host }{ 'username' };
  my @tmp_auth = split(/@/, $config->{ $rhevm_host }{ 'username' });
  croak "RHEV Username is missing.\n" unless $tmp_auth[0];
  croak "RHEV Domain is missing.\n" unless $tmp_auth[1];
  # missing password
  croak "RHEV Password is missing.\n" unless ($config->{ $rhevm_host }{ 'password' });
  
  $config->{ $rhevm_host }{ 'port' } 	= $self->{ 'port' }	  unless defined $config->{ $rhevm_host }{ 'port' };
  $config->{ $rhevm_host }{ 'api' }		= $self->{ 'api' }    unless defined $config->{ $rhevm_host }{ 'api' };
  $config->{ $rhevm_host }{ 'timeout' }	= $self->{ 'timeout'} unless defined $config->{ $rhevm_host }{ 'timeout' };
  $config->{ $rhevm_host }{ 'cookie' }	= $self->{ 'cookie'}  unless defined $config->{ $rhevm_host }{ 'cookie' };

  if (defined $config->{ $rhevm_host }{ 'ca_file' }){
    croak "Can't read Certificate Authority file: $config->{ $rhevm_host }{ 'ca_file' }!\n" unless -r $config->{ $rhevm_host }{ 'ca_file' };
  }
  
  return $config;

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
	
  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  my $rhevm_host	= "";
  foreach my $host (keys %{ $self->{ 'config' } }){
  	$rhevm_host		= $host if defined $self->{ 'config' }{ $host }{ 'username' };
  }
  
  my $rhevm_port	= $self->{ 'config' }{ $rhevm_host }{ 'port' };
  my $rhevm_api		= $self->{ 'config' }{ $rhevm_host }{ 'api' };
  my $rhevm_timeout = $self->{ 'config' }{ $rhevm_host }{ 'timeout' };
  my $rhevm_ca   	= $self->{ 'config' }{ $rhevm_host }{ 'ca_file' };
  my $rhevm_user 	= $self->{ 'config' }{ $rhevm_host }{ 'username' };
  my $rhevm_pwd  	= $self->{ 'config' }{ $rhevm_host }{ 'password' };
  my $cookie     	= $self->{ 'config' }{ $rhevm_host }{ 'cookie' };

  # construct URL
  my $rhevm_url = "https://" . $rhevm_host . ":" . $rhevm_port . $rhevm_api . $self->{ 'path' };

  # connect to REST-API
  my $ra = LWP::UserAgent->new();
     $ra->timeout($rhevm_timeout);
     $ra->env_proxy;				# read proxy information from env variables
     
  # handle no_proxy settings for old LWP::UserAgent versions
  if ((LWP::UserAgent->VERSION < 6.0) && (defined $ENV{no_proxy})){
    if ($ENV{no_proxy} =~ $rhevm_host){
      delete $ENV{https_proxy} if defined $ENV{https_proxy};
      delete $ENV{HTTPS_PROXY} if defined $ENV{HTTPS_PROXY};
    }
  }

  # SSL certificate verification
  if (defined $rhevm_ca){
    # check certificate
    $ra->ssl_opts(verfiy_hostname => 1, SSL_ca_file => $rhevm_ca);
  }else{
    # disable SSL certificate verification
    if (LWP::UserAgent->VERSION >= 6.0){
      $ra->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);     # disable SSL cert verification
    }
  }

  my $rr = HTTP::Request->new(GET => $rhevm_url);

  # cookie authentication or basic auth
  my $cf = `echo "$rhevm_host-$rhevm_user" | base64`;
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
      $re = $self->rest_api_connect($rr, $ra, $cookie . "/" . $cf);
    }
  }else{
    # authentication with username and password
    $rr->authorization_basic($rhevm_user,$rhevm_pwd);
    $re = $self->rest_api_connect($rr, $ra, $cookie . "/" . $cf);
  }

  my $result = eval { XMLin($re->content) };
  croak "Error in XML returned from RHEVM - enable debug mode for details.\n" if $@;
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


#----------------------------------------------------------------

=head2 get_result

=head3 SYNOPSIS

 get_result ( "config" => $config, "path" => $path, "component" => $component, "item" => $item )
 
=item config

Configuration options read by parse_authrc()

=item path

REST API path leading to the required component
(without /api)

=item component

XML component to parse

=item item

Item to return

=head3 DESCRIPTION
 
Get the requested information from API.
Returns string/integer value.

=head3 EXAMPLE

  Get id of vm myvm01.

  my $id = get_result( "config"    => $config,
  					   "path"      => "/vms?search=name%3Dmyvm01",
  					   "component" => "vm",
  				       "item"      => "id" );
  
  Get cpu usage of vm myvm01.
  
  my $cpu = get_result ( "config"	 => $config,
  						 "path"		 => "/vms/$id/statistics",
  						 "component" => "statistic",
  						 "item"		 => "cpu.current-guest" );
  
=cut

sub get_result{

  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }

  croak "Missing config in get_result() function." 	  unless defined $self->{ 'config' };
  croak "Missing path in get_result() function." 	  unless defined $self->{ 'path' };
  croak "Missing component in get_result() function." unless defined $self->{ 'component' };
  croak "Missing item in get_result() function." 	  unless defined $self->{ 'item' };
  
  my $rref = $self->rhev_connect();
  
  if ($self->{ 'item' } ne "id"){
  	return $rref->{ $self->{ 'component' } }{ $self->{ 'item' } }{ 'values' }{ 'value' }{ 'datum' };
  }else{
    return $rref->{ $self->{ 'component' } }{ $self->{ 'item' } };
  }
  
}


#----------------------------------------------------------------

=head2 get_result

=head3 SYNOPSIS

 get_result ( "config" => $config, "path" => $path, "component" => $component, "item" => $item )
 
=item config

Configuration options read by parse_authrc()

=item path

REST API path leading to the required component
(without /api)

=item component

XML component to parse

=item item

Item to return

=head3 DESCRIPTION
 
Get the requested information from API.
Returns string/integer value.

=head3 EXAMPLE

  Get id of vm myvm01.

  my $id = get_result( "config"    => $config,
  					   "path"      => "/vms?search=name%3Dmyvm01",
  					   "component" => "vm",
  				       "item"      => "id" );
  
  Get cpu usage of vm myvm01.
  
  my $cpu = get_result ( "config"	 => $config,
  						 "path"		 => "/vms/$id/statistics",
  						 "component" => "statistic",
  						 "item"		 => "cpu.current-guest" );
  
=cut

sub get_vms{

  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }

  croak "Missing config in get_result() function." 	  unless defined $self->{ 'config' };
  croak "Missing path in get_result() function." 	  unless defined $self->{ 'path' };
  
  my $rref = $self->rhev_connect();
  
  my $vms = {};
  my $clusters = {};
  my $datacenters = {};
  
  foreach my $vm_name (keys %{ $rref->{ 'vm' } }){
  	$vms->{ $vm_name }{ 'name' } = $vm_name;
  	$vms->{ $vm_name }{ 'id' } = $rref->{ 'vm' }{ $vm_name }{ 'id' };
  	
  	# use cached cluster name if available
  	if (! defined $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }){
  	  # get cluster name
  	  $self->{ 'path' } = $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'href' };
  	  $self->{ 'path' } =~ s/\/api//g;
  	  my $cref = $self->rhev_connect();
  	  # store cluster name in hash
  	  $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'name' } = $cref->{ 'name' };
  	  $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'data_center' } = $cref->{ 'data_center' }{ 'id' };
  	}
  	$vms->{ $vm_name }{ 'cluster' } = $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'name' };
  	
  	# use cached datacenter name if available
  	if (! defined $datacenters->{ $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'data_center' } }){
  	  # get datacenter name
  	  $self->{ 'path' } = "/datacenters/" . $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'data_center' };
  	  my $dref = $self->rhev_connect();
  	  # store datacenter name in hash
  	  $datacenters->{ $dref->{ 'id' } }{ 'name' } = $dref->{ 'name' };
  	}
    $vms->{ $vm_name }{ 'datacenter' } = $datacenters->{ $clusters->{ $rref->{ 'vm' }{ $vm_name }{ 'cluster' }{ 'id' } }{ 'data_center' } }{ 'name' };

  }
 
  return $vms;
  
}


1;


=head1 EXAMPLES

TODO

=head1 SEE ALSO

TODO

=head1 AUTHOR

Rene Koch, E<lt>rkoch@rk-it.atE<gt>

=head1 VERSION

Version 1.000  (July 28 2014))

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Zabbix check_rhev development team

This library is free software; you can redistribute it and/or modify
it under the same terms as zabbix_check_rhev itself.

=cut

