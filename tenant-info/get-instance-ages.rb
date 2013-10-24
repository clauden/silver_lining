require 'rubygems'
require 'date'
require 'popen4'
require 'slop'

# get instances 

#
# | 24578245-b0ad-4b8a-8aed-fc653ea75e2d | salt-minion-1 | ACTIVE | vlan2022=10.0.22.7, 64.143.228.214 |"
#
# cmd = "nova list | grep ACTIVE | awk '{print $2}'"
cmd = "nova list --all-tenants | grep ACTIVE | awk '{print $2}'"
x = `#{cmd}`
ls = x.split("\n")
puts "#{ls.class} , #{ls.length}"

if 1 == 2
n = 1
ls.each do |l|
	puts "#{n}: #{l}"
	n += 1
end
end

@instance_ids = []
ls.each do |l|
	@instance_ids << l
end
# puts @instance_ids.inspect


# get per-instance data

@info = Hash.new(DateTime.parse("1/1/1999"))

@instance_ids.each do |id|
	cmd = "nova show #{id}"
	# p cmd
	l = {}
	begin
		# p "run cmd #{cmd}"
		POpen4::popen4(cmd) do |o,e,i,p| 
			l = o.readlines
		end	
		# p l
	end
	x = l.grep /updated|tenant_id/
	u = t = nil
	x.each do |r|
		f = r.split('|').inject([]) {|r,i| r << i.strip; r}
		case f[1]
			when "updated":
				u = DateTime.parse(f[2]) 
			when "tenant_id":
				t = f[2]
		end
	end
	puts "#{t} : #{u} (#{@info[t].to_s})"
	@info[t] = u if u > @info[t]
end

@tenants = {}
cmd = "keystone tenant-list"
x = `#{cmd}`
ls = x.split("\n")
ls.each do |l|
	f = l.split('|').inject([]) {|r,i| r << i.strip; r}
	next if f.length < 3
	@tenants[f[1]] = f[2]
end

@info.each_key do |k|
	puts "#{@tenants[k]}\t#{@info[k]}"
end

exit 1

#
# main begins
# 

opts = Slop.parse do
    banner "Usage: #{$0} [-u username] [-t tenantname]"
    on :u, :user=, "user name", true
    on :t, :tenant=, "tenant name", true
end

raise "nothing to do" if not opts[:tenant] and not opts[:user]

# p opts.inspect

users_for_tenant(opts[:tenant]) if opts.tenant?
tenants_for_user(opts[:user]) if opts.user?
