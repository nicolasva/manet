#!/usr/bin/ruby

class Choix_machines
	def initialize(machines)
		@machines = machines
	end

	def choix_machines?
		@machines == "linux"
	end
end

class Route
	def initialize(adresse_depart)
		choix_machines = Choix_machines.new(%x[uname].chomp)
		@choix_system = choix_machines.choix_machines?
		@adress = adresse_depart
	end

	def sup_route
		( @choix_system ? sup_route_linux : sup_route_bsd ) ? "La suppression de cette route s'est bien déroulée elle n'est plus disponible" : "La suppression de cette route ne s'est pas déroulée correctement elle est encore disponible"
	end

	def add_route_bsd(choix_add_route,choix_adresse_destination)
		system("route add #{choix_add_route} #{@adress} #{choix_adresse_destination}") ? "L'ajout de cette route s'est bien d&#233;roul&#233;e elle est d&#233;sormais disponible" : "BSD L'ajout de cette route ne s'est pas correctement d&#233;roul&#233;e elle n'est pas disponible" 
	end

	def add_route_linux(choix_add_route,netmask,gateway)
		system("route add #{choix_add_route} #{@adress} netmask #{netmask} gw #{gateway}") ? "L'ajout de cette route s'est bien d&#233;roul&#233;e elle est d&#233;sormais disponible" : "L'ajout de cette route ne s'est pas d&#233;roul&#233;e correctement elle n'est pas disponible" 
	end

	protected
	def sup_route_bsd
		system("route delete -net #{@adress}")
	end

	def sup_route_linux
		system("route del -net #{@dress}")
	end

end

class Netstat
	def initialize
	end

	def execute_netstat
		%x[netstat -rf inet]
	end

	def netstat_i
		%x[netstat -i]
	end
end

class ReaderNetstat < Netstat
	def initialize
		choix_machines = Choix_machines.new(%x[uname].chomp)
		@choix_machines = choix_machines.choix_machines?
		@tab_netstat = @tab_valid = Array.new
		@titre_netstat_i = @titre_netstat_r = ""
	end

	def read_file		
		@tab_netstat = @tab_valid = []
		i_ligne = 0
		execute_netstat.each_line{ |ligne|
			if i_ligne > 3
			@tab_netstat = ligne.split(" ")
			@tab_valid.push(@tab_netstat)
			@tab_netstat = Array.new
			end
			i_ligne = i_ligne + 1
		}
		@tab_valid
	end

	def read_netstat_i	
		@tab_netstat = @tab_valid = []
		i_ligne = 0
		netstat_i.each_line{ |ligne|
			@tab_netstat = ligne.split(" ")
			unless @tab_netstat[0] == "Name"
			@tab_valid.push(@tab_netstat)
			@tab_netstat = Array.new
			end
		}
		@tab_valid
	end

	def titre_colonne_netstat_i
		@choix_machines ? [[:Iface, 50], [:MTU, 50], [:Met, 50], [:RX_OK, 50], [:RX_ERR, 50], [:RX_DRP, 50], [:RX_OVR, 50], [:TX_OK, 50], [:TX_ERR, 50], [:TX_DRP, 50], [:TX_OVR, 50], [:Flag, 40]] : [[:name, 46], [:Mtu, 50], [:Network, 100], [:Address, 150], [:Ipkts, 42], [:Ierrs, 40], [:Opkts, 53], [:Oerrs, 50], [:Coll, 25]]	
	end

	def titre_colonne_netstat_rf
		@choix_machines ? [[:Destination, 250], [:Passerelle, 160], [:Genmask, 160], [:Indic, 100], [:Mss, 50], [:Fenetre, 100], [:irtt, 100], [:Iface, 100]] : [[:Destination, 250], [:Gateway, 120], [:Flags, 45], [:Refs, 38], [:Use, 32], [:Netif, 48], [:Expire, 40]]
	end

	def hash_netstat
		hash = Hash.new
		hash = {:items=>read_file}
		hash
	end
end
