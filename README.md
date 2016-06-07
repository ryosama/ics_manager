#ics_manager.pl
---------------
Manage events inside ICS file

# Usage
-------
`--ics=xxx`
	ICS file to manage (require)

`--remove-events-older-than=yyyy-mm-dd`
	Remove events older than the date (require)

`--dry-run`
	Only do a simulation

`--usage` or `--help`
	Display this message

`--quiet`
	No output

# Examples
----------
`perl ics2baikal.pl --ics=bob.ics --remove-events-older-than=2015-01-01`