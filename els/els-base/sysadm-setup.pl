#!/usr/bin/perl -w

#########################################################################
#
# This file patches various configuration of Red Hat 7.2
# It establishes a nice and workable environment.
#
#########################################################################
#
# $Id: sysadm-setup.pl,v 1.7 2001/12/05 14:47:13 holgerschurig Exp $
#

use strict;
use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;



=head1 NAME

els-base.pl - system setup scriptlet engine

=head1 SYNOPSIS

  els-base.pl [options] [scriptname ..]
  els-base.pl [options] 

=head1 OPTIONS

  --quiet	don't emit progress stati
  --verbose	emit script names
  --laptop	taylor script behavior to laptop mode
  ­-server      taylor script behavior to server mode
  --all		execute all script files that can be found
  --rerun	only re-run specified script if it were run already

=head1 DESCRIPTION

This is a a script that helps you to tailer your system according to your needs.
For this, it executed little scripts that are either stored in the current
directory or in B</usr/lib/els>.

It has three modes:

=head2 Install everything

This options searches for all scripts and executes them all. You need to
specify I<--all> on the command line.

=head2 Install one specific script

Executes just one script. You need to specify the script name on the
command lnie.

=head2 Install already executed scripts again

When you execute a script using one of the first two methods then the
name of the script will be remembered. Should you wish to re-execute those
scripts, e.g. after a system update, then just run B<els-base.pl> without
and command line parameter at all. It will then only re-execute you special
choice of setup scripts.

=head2 Rerun executed installation scripts

When you specify '--rerun' then only scripts that have been executed will
be re-executed again. So you can specify savely 'sysadm-setup.pl --all --rerun'
and be sure that no yet un-approved install script will be executed.

=head1 SCRIPTS

Scripts are name B<*.script>. The head of the script should have some
comments in a special format that we will use for automatic generation
of documentation:

  #Title Short title for your script
  #Module els-base
  #Author Your name goes here
  #Desc
  # Longer description, may include paragraphs seperated by an
  # empty line.
  #DescEnd
  #Id $Id: sysadm-setup.pl,v 1.7 2001/12/05 14:47:13 holgerschurig Exp $

  perl code

  1;

The text in dollar signs after #Id will become the CVS id of your file.

Once a script has been stored in B</usr/lib/els> it will automatically
show up in the sysadm menu.

=cut


#########################################################################
#
# Setup environment
#

# First of all, we determine which version of RedHat we're running
open FILE, '/etc/redhat-release';
$_ = <FILE>;
/(\d.\d)/;
my $version = $1 || 'unknown';
unless ($version eq '7.2') {
    print "This module has only been certified for Red Hat 7.2\n";
}
my $insideanaconda = !defined $ENV{LOGNAME};
my $quiet = 0;
my $verbose = 0;
my $laptop = 0;
my $server = 0;
my $workstation = 0;
my $all = 0;
my $rerun = 0;
my $setupdir = $ENV{ELS_MENULIB} || '/usr/lib/els';

use Getopt::Long;
GetOptions('quiet' => \$quiet,
           'verbose' => \$verbose,
           'laptop' => \$laptop,
           'server' => \$server,
           'workstation' => \$workstation,
           'all' => \$all,
           'rerun' => \$rerun);
$quiet = 0 if $verbose;


# Save persistent data
loadfile '/etc/els.conf';
if    ($laptop)      { setopt 'TYPE=', '"laptop"' }
elsif ($server)      { setopt 'TYPE=', '"server"' }
elsif ($workstation) { setopt 'TYPE=', '"workstation"' }
$laptop      = (getopt('TYPE=') =~ /laptop/i);
$server      = (getopt('TYPE=') =~ /server/i);
$workstation = (getopt('TYPE=') =~ /workstation/i);
writefile;


# mark output unbuffered
$| = 1;


sub logit ($)
{
   print @_ unless $quiet;
}


sub ProcessScript($)
{
   my $file = shift;

   unless (open FILE, $file) {
      unless (open FILE, "$file.setup") {
         unless (open FILE, "$setupdir/$file") {
             unless (open FILE, "$setupdir/$file.setup") {
                 print "Setup script $file not found.\n";
                 return;
             }
         }
      }
   }

   $file =~ s{.setup$}{};


   undef $/;
   my $script = <FILE>;
   $/ = "\n";
   unless ($script =~ /#Desc/) {
      print "File $file is not a valid setup script.\n";
      return;
   }


   # Check if script has been executed already and bail out if not
   if ($rerun) {
      loadfile '/etc/els.conf';
      my $scripts = getopt('BASE_SCRIPTS=');
      return unless ($scripts =~ /$file/);
   }

   print "$file\n" if $verbose > 1;
   if (eval $script) {
      # Add executed script to configuration files
      $file =~ s:^.+/([^/]+)$:$1:;      # basename without a slow 'use ...'
      # we don't load the config file only once because there might be a slight
      # chance that the evaled script changed it:
      loadfile '/etc/els.conf';
      my $scripts = getopt('BASE_SCRIPTS=');
      unless ($scripts =~ /$file/) {
         $scripts .= ',' if $scripts;
         $scripts .= $file;
	 setopt 'BASE_SCRIPTS=', $scripts;
         writefile;
      }
   } else {
      print "Eval error $@\n";
   }
}




# Process all scripts (when --all on cmdline)
if ($all) {
   my @files = glob('*.setup') || glob("$setupdir/*.setup");
   foreach (@files) {
      ProcessScript $_;
   }
   exit;
}

# Re-Process the scripts that have been run already (when no cmdline)
if ($#ARGV == -1) {
   my $scripts = getopt('BASE_SCRIPTS=');
   if (defined $scripts && $scripts) {
      foreach (split /,/, $scripts) {
         ProcessScript $_;
      }
   }
   exit;
}

# Process all scripts named on the command line (when scriptnames on cmdline)
foreach (@ARGV) {
   ProcessScript $_;
}
