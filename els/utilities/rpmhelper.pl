#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use File::Spec;
use vars qw(%DIRECTORIES %FILES $prefix $verify_modes $verify_stamp $verbose);
$prefix = '';
$verify_modes = 0;
$verify_stamp = 0;
$verbose = 1;


=head1 NAME

rpmhelper.pl - little helper to create and test RPM files

=head1 SYNOPSIS

 rpmhelper.pl [options] [--nostamp] [--nomodes] --verify
 rpmhelper.pl [options] --diff
 rpmhelper.pl [options] --install

=head1 DESCRIPTION

This is a little helper script using while generating RPM modules
for the B<Easy Linux Server>.

=head1 VERIFY

When you execute C<do --verify> then this helper script will compare
all files in the current directory with the files in your real-life
system. This allows you to quickly find out which files have been
modified.

Oh, by the way: the above description was somewhat incorrect. The
script will read the C<*.spec> file in the current directory and
then only compares the files listed in this file with their real-life
counterparts, not just all local files.

B<Options>: with C<--stamp> the time stamps of files are also compared.
With C<--modes> the file modes are also compared.

=head1 DIFF

Once you used C<do --verify> to find out about differences you might
want to learn what differences actually do exist. This is what this
file is for.

=head1 INSTALL

You might want to opt to install all files in the current directory to
their final destination. Use C<do --install> for this.

However, when you want to install them into a "shadow" directory structure,
e.g. inside the %install section of a spec file, then call it with
C<do --prefix=/some/path --install>.

=cut

# set output unbuffered
$| = 1;

sub LoadFileList
{
    foreach (glob '*.spec') {
        print "Reading $_\n" if $verbose;
        my $infiles = 0;
        open FILE, "<$_";
        while (defined($_ = <FILE>)) {
            chomp($_);
            if (/^%files/) {
                $infiles = 1;
                next;
            }
            next unless $infiles;
            chomp;
            next if /^#/;
            next if /^\s*$/;
            next if /^%doc/;
            next if /^%if/;
            next if /^%endif/;

            #print "Before: $_\n";
            s/^%attr(.+?)\s+//;
            s/^%config\(.+?\)\s+//;
            s/^%config\s+//;
            s/^%attr(.+?)\s+//;
            s/\s+$//;
            #print "After: $_\n";

            if (/^%dir\s+(.+)/) {
                my $rights = '0755';
                my $user   = 'root';
                my $group  = 'root';
                $DIRECTORIES{$1} = [$rights, $user, $group];
                #print "$1\n";
            } else {
                $_ =~ m:^(.+)/([^/]+)$:;
                #my ($path, $file) = ($1, $2);
                #chop($path);
                #$FILES{$file} = $path;
                #print "$path   $file\n";

                $FILES{$2} = $1;
                #print "$1   $2\n";
            }
        }
        close FILE;
    }
}


sub StartClean
{
    # get rid of old installation
    if ($prefix) {
	system('rm', '-rf', $prefix);
    }
}


sub MakeDirectories
{
    foreach my $dir (keys %DIRECTORIES) {
        #system('echo', 'mkdir', '-p', "$prefix$dir");
        system('mkdir', '-p', "$prefix$dir");
	system('chmod', $DIRECTORIES{$dir}[0], "$prefix$dir");
	system('chown', $DIRECTORIES{$dir}[1], "$prefix$dir");
	system('chgrp', $DIRECTORIES{$dir}[2], "$prefix$dir");
    }
}


sub InstallFiles
{
    foreach my $source_file (keys %FILES) {
 	my $dir = $FILES{$source_file};
	my $dest_file;
	if ($dir =~ /^(.+)\s(.+)/) {
	    $dir = $1;
	    $dest_file = $2;
	} else {
	    $dest_file = $source_file;
        }

        unless (-d "$prefix$dir") {
            system('mkdir', '-p', "$prefix$dir");
        }

	system('echo', 'cp','-a', $source_file, "$prefix$dir/$dest_file") if $verbose;
	system(        'cp','-a', $source_file, "$prefix$dir/$dest_file");
    }
}


