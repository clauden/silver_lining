require 'nokogiri'

def usage
  puts "Usage: #{$0} <nmap-xml-file>"
  exit 1
end
  
usage if not ARGV[0]
File.open ARGV[0] do |f|
  d = Nokogiri::XML(f)
  hosts = d.xpath("//host/status[@state='up']/..")
  hosts.each do |h|
    address = h.xpath("address[@addrtype='ipv4']").attribute("addr").to_s
    ports = []
    h.xpath("ports/port").each do |p|
      ports << p.attribute("portid").to_s
    end
    printf("%s: %s\n", address, ports.inject("") {|r,i| r << i; r << " "; r})
  end
end

