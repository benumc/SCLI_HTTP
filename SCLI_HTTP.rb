#!/usr/bin/env ruby
#Script should be run as daemon on host boot
require 'socket'
require 'uri'

$SCLI = "~/Applications/RacePointMedia/sclibridge "
a = RUBY_PLATFORM
if a.include? "linux"
 $SCLI = "/usr/local/bin/sclibridge "
end
$savConn = true

def readFromRemote(rti)
  rType = 'tcp'
  data = rti.gets("\n")
  if data.include? "HTTP"
    rti.gets("\r\n\r\n")
    /GET \/([^ ]+) HTTP/.match(data)
    data = URI.unescape($1)
    rType = 'http'
  end
  data.gsub!(/\0/, '')
#puts data
  return data,rType
end

def writeToRequest(data)
  d = data.gsub("servicerequestcommand ","")
  d.gsub!("\n","")

  begin
#puts data
    $sav.write(d)
#puts "wrote it"    
    return $sav.gets("\r").gsub("\r","\n")
  rescue
    $savConn = false
#puts "savant not connected. fall back to scli"
th = Thread.new do
    $sav = $savant.accept
    $savConn = true
end
    return writeToScli(data)
  end
end

def writeToScli(data)
  return `#{$SCLI + data}`
end


def connThread(rti)
  loop do
    begin
      data,rType = readFromRemote(rti)
    rescue
      break
    end
    #puts data.inspect
    if /(readstate|writestate|servicerequestcommand|servicerequest|userzones|statenames|settrigger)/.match(data)
      #puts $1.inspect
      if $1 == "servicerequestcommand" && $savConn == true
        r = writeToRequest(data)
      else
#puts "writing to scli"
        r = writeToScli(data)
        #puts r.inspect
      end
      begin
        if rType == 'http' && r
          rti.write "HTTP/1.1 200 OK\r\n" +
             "Content-Type: text/plain\r\n" +
             "Content-Length: #{r.length}\r\n" +
             "Connection: close\r\n\r\n"+ r
        else
#puts "Replied with #{r.inspect} "
         rti.write r
        end
      rescue
        puts "connection closed, can't send reply"
      end
      break if rType == 'http'
    else
      puts "Format incorrect!: #{data.inspect}"
    end
  end
  rti.close
end

#Thread.abort_on_exception = true
server = TCPServer.open(12000)
$savant = TCPServer.open(12001)

loop do
  Thread.start(server.accept) { |rti| connThread(rti) }
end
