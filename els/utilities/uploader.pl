#!/usr/bin/perl

=head1 NAME

uploader.pl - uploader using sftp for the Easy Linux Server

=head1 SYNOPSIS

  B<uploader.pl> [--homedir=dir] [--subdir=dir ] [--login=login] files..

=head1 DESCRIPTION

This little program uploads the web site for the Easy Linux Server.
It does so by B<sftp>(1). In the file B<.uploader> it is keeping track
of the MD5 digest of files, so that only changed files will make their
way (independend of the timestamp).

 B<--homedir>  home dir to use, overwrites HTMLBASE environment variable

 B<--subdir>   subdir to use

 B<--login>    username@host use for SSH, overwrites SSHLOGIN

=cut


use strict;
use Digest::MD5;
use Getopt::Long;

my $Md5File  = ".uploader";
my $HomeDir  = $ENV{HTMLBASE} || "/home/groups/els/htdocs";
my $SubDir   = '';
my $SshLogin = $ENV{SSHLOGIN} || '';
my $Debug = 0;

GetOptions("homedir=s", \$HomeDir,
	   "subdir=s",  \$SubDir,
	   "login=s",   \$SshLogin,
	   "debug",     \$Debug);

$HomeDir = "$HomeDir/$SubDir" if $SubDir;

my %MD5;
my @Upload;

$| = 1;		# unbuffered io

# Read list of all known files
if (open FILE, "<$Md5File") {
   while (defined ($_ = <FILE>)) {
      chomp($_);
      $MD5{$1} = $2 if $_ =~ /(^.+?)=(.+)/;
   }
}



sub MirrorFile ($)
{
   my $file = shift;
   
   if ($file =~ m:/:) {
      die "Please specify only files, not paths: $file\n";
   }
   return if $file =~ m:\*:;

   my $olddigest = 'none';

   unless ($olddigest = $MD5{$file}) {
      print "$file: will add\n" if $Debug > 1;
      $olddigest  = 'added';
   }

   my $ctx = Digest::MD5->new;
   open FILE, "<$file" or die "File $file does not exist.\n";
   $ctx->add("tester");
   $ctx->addfile(*FILE);

   $_ = $ctx->b64digest;   
   if ($olddigest eq $_) {
      #print $olddigest, "\n", $_, "\n";
      print "$file: md5 equal\n" if $Debug > 1;
   } else {
      #print $olddigest, "\n", $_, "\n";
      print "$file: need update\n" if $Debug > 1;
      push @Upload, $file;
      $MD5{$file} = $_;
   }
}



# Process all files
foreach (@ARGV) {
   MirrorFile $_;
}


# Upload all changed files
my $first = 1;
foreach (sort @Upload) {
   my $file = $_;
   if ($first) {
      open FILE, ">/dev/stdout" if $Debug;
      $_ = "sftp -1 -s /usr/lib/ssh/sftp-server $SshLogin";
      print "$_\n";
      open FILE, $Debug ? ">/dev/stdout" : "|$_ >/dev/null";
      print FILE "cd $HomeDir\n";
      $first = 0;
   }

   print STDERR "put $file\n";
   print FILE "put $file\n";
}
close FILE unless $first;


exit if $Debug;

# Write MD5s
open FILE, ">$Md5File";
foreach (keys %MD5) {
   print FILE "$_=$MD5{$_}\n";
}
