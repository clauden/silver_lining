Simple accounting from current state.  Doesn't look at logs, so must be run frequently.

Assumes an OpenStack Admin account is running it.  Probably fails miserably if a non-Admin tries.

Time is accrued in days.  Assumes a minimum of one day per instance (so even if instance was start
a second ago it is one day "old").
