#!/usr/bin/perl -w

=head1 NAME

shtml2html.pl - convert *.shtml files into *.html

=head1 SYNOPSIS

B<shtml2html.pl> shtml-files ..

=head1 DESCRIPTION

I mostly write web-site manually, by hand. So I like simple HTML code, that
a user can understand. Yet I also like nice and nifty headers, trailers and
sidebars. So I ended up with server-site includes (SSI), also known as SHTML.

Unfortunately, many web servers are not configured to execute SSI files.
So I wrote this little tool that understands a subset of SSI, namely

  #include file="somefile"
  #set var="somevar" value="somevalue"
  #echo var="somevar"
  
It expects shtml file names on the command line, processes them and write
html files with the same name but .html as extension. These files are then
uploaded to the web server.

=cut


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
