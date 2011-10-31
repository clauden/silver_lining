Simple port scan and report.
<p/>
Example:
<pre>
<code>
$ run.bash 10.4.1.0/30
10.4.1.2: 22 
10.4.1.4: 22 
10.4.1.5: 22 5432 
10.4.1.6: 22 80 
10.4.1.7: 22 
10.4.1.8: 22 
</code>
</pre>

In the openstack environment, both external (floating) IPs and private addresses may need to be scanned.

Externals are allocated individually, so this should work:
 
$ nova-manage floating list | awk '{print $2}' | xargs run.bash

Per-project VLAN addresses are a little trickier, since we don't allocate the first couple of 
addresses in each block.