sub GetFiles
{
    foreach my $source_file (keys %FILES) {
 	my $dir = $FILES{$source_file};
	my $dest_file;
	if ($dir =~ /^(.+)\s(.+)/) {
	    $dir = $1;
	    $dest_file = $2;
	} else {
	    $dest_file = $source_file;
        }

	#system('echo', 'cp','-a', "$prefix$dir/$dest_file", $source_file);
	system('cp','-a', "$prefix$dir/$dest_file", $source_file);
    }
}


sub Install
{
    MakeDirectories;
    InstallFiles;
    exit 0;
}

sub Verify
{
    if ($prefix &&  $prefix !~ m:/$:) { $prefix = $prefix . '/'; }
    my ($smode, $dmode, $suid, $duid, $sgid, $dgid, $ssize, $dsize, $smtime, $dmtime);

    foreach my $source_file (sort keys %FILES) {
 	my $dir = $FILES{$source_file};
	my $dest_file;
	if ($dir =~ /^(.+)\s(.+)/) {
	    $dir = $1;
	    $dest_file = $2;
	} else {
	    $dest_file = $source_file;
        }

	unless (-e $source_file || -e $source_file) {
	    printf "%-35s file does not exist\n", "$source_file:";
	    next;
	}
	unless (-e "$dir/$dest_file") {
	    printf "%-35s file does not exist\n", "$dir/$dest_file:";
	    next;
	}

	($_,$_,$smode,$_,$suid,$sgid,$_,$ssize,$_,$smtime,$_,$_) = stat $source_file;
	($_,$_,$dmode,$_,$duid,$dgid,$_,$dsize,$_,$dmtime,$_,$_) = stat "$dir/$dest_file";

        if ($verify_modes && ($smode != $dmode)) {
	    printf "%-35s source has mode %o, dest has %o\n", "$dir/$dest_file:", $smode, $dmode;
	    next;
        }
        if ($suid != $duid || $sgid != $dgid) {
	    printf "%-35s source owned by %d.%d, dest by %d.%d\n", "$dir/$dest_file:", $suid, $sgid, $duid, $dgid;
	    next;
        }
        if ($ssize != $dsize) {
	    printf "%-35s source has %d bytes, dest has %d\n", "$dir/$dest_file:", $ssize, $dsize;
	    next;
        }
        if ($verify_stamp && ($smtime != $dmtime)) {
	    printf "%-35s source has timestamp %d, dest has %d\n", "$dir/$dest_file:", $smtime, $dmtime;
	    next;
        }

    }

    #
    # The following hack checks for files that are in the
    # directory, but not in the *.spec file
    #

    my %FOUND;
    foreach (glob('*'), glob('.*')) {
        next if $_ eq '.';
        next if $_ eq '..';
        next if $_ eq 'do';
        next if $_ eq 'CVS';
        next if $_ eq 'html';
        next if $_ eq 'a';
        next if $_ eq '.cvsignore';
        next if /\.spec$/;
        $FOUND{$_} = 1;
    }
    foreach (keys %FILES) {
        delete $FOUND{$_};
    }
    foreach (keys %FOUND) {
	printf "%-35s is not listed in the spec file\n", $_;
    }
    exit 0;
} 


sub Diff
{
    my ($smode, $dmode, $suid, $duid, $sgid, $dgid, $ssize, $dsize, $smtime, $dmtime);

    foreach my $source_file (sort keys %FILES) {
 	my $dir = $FILES{$source_file};
	my $dest_file;
	if ($dir =~ /^(.+)\s(.+)/) {
	    $dir = $1;
	    $dest_file = $2;
	} else {
	    $dest_file = $source_file;
        }

	next unless -e $source_file;
	next unless -e "$dir/$dest_file";

	system('diff', '-udb', "$dir/$dest_file", $source_file);
    }   
    exit 0;
} 


LoadFileList;
exit 0 if GetOptions(
	'prefix=s' => \$prefix,
	'verbose!' => \$verbose,

	'diff' => sub { Diff },

	'verify' => sub { Verify },
	'modes!' => \$verify_modes,
	'stamp!' => \$verify_stamp,

        'get' => sub { GetFiles },

	'install' => sub { Install },
);
