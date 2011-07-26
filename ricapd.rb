#!/usr/bin/env ruby
#=
#= Ruby ICAP Server
#=

require 'eventmachine'

class RIcap < EM::Connection

  def clear_header
    @header={:data=>"", :mode=>"", :path=>"", :hdr=>{}}
  end

  def post_init
    puts [:post_init].inspect
    @data=""
    @body=""
    clear_header
  end

  def receive_data(_data)
    puts [:receive_data].inspect
    @data<<_data
    if @header[:data]=="" and pos=(@data=~/\r\n\r\n/)
      @header[:data]=@data[0..pos+1]
      if @header[:data]=~/^((OPTIONS|REQMOD|RESPMOD) icap:\/\/([A-Za-z0-9\.\-:]+)([^ ]+) ICAP\/1\.0)\r\n/
        req=$1; @header[:mode]=$2; @header[:host]=$3; @header[:path]=$4
        @header[:data][req.size+2..@header[:data].size-1].scan(/([^:]+): (.+)\r\n/).each do |h|
          @header[:hdr][h[0]]=h[1]
        end
p @header
      else
        print "Not found #{@header[0..50]}\n"
      end
      # Encapsulated: req-hdr=0, res-hdr=410, res-body=727
      @data=@data[pos+4..@data.size-1]
    end
    p @data.size
    if @header[:mode]=="OPTIONS"
      meth="REQMOD"
      meth="RESPMOD" if @header[:path]=="/response"
      send_data("ICAP/1.0 200 OK\r\nMethods: #{meth}\r\n\r\n")
      @data=""
      clear_header
    else
      send_data("ICAP/1.0 200 OK\r\nConnection: close\r\n\r\n")
      @data=""
      clear_header
    end
  end

  def unbind
  end

end

EM.run do
  s=EM.start_server 'localhost', 1344, RIcap
end

