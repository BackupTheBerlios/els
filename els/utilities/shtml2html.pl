#!/usr/bin/perl -w

use vars qw(%vars %files);

sub Process ($)
{
   my($filename) = @_;

   open FILE, "<$filename";
   my $txt = <FILE>;
   close FILE;

   # Process #include


   $txt =~ s/<!--#include\s+file="(.*)"\s*-->\n/
      unless (defined($files{$1})) {
         open FILE, "<$1";
         $files{$1} = <FILE>;
      }
      $files{$1}
   /ge;


   # process #set
   while ($txt =~ s/<!--#set\s+var="(.+)"\s+value="(.+)"\s*-->\n//mi) {
	$vars{$1} = $2;
   }

   # process #echo
   $txt =~ s/<!--#echo\s+var="(.+)"\s*-->/$vars{$1}/gmi;

   # Change shtml links into normal ones
   $txt =~ s/\.shtml/.html/g;

   print $txt;
}


undef $/;

foreach (@ARGV) {
   Process($_);
}
