# Host: 12.208.178.14 ()  Ports: 22/open/tcp//ssh///, 80/open/tcp//http///, 443/open/tcp//https///,   8080/open/tcp//http-proxy///  Ignored State: closed (996)

rx = /^Host: ([0-9.]+).*Ports:(.*) Ignored.*$/
rx = /^Host: ([0-9.]+).*Ports:(.*)Ignored/
  
results = {}

while (l = gets)
  # printf("read: %s\n", l)
  
  m = rx.match(l)
  next if not m or not m.captures
  if m.captures.length != 2
    printf("weird capture: %s\n", l)
    next
  end

  ip = m.captures[0]
  a = []
  ports = m.captures[1].split(',')
  for p in ports
    a << p.split('/')[0].strip.to_i
  end
  results[ip] = a
  
  # printf("captured %s: %s\n", m.captures[0], m.captures[1])
end
results.each_key do |k|
  s = "%s: " % k
  results[k].each { |p| s << "%d " % p }
  puts s
end
  
  
    

