#!/usr/bin/perl -w

#########################################################################
#
# This file patches various configuration of Red Hat 7.2
# It establishes a nice and workable environment.
#
#########################################################################

use strict;
use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;



#########################################################################
#
# Setup environment
#

# First of all, we determine which version of RedHat we're running
open FILE, '/etc/redhat-release';
$_ = <FILE>;
/(\d.\d)/;
my $version = $1;
unless ($version eq '7.2') {
    die "This module has not been certified for Red Hat $version\n";
}
my $insideanaconda = !defined $ENV{LOGNAME};
my $force = 0;
my $quiet = 0;
my $laptop = 0;
my $server = 0;

use Getopt::Long;
GetOptions('force' => \$force,
           'quiet' => \$quiet,
           'laptop' => \$laptop,
           'server' => \$server);

# Save persistent data
loadfile '/etc/sysconfig/rc.sysadm';
if    ($laptop) { setopt 'TYPE=', '"laptop"' }
elsif ($server) { setopt 'TYPE=', '"server"' }
$laptop = (getopt('TYPE=') =~ /laptop/i);
$server = (getopt('TYPE=') =~ /server/i);
#writefile;


# mark output unbuffered
$| = 1;


sub logit ($)
{
   print @_ unless $quiet;
}


my $file;
foreach $file (@ARGV) {
   unless (open FILE, $file) {
      print "File $file not found.\n";
      next;
   }
   undef $/;
   my $script = <FILE>;
   $/ = "\n";
   unless ($script =~ /#Desc/) {
      print "File $file is not a valid setup script.\n";
      next;
   }
   unless (eval $script) {
      print "Eval error $@\n";
   }
}
