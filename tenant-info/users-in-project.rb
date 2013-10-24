require 'rubygems'
require 'popen4'
require 'slop'

user = "cn5542"

# get users
cmd = "keystone user-list | grep True | awk '{print $2\"\t\"$4}'"
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

@users = {}
ls.each do |l|
	id, name = l.split
	@users[name] = id
end
# puts users.inspect

# get tenants
cmd = "keystone tenant-list | grep True | awk '{print $2\"\t\"$4}'"
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

@tenants = {}
ls.each do |l|
  id, name = l.split
  @tenants[id] = name
end
# puts users.inspect
# puts tenants.inspect

# look for specified user

# tenants = {"20bc37b37bbf4cbe9311a7769b589505" => "foo"}

def tenants_for_user (user)
	puts "tenants for user #{user} / #{@users[user]}"
	@tenants.each_key do |t|
		cmd = "keystone user-role-list --user #{@users[user]} --tenant #{t}"
		begin
			POpen4::popen4(cmd) do |o,e,i,p| 
				l = o.readlines
				n = l.length
				# puts "checking #{@tenants[t]} : #{n}"
				raise "found" if n > 1
			end	
		rescue
			puts " #{user} is in #{@tenants[t]}"
		end
	end
end

def users_for_tenant(tenant)
		tid = (@tenants.select {|k,v| v == tenant})[0]
		# puts tid
	@users.each do |u, id|
		cmd = "keystone user-role-list --user #{id} --tenant #{tid}"
		begin
			POpen4::popen4(cmd) do |o,e,i,p| 
				l = o.readlines
				n = l.length
				# puts "checking #{u} : #{n}"
				raise "found" if n > 1 
			end	
		rescue
			puts "#{u}"
		end
	end
end

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
