#!/usr/bin/perl -w

$ENV{PR_NAME}		= 'lp';
$ENV{PR_PORT}		= 'REMOTE';
$ENV{PR_HOST}		= 'mnz31';
$ENV{PR_QUEUE}		= 'lj2100_1';
$ENV{PR_USAGE}		= 'UNIX';
$ENV{PR_MODEL}		= 'LaserJet2p';
$ENV{PR_SIZE}		= 'a4';
$ENV{PR_PAGES}		= '1';
$ENV{PR_FAST}		= 'YES';
$ENV{PR_FORMFEED}	= 'YES';
$ENV{PR_FIXSTAIR}	= 'YES';
$ENV{PR_CHARSET}	= 'ascii';
$ENV{PR_RESOLUTION}	= '300x300';
$ENV{PR_BPS}		= '-not-defined-';
system('/usr/sbin/sysadm-printer.pl', '--addprinter');


$ENV{PR_NAME}		= 'lp-2';
$ENV{PR_PAGES}		= '2';
system('/usr/sbin/sysadm-printer.pl', '--addprinter');
