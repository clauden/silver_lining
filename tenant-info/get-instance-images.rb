#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'popen4'
require 'slop'

MAX = 5
@single_tenant_only = nil

# get image names for each tenant

#
# | 24578245-b0ad-4b8a-8aed-fc653ea75e2d | salt-minion-1 | ACTIVE | vlan2022=10.0.22.7, 64.143.228.214 |"
#

cmd = @single_tenant_only ? "nova list | grep ACTIVE | awk '{print $2}'" : "nova list --all-tenants | grep ACTIVE | awk '{print $2}'"
x = `#{cmd}`
ls = x.split("\n")
puts "#{ls.class} , #{ls.length}"

@instance_ids = []
ls.each do |l|
	@instance_ids << l
end
# puts @instance_ids.inspect


# get per-instance data

@tenants = {}
cmd = "keystone tenant-list"
x = `#{cmd}`
ls = x.split("\n")
ls.each do |l|
	f = l.split('|').inject([]) {|r,i| r << i.strip; r}
	next if f.length < 3
	@tenants[f[1]] = f[2]
end

# @info[tenant_id] = { image_name => count, ... }
@info = {} 	# Hash.new(Hash.new(0))

dummy = 0
@instance_ids.each do |id|
	cmd = "nova show #{id}"
	p cmd
	l = {}
	begin
		 # p "run cmd #{cmd}"
		POpen4::popen4(cmd) do |o,e,i,p| 
			l = o.readlines
		end	
		# p l
	end
	x = l.grep /updated|tenant_id|image/
	u = t = img = nil
	x.each do |r|
		f = r.split('|').inject([]) {|r,i| r << i.strip; r}
		# puts "read #{f[1]}"
		case f[1]
			when "updated":
				u = DateTime.parse(f[2]) 
			when "tenant_id":
				t = f[2]
			when "image":
				img = (f[2].split)[0]
		end
	end
	### puts "#{@tenants[t]} : #{img} (#{@info[t]}) #{@info.length}"
	@info[t] = Hash.new(0) if not @info[t]
	@info[t][img] += 1
	# p @info

	# @info[t] = u if u > @info[t]
	
	dummy += 1
	break if dummy > MAX
end

puts "#{@info.inspect}"

@info.each_key do |k|
	tenant_name = @tenants[k]
	@info[k].each_key do |i|
		puts "#{tenant_name}\t#{i}\t#{@info[k][i]}"
	end
	# puts "#{k}\t#{@tenants[k]}\t#{@info[k]}"
end

exit 1

#
# main begins
# 

opts = Slop.parse do
    banner "Usage: #{$0} [-u username] [-t tenantname]"
    on :u, :user=, "user name", true
    on :t, :tenant=, "tenant name", true
    on :s, :single=, "single tenant only", false
end

raise "nothing to do" if not opts[:tenant] and not opts[:user]
@single_tenant_only = opts[:single]

# p opts.inspect

users_for_tenant(opts[:tenant]) if opts.tenant?
tenants_for_user(opts[:user]) if opts.user?
