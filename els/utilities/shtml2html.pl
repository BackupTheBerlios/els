#!/usr/bin/perl -w

#
# I wrote the web site manually, by hand. I only use the *.inc and *.shtml files
# for contents. A local running Apache handles the server-site-include scripts,
# so I can directly view the files from the browser.
#
# However, most web-servers don't have server-site include scripts enabled. So
# a little tool 'makehtml.pl' takes the *.shtml files, executes a limited set
# of SSI commands (#include, #set and #echo) and omits the result. These *.html
# files are then sent to the webserver.
#

use vars qw(%vars %files);

sub Process ($)
{
   my($filename) = @_;

   open FILE, "<$filename";
   my $txt = <FILE>;
   close FILE;

   # process #include
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
