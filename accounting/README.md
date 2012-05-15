Simple accounting from current state.  Doesn't look at logs, so must be run frequently. Relies on uniqueness of instance IDs to keep track of transient instances.

Assumes an OpenStack Admin account is running it.  Probably fails miserably if a non-Admin tries.

Time is accrued in decimal days, so one hour is about 0.042 days.
Output is tab-delimited.

The idea is to process as a pipeline so that various statistics can be extracted.
Various modes (differentiated by command-line arguments) can display different functions on the data.

*Mode*: **parse**     
*Input*: euca-describe-instances output    
*Output*: [id project type age timestamp] for each active instance

*Mode*: **sum**  
*Input*: [id project type age] for each instance    
*Output*: [project type instance-days] for each project:type

*Mode*: **count**   
*Input*: [id project type age] for each instance    
*Output*: [project type instance-count] for each project:type

*Mode*: **age(age-date)**   
*Input*: [id project type age timestamp] for each (historical) instance    
*Output*: [id project type age] for each instance newer than age-date

*Meta-Mode*: **ignore-projects**    
For **count** and **sum** modes, ignore projects -- just add everything together and display by instance type.

Overview
--------
There are two logical pieces -- taking snapshots and generating reports.

### Snapshots
It is possible to get snapshots in various ways.  The present implementation uses euca-describe-instance
and relies on the instance placement data reported for an administrative user.  Therefore it **depends on 
EC2 API access to each site via an account with cloudadmin privilege**.

Site credentials are placed in a yml file as follows:
```
---
san1:
    api: http://75.55.64.12:8773/services/Cloud
    key: xxx
    secret: yyy
ewr1:
    api:
    key:
    secret:
```
    
Using
-----
#### To take a snapshot

```
$ snapshot.rb -f 
```

This will attempt to resolve Keystone tenant IDs to names using fix-keystone-tenants.

#### Using fix-keystone-tenants

Provide a 'tenants.yml' file like this:

```
1: sandbox
4: mhealth-prod-ewr1
5: site-latency-test-ewr1
6: ucm-dev-ewr1
7: openpeak-dev-ewr1
8: blackflag-apigee-kms4-ewr1
```

#### To count active instances
```
$ cat snapshot_1335912173 | ./project-accounting.rb -c
```


#### To look at cumulative instance-days

```
$ cat snapshot_1335912173 | ./project-accounting.rb -s
```

Add --ignoreprojects to look at sitewide usage.

### Looking at aggregate resource usage

Use the -u and -f options to get usage in vCPUs and RAM.  Currently works for --count only.  The --flavors file is yaml, like

```
m1.medium: { ram: 4096, vcpus: 2}
m1.small: {ram: 2048, vcpus: 1}
m1.large: {ram: 8192, vcpus: 4}
m1.tiny: {ram: 512, vcpus: 1}
m2.large: {ram: 32768, vcpus: 4}
m1.xlarge: {ram: 16384, vcpus: 8}
m2.xlarge: {ram: 32768, vcpus: 8}
```

#### Time series

To track cumulative use over time, keep a running history of instance data in order to avoid losing information when instances disappear.  Instances age out and stop being counted by being dead for long enough.  Aging out requires keeping a last-seen timestamp on each instance record.

Notes
-----
simple-automation.rb is another approach I did on a lark.  The snapshot.rb thing is probably better and should be used.
