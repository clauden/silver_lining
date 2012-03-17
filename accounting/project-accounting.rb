#!/usr/bin/env ruby

#
# use euca-describe-instances on an account with admin rights to count instances
# 

require 'date'
require 'slop'
# require 'ruby-debug'

@debug = nil
@now = DateTime.now.to_time

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
def extract_from_euca_output(l)
  f = l.split(/\t/)

  info = f[6].split(/ \(/)   # username (project, ...)
  project = info[1].split(/,/)[0][0..-1]     # strip ( and ,
  type = f[8].strip
  trace "project:%s, type:%s, date:%s" % [project, type, Date.parse(f[9])]

  # age in decimal days
  age = (@now - DateTime.parse(f[9]).to_time)/3600/24
  
  # age in integer days
  # age = (Date.today - Date.parse(f[9])).to_int

  return project, type, age 
end


def parse_worker
  projects = {}

  ARGF.each do |l|
    next if not l.match /^INSTANCE/

    # a = l.split
    # a.each_index { |i| p "%d : %s" % [i, a[i]] }

    project, type, age = extract_from_euca_output(l) rescue p "FAIL: %s" % l.split[11]
    trace "Read %s : %s : %f" % [project, type, age]

    # show instance details
    printf("%s\t%s\t%0.2f\t%s\n", project, type, age, @now.to_s)
  end
end

# skip anything older than age_date
def age_worker(age_date)
  ARGF.each do |l|
    project, type, age, last_seen = l.split 
    DateTime.parse(last_seen)
    puts l unless last_seen < age_date
  end
end

def count_worker
  projects = {}

  ARGF.each do |l|
    # next if not l.match /^INSTANCE/

    project, type = l.split 
    trace "Read %s : %s " % [project, type]

    # accumulate total project-type usage
    projects[project] = {} if not projects[project] 
    trace "project: %s" % projects[project].inspect

    projects[project][type] = 0 if not projects[project][type] 
    projects[project][type] += 1
    
  end

  trace projects.inspect
  projects.each_pair do |pname, p|
    p.keys.sort.each do |t|
      printf("%s\t%s\t%d\n", pname, t, p[t])
    end
  end

end

def sum_worker
  projects = {}

  ARGF.each do |l|
    # next if not l.match /^INSTANCE/

    project, type, age = l.split 
    age = age.to_f
    trace "Read %s : %s : %f" % [project, type, age]

    # accumulate total project-type usage
    projects[project] = {} if not projects[project] 
    trace "project: %s" % projects[project].inspect

    projects[project][type] = 0 if not projects[project][type] 
    projects[project][type] += age
    
  end

  trace projects.inspect
  projects.each_pair do |pname, p|
    p.keys.sort.each do |t|
      printf("%s\t%s\t%0.2f\n", pname, t, p[t])
    end
  end

end

if __FILE__ == $0

 opts = Slop.new(:strict => true) do
    on :p, :parse, 'parse mode: assumes euca-run-instances output for admin user'
    on :a, :age, 'age mode: filter out instance data older than specified date, assumes --parse output format', :argument => :true
    on :s, :sum, 'sum mode: compute aggregate usage per-project'
    on :c, :count, 'count mode: calculate number of active instances per project'
    on :d, :debug, 'enable debug'
    banner "Usage: #{$0} [options] test | prod | s3" \
           "\nWhere 'test' is basho test env, 'prod' is SL, 's3' is Amazon"
    on :h, :help, 'get help' do
      puts help
      exit 2
    end
  end
    
  begin
    opts.parse!
  rescue Slop::InvalidOptionError => x
    # p "bad option"
    puts x.to_s
    puts opts.help
    exit 1
  rescue Slop::MissingArgumentError => x
    # p "missing argument"
    puts x.to_s
    puts opts.help
    exit 2
  end

  if opts.age?
    mode = :age 
  elsif opts.parse?
    mode = :parse 
  elsif opts.sum?
    mode = :sum 
  elsif opts.count?
    mode = :count 
  else
    puts "Mode selection missing."
    puts opts.help
    exit 4
  end

  case mode
  when :age
    age_worker(opts[:age])
  when :parse
    parse_worker
  when :sum
    sum_worker
  when :count
    count_worker
  end



=begin
  projects = {}
  ARGF.each do |l|
    next if not l.match /^INSTANCE/

    # a = l.split
    # a.each_index { |i| p "%d : %s" % [i, a[i]] }

    project, type, age = extract(l) rescue p "FAIL: %s" % l.split[11]
    trace "Read %s : %s : %f" % [project, type, age]

    # show instance details
    printf("INSTANCE\t%s\t%s\t%0.2f\n", project, type, age)

    # accumulate total project-type usage
    projects[project] = {} if not projects[project] 
    trace "project: %s" % projects[project].inspect

    projects[project][type] = 0 if not projects[project][type] 
    projects[project][type] += age
    
  end

  trace projects.inspect
  projects.each_pair do |pname, p|
    p.keys.sort.each do |t|
      printf("TOTAL\t%s\t%s\t%0.2f\n", pname, t, p[t])
    end
  end
=end
end
