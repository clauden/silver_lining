Simple accounting from current state.  Doesn't look at logs, so must be run frequently. Relies on uniqueness of instance IDs to keep track of transient instances.

Assumes an OpenStack Admin account is running it.  Probably fails miserably if a non-Admin tries.

Time is accrued in decimal days, so one hour is about 0.042 days.
Output is tab-delimited.

The idea is to process as a pipeline so that various statistics can be extracted.
Various modes (differentiated by command-line arguments) can display different functions on the data.

*Mode*: parse    
*Input*:: euca-describe-instances output    
*Output*:: <id project type age timestamp> for each active instance

*Mode*: cumulative    
*Input*:: <id project type age> for each instance    
*Output*:: <project type instance-days> for each project:type

*Mode*: count    
*Input*:: <id project type age> for each instance    
*Output*:: <project type instance-count> for each project:type

*Mode*: prune(n)    
*Input*:: <id project type age timestamp> for each (historical) instance    
*Output*:: <id project type age> for each instance last seen within last n days

To look at current usage, parse then count.

To track cumulative use over time, keep a running history of instance data in order to avoid losing information when instances disappear.  Instances age out and stop being counted by being dead for long enough.  Aging out requires keeping a last-seen timestamp on each instance record.

```
  # update history by merging current data 
  current = parse
  for record in history
    if record.id in current
      history[id] = record    # update, assuming unique ids
    else
      # instance is gone, has it aged out?
    end
  end

  # prune 

  # count
```
