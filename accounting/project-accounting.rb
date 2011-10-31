#!/usr/bin/env ruby

#
# use euca-describe-instances on an account with admin rights to count instances
# 

require 'date'
# require 'ruby-debug'

@debug = nil


def trace(s)
  puts s if @debug
end


# 
# tab separated:
#     0          1           2               3           4         5                    6
# INSTANCE___i-0000077c___ami-000000a5___10.4.6.21___10.4.6.21___running ___userid-001 (mhealth, enc1b6)
#
#     7       8                9                  10
#  ___0 ___m1.small ___2011-08-18T17:36:42Z ___paloalto0
#
# returns [project, size, age-in-days]
#
def extract(l)
  f = l.split(/\t/)

  info = f[6].split(/ \(/)   # username (project, ...)
  project = info[1].split(/,/)[0][0..-1]     # strip ( and ,
  type = f[8].strip
  trace "project:%s, type:%s, date:%s" % [project, type, Date.parse(f[9])]

  age = (Date.today - Date.parse(f[9])).to_int

  return project, type, age 
end


if __FILE__ == $0

  projects = {}

  ARGF.each do |l|
    next if not l.match /^INSTANCE/

    # a = l.split
    # a.each_index { |i| p "%d : %s" % [i, a[i]] }

    project, type, age = extract(l) rescue p "FAIL: %s" % l.split[11]
    trace "Read %s : %s : %d" % [project, type, age]


    projects[project] = {} if not projects[project] 
    trace "project: %s" % projects[project].inspect

    projects[project][type] = 0 if not projects[project][type] 
    projects[project][type] += age
    
  end

  trace projects.inspect
  projects.each_pair do |pname, p|
    p.keys.sort.each do |t|
      printf("%s\t%s\t%d\n", pname, t, p[t])
    end
  end

end
