#!/usr/bin/env ruby

['systemu', 'slop', 'yaml'].each do |gem|
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
  on :f, :file, 'site credentials yaml file', :argument => true
  on :o, :output, 'filename for snapshot (default is based on timestamp)', :argument => true
  on :d, :debug, 'enable debug'
  banner "Usage: #{$0} [options]\n"   \
         "Snapshot all instances across specified sites."
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

creds_data = ""
if opts[:file] 
  File.open(opts[:file]) do |f|
    creds_data = f.readlines
    trace "read #{creds_data}"
  end
else
  creds_data = STDIN.readlines
end
  
sitekeys = YAML::load(creds_data.join)

snapshot_file = opts[:output] || "snapshot_#{Time.now.to_i}"

sitekeys.each_pair do |site, info|
  trace "KEY: #{info['key']}"
  trace "SECRET: #{info['secret']}"
  trace  "API: #{info['api']}"

  if !info['key'] or !info['secret'] or !info['api']
    puts "missing credentials for site '#{site}'"
    next
  end

  puts "checking site '#{site}'"

  cmd = "euca-describe-instances -a #{info['key']} -s #{info['secret']} -U #{info['api']} | ./project-accounting.rb --parse >> #{snapshot_file}"
  trace cmd

  status, stdout, stderr = systemu(cmd)
  trace status

  cmd_output = stdout
  trace "OUTPUT: #{cmd_output.length}"
  err = stderr
  trace "ERR: #{err.length}"

  raise "command '#{cmd}' failed: #{err}" if not err.empty?
  trace "status: #{status.exitstatus}"
end
