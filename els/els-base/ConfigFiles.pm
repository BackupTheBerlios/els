package      ConfigFiles;
require      Exporter;
@ISA       = qw(Exporter); 
@EXPORT    = qw(loadfile printfile writefile deleteall
                comment commentanywhere commentonce
		uncomment uncommentanywhere uncommentonce
                append prepend appendonce prependonce
                setopt getopt
                search replace replaceonce
                deleteline
		searchline

	        ActivateSample

		%users %groups
		ReadPasswd ReadGroup ReadData
		WritePasswd WriteGroup WriteData
		GetGroupName);
@EXPORT_OK = qw($dobackup @lines);

@lines	= ();
%users  = ();
%groups = ();



# LOADFILE
#	loads a file into memory
sub loadfile ($;$) {
    ($file, $header) = @_;
    @lines = ();
    open FILE, "$file" and @lines = <FILE>;
};

# PRINTFILE
#	prints the current memory-image of the file to stdout
sub printfile () {
    print "File \"$file\":\n";
    print @lines;
    print "\n\n";
}

# WRITEFILE
#	supposed to write the file back onto the disk
sub writefile () {
    # let's create a backup of the initial file
    chomp($filename = `basename $file`);
    $backup = "/tmp/" . $filename . ".orig";
    system "cp $file $backup >/dev/null 2>&1" unless -f $backup;

    # open for output, write all lines
    open FILE, ">$file" or die "Couldn't open $file for output: $!";
    print FILE @lines;
    close FILE
}

# DELETEALL
#	delete all lines
sub deleteall () {
    @lines = ();
}

