#!/usr/bin/perl -w

use strict;

##################################################### command line handling
use Getopt::Long;

my $srcdir    = './';
my $destdir   = './';
my $verbose   = 0;
my $textmode  = 0;
my $shtml     = 0;
my $tablemode = 1;
GetOptions('verbose!'  => \$verbose,
           'destdir=s' => \$destdir,
           'srcdir=s'  => \$srcdir,
           'text'      => \$textmode,
           'shtml'     => \$shtml,
          );
chdir $srcdir;



my $FileStatus = "before";
my $MenuStatus = "before"; 
my $Name       = '';
my $Title      = '';
my $FileName   = '';
my %Writings   = ();
my %SubMenus   = ();
my %SubFiles   = ();
my %SubRefer   = ();




######################################################### Utility functions


#
# Strips *.mnu and *.html from the end and changes it into a .html
#
sub MakeShortFilename ($)
{
   my($fn) = @_;

   $fn =~ s/\.mnu$//;
   $fn =~ s/\.s?html$//;
   $fn =  $fn . ($shtml ? '.shtml' : '.html');

   return $fn;
}


#
# Emits a line of HTML text, appending a NL at the end
#
sub html ($)
{
    my($line) = @_;
    htmlwithoutnl("$line\n");
}


#
# Emit a line of HTML text
#
# Some HTML statements are stripped away if in text mode.
#
sub htmlwithoutnl ($)
{
    my($line) = @_;

    if ($textmode) {
        $line =~ s{</?P>}{}g;
        $line =~ s{</?TT>}{}g;
        $line =~ s{</?I>}{}g;
	$line =~ s{<A .+?>(.+)</A>}{$1}g;
	$line =~ s{<BR>}{\n}g;
	$line =~ s{&lt;}{<}g;
	$line =~ s{&gt;}{>}g;
	$line =~ s{&amp;}{&}g;
	$line =~ s{&nbsp;}{ }g;
	$line =~ s{&quot;}{\"}g;
        print "$line";
    } else {
        print HTML "$line";
    }
}



#
# If we render a file as HTML, we do it the following way:
#
#
#  +----------------------- toptable -------------------------+
#  | Title                                                    |
#  +----------------------------------------------------------+
#
#  
#  +---------------------- Outertable ------------------------+
#  | Title                                                    |
#  +----------------------------------------------------------+
#  |                                                          |
#  |    +----------------- Bordertable ------------------+    |
#  |    |                                                |    |
#  |    |    +------------ Inner table -------------+    |    |
#  |    |    | Entry                                |    |    |
#  |    |    +--------------------------------------+    |    |
#  |    |    | Entry                                |    |    |
#  |    |    +--------------------------------------+    |    |
#  |    |    | Entry                                |    |    |
#  |    |    +--------------------------------------+    |    |
#  |    |                                                |    |
#  |    +------------------------------------------------+    |
#  |                                                          |
#  +----------------------------------------------------------+
#

sub OuterTableBegin ($)
{
    my($width) = @_;

    unless ($textmode) {
        #html "<!-- outer table -->";
        html "<TABLE $width BORDER=1 CELLPADDING=2 CELLSPACING=0 BGCOLOR=\"#c0c0c0\">";
        html "<TR><TD>";
    }
}

sub OuterTableEnd ()
{
    unless ($textmode) {
        html "</TD></TR>";
        html "</TABLE>";
        #html "<!-- end outer table -->";
        html "<P>";
    }
}


sub BorderTableBegin ()
{
    unless ($textmode) {
        #html "<!-- border table -->";
        html "<TABLE WIDTH=\"90%\" BORDER=1 CELLPADDING=0 CELLSPACING=0>";
        html "<TR><TD ALIGN=\"CENTER\">";
    }
}


sub BorderTableEnd ()
{
    unless ($textmode) {
        html "</TD></TR>";
        html "</TABLE>";
        #html "<!-- end border table -->";
    }
}


sub TableBegin ($$)
{
    my($title, $width) = @_;

    if ($textmode) {
        html "";
        html $title;
        html "";
    } else {
        $title = "&nbsp;" if $title eq "";

        OuterTableBegin($width);
        html "<CENTER><FONT SIZE=-1><B>&nbsp; &nbsp; $title</B></FONT>";
        BorderTableBegin;
        #html "<!-- inner table -->";
        html "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=3>";
    }
}

sub TableEnd ($)
{
    my($trailer) = @_;

    if ($textmode) {
       html "";
    } else {
       html "</TABLE>";
       #html "<!-- end inner table -->";
       html "<BR>";
       html "</TD></TR>";
       html "<TR><TD ALIGN=\"CENTER\">";
       html "<TT>$trailer</TT>";
       BorderTableEnd;
       html "</CENTER>";
       OuterTableEnd;
    }
}





########################################################################## File 

sub FileBegin ()
{
    return if $FileStatus eq "in";

    unless ($textmode) {
	if ($shtml) {
	    html "<!--#set var=\"title\" value=\"ELS sysadm - $Name\"-->";
	    html '<!--#include file="top.inc"-->';
	    html '<!--#include file="admins.inc"-->';
	    html '<!--#include file="logos.inc"-->';
        } else {
            html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">";
            html "<HTML>";
            html "<HEAD>";
            html "<TITLE>sysadm - $Name</TITLE>";
            html "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">";
            html "</HEAD>";
            html "<BODY BGCOLOR=\"#ffffff\">";
            html "<TABLE CELLPADDING=10 WIDTH=\"100%\"><TR><TD BGCOLOR=\"#FFFFCC\" ALIGN=\"CENTER\">";
            html "<H1>Easy Linux Server</H1>";
            html "<H2>sysadm - $Name</H2>";
            html "</TD></TR></TABLE>";
            html "<P>";
        }
    } 
    $FileStatus = "in";
}

sub FileEnd ()
{
    unless ($textmode) {
	if ($shtml) {
	    html '<!--#include file="bottom.inc"-->';
        } else {
            html "</BODY></HTML>";
        }
    } 
    $FileStatus = "after";
}



######################################################################## Menu

sub MenuBegin ()
{
    return if $MenuStatus eq "in";

    # Emit text
    
    FileBegin();
    if ($textmode) {
        html "Menu: $Title\n"
    } else {
        html "";
        if ($tablemode) {
            html "<CENTER>";
            TableBegin($Title, "WIDTH=\"70%\"");
        } else {
            html "<H2>Contents</H2>";
            html "<UL>";
        }
    }
    $MenuStatus = "in";
}


sub MenuEntry ($$$)
{
    my($label, $text, $htmllabel) = @_;


    # Set $label and $htmllabel

    my $llabel = lc($label);
    if ($htmllabel) {
        $htmllabel = MakeShortFilename($htmllabel);
    } else {
        $htmllabel = "#$llabel";
    }


    # Replace all source-text variables text with sample data

    study $text;

    # cdrom setup
    $text =~ s:\$CDROM: hdc: ;

    # installation menu
    $text =~ s:\$INSTALLFROM:RedHat-CD: ;
    $text =~ s:\$SOURCE:/mnt/cdrom/redhat/RPMS: ;

    # usermod menu
    $text =~ s:\$SHELLSTATE:disabled: ;

    # modem setup
    $text =~ s:\$MODEMSPEED:57600: ;
    $text =~ s:\$MODEMINIT:ATZ: ;
    $text =~ s:\$MODEMDIAL:ATDT: ;
    $text =~ s:\$MODEMRINGS:4: ;
    $text =~ s:\$MODEMFAXID:49-6261-18564: ;
    $text =~ s:\$MODEM:/dev/ttyS2: ;

    # tcpip setup
    $text =~ s:\$HOSTNAME:d.om.org: ;
    $text =~ s:\$IPADDR:192.168.1.200: ;
    $text =~ s:\$PPPDIAL:0621-12345: ;
    $text =~ s:\$PPPACCOUNT:Pomd: ;
    $text =~ s:\$PPPPASSWORD:secret: ;
    $text =~ s:\$PPPLOCALIP:0.0.0.0: ;
    $text =~ s:\$PPPREMOTEIP:0.0.0.0: ;
    $text =~ s:\$PPPNETMASK:255.255.255.0: ;

    # printer modification
    $text =~ s:\$PR_USAGE:UNIX: ;
    $text =~ s:\$PR_PORT:/dev/lp0: ;
    $text =~ s:\$PR_QUEUE:LASERJET4: ;
    $text =~ s:\$PR_USER:GUEST: ;
    $text =~ s:\$PR_PASSWORD:SECRET: ;
    $text =~ s:\$PR_HOST:SCRUMPY: ;
    $text =~ s:\$PR_MODEL:Laserjet4: ;
    $text =~ s:\$PR_SIZE:a4: ;
    $text =~ s:\$PR_PAGES:2: ;
    $text =~ s:\$PR_RESOLUTION:300: ;
    $text =~ s:\$PR_BPS:1: ;
    $text =~ s:\$PR_FAST:YES: ;
    $text =~ s:\$PR_CHARSET:ibm437: ;
    $text =~ s:\$PR_FORMFEED:NO: ;
    $text =~ s:\$PR_FIXSTAIR:YES: ;

    # system menu
    $text =~ s:\$DATE:29-Oct-1997: ;
    $text =~ s:\$TIME:11\:26\:15: ;

    # tape setup
    $text =~ s:\$WHICH:  (now /dev/nrft0): ;

    # user modification
    $text =~ s:\$LOGIN:donald: ;
    $text =~ s:\$USER_FULLNAME:Donald Duck: ;
    $text =~ s:\$USER_PASSWORD:(no password, login disabled): ;
    $text =~ s:\$USER_UID:110: ;
    $text =~ s:\$USER_GID:110: ;
    $text =~ s:\$USER_HOME:/usr/home/donald: ;
    $text =~ s:\$USER_SHELL:/bin/bash: ;

    # samba global setup
    $text =~ s:\$NAME:LINUX: ;
    $text =~ s:\$LOGON:no: ;
    $text =~ s:\$NULL:yes: ;
    $text =~ s:\$PRNT:no: ;
    $text =~ s:\$CHAR:iso8559-1: ;
    $text =~ s:\$PAGE:850: ;
    $text =~ s:\$DEBUG:3: ;

    # samba share modification
    $text =~ s:\$MYPATH:/usr/samba/app: ;
    $text =~ s:\$COMMENT:Server based applications: ;
    $text =~ s:\$VOLUME:-none-: ;
    $text =~ s:\$SMB_AVAILABLE:yes: ;
    $text =~ s:\$SMB_BROWSEABLE:yes: ;
    $text =~ s:\$SMB_GUESTOK:no: ;
    $text =~ s:\$SMB_READONLY:yes: ;
    $text =~ s:\$WRITELIST:root: ;

    # email menu
    $text =~ s:\$EMAIL_TYPE:smtp (dialup): ;
    $text =~ s:\$EMAIL_FUZZYRATIO:30: ;

    # expert menu
    $text =~ s:\$EXPERTMODE:no: ;
    $text =~ s:\$TYPE:server: ;


    $text = " " . $text;
    $text =~ s: :&nbsp;:g ;

    MenuBegin();

    if ($textmode) {
        html (sprintf "%-15s%s", $label, $text);
    } else {
        if ($tablemode) {
            html "<TR VALIGN=\"top\">";
            html "  <TD><FONT SIZE=-1><TT><A HREF=\"$htmllabel\">$label</A>&nbsp;</TT></FONT></TD>";
            html "  <TD><FONT SIZE=-1><TT>$text</TT></FONT></TD>";
            html "</TR>";
        } else {
            html "  <LI><A HREF=\"$htmllabel\">$label</A>";
        }
    }
}


sub MenuEnd ()
{
    if ($textmode) {
	html "";
    } else {
        if ($tablemode) {
            html "<TR>";
            html "  <TD><BR></TD>";         
            html "  <TD><BR></TD>";         
            html "</TR>";
            TableEnd("&lt;  OK  &gt;      &lt;Cancel&gt;");
            html "</CENTER>";
        } else {
            html "</UL>";
        }
    } 
    $MenuStatus = "after";
}




################################################################## Descriptions

sub DoCheckList ($)
{
    my($title) = @_;

    unless ($textmode) {
        TableBegin($title, "");
    }

    while (<MENUFILE>) {
        last if /#CheckListEnd/i;
        next unless /# (\[.+\])+\s*(.*)/;

        if ($textmode) {
            print "  [ ] $1 $2\n";
        } else {
            if ($tablemode) {
                html "<TR VALIGN=\"top\">";
                my($line1,$line2) = ($1,$2);
	        $line1 =~ s/\[ \]/\[&nbsp;\]/g;
                html "  <TD><TT><FONT SIZE=-1>&nbsp;$line1&nbsp;</FONT></TT></TD>";
                if ( $line2 ) {
                    $line2 =~ s: :&nbsp;:g ;
                    html "  <TD><TT><FONT SIZE=-1>$line2&nbsp;</FONT></TT></TD>";
                }
                html "</TR>";
            } else {
                htmlwithoutnl "<TT>$1";
                htmlwithoutnl " $2" if $2;
                html "</TT><BR>";
            }
        }
    }

    unless ($textmode) {
        html "<TR><TD>&nbsp;</TD></TR>" if (!$textmode) && $tablemode;
        TableEnd("  &lt;   OK   &gt;      &lt;Cancel&gt;");
    }
}


sub DoMenu ($)
{
    my($title) = @_;

    unless ($textmode) {
	html "<P>";
        TableBegin($title, "");
    }

    while (<MENUFILE>) {
        last if /#MenuEnd/i;

        /# (\S+)+\s*(.*)/;
        if ($textmode) {
            print " $1 $2\n";
        } else {
            if ($tablemode) {
                html "<TR VALIGN=\"top\">";
                html "  <TD NOWRAP><TT><FONT SIZE=-1>&nbsp;$1&nbsp;</FONT></TT></TD>";
                if ($2) {
                    my($line) = $2;
                    $line =~ s: :&nbsp;:g ;
                    html "  <TD NOWRAP><TT><FONT SIZE=-1>$line&nbsp;</FONT></TT></TD>";
                    html "</TR>";
                }
            } else {
                htmlwithoutnl "<TT>$1";
                htmlwithoutnl " $2" if $2;
                html "</TT><BR>";
            }
        }
    }

    unless ($textmode) {
        html "<TR><TD>&nbsp;</TD></TR>" if !$textmode && $tablemode;
        TableEnd("  &lt;   OK   &gt;      &lt;Cancel&gt;  ");
    }
}


sub DoTextbox ($)
{
    my($title) = @_;
    my($line);

    html "<P>";
    unless ($textmode) {
        #html "<!-- begin text box -->";
        OuterTableBegin("");
        html "<FONT SIZE=-1><TT>";
    }

    while (<MENUFILE>) {
        last if /#TextboxEnd/i;

        if ( /# (.*)$/ ) {
            $line = $1;
        } else {
            $line = "";
        }
        if ($textmode) {
            html $line;
        } else {
	    $line =~ s{ }{&nbsp;}g;
            html " $line<BR>";
        }
    }

    unless ($textmode) {
        html "</TT></FONT>";
        html "</TD></TR>";
        html "<TR><TD ALIGN=\"CENTER\">";
        html "<TT>&lt;&nbsp;EXIT&nbsp;&gt;</TT>";
        OuterTableEnd;
        #html "<!-- end text box -->";
    }
}


sub DoMsgbox ($)
{
    my($title) = @_;

    unless ($textmode) {
        OuterTableBegin("");
        html "<TT>"; # was <PRE>
    }

    while (<MENUFILE>) {
        last if /#MsgBoxEnd/i;

        /# (.*)$/;
        if ($textmode) {
            html " $1";
        } else {
            html " $1<BR>";
        }
    }

    unless ($textmode) {
        html "</TT>"; # was </PRE>
        html "</TD></TR>";
        html "<TR><TD ALIGN=\"CENTER\">";
        html "  <TT>&lt;&nbsp;&nbsp;OK&nbsp;&nbsp;&gt;</TT>";
        OuterTableEnd;
    }
}


sub DoTable ($$)
{
    my($h1,$h2) = @_;

    if ($textmode) {
       html "";
    } else {
       html "<P>";
       html "<TABLE BORDER=1 CELLPADDING=2 CELLSPACING=0 BGCOLOR=\"#ffffc0\">";
       if ($1 ne "") {
           html "<TR>";
           html "  <TH ALIGN=left>$h1</TH>";
           html "  <TH ALIGN=left>$h2</TH>";
           html "</TR>";
       }
    }

    while (<MENUFILE>) {
        last if /#TableEnd/i;

        /# (\S+)\s+(.*)$/;
        if ($textmode) {
            html "$1   $2";
        } else {
            html "<TR>";
            html "  <TD VALIGN=top>$1</TD>";
            html "  <TD VALIGN=top>$2</TD>";
            html "</TR>";
        }
    }
   
    if ($textmode) {
        html "";
    } else {
        html "</TABLE>";
        html "<P>";
    }
}


sub DoInput ($)
{
    my($sample) = @_;
    #$sample .= "<BLINK>_</BLINK>";
    my($line);

    if ($textmode) {
        html "";
    } else {
        #html "<!-- outer input table -->";
        html "<P>";
        html "<TABLE WIDTH=\"75%\" BORDER=1 CELLPADDING=2 CELLSPACING=0 BGCOLOR=\"#c0c0c0\">";
        html "<TR><TD ALIGN=\"CENTER\">";

        #html "<!-- justification table -->";
        html "<TABLE WIDTH=\"90%\" BORDER=0 CELLPADDING=2 CELLSPACING=0>";
        html "<TR><TD>";
    }

    while (<MENUFILE>) {
        last if /#InputEnd/i;

        if ( /# (.*)$/ ) {
            $line = $1;
        } else {
            $line = "";
        }
        html " $line";
    }

    if ($textmode) {
        html "";
    } else {
        #html "<!-- input table for border -->";
        html "<TABLE WIDTH=\"100%\" BORDER=1 CELLPADDING=2 CELLSPACING=0>";
        html "<TR><TD>";
        html "  <TT>${sample}_</TT>";
        html "</TD></TR>";
        html "</TABLE>";

        #html "<!-- end of justification table -->";
        html "</TD></TR>";
        html "</TABLE>";
        
        #html "<!-- end of outer input table -->";
        html "<TR><TD ALIGN=\"CENTER\">";
        html "  <TT>&lt;&nbsp;&nbsp;OK&nbsp;&nbsp;&gt;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;Cancel&gt;</TT>";
        html "</TD></TR>";
        html "</TABLE>";
        html "<P>";
    }
}


sub DoQuestion ()
{
    my($line);

    #html "<!-- outer table -->";
    html "<P>";
    html "<TABLE WIDTH=\"75%\" BORDER=1 CELLPADDING=2 CELLSPACING=0 BGCOLOR=\"#c0c0c0\">";
    html "<TR><TD ALIGN=\"CENTER\">";

    #html "<!-- justification table -->";
    html "<TABLE WIDTH=\"90%\" BORDER=0 CELLPADDING=2 CELLSPACING=0>";
    html "<TR><TD>";

    while (<MENUFILE>) {
        last if /#QuestionEnd/i;

        if ( /# (.*)$/ ) {
            $line = $1;
        } else {
            $line = "";
        }
        if ($textmode) {
            print "$line\n";
        } else {
            html " $line";
        }
    }

    #html "<!-- end of justification table -->";
    html "<P>";
    html "</TD></TR>";
    html "</TABLE>";
    
    #html "<!-- end of outer table -->";
    html "<TR><TD ALIGN=\"CENTER\">";
    html "  <TT>&lt;&nbsp;Yes&nbsp;&gt;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;&nbsp;&nbsp;No&nbsp;&nbsp;&gt;</TT>";
    html "</TD></TR>";
    html "</TABLE>";
    html "<P>";
}


sub DoEdit ($)
{
    my($title) = @_;
    my($line);

    OuterTableBegin("");
    html "<FONT SIZE=-1><TT>"; # was <PRE>
    while (<MENUFILE>) {
        last if /#EditEnd/i || /#ScreenEnd/i;

        if ( /# (.*)$/ ) {
            $line = $1;
        } else {
            $line = "";
        }
        if ($textmode) {
            print "$line\n";
        } else {
            html " $line<BR>";
        }
    }

    html "</TT></FONT>"; # was </PRE>
    OuterTableEnd;
}


sub DoMacro ($)
{
    my($topic) = @_;
    $topic = lc $topic;

    if ($topic eq "editor") {
        if ($textmode) {
            print "See documentation on the \"q\" editor for additional help.\n";
        } else {
            html "Do all changes in the full-screen editor. When finished, press [Alt-X]";
            html "to e<B>x</B>it and save your work. Did you make a terrible";
            html "mistake?  Don't panic, just press [Alt-Q] to <B>q</B>uit";
            html "without saving. See \"<A HREF=\"../qeditor.html\">The q editor</A>\"";
            html "for additional info.";
        }
    }
    elsif ($topic eq "textbox") {
        html "Use the grey cursor keys to navigate up and down as well as";
        html "sideways if necessary. For long texts the [End]";
        html "puts you right at the end.";
        html "You can even search for things with the [/] key to enter the";
        html "search text and [n] to search agai<B>n</B>. Finally press";
        html "[Enter] to stop reading.";
    }
    elsif ($topic eq "checklist") {
        html "Use [Up] and [Down] to navigate. Press [Space] to toggle";
        html "the selected item. Press [Enter] when finished.";
    }
    elsif ($topic eq "question") {
        html "Press either [Y] or [N] to select your choice. You can also";
        html "use [Tab] to toggle between these option, press [Enter]";
        html "when you desired option is highligthed.";
    }
    elsif ($topic eq "menu") {
        html "Use [Up] and [Down] to navigate. Press [Enter] after you";
        html "reached the option of your choice.";
    }
    elsif ($topic eq "cancel") {
        html "To terminate this and return to the previous menu ";
        html "press [Tab] until the &lt;Cancel&gt; button is selected";
        html "and hit [Enter].";
    }
    else {
        die "Macro for $topic not implemented ($FileName).\n";
    }
}


sub Item ($)
{
    my($topic) = @_;

    if ($textmode) {
        print "$topic\n" . "-" x length($topic) . "\n";
    } else {
        html "<B>$topic</B><BR>";
    }
}


sub Description ()
{
    FileBegin();

    while (<MENUFILE>) {
        study;
        last if /#DescEnd$/i;
        if ( /#[ \t]*$/ ) {
            html "<P>\n";
        }
        elsif ( /# (.*)/ ) {
            html "$1" ;
        }
        elsif ( /#Macro\s*(.*)$/i ) {
            DoMacro($1);
        }
        elsif ( /#Item\s*(.*)$/i ) {
            Item($1);
        }

        elsif ( /#CheckList\s*(.*)$/i ) {
            DoCheckList($1);
        }
        elsif ( /#Menu\s*(.*)$/i ) {
            DoMenu($1);
        }
        elsif ( /#Textbox\s*(.*)$/i ) {
            DoTextbox($1);
        }
        elsif ( /#Input\s*(.*)$/i ) {
            DoInput($1);
        }
        elsif ( /#Question\s*(.*)$/i ) {
            DoQuestion();
        }
        elsif ( /#MsgBox\s*(.*)$/i ) {
            DoMsgbox($1);
        }
         elsif ( /#Edit$/i || /#Screen$/i ) {
            DoEdit($1);
        }
        elsif ( /#Table\s*(\S*)\s*(.*)$/i ) {
            DoTable($1,$2);
        }


        elsif ( /#([a-z]+)/i ) {
            die "Unknown directive $1 in $FileName.\n";
        }
    }
    html "<P>";
}


sub Label ($)
{
    my($label) = @_;
    my($lclabel) = lc $label;

    # use original case if we have this
    if ( $Writings{$label} ) {
        $label = $Writings{$label};
    }

    if ($textmode) {
        print "\n\nOption \"$label\"\n";
        print "=" x length($label) . "=" x 9 . "\n";
    } else {
        html "";
        html "<H2><A NAME=\"$lclabel\"><!-- --></A>Option \"$label\"</H2>";
    }
}









##########################################################################

sub Include ($$)
{
    # e.g.        $topic is "Network"
    #             $refer is "sysadm -> Network"
    my($topic, $refer) = @_;

    my($fn, $line);

    $refer =~ s:>:&gt;:g ;

    opendir INCLUDES, ".";
    while (defined($fn = readdir INCLUDES)) {
        next unless $fn =~ /\.mnu$/;
        open INCLUDE, "$fn";
        while (<INCLUDE>) {
            if ( /^\s+Title\s+"$topic"\s+"(.*)"\s+"(.*)"/ ) {
                $SubMenus{$1} = $2;
                $SubFiles{$1} = MakeShortFilename($fn);
                $SubRefer{$1} = $refer;
            }
        }
    }

    foreach $line ( sort keys %SubMenus ) {
        MenuEntry($line, $SubMenus{$line}, $SubFiles{$line} );
    }

    closedir INCLUDES;
}

sub ProcessRememberedIncludes()
{
    # now process remembered "#include" options:
    my($name);
    foreach $name (sort keys %SubFiles) {
        Label($name);
        html "See <A HREF=\"$SubFiles{$name}\">$SubRefer{$name} -&gt; $name</A>.";
    }
    %SubMenus   = ();
    %SubFiles   = ();
    %SubRefer   = ();
}

sub ProcessMenuFile ($)
{
    ($FileName) = @_;

    my ($atime,$mtime) = (stat($FileName))[8,9];
    #print "$atime $mtime\n";

    # initialize variables
    $FileStatus = "before";
    $MenuStatus = "before";
    %Writings   = ();
    %SubMenus   = ();
    %SubFiles   = ();
    %SubRefer   = ();

    # open output file
    my $HTMLFile;
    unless ($textmode) {
        $HTMLFile = MakeShortFilename $FileName;
        $HTMLFile = "index.html" if $HTMLFile eq "main.html";
        $HTMLFile = "index.shtml" if $HTMLFile eq "main.shtml";
        print "Write $destdir$HTMLFile\n" if $verbose;
        open HTML, ">$destdir$HTMLFile" or die "$!\n";
    }

    # now go throught the menu file
    open MENUFILE, $FileName or die "$FileName: $!\n";
    while (<MENUFILE>) {
        chomp;
        study;
        if ( /^[ \t]+Title "[^"]*" "([^"]*)" "([^"]*)"/ ) {
            $Name  = $1;
            $Title = $2;
            $Title =~ s:\$LOGIN:donald: ;
            $Title =~ s:\$SMB_SHARE:APP: ;
            $Title =~ s:\$PR_NAME:-ljet-2: ;
        }
        elsif ( /[^#]Option\s*?"([^"]*)"\s*?"([^"]*)"/ ) {
            MenuEntry($1,$2,undef);
            $Writings{lc $1} = $1;
        }
        elsif ( /;;/ && $MenuStatus eq "in" ) {
            MenuEnd;
        }
        elsif ( /([-a-z1-9]+)[\)\|][\s\\]*$/ && $MenuStatus eq "after") {
            Label ($1);
        }
        elsif ( /#Desc$/i ) {
            Description;
        }
        elsif ( /#Include (\w+)\s*(.*)$/i ) {
            Include($1,$2);
        }
        elsif ( /#DoIncludes/i ) {
            ProcessRememberedIncludes;
        }
    }
    close MENUFILE;

    ProcessRememberedIncludes;

    # write trailer
    if ($textmode) {
        printf "\n\n";
        FileEnd;
    } else {
        html '<P>';
	if ($shtml) {
            html '<!--#include file="bottom.inc"-->' if $shtml;
        } else {
            html '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="10" WIDTH="100%" BGCOLOR="#FFFFCC">';
            html '<TR><TD>';
            html "File automatically generated from \"<TT>$FileName</TT>\".";
            html '</TD></TR>';
            html '</TABLE>';
        }
        close HTML;
    }

    # set to same time as .mnu file
    utime $atime, $mtime, $HTMLFile unless $textmode;
}


# Process all scripts named on the command line (when scriptnames on cmdline)
foreach (@ARGV) {
   ProcessMenuFile $_;
}
