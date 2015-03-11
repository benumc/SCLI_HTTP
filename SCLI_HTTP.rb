#!/usr/bin/env ruby
#Script should be run as daemon on host boot
require 'socket'
require 'uri'

$SCLI = "~/Applications/RacePointMedia/sclibridge "
a = RUBY_PLATFORM
if a.include? "linux"
 $SCLI = "/usr/local/bin/sclibridge "
end

def connThread(rti,sav)
  puts "open"
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
        if rType == 'http'
          if $1 == "servicerequestcommand"
            r = `#{$SCLI + data}`
          else
             sav.write(data.gsub("servicerequestcommand ","").gsub("\n","\r"))
             r ="\n"
          end 
          rti.write "HTTP/1.1 200 OK\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{r.length}\r\n" +
                 "Connection: close\r\n\r\n"
          rti.write(r)
        else
          t = Thread.new do
            d = data
            if $1 == "servicerequestcommand"
              r = `#{$SCLI + d}`
            else
               sav.write(d.gsub("servicerequestcommand ","").gsub("\n","\r"))
               r ="\n"
            end 
            rti.write(r)
          end
        end
        break if rType == 'http'
      else
        puts "Format incorect!: #{data.inspect}"
        
      end
    end
    rti.close
end

Thread.abort_on_exception = true
server = TCPServer.open(12000)
savant = TCPServer.open(12001)
loop do
  sav = savant.accept
  Thread.start(server.accept) { |rti| connThread(rti,sav) }
end