# COMMENT 
# 	comment out a line, pattern must match at start of line
sub comment ($) {
    $pattern = shift(@_);
    #
    # The used regular expression means:
    #
    # ^		start at beginning of line
    # ()	the matched string will be stored in $1
    # $pattern	will be substituted by the argument
    # .*	zero or more additional characters allowed
    #
    $_ = grep { s/^($pattern.*)/#$1/ } @lines;
    return not $_;
}

# COMMENTANYWHERE
# 	comment out a line, pattern can match anywhere
sub commentanywhere ($) {
    $pattern = shift(@_);
    # () the matched string will be stored in $1
    # .* zero or more additional characters allowed
    # $pattern will be substituted by the argument
    # .* zero or more additional characters allowed
    $_ = grep { s/^([^#].*$pattern.*)$/#$1/ } @lines;
    return not $_;
}

# COMMENTONCE
# 	comment first line, pattern must match at start of line
sub commentonce ($) {
    $pattern = shift(@_);
    for (@lines) {
	last if s/^($pattern.*$)/#$1/;
    }
    return not $_;
}

# UNCOMMENT 
# 	uncomment a line, pattern must match at start of line
sub uncomment ($) {
    $pattern = shift(@_);
    $_ = grep { s/^#[ \t]*($pattern.*)/$1/ } @lines;
    return not $_;
}

# UNCOMMENTANYWHERE
# 	uncomment a line, pattern can match anywhere
sub uncommentanywhere ($) {
    $pattern = shift(@_);
    $_ = grep { s/^#[ \t]*(.*$pattern.*)/$1/ } @lines;
    return not $_;
}

# UNCOMMENTONCE
# 	uncomment first line, pattern must match at start of line
sub uncommentonce ($) {
    $pattern = shift(@_);
    foreach (@lines) {
	last if s/^#[ \t]*(.*$pattern.*)/$1/;
    }
}

# APPEND
# 	append line at the end
sub append ($) {
    $what = shift(@_);
    push @lines, $what . "\n";
}

# APPENDONCE
# 	appendonce line if not already present
sub appendonce ($) {
    $what = shift(@_);
    $_ = grep { /$what/ } @lines or push @lines, $what . "\n";
    return not $_;
}

# PREPEND
# 	inserts a line at the beginning
sub prepend ($) {
    $what = shift(@_);
    unshift @lines, $what . "\n";
}

# PREPENDONCE
# 	inserts a line at the beginning if not already present
sub prependonce ($) {
    $what = shift(@_);
    $_ = grep { /$what/ } @lines or unshift @lines, $what . "\n";
    return not $_;
}

# SETOPT
#	set option, even if commented out
#	if option is not already present, put it into the file
sub setopt ($$) {
    ($pattern, $option) = @_;
    $_ = grep { s/^([# \t])*($pattern).*/$2$option/ } @lines   or appendonce $pattern . $option;
    return not $_;
}

# GETOPT
sub getopt ($) {
    $pattern = shift;
    foreach (@lines) {
	if (/^$pattern(.*)$/) { return $1 };
    }
    return '';
}

# SEARCH
#	returns whether a string has been found or not
sub search ($) {
    $pattern = shift(@_);
    $_ = grep { m/$pattern/ } @lines;
    return $_;
}

# REPLACE
#	replaces each string with another one
sub replace ($$) {
    ($search, $replace) = @_;
    $_ = grep { s/$search/$replace/g } @lines;
    return not $_;
}

# REPLACEONCE
#	replaces the first occurrence of a string with another one
sub replaceonce ($$) {
    ($search, $replace) = @_;
    foreach $_ ( @lines ) {
	last if s/$search/$replace/g;
    }
}

# DELETELINE
#	deletes an entire line
sub deleteline ($) {
    $pattern = shift(@_);
    @lines = map { if ($_ =~ /$pattern/) { } else { $_ } } @lines;
}

# SEARCHLINE
#	searches a line in the array and returns the number of the first
#	occurence
sub searchline ($) {
    $pattern = shift(@_);
    $number = 0;
    foreach (@lines) {
	last if /$pattern/;
	$number++
    }
    $number = undef if ($number > $#lines);
    return $number;
}


#
# ActivateSample
#	if a file  x.sample  exists but the file  x  not, then the
#	x  file will be created by copying  x.sample
sub ActivateSample($)
{
    my($file) = @_;

    $file =~ s/\.sample$//;

    system("cp --preserve $file.sample $file") if (-f "$file.sample" && ! -f $file);
}


###########################################################################
#
# User data functions
#
###########################################################################
#
# The structure of the user data is a "hash of array", as described in the
# book "Programming perl, 2nd edition" on page 266f.
#
# To access a single field, e.g. the full name of user holger, use
# $users{"holger"}[3] = "Holger Schurig". Here are all fields:
#
# $users{$name}[0] password		$groups{$name}[0] group-password
# $users{$name}[1] user id		$groups{$name}[1] group id
# $users{$name}[2] primary group id	$groups{$name}[2] member list
# $users{$name}[3] full name
# $users{$name}[4] home path
# $users{$name}[5] shell
#
###########################################################################


#
# READPASSWD
#	Reads /etc/passwd and put the data into the %users hash
#
sub ReadPasswd ()
{
    my $name;

    $FILE = "/etc/passwd";
    open FILE or die "Can't open $FILE";
    while (<FILE>) {
	chomp;
	@_ = split ":", $_;
	$name = shift;
	$users{$name} = [ @_ ];
	unless ($users{$name}[5]) { $users{$name}[5] = ""; }
    }
}


#
# READGROUP
#	Reads /etc/group and put the data into the %groups hash
#
sub ReadGroup ()
{
    my $name;

    $FILE = "/etc/group";
    open FILE or die "Can't open $FILE";
    while (<FILE>) {
	chomp;
	@_ = split ":", $_;
	$name = shift;
	$groups{$name} = [ @_ ];
	unless ($groups{$name}[2]) { $groups{$name}[2] = ""; }
    }
}


#
# READDATA
#	Reads the whole user database (/etc/passwd and /etc/group).
#
sub ReadData ()
{
    ReadPasswd;
    ReadGroup;
}


#
# WRITEPASSWD
#	Writes user data from %users to /etc/passwd.
#	Creates a backup file "/etc/passwd-".
#
sub WritePasswd ()
{
    # make a backup copy ...
    system "cp --preserve /etc/passwd /etc/passwd-";

    # ... and write the data
    $FILE = ">/etc/passwd";
    open FILE or die "Can't open $FILE";

    my $name;
    foreach $name ( sort { $users{$a}[1] <=> $users{$b}[1] } keys %users ) {
	print FILE "$name:" , (join ":", @{ $users{$name} }) , "\n";
    }
}


#
# WRITEGROUP
#	Writes group data from %groups to /etc/group.
#	Creates a backup file "/etc/group-".
#
sub WriteGroup ()
{
    # make a backup copy ...
    system "cp --preserve /etc/group /etc/group-";

    # ... and write the data
    $FILE = ">/etc/group";
    open FILE or die "Can't open $FILE";

    my $name;
    foreach $name ( sort { $groups{$a}[1] <=> $groups{$b}[1] } keys %groups) {
	print FILE "$name:" , (join ":", @{ $groups{$name} }) , "\n";
    }
}


#
# WRITEDATA
#	Writes both %users and %groups to /etc/passwd and /etc/group.
#
sub WriteData ()
{
    WritePasswd;
    WriteGroup;
}


#
# GETGROUPNAME
#	returns group name for a given group id
#
sub GetGroupName ($)
{
    my($id) = @_;

    foreach $_ ( keys %groups ) {
	if ($groups{$_}[1] eq $id) {
	    return $_;
	}
    }

    # Not found?
    return "";
}


1;
