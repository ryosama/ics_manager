#ics_manager.pl
---------------
Manage events inside ICS file

# Usage
-------
`--ics`=xxx
	ICS file to manage (require)

`--remove-events-older-than`=yyyy-mm-dd
	or
`--remove-events-older-than`=2D | 2W | 2M | 2Y
	Remove events older than the date or the duration in days, weeks, months or years (require)

`--dry-run`
	Only do a simulation

`--usage` or `--help`
	Display this message

`--quiet`
	No output

# Examples
----------
`perl ics_manager.pl --ics=bob.ics --remove-events-older-than=2015-01-01`
`perl ics_manager.pl --dry-run --ics=bob.ics --remove-events-older-than=5years`