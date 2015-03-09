#!/usr/bin/env ruby
#Script should be run as daemon on host boot
require 'socket'

$SCLI = "~/Applications/RacePointMedia/sclibridge "
a = RUBY_PLATFORM
if a.include? "linux"
 $SCLI = "/usr/local/bin/sclibridge "
end

Thread.abort_on_exception=true

def connThread(rti)
    loop do
      begin
        data = rti.gets("\r").chomp
      rescue
        break
      end
      unless data
        break
      end
      if data.length > 10
        r = `#{$SCLI + data}`
        rti.write(r)
      end
    end
    rti.close
end

server = TCPServer.open(12000)
loop do
  Thread.start(server.accept) { |rti| connThread(rti) }
end
