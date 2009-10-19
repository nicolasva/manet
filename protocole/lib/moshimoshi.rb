module Moshimoshi
  VERSION = 1
  
  class Protocol
    CONF_PATH = 'etc/moshimoshi.yml'
    BROADCAST = '255.255.255.255'
    LOCALHOST = '127.0.0.1'
    
    def initialize
      @options = parse_opts
      @options[:debug] = false unless @options[:debug]
      @options[:file] = CONF_PATH unless @options[:file]
      @options[:verbose] = false unless @options[:verbose]
      abort("Configuration file not found: #{@options[:file]}") unless File.exist?(@options[:file])
      @config = YAML::load_file(@options[:file])
      @routing_system = RoutingSystem.new
      @sock = UDPSocket.new
      @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      begin
        @sock.bind(Socket.gethostname, @config['port']) #@sock.bind(Socket.gethostname, @config['port'])
      rescue
        @sock.bind(my_addr.to_s, @config['port'])
      end
      @hexdigest = Regexp.new(/[a-f0-9]{16}/)
      routing_table << [ MyRoute.new(IPAddr.new(my_addr.to_s)) ]
      global_flooding unless @config['inconspicuous']
    end
    
    def run
      Thread.new { loop { udp_server } }
      loop do
        @config['inconspicuous'] ? local_presence : local_flooding
        if @options[:debug]
          puts "table content:"
          p @table
        end
        sleep(@config['update'])
      end
    end
    
    protected
    
    def routing_table(depth = 0)
      @table = Array.new unless @table
      @table[depth] = Array.new unless @table[depth]
      @table[depth]
    end
    
    def udp_server
      message, sender = receive
      puts "message received from #{sender}: #{message}" if @options[:debug]
      datagram = message.scan(/[^,]+/)
      src_addr = IPAddr.new(sender[3])
      dst_addr = IPAddr.new(sender[1]) # gateway?
      puts "scr= #{src_addr}, dst= #{dst_addr}" if @options[:debug]
      case datagram.type
        when 0: datagram, dst_addr = discover_lans(datagram)
        when 1: datagram, dst_addr = discover_tree(datagram)
        when 2: datagram, dst_addr = network_path(datagram)
      end
      #@table.merge!({ resource => Route.new(0, sender[3], false, sender[3]) }) unless @table.has_key?(resource)
      @sock.send response, 0, sender[3], sender[1]
      @sock.send(datagram.to_s, 0, dst_addr.to_s, @config['port'])
    end
    
    def discover_lans(datagram)
      
      [datagram, dst_addr]
    end
    
    def parse_opts
      options = Hash.new
      opts = OptionParser.new
      opts.banner = "Usage: #$0 [options]"
      opts.on('-d', '--debug', 'Debug mode.') { options[:debug] = true }
      opts.on('-f', '--file file', 'Load the rules contained in file.') { |f| options[:file] = f }
      opts.on('-h', '--help', 'Help.') { puts opts; exit }
      opts.on('-v', '--verbose', 'Produce more verbose output.') { options[:verbose] = true }
      opts.on('-V', '--version', 'Show version.') { self.version; exit }
      opts.parse(ARGV)
      options
    end
    
    def receive
      @sock.recvfrom(1_500)
    end
    
    def global_flooding
      data = my_addr.to_s
      sequence = rand_sequence
      type = 1
      dest_addr = IPAddr.new(BROADCAST)
      udp_client(Segment.new(data, sequence, type), dest_addr)
    end
    
    def local_flooding
      data = my_addr.to_s
      sequence = rand_sequence
      type = 0
      dest_addr = IPAddr.new(BROADCAST)
      udp_client(Segment.new(data, sequence, type), dest_addr)
    end
    
    def local_presence
      data = my_addr.to_s
      sequence = rand_sequence
      type = 0
      if routing_table(1).size > 0
        local_router_id = rand(routing_table(1).size - 1)
        dest_addr = routing_table(1)[local_router_id]
        puts "dest_addr: #{dest_addr.to_s}" if @options[:debug]
        udp_client(Segment.new(data, sequence, type), dest_addr)
      end
    end
    
    def rand_sequence
      rand 65_536
    end
    
    def udp_client(datagram, dst_addr)
      puts "send message: #{datagram}" if @options[:debug]
      client = UDPSocket.new
      client.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true) if dst_addr.to_s == BROADCAST
      client.send(datagram.to_s, 0, dst_addr.to_s, @config['port'])
    end
    
    def hash(string)
      Digest::Crypsh16.new(string).hexdigest.rjust(4, '0')
    end
    
    MAX_RESOURCE = 50
    def messages(resources, depth, connection)
      messages = []
      i = 0
      ((resources.length / MAX_RESOURCE) + 1).time do
        messages << [ resources.slice(i, MAX_RESOURCE), depth, connection ]
        i += 1
      end
      messages
    end
    
    def my_addr
      begin
        IPAddr.new(IPSocket.getaddress(Socket.gethostname).slice(/^[^%]*/))
      rescue
        IPAddr.new(@config['addr'])
      end
    end
    
    def version
      puts "Moshimoshi #{VERSION}"
    end
  end
  
  class Route
    def initialize(depth, destination, connection, gateway)
      @depth       = depth.to_i
      @destination = destination.to_s
      @connection  = connection ? 1 : 0
      @gateway     = gateway.to_s
    end
    
    attr_accessor :depth, :destination, :connection, :gateway
    
    def to_s
      [ @depth, @destination, @connection, @gateway ]
    end
  end
  
  class MyRoute < Route
    def initialize(my_address)
      @depth       = 0
      @destination = my_address.to_s
      @connection  = true ? 1 : 0
      @gateway     = my_address.to_s
    end
  end
  
  class RoutingSystem
    def initialize
      abort("Must be root to alter routing table.") unless is_root?
    end
    
    def add(destination, gateway)
      %x[route add #{destination} #{gateway}]
    end
    
    def flush(destination, gateway)
      %x[route flush #{destination} #{gateway}]
    end
    
    def delete(destination, gateway)
      %x[route delete #{destination} #{gateway}]
    end
    
    def change(destination, gateway)
      %x[route change #{destination} #{gateway}]
    end
    
    def get(destination)
      %x[route get #{destination}]
    end
    
    def monitor
      %x[route monitor]
    end
    
    protected
    
    def is_root?
      begin
        %x[id -u].chomp == '0'
      rescue
        false
      end
    end
  end
  
  class Segment
    def initialize(data, sequence, type, depth = 0, fragment = false)
      @data = data
      @depth = depth
      @fragment = fragment ? 1 : 0
      @sequence = sequence
      @type = type
    end
    
    attr_accessor :data, :depth, :fragment, :sequence, :type
    
    def to_s
      [VERSION, @type, @sequence, @fragment, @depth, @data] * ','
    end
  end
end
