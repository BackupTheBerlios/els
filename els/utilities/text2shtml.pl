#!/usr/bin/perl -w

=head1 NAME

txt2html.pl - Text to HTML

=head1 SYNOPSIS

B<txt2html.pl> files...

Converts a text file that is formatted like the README file into
a shtml file.

=cut

use strict;

sub ProcessFile ($)
{
    my $fname = shift;

    open FILE, "<$fname" or die "$!\n";
    undef $/;

    my $lines = <FILE>;
    $lines = "\n$lines\n";

    $lines =~ s{\n(.+?)\n=+\n}{\n<H2>$1</H2>\n\n}g;
    $lines =~ s{\n(.+?)\n-+\n}{\n<H3>$1</H3>\n\n}g;
    $lines =~ s{\n-\s+(.+?)}{\n<LI>$1}g;
    $lines =~ s{\n\n<LI>}{\n\n<UL>\n<LI>}g;
    $lines =~ s{<LI>(.+?)\n\n}{<LI>$1\n</UL>\n\n}g;
    $lines =~ s{\n\n\n}{\n\n}g;
    $lines =~ s{\n\n([^<\n])}{\n<P>\n$1}g;
    $lines =~ s{([^>])\n\n}{$1\n</P>\n}g;
    $lines =~ s{([^>])\n<P>\n}{$1\n</P><P>\n}g;
    $lines =~ s{^\s+}{}g;
    $lines =~ s{\s+$}{}g;

    print "$lines\n";
}


foreach (@ARGV) {
   ProcessFile $_;
}
