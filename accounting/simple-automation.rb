#!/usr/bin/env ruby

#
# gather info about envs
# parse and produce report
#

require 'pp'
require 'json'

tmpfile = "/tmp/#{$$}.instances"

f = ARGV[0]
envs = {}
s = File.open(ARGV[0]) { |f| f.read }
envs = JSON.parse(s)
#envs.each do |e|
  #p e[1]
#end

# gather all the euca output
envs.keys.each do |env|
  pp env
  c = ""
  envs[env].each_pair do |k,v|
    c += "#{k}=#{v} "
  end
  c += "euca-describe-instances >> #{tmpfile}"
  system("#{c}")
end

# parse
c = "./project-accounting.rb -p #{tmpfile} | ./project-accounting.rb -c -i "
p  system("#{c}")
