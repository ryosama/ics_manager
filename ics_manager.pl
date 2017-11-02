#!/usr/bin/perl

my $VERSION = 1.0;

use strict;
use Getopt::Long;
use File::Copy;
use DateTime::Duration;
use DateTime;

my ($ics,$remove_events_older_than,$dry_run,$no_backup,$help,$quiet);
GetOptions('ics:s'=>\$ics, 'remove-events-older-than:s'=>\$remove_events_older_than, 'dry-run!'=>\$dry_run, 'no-backup!'=>\$no_backup, 'help|usage!'=>\$help, 'quiet!'=>\$quiet) ;
die <<EOT if ($help || length($ics)<=0);
Parameters :
--ics=xxx
	ICS file to import (require)

--remove-events-older-than=yyyy-mm-dd
	or
--remove-events-older-than=2D | 2W | 2M | 2Y
	Remove events older than the date or the duration in days, weeks, months or years (require)

--dry-run
	Only do a simulation

--no-backup
	Do not create backup /!\\dangerous/!\\

--usage or --help
	Display this message

--quiet
	No output
EOT

die "Option --ics is missing" if length($ics) <= 0;
die "Unable to find ics file '$ics'" unless -e $ics;
open(ICS,"<$ics") or die "Unable to open ics file '$ics' ($!)";
my $content = join('',<ICS>);
close(ICS);


# --remove_events_older_than can be a duration
my $older_than = DateTime->now;
my %units_keywords = qw/	d days		days days		day days
							w weeks 	weeks weeks 	week weeks
							m months 	months months	month months
							y years		years years		year years/;

my $possible_units = join('|',keys %units_keywords);

# remove units from current date
if ($remove_events_older_than =~ /^(\d+)($possible_units)$/i) {
	$older_than->subtract_duration( DateTime::Duration->new( $units_keywords{lc($2)} => $1 ) );
	$remove_events_older_than = $older_than->ymd;

# remove_events_older_than can be a specific date in format yyyy-mm-dd
} elsif ($remove_events_older_than =~ /^\d{4}-\d{2}-\d{2}$/) {

} elsif (length($remove_events_older_than) <= 0) {
	die "Option --remove_events_older_than is missing";
} else {
	die "Date format '$remove_events_older_than' is malformed.\nGood format is yyyy-mm-dd"
}

my $original_remove_events_older_than = $remove_events_older_than;
$remove_events_older_than =~ s/-//g;

unless ($dry_run) {
	open(OUTPUT, "+>$ics.tmp") or die "Unable to create temporary file '$ics.tmp' ($!)";
	open(DELETED,"+>$ics.deleted.ics") or die "Unable to create deleted file '$ics.deleted.ics' ($!)";
}

# print calendar header
$content =~ /^BEGIN:VEVENT$/im ;
print OUTPUT  $` unless $dry_run;
print DELETED $` unless $dry_run;

my ($nb_events,$nb_deleted_events) = (0,0);

while($content =~ /(BEGIN:VEVENT.+?END:VEVENT)/gis) { # match an event
	my $event = $1;
	my ($uid) 	= ($event =~ m/^UID:(.+)$/im);
	$nb_events++;

	my $delete_event = 0;
	my $preserve_event = 0;

	my $until = '';
	my ($freq) 	= ($event =~ m/^RRULE:FREQ=(.+)$/im);
	if (length($freq) > 0) { # event has a frequence --> skip
		($until) = ($freq =~ m/;UNTIL=(\d{8})/i);
		if (length($until)>0) {
			if ($until < $remove_events_older_than) {
				$delete_event = 2 ;
			} else {
				$preserve_event = 1 ;
			}
		} else {
			$preserve_event = 1 ;
		}
	}

	my ($date_eventend) = ($event =~ m/^DTEND;(?:.+?):(\d{8})/im);
	if (length($date_eventend) > 0 && $preserve_event == 0) {
		$delete_event = 1 if $date_eventend < $remove_events_older_than ;
	}
	
	if ($delete_event > 0) {
		printf "Delete event : %s (end at %04d-%02d-%02d)\n", $uid, substr($date_eventend,0,4,), substr($date_eventend,4,2), substr($date_eventend,6,4) unless $quiet;
		print DELETED "$event\n" unless $dry_run;
		$nb_deleted_events++;
	} else {
		print OUTPUT "$event\n" unless $dry_run;
	}
}

# print calendar footer
unless ($dry_run) {
	print OUTPUT  "END:VCALENDAR\n";
	print DELETED "END:VCALENDAR\n";
	close(OUTPUT);
	close(DELETED);

	# make a backup of original ics
	unless ($no_backup) {
		move($ics,"$ics.bak") or die "Unable to make a backup or original ICS ($!)";
	}

	# move new ics to old one
	move("$ics.tmp",$ics) or die "Unable to rename $ics.tmp to $ics ($!)";
}

if ($dry_run) {
	print "\n/!\\ I'm running in dry-run mode, I don't do anything /!\\\n" unless $quiet;
}

print  "\nRemove events older than $original_remove_events_older_than\n";
printf "Removed %d of %d events (%0.1f %%)", $nb_deleted_events, $nb_events, (100*$nb_deleted_events / $nb_events) unless $quiet;