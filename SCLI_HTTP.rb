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
      begin
        request = /GET \/([^ ]+) HTTP/.match(rti.gets("\r\n\r\n"))
        data = URI.unescape($1)
      rescue
        break
      end
      unless data
        break
      end
      if data.length > 10
        r = `#{$SCLI + data}`
        rti.write "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: #{r.length}\r\n" +
               "Connection: close\r\n\r\n"+r
      end
    end
    rti.close
end

Thread.abort_on_exception = true
server = TCPServer.open(12001)
loop do
  Thread.start(server.accept) { |rti| connThread(rti) }
end