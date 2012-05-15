#!/usr/bin/env ruby

#
# use euca-describe-instances on an account with admin rights to count instances
# 


['pp', 'date', 'slop', 'yaml'].each do |gem|
  begin
    require gem
  rescue LoadError
    require "rubygems"
    require gem
  end
end
  

@debug = nil
@now = DateTime.now.to_time
@ignoreprojects = false

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

#
# return a formatted string containing vcpu and ram
#
def resource_usage_summary(flavor, count)
  d = @flavormap[flavor]
  raise "No such flavor #{flavor}" if not d
  ram = d["ram"] * count
  vcpus = d["vcpus"] * count 
  sprintf("%d\t%d", vcpus, ram)
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
    printf("%s\t%s\t%0.2f\t%d\n", project, type, age, @now.to_i)
  end
end

# skip anything older than age_date
def age_worker(age_date)
  age_time = age_date.to_time
  ARGF.each do |l|
    project, type, age, last_seen = l.split 
    last_seen = Time.at(last_seen.to_i)
    age_date = DateTime.parse(last_seen)
    puts l unless last_seen < age_date
  end
end

def count_worker
  projects = {}

  ARGF.each do |l|

    project, type = l.split 
    trace "Read %s : %s " % [project, type]

    # accumulate total project-type usage
    projects[project] = {} if not projects[project] 
    trace "project: %s" % projects[project].inspect

    projects[project][type] = 0 if not projects[project][type] 
    projects[project][type] += 1
    
  end

  trace projects.inspect

  if @ignoreprojects
    types = {}
    projects.each_pair do |pname, p|
      p.keys.sort.each do |t|
        types[t] = 0 if not types[t]
        types[t] += p[t]
      end
    end
    types.each_pair do |type, count|
      if @usagereport
        printf("%s\t%d\t%s\n", type, count, resource_usage_summary(type, count))
      else
        printf("%s\t%d\n", type, count)
      end
    end
  else
    projects.each_pair do |pname, p|
      p.keys.sort.each do |t|
        if @usagereport
          printf("%s\t%s\t%d\t%s\n", pname, t, p[t], resource_usage_summary(t, p[t]))
        else 
          printf("%s\t%s\t%d\n", pname, t, p[t])
        end
      end
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

  if @ignoreprojects
    types = {}

    projects.each_pair do |pname, p|
      p.keys.sort.each do |t|
        types[t] = 0.0 if not types[t]
        types[t] += p[t]
      end
    end

    types.each_pair do |type, count|
      printf("%s\t%0.2f\n", type, count)
    end

  else
    projects.each_pair do |pname, p|
      p.keys.sort.each do |t|
        printf("%s\t%s\t%0.2f\n", pname, t, p[t])
      end
    end
  end

end

if __FILE__ == $0

 opts = Slop.new(:strict => true) do
    on :p, :parse, 'parse mode: assumes euca-run-instances output for admin user'
    on :a, :age, 'age mode: filter out instance data older than specified date, assumes --parse output format', :argument => :true
    on :s, :sum, 'sum mode: compute aggregate usage per-project'
    on :c, :count, 'count mode: calculate number of active instances per project'
    on :i, :ignoreprojects, 'compute statistics without regard to projects'
    on :f, :flavors, 'YAML file containing flavor mappings (for use with --usage)', 'foo', :argument => :true
    on :u, :usage, 'describe detailed RAM and VCPU usage'
    on :d, :debug, 'enable debug'
    banner "Usage: #{$0} [options] "    \
           "\nParse eucatools output, compute project/instance type statistics, strip aged entries."
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

  @ignoreprojects = opts.ignoreprojects?
  @usagereport = opts.usage?

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

  @flavormap = {}
  if @usagereport
    raise "Missing flavors YAML" if not opts[:flavors]
    begin
      f = File.read(opts[:flavors])
      @flavormap = YAML.load f 
    rescue Object => x
      p x
      exit 5
    end
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

end
