#!/usr/bin/perl

my $VERSION = 1.0;

use strict;
use Getopt::Long;
use File::Copy;

my ($ics,$remove_events_older_than,$dry_run,$help,$quiet);
GetOptions('ics:s'=>\$ics, 'remove-events-older-than:s'=>\$remove_events_older_than, 'dry-run!'=>\$dry_run, 'help|usage!'=>\$help, 'quiet!'=>\$quiet) ;
die <<EOT if ($help || length($ics)<=0);
Parameters :
--ics=xxx
	ICS file to import (require)

--remove-events-older-than=yyyy-mm-dd
	Remove events older than the date

--dry-run
	Only do a simulation

--usage or --help
	Display this message

--quiet
	No output
EOT

die "Unable to find ics file '$ics'" unless -e $ics;
open(ICS,"<$ics") or die "Unable to open ics file '$ics' ($!)";
my $content = join('',<ICS>);
close(ICS);

die "Date format '$remove_events_older_than' is malformed.\nGood format is yyyy-mm-dd" unless $remove_events_older_than =~ /^\d{4}-\d{2}-\d{2}$/;
$remove_events_older_than =~ s/-//g;

if ($dry_run) {
	print "I'm running in dry-run mode, I won't do anything\n" unless $quiet;
}

unless ($dry_run) {
	open(OUTPUT,"+>$ics.tmp") or die "Unable to create temporary file '$ics.tmp' ($!)";
}

# print calendar header
$content =~ /^BEGIN:VEVENT$/im ;
print OUTPUT $` unless $dry_run;


while($content =~ /(BEGIN:VEVENT.+?END:VEVENT)/gis) { # match an event
	my $event = $1;
	my ($uid) 	= ($event =~ m/^UID:(.+)$/im);
	my $delete_event = 0;
	my $until = '';

	my ($freq) 	= ($event =~ m/^RRULE:FREQ=(.+)$/im);
	if (length($freq) > 0) { # event has a frequence --> skip
		($until) = ($freq =~ m/;UNTIL=(\d{8})/i);
		if (length($until)>0) {
			$delete_event = 1 if $until < $remove_events_older_than ;
		}
	}


	my ($date_eventend) = ($event =~ m/^DTEND;(?:.+?):(\d{8})/im);
	if (length($date_eventend) > 0) {
		$delete_event = 1 if $date_eventend < $remove_events_older_than ;
	}

	
	if ($delete_event == 1) {		
		print "Delete event : $uid (end at $date_eventend)\n" unless $quiet;
	} else {
		print OUTPUT "$event\n" unless $dry_run;
	}
}

# print calendar footer
unless ($dry_run) {
	print OUTPUT "END:VCALENDAR\n";
	close(OUTPUT);

	# make a backup of original ics
	move($ics,"$ics.bak") or die "Unable to make a backup or original ICS ($!)";

	# move new ics to old one
	move("$ics.tmp",$ics) or die "Unable to rename $ics.tmp to $ics ($!)";
}