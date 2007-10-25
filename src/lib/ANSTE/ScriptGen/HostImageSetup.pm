# Copyright (C) 2007 José Antonio Calvo Fernández <jacalvo@warp.es> 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package ANSTE::ScriptGen::HostImageSetup;

use strict;
use warnings;

use ANSTE::Scenario::Host;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidFile;

# Class: HostImageSetup
#
#   Writes the setup script for a host image (a copy of a base image) 
#   that needs to be executed with the virtual machine running.
#

# Constructor: new
#
#   Constructor for HostImageSetup class.
#
# Parameters:
#
#   host - <ANSTE::Scenario::Host> object.
#
# Returns:
#
#   A recently created <ANSTE::ScriptGen::HostImageSetup> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub new # (host) returns new HostImageSetup object
{
	my ($class, $host) = @_;
	my $self = {};

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw ANSTE::Exceptions::InvalidType('host',
                                            'ANSTE::Scenario::Host');
    }
	
	$self->{host} = $host;
    my $system = ANSTE::Config->instance()->system();

    eval("use ANSTE::System::$system");
    die "Can't load package $system: $@" if $@;

    $self->{system} = "ANSTE::System::$system"->new();

	bless($self, $class);

	return $self;
}

# Method: writeScript
#
#   Writes the script to the given file.
#
# Parameters:
#
#   file - String with the name of the file to be written.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidFile> - throw if argument is not a writable file
#
sub writeScript # (file)
{
	my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    if (not -w $file) {
        throw ANSTE::Exceptions::InvalidFile('file');
    }

	print $file "#!/bin/sh\n";
	my $name = $self->{host}->name();
	my $desc = $self->{host}->desc();
	print $file "\n# Configuration file for host $name\n";
	print $file "# Server description: $desc\n";
	print $file "# Generated by ANSTE\n\n"; 
	$self->_writePackageInstall($file);
	$self->_writeNetworkConfig($file);
}

sub _writePackageInstall # (file)
{
	my ($self, $file) = @_;

    my $system = $self->{system};
    
	print $file "# Install packages\n";
	my @packages = @{$self->{host}->packages()->list()};
    my $command = $system->installPackagesCommand(@packages);
	print $file "$command\n\n";
}

sub _writeNetworkConfig # (file)
{
	my ($self, $file) = @_;

    my $system = $self->{system};
	my $network = $self->{host}->network();

    my $config = $system->networkConfig($network);

	print $file "# Write network configuration\n";
    print $file "$config\n\n";

    print $file "# Update network configuration\n";
    my $command = $system->updateNetworkCommand();
    print $file "$command\n\n";
}

1;
