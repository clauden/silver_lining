#!/usr/bin/env ruby

#
# translate keystone tenant IDs to strings for compatibility
#


['pp', 'systemu', 'slop', 'yaml'].each do |gem|
  begin
    require gem
  rescue LoadError
    require "rubygems"
    require gem
  end
end
  
@debug = false

def trace(s)
  # puts "trace: #{@debug}"
  puts s if @debug
end

# main begins
opts = Slop.new(:strict => true) do
  on :f, :file, 'keystone tenant mapping yaml file', :argument => true
  on :d, :debug, 'enable debug'
  banner "Usage: #{$0} [options]\n"   \
         "Translate tenant IDs to names."
  on :h, :help, 'get help' do
    puts help
    exit 2
  end
end
    
begin
  opts.parse!
rescue Slop::InvalidOptionError => x
  puts x.to_s
  puts opts.help
  exit 1
rescue Slop::MissingArgumentError => x
  puts x.to_s
  puts opts.help
  exit 2
end

@debug = opts.debug?

tenant_data = ""
if opts[:file] 
  File.open(opts[:file]) do |f|
    tenant_data = f.readlines
    trace "read #{tenant_data}"
  end
else
  puts "Missing tenant mapping yaml!"
  exit 4 
end
  
mapping = YAML::load(tenant_data.join)
STDIN.each do |l|
  f = l.split

  if f[0].match(/^[0-9]/)
    f[0] = mapping[f[0].to_i]
  end
  puts f.join(' ')
end
