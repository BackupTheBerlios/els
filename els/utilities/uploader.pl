#!/usr/bin/perl

=head1 NAME

uploader.pl - uploader using sftp for the Easy Linux Server

=head1 SYNOPSIS

B<uploader.pl> files ..

=head1 DESCRIPTION

This little program uploads the web site for the Easy Linux Server.
It does so by B<sftp>(1). In the file B<.uploader> it is keeping track
of the MD5 digest of files, so that only changed files will make their
way (independend of the timestamp).

=cut


use strict;
use Digest::MD5;

my $debug = 0;
my $Md5File = ".sftp-mirror";


# Parse CVSROOT so that we know how to log in
$ENV{CVSROOT} =~ /^(.+):(\/.+)$/ or
   die "CVSROOT not set.\n";

my $SshLogin = $1;
my $CvsRoot  = $2;
my %MD5;
my @Upload;

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
   
   my $olddigest = 'none';

   unless ($olddigest = $MD5{$file}) {
      print "$file: will add\n" if $debug;
      $olddigest  = 'added';
   }

   my $ctx = Digest::MD5->new;
   open FILE, "<$file" or die "File $file does not exist.\n";
   $ctx->add("tester");
   $ctx->addfile(*FILE);

   $_ = $ctx->b64digest;   
   if ($olddigest eq $_) {
      #print $olddigest, "\n", $_, "\n";
      print "$file: md5 equal\n" if $debug;
   } else {
      #print $olddigest, "\n", $_, "\n";
      print "$file: need update\n" if $debug;
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
foreach (@Upload) {
   my $file = $_;
   if ($first) {
      #open FILE, ">/dev/stdout";
      $_ = "sftp -1 -s /usr/lib/ssh/sftp-server $SshLogin";
      print "$_\n";
      open FILE, "|$_";
      print FILE "cd /home/groups/els/htdocs\n";
      $first = 0;
   }
   print FILE "put $file\n";
}
unless ($first) {
   close FILE;
}


# Write MD5s
open FILE, ">$Md5File";
foreach (keys %MD5) {
   print FILE "$_=$MD5{$_}\n";
}
