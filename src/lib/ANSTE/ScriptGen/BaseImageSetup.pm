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

package ANSTE::ScriptGen::BaseImageSetup;

use strict;
use warnings;

use ANSTE::Scenario::BaseImage;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidFile;

# Class: BaseImageSetup
#
#   Writes the setup script for a base image that needs to be
#   executed with the virtual machine running.
#

# Constructor: new
#
#   Constructor for BaseImageSetup class.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   A recently created <ANSTE::ScriptGen::BaseImageSetup> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub new # (image) returns new BaseScriptGen object
{
	my ($class, $image) = @_;
	my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exceptions::InvalidType('image',
                                            'ANSTE::Scenario::BaseImage');
    }
	
	$self->{image} = $image;
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
	my $image = $self->{image}->name();
	print $file "\n# Configuration file for image $image\n";
	print $file "# Generated by ANSTE\n\n"; 
    $self->_writePreInstall($file);
	$self->_writePackageInstall($file);
    $self->_writePostInstall($file);
    $self->_writeFirewallRules($file);
}

sub _writePreInstall # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $vars = $system->installVars();
    print $file $vars;

    my $command = $system->updatePackagesCommand();
    print $file "$command\n\n";
}

sub _writePackageInstall # (file)
{
	my ($self, $file) = @_;

    my $system = $self->{system};

	my @packages = @{$self->{image}->packages()->list()};

    if (@packages > 0) {
    	print $file "# Install packages\n";
        my $command = $system->installPackagesCommand(@packages); 
    	print $file "$command\n\n";
    }
}

sub _writePostInstall # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $command = $system->cleanPackagesCommand();

    print $file "$command\n\n";
}

sub _writeFirewallRules # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $rules = $system->firewallDefaultRules();

    print $file "# Set firewall configuration\n";
    print $file "$rules\n"
}

1;
