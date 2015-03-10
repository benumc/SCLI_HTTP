#!/usr/bin/env ruby
#Script should be run as daemon on host boot
require 'socket'
require 'uri'

$SCLI = "~/Applications/RacePointMedia/sclibridge "
a = RUBY_PLATFORM
if a.include? "linux"
 $SCLI = "/usr/local/bin/sclibridge "
end

Thread.abort_on_exception=true

def connThread(rti)
    loop do
      rType = 'tcp'
      begin
        data = rti.gets("\n")
        if data.include? "HTTP"
          rti.gets("\r\n\r\n")
          /GET \/([^ ]+) HTTP/.match(data)
          data = URI.unescape($1)
          rType = 'http'
        end
        data.gsub!(/\0/, '')
        data.gsub!("\r",'')
      rescue
        break
      end
      if /(readstate|writestate|servicerequest|userzones|statenames|settrigger)/.match(data)
        r = `#{$SCLI + data}`
        rti.write "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: #{r.length}\r\n" +
               "Connection: close\r\n\r\n" if rType == 'http'
        rti.write(r)
      else
        puts "Format incorect!: #{data.inspect}"
        break
      end
    end
    rti.close
end

Thread.abort_on_exception = true
server = TCPServer.open(12000)
loop do
  Thread.start(server.accept) { |rti| connThread(rti) }
end