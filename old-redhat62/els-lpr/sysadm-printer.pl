#!/usr/bin/perl -w

#
# written by Holger Schurig
#
# modified by wnp@doulos.at to add PRINTER_NAME parameter to
# general.cfg in spool dir, to support setup script /usr/sbin/printername
#

$ENV{PATH} = "/usr/bin:/bin:/usr/sbin:/sbin";

use Getopt::Long;


##########################################################################


%prcap_opts    = ();    # the ":mx#0:if=something:" stuff
%prcap_aliases = ();	# other names for the printer, e.g. "lp|raw"
%prcap_desc    = ();	# the "###PRINTTOOL3###"... comment line

sub ReadPrintcap ()
{
    my($first, $line, $printer, $printtool_desc);

    $FILE = "/etc/printcap";
    open FILE or return;

    $first = 0;
    while (<FILE>) {
	chomp;
	# save printtool comment
	$printtool_desc = $1 if /^##PRINTTOOL3## (.*)/;
	# ignore comment lines for now
        next if /^$/ or /^#/;
	# for all lines with a trailing \ ...
	while (/\\$/) {
	   # append next line to our string ...
	   $_ .= <FILE>;
	   chomp;
	   # and delete the \ as well as any LFs, SPCs and TABs
	   s/:\\[\n \t]*//;
	}

	# now we have a string of the form "lp:sd=/var/spool/lpd/lp:mx#0:"
	$line = $_;

	# select text before first colon: these are the printer names
	/^([^:]*):.*/;
	$printer = $1;
	# if this printer had alias names, remember them
	if ($printer =~ /\|/) {
	    my(@temp);
	    @temp = split /\|/, $printer;
	    $printer = shift @temp;
	    $prcap_aliases{$printer} = join "\|", @temp;
	} else {
	    $prcap_aliases{$printer} = "";
	}

	# select text after first colon: these are the options
	$line =~ /^[^:]*(.*)/;
	$prcap_opts{$printer} = $1;

	# now store remembered printtool(8) description
	$prcap_desc{$printer}    = $printtool_desc;
    }
}

sub WritePrintcap ()
{
    open FILE, ">/etc/printcap";
    print FILE "# /etc/printcap\n";
    print FILE "#\n";
    print FILE "# Please dont edit this file directly unless you know what you are doing!\n";
    print FILE "# Be warned that PRINTTOOL and SYSADM requires a very strict format!\n";
    print FILE "# Look at the printcap(5) man page for more info.\n";
    print FILE "#\n";
    print FILE "# This file can be edited with PRINTOOL and SYSADM\n";
    print FILE "\n\n";

    foreach $p (sort keys %prcap_opts) {
	print FILE "##PRINTTOOL3## ";
	print FILE join " ", $prcap_desc{$p};
	print FILE "\n";

	print FILE "$p";
	if ($prcap_aliases{$p}) { print FILE "|", $prcap_aliases{$p} }

	$_ = $prcap_opts{$p};
	s/:/:\\\n\t:/g;
	s/^\t//;
	s/\\\n\t:$//;
	print FILE "$_\n";
    }
}

