#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'popen4'
require 'slop'

MAX = 5
@single_tenant_only = nil
@max_tenants = MAX
@legacy = nil
@csv = nil

# get quota info for each tenant
#
# #$ nova quota-show --tenant xdm-cdn-prod
# +-----------------------------+-------+
# | Property                    | Value |
# +-----------------------------+-------+
# | metadata_items              | 128   |
# | injected_file_content_bytes | 10240 |
# | injected_files              | 5     |
# | gigabytes                   | 1000  |
# | ram                         | 51200 |
# | floating_ips                | 10    |
# | key_pairs                   | 100   |
# | instances                   | 10    |
# | security_group_rules        | 20    |
# | volumes                     | 10    |
# | cores                       | 20    |
# | fixed_ips                   | -1    |
# | injected_file_path_bytes    | 255   |
# | security_groups             | 50    |
# +-----------------------------+-------+
#

# 
# attributes to be shown in CSV format
#
ALL_QUOTA_TAGS = %w[
	metadata_items
	injected_file_content_bytes
	injected_files
	gigabytes
	ram
	floating_ips
	key_pairs
	instances
	security_group_rules
	volumes
	cores
	fixed_ips
	injected_file_path_bytes
	security_groups
]


DEFAULT_QUOTA_TAGS = %w[
	cores
	ram
	gigabytes
	instances
	volumes
]

@quota_tags = DEFAULT_QUOTA_TAGS


def load_tenants() 
	tenants = []
	cmd = "keystone tenant-list"
	x = `#{cmd}`
	ls = x.split("\n")
	ls.each do |l|
		f = l.split('|').inject([]) {|r,i| r << i.strip; r}
		next if f.length < 3
		tenants << f[2]
	end
	# p tenants
	tenants
end

def load_quotas(tenants)
	# puts "load_quotas: #{tenants.inspect}"

	# @info[tenant_id] = { quota_property => value, ... }
	info = {} 	

	tenant_count = 0
	tenants.each do |t|
		cmd = @legacy ? "nova-manage project quota \"#{t}\"" : "nova quota-show --tenant \"#{t}\""
		# p cmd
		l = {}
		begin
			# p "run cmd #{cmd}"
			status = POpen4::popen4(cmd) do |o,e,i,p| 
				l = o.readlines
			end	
			# p status.exitstatus
		end
		
		# l has raw cmd output
		# p l
		q = {}
		l.each do |r|
			if @legacy
				next if not r =~ /^[a-z]+: [0-9]/
				f = r.split(':').inject([]) {|r,i| r << i.strip; r}
				q[f[0]] = f[1]
			else
				next if r =~ /---/
				f = r.split('|').inject([]) {|r,i| r << i.strip; r}
				next if not f[2] =~ /[0-9]+/
				q[f[1]] = f[2]
			end
			
		end

		info[t] = q
		# p info[t]
		
		if @tenant_limit
			tenant_count += 1
			break if tenant_count >= @tenant_limit
		end
	end
	info
end


def parse_quotas(info)
	s = ""
	info.each_key do |k|
		q = info[k]
		if not @csv
			s << "#{k}\n"
			q.each_key do |i|
				s << "\t#{i} = #{q[i]}\n"
			end
		else
			s << "#{k}"
			@quota_tags.each do |a|	
				s << ",#{q[a]}"
			end
			s << "\n"
		end
	end
	s
end

#
# main begins
# 

opts = Slop.parse({:help => true})  do
    banner "Usage: #{$0} [--tenants tenant-name,...] [--quota quota-tag,...] [--csv] [--legacy] [--Header] [--num num-tenants-to-show]\n       #{$0} --show_quota_tags"
    on :t, :tenants=, "tenant name", true
    on :c, :csv, "fixed format CSV output"
    on :n, :num=, "number of tenants to list", true
    on :q, :quota=, "quota tags to capture", true
    on :s, :show_quota_tags, "show available quota tags"
    on :l, :legacy, "use legacy (pre-Grizzly) commands"
    on :H, :Header, "quota tag header in csv output"
end

if opts[:show_quota_tags]
	p ALL_QUOTA_TAGS
	exit 2
end

@tenant_limit = opts[:num].to_i if opts[:num]
@tenants = opts[:tenants] ? opts[:tenants].split(/,/) : load_tenants
@quota_tags = opts[:quota] ? opts[:quota].split(/,/) : DEFAULT_QUOTA_TAGS
@csv = opts[:csv]
@legacy = opts[:legacy]
@header = opts[:Header]

# p "@legacy = #{@legacy}"
# p "@tenant_limit = #{@tenant_limit}"
# p "@tenants = #{@tenants}"
# p "@quota_tags = #{@quota_tags}"

@info = load_quotas(@tenants)
# puts "#{@info.inspect}"

if @header && @csv
	s = "# tenant"
	@quota_tags.each do |a|	
		s << ",#{a}"
	end
	puts s
end
puts parse_quotas(@info)