sub GetPrintcapValue ($$)
{
    my($p, $item) = @_;
    if    ($prcap_opts{$p} =~ /:$item=(.*?):/) { return $1 }
    elsif ($prcap_opts{$p} =~ /:$item#(.*?):/) { return $1 }
    else  { return "" };
}

sub SetPrintcapValue ($$$)
{
    my($p, $item, $value) = @_;

    # make sure there is at least one preceeding colon
    $prcap_opts{$p} = ":" unless ($prcap_opts{$p});

    # delete any previous entry
    $prcap_opts{$p} =~ s/:$item.*?:/:/;

    # append new entry
    $prcap_opts{$p} .= $item . $value . ":";
}

%prdb_driver = ();
%prdb_desc   = ();
%prdb_res    = ();
%prdb_bps    = ();

sub ReadPrinterDB ()
{
    my($printtype);

    $FILE = "/usr/lib/rhs/rhs-printfilters/printerdb";
    open FILE or die "$FILE is not there";

    while (<FILE>) {
	next if /^$/ || /^#/;
	chomp;
	$prtype               = $1 if /^StartEntry:\s*(.+)/;
	$prdb_driver{$prtype} = $1 if /GSDriver:\s*([^\s]+)/;
	$prdb_desc{$prtype}   = $1 if /Description:\s*\{(.*?)\}/;
	if (/Resolution:\s*\{(.*?)\}\s*\{(.*?)\}/) {
	    if ($prdb_res{$prtype}) { $prdb_res{$prtype} .= " $1x$2" } else { $prdb_res{$prtype} = "$1x$2" }
	}
	if (/BitsPerPixel:\s*(\{.*?\})\s*(\{.*?\})/) {
	    if ($prdb_bps{$prtype}) { $prdb_bps{$prtype} .= "\@$1 $2" } else { $prdb_bps{$prtype} = "$1 $2" }
	}
    }
    # some cleanup to preset empty bps fields (avoids ugly error messages)
    for $p (keys %prdb_desc) {
        $prdb_bps{$p} = "" unless $prdb_bps{$p};
    }
}

@lines = ();

sub LoadConfig ($)
{
    my ($file) = @_;

    @lines = ();
    open FILE, $file and @lines = <FILE>;
}

sub GetConfig ($)
{
    my ($pattern) = @_;
    #print "$pattern\n";
    @_ = grep { /$pattern(.*)/ } @lines;
    unless ($_[0]) { return "" }
    $_[0] =~ /$pattern(.*)$/;
    return $1;
}



############################################################################



sub ShowPrinters ()
{
format PRINTERS_TOP =
Printer          Port    Type                                    Aliases
------------------------------------------------------------------------
.
format PRINTERS =
@<<<<<<<<<<<<<<< @<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ^>>>>>>>>>>>
$p,              $port,  $prdb_res,                              $alias,
                         ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~ ^>>>>>>>>>>~
                 $prdb_res, $alias
.

    ReadPrintcap();

    $ofh = select(STDOUT);
    $~   = "PRINTERS";
    $^   = "PRINTERS_TOP";

    $found = 0;
    foreach $p (sort keys %prcap_opts) {
	$found = 1;
	@temp = split / /, $prcap_desc{$p};
	$temp[2] = "" unless($temp[2]);
	$temp[5] = "" unless($temp[5]);
 
	$prdb_res = $temp[5];
	unless ($temp[2]) { $prdb_res = "normal printer" }
	elsif ($temp[2] =~ /^[0-9]/) { $prdb_res .= " " . $temp[2] . " dpi" }
	if ($p =~ /.+\-1$/) { $prdb_res .= " with filter" } 
	elsif ($p =~ /.+\-2$/) { $prdb_res .= " with filter, 2 pages printed on one sheet" }

	$_ = GetPrintcapValue($p, "lp"); $_ = "" unless $_;
	$port = $_;
	if ($port =~ /^\/dev\/(.+)/) { $port = $1 }
	if ($port eq "" || $port eq "null") { $port = $temp[0] }

	$alias = $prcap_aliases{$p};
	write;
    }
    if (! $found) {
	print "Currently there are no printers defined.\n";
    }
    select($ofh);
    exit 0;
}


sub ListPrinters ()
{
    ReadPrintcap;
    my(@temp, $prdb_res, $p, $err);

    $err = 1;
    foreach $p (sort keys %prcap_opts) {
	$err = 0;
	@temp = split / /, $prcap_desc{$p};
	$temp[2] = "" unless($temp[2]);
	$temp[5] = "" unless($temp[5]);

	$prdb_res = $temp[5];
	if ($temp[2] =~ /^[0-9]/) { $prdb_res .= " " . $temp[2] . " dpi" }

	print "\"$p\" \"$temp[0] $prdb_res\" ";
    }

    exit $err;
}


sub ListPrinterDB ()
{
    my($p);

    ReadPrinterDB();
    foreach $p (sort keys %prdb_desc) {
	print "\"$p\" \"$prdb_desc{$p}\" ";
    }
    exit 0;
}

sub ListResolution ()
{
    ReadPrinterDB();
    my(@temp) = split / /, $prdb_res{$ListResolution};
    foreach $r (@temp) {
	print "\"$r\" \"\" ";
    }
    exit 0;
}

sub ListBPS ()
{
    ReadPrinterDB();
    my(@temp) = split /\@/, $prdb_bps{$ListBPS};
    foreach $r (@temp) {
    	$r =~ /{(\d*)} {(.*)}/;
	print "\"$1\" \"$2\" ";
    }
    exit 0;
}

sub ListFilters ()
{
    open FILE, "recode -l |";
    while (<FILE>) {
	chomp;
	@temp = split / /;
	$useful = "";
	foreach $f (@temp) {
	   $useful .= "$f " if (length($f)<10);
	}
	# move cp to front
	if ($useful =~ /(.*)\b(cp.*?)\b(.*)/ and $2 ne "cp367") {
	    $useful = "$2 $1 $3";
	    $useful =~ s/  +/ /g;
	};
	# strip trailing spaces
	$useful =~ s/\s*$//;
	if ( $useful =~ /(\S+)\s(.*)/ ) {
	    $hash{$1} = $2;
	}
    }
    foreach $f (sort { lc($a) cmp lc($b) } keys %hash) {
	print "\"$f\" \"$hash{$f}\" ";
    }

    exit 0;
}










$PR_NAME       = $ENV{"PR_NAME"};
$PR_PORT       = $ENV{"PR_PORT"};
$PR_HOST       = $ENV{"PR_HOST"};
$PR_QUEUE      = $ENV{"PR_QUEUE"};
#$PR_DESC       = $ENV{"PR_DESC"};
$PR_USAGE      = $ENV{"PR_USAGE"};
$PR_MODEL      = $ENV{"PR_MODEL"};
$PR_SIZE       = $ENV{"PR_SIZE"};
$PR_PAGES      = $ENV{"PR_PAGES"};
$PR_FAST       = $ENV{"PR_FAST"};
$PR_RESOLUTION = $ENV{"PR_RESOLUTION"};
$PR_BPS        = $ENV{"PR_BPS"};
$PR_FORMFEED   = $ENV{"PR_FORMFEED"};
$PR_FIXSTAIR   = $ENV{"PR_FIXSTAIR"};
$PR_CHARSET    = $ENV{"PR_CHARSET"};

sub AddOnePrinter($)
{
    my($p) = @_;
    my(@temp, $dir, $port);
    $dir = "/var/spool/lpd/$p";

    #########
    #
    #  Create the entry for /etc/printcap
    #
    #########

    SetPrintcapValue($p, "sd=", "$dir");		# spool directory
    SetPrintcapValue($p, "mx#", "0");			# impose no so size limit
    SetPrintcapValue($p, "sh", "");			# suppress header
    
    if ($PR_PORT eq "REMOTE") {
	# remote LPD protocol printer
	$port = $PR_PORT;
	SetPrintcapValue($p, "rm=", "$PR_HOST");	# remote host
	SetPrintcapValue($p, "rp=", "$PR_QUEUE");	# remote queue
	$temp[0] = "REMOTE";
    }
    else {
	# local printer
	$port = "LOCAL";
	SetPrintcapValue($p, "lp=", "$PR_PORT");
	$temp[0] = "LOCAL";
    }


    if ($PR_USAGE ne "WIN") {
	SetPrintcapValue($p, "if=", "$dir/filter");
    }

    if ($PR_USAGE eq "UNIX") {
        $PR_RESOLUTION =~ s/"//g;
	$temp[1] = $prdb_driver{$PR_MODEL};
        $temp[2] = $PR_RESOLUTION;
        $temp[3] = $PR_SIZE;
        $temp[4] = "{}";
        $temp[5] = $PR_MODEL;
	$temp[6] = ($PR_BPS eq "-not-defined-") ? "Default" : $PR_BPS;
	$temp[7] = "{}";
    }

    if ($PR_USAGE ne "UNIX") {
	SetPrintcapValue($p, "sf", "");		# suppress formfeed
    }

    $prcap_desc{$p} = join " ", @temp;


    #########
    #
    #  Create the directory in /var/spool/lpd
    #
    #########

    # create the spooldir
    mkdir "$dir", 0755;
    system "chown root.lp $dir";


    if ($PR_USAGE eq "WIN") {
	# see if we want to use SAMBA ...
	if (-d "/etc/samba.d") {
	    open FILE, ">/etc/samba.d/$PR_NAME.smb";
	    #print FILE "comment=$PR_DESC\n";
	    print FILE "force user=root\n";
	    print FILE "printable=yes\n";
	    print FILE "printer name=$PR_NAME\n";
	    print FILE "path=/var/tmp\n";
	    print FILE "create mode=700\n";
	    close FILE;
	    chmod 0644, "/etc/samba.d/$PR_NAME.smb";
	    system "/usr/sbin/sysadm-samba.pl", "--updateconfig";
	}

	# raw printers don't need filters, so bark out
	return;
    }

    # so called UNIX printers accept all sorts of input
    # files via filtering throught postscript
    elsif ($PR_USAGE eq "UNIX") {
	$gs_device     = $prdb_driver{$PR_MODEL}; 
        $desired_to    = (GS_DEVICE eq "TEXT")        ? "asc" : "ps";
	$paper_size    = $PR_SIZE;
	$resolution    = $PR_RESOLUTION;
	$color         = ($PR_BPS eq "-not-defined-") ? "" : "-dBitsPerPixel=$PR_BPS";
	$ps_send_eof   = (GS_DEVICE eq "POSTSCRIPT")  ? "YES" : "NO";
	$ascii_to_ps   = ($PR_PAGES ne "1" || $PR_FAST eq "NO") ? "YES" : "NO";
	$nup           = $PR_PAGES;
    }

    # delete old config files and rewrite master filter
    unlink "$dir/general.cfg", "$dir/textonly.cfg", "$dir/postscript.cfg", "$dir/.config";

    # create general config
    if ($PR_USAGE ne 'WIN') {
	system "ln -sf /usr/lib/sysadm/printfilter $dir/filter";

	open FILE, ">$dir/general.cfg";
	print FILE "#\n";
	print FILE "# General config options for	printing on this queue\n";
	print FILE "# Generated by SYSADM, do not modify.\n";
	print FILE "#\n";
	print FILE "export DESIRED_TO=$desired_to\n";
	print FILE "export PAPERSIZE=$paper_size\n";
	print FILE "export PRINTER_TYPE=$port\n";
	print FILE "export ASCII_TO_PS=$ascii_to_ps\n";
	print FILE "export RECODE_FILTER=$PR_CHARSET\n";
	print FILE "export PRINTER_NAME=$PR_NAME\n" ;

	# generate textonly cfg
	open FILE, ">$dir/textonly.cfg";
	print FILE "#\n";
	print FILE "# text-only	printing options for	printing on this queue\n";
	print FILE "# Generated by SYSADM, do not modify.\n";
	print FILE "#\n";
	print FILE "TEXTONLYOPTIONS=\n";
	print FILE "CRLFTRANS=$PR_FIXSTAIR\n";
	print FILE "TEXT_SEND_EOF=$PR_FORMFEED\n";

	# generate postscript config
	open FILE, ">$dir/postscript.cfg";
	print FILE "#\n";
	print FILE "# configuration related to postscript	printing\n";
	print FILE "# generated automatically by SYSADM\n";
	print FILE "# manual changes to this file may be lost\n";
	print FILE "#\n";
	print FILE "GSDEVICE=$gs_device\n";
	print FILE "RESOLUTION=$resolution\n";
	print FILE "COLOR=$color\n";
	print FILE "PAPERSIZE=$paper_size\n";
	print FILE "EXTRA_GS_OPTIONS=\"\"\n";
	print FILE "REVERSE_ORDER=\n";
	print FILE "PS_SEND_EOF=$ps_send_eof\n";
	print FILE "\n";
	print FILE "#\n";
	print FILE "# following is related to	printing multiple pages per output page\n";
	print FILE "#\n";
	print FILE "NUP=$nup\n";
	print FILE "RTLFTMAR=18\n";
	print FILE "TOPBOTMAR=18\n";
    }

    # set access rigths
    chmod 0755, "$dir/filter", "$dir/general.cfg", "$dir/textonly.cfg", "$dir/postscript.cfg";
    # see if we want to use SAMBA ...
    if ($PR_USAGE eq "WIN" && -d "/etc/samba.d") {
	open FILE, ">/etc/samba.d/$PR_NAME.smb";
	#print FILE "comment=\"$PR_DESC\"\n";
	print FILE "force user=root\n";
	print FILE "read only=yes\n";
	print FILE "printable=yes\n";
	print FILE "printer name=$PR_NAME\n";
	print FILE "path=/var/tmp\n";
	print FILE "create mode=700\n";
	close FILE;
	chmod 0755, "/etc/samba.d/$PR_NAME.smb";
	system "/usr/sbin/sysadm-samba.pl", "--updateconfig";
    }
}


sub AddPrinter ()
{
    ReadPrintcap;
    ReadPrinterDB;

    AddOnePrinter($PR_NAME);

    WritePrintcap;
    exit 0;
}


sub DelPrinter ()
{
    ReadPrintcap;

    system "lpc down $DelPrinter >/dev/null 2>&1";
    delete $prcap_opts{$DelPrinter};
    WritePrintcap; 
    exit 0;
}


sub GetPrinter ()
{
    ReadPrintcap;

    my($opts, @desc, $dir, $temp);
    my($name, $port, $host, $queue, $usage, $model);
    my($size, $pages, $fast, $resolution, $bps, $fixstair, $formfeed, $charset);

    $opts = $prcap_opts{$GetPrinter};
    return if ! $opts;
    
    $name = $GetPrinter;
    $dir  = "/var/spool/lpd/$name";

    @desc = split / /, $prcap_desc{$GetPrinter};
   

    if ($desc[0] eq "REMOTE") {
	$port     = "REMOTE";
	$host     = GetPrintcapValue($name, "rm");
	$queue    = GetPrintcapValue($name, "rp");
    }
    elsif ($desc[0] eq "LOCAL") {
	$port = GetPrintcapValue($name, "lp");
    }

    if (! -f "$dir/textonly.cfg") {
        $usage = "WIN";
    } else {
        $usage = "UNIX";
    }
    

    if ($desc[5]) {
	$model      = $desc[5];
	$size       = $desc[3];
	$resolution = $desc[2] unless $desc[2] eq "NAxNA"; 
 	$bps        = $desc[6] unless $desc[6] eq "Default";

	LoadConfig("$dir/general.cfg");
	$fast = (GetConfig("ASCII_TO_PS=") eq "NO") ? "YES" : "NO";
	$charset  = GetConfig("RECODE_FILTER=");

	LoadConfig("$dir/postscript.cfg");
	$page = GetConfig("NUP=");

	LoadConfig("$dir/textonly.cfg");
	$fixstair = GetConfig("CRLFTRANS=");
	$formfeed = GetConfig("TEXT_SEND_EOF=");
    }
    
    print "export PR_NAME=$name\n" if $name;
    print "export PR_PORT=$port\n" if $port;
    print "export PR_HOST=$host\n" if $host;
    print "export PR_QUEUE=$queue\n" if $queue;
    #print "export PR_DESC=\"$desc\"\n" if $desc;

    print "export PR_USAGE=$usage\n" if $usage;
    print "export PR_MODEL=$model\n" if $model;
    print "export PR_SIZE=$size\n" if $size;
    print "export PR_PAGES=$page\n" if $page;
    print "export PR_FAST=$fast\n" if $fast;
    print "export PR_RESOLUTION=$resolution\n" if $resolution;
    print "export PR_BPS=$bps\n" if $bps;
    print "export PR_FIXSTAIR=$fixstair\n" if $fixstair;
    print "export PR_FORMFEED=$formfeed\n" if $formfeed;
    print "export PR_CHARSET=$charset\n" if $charset;

    exit 0;
}




sub ShowJobs ()
{
format JOBS =
@<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>
$p,              $username,       $filename,                   $filesize
.

    $ofh = select(STDOUT);
    $~   = "JOBS";

    ReadPrintcap;
    $| = 1;

    # go througth all printers ...
    print "Printer          User             Filename                   Length (kB)\n";
    print "------------------------------------------------------------------------\n";
    foreach $p (sort keys %prcap_opts) {
	$dir = "/var/spool/lpd/$p";
	$found = 0;
	
	# open the directory it and go throught all files ...
	opendir DIR, "$dir";
	while (defined($_ = readdir DIR)) {
	    # only cf* files are interesting to us
	    next unless /^cf/;
	    $found++;
	    # open, read and extract the important info
	    open FILE, "$dir/$_" and @lines = <FILE>;
	    foreach $line (@lines) {
		$filename = $1 if $line =~ /^J(.*)/;
		$datafile = $1 if $line =~ /^U(.*)/;
		$username = $1 if $line =~ /^P(.*)/;
	    }	
	    # calculate the size of the data file
	    @_ = stat "$dir/$datafile";
	    $filesize = sprintf "%9.1f", $_[7] / 1024;
	    write;
	}
	closedir DIR;
	$stat = "$found jobs";


	@lines = ();
	open FILE, "lpc status $p |" and @lines = <FILE>;
        if ( grep { /queuing is dis/ } @lines ) { $stat .= ", queuing disabled" }
        if ( grep { /printing is dis/ } @lines ) { $stat .= ", printer stopped" }

	printf "%-16s ($stat)\n\n", $p;
    }
    select($ofh);
    exit 0;
}

sub ListJobs ()
{
    ReadPrintcap;

    # go througth all printers ...
    $err = 1;
    foreach $p (sort keys %prcap_opts) {
	$dir = "/var/spool/lpd/$p";

	# open the directory it and go throught all files ...
	opendir DIR, "$dir";
	while (defined($_ = readdir DIR)) {
	    # only cf* files are interesting to us
	    next unless /^cf/;
	    $err = 0;
	    # open, read and extract the important info
	    open FILE, "$dir/$_" and @lines = <FILE>;
	    foreach $line (@lines) {
		$filename = $1 if $line =~ /^J(.*)/;
		$jobid    = $1 if $line =~ /^U...(.*)/;
		$datafile = $1 if $line =~ /^U(.*)/;
		$username = $1 if $line =~ /^P(.*)/;
	    }
	    if ($datafile) {
		# calculate the size of the data file
		@_ = stat "$dir/$datafile";
		$filesize = sprintf "%.1f", $_[7] / 1024;
		print "\"$p $jobid\" \"$filename from $username ($filesize kB)\" ";
	    }
	}
	closedir DIR;
    }
    exit $err;
}





sub ShowUsage ()
{
    print "Please invoke with the proper options ...\n";
    exit 1;
}


%OptionsControl = (
		    # for "printer.mnu":
		    "printers" => \$ShowPrinters,
		    "listprinters" => \$ListPrinters,
		    "listprinterdb" => \$ListPrinterDB,
		    "listresolution:s" => \$ListResolution,
		    "listbps:s" => \$ListBPS,
		    "listfilters" => \$ListFilters,
		    "addprinter" => \$AddPrinter,
		    "delprinter:s" => \$DelPrinter,
		    "getprinter:s" => \$GetPrinter,

		    "jobs" => \$ShowJobs,
		    "listjobs" => \$ListJobs,

		  );

GetOptions(%OptionsControl);

ShowPrinters if $ShowPrinters;		# formatted for humans
ListPrinters if $ListPrinters;		# formatted for dialog
ListPrinterDB if $ListPrinterDB;	# formatted for dialog
ListResolution if $ListResolution;	# formatted for dialog
ListBPS if $ListBPS;			# formatted for dialog
ListFilters if $ListFilters;		# formatted for dialog
AddPrinter if $AddPrinter;
DelPrinter if $DelPrinter;
GetPrinter if $GetPrinter;

ShowJobs if $ShowJobs;
ListJobs if $ListJobs;


ShowUsage();
exit 1;
