# WhatsMyIP Plugin to find Internal & External IP Address

class WhatsMyIP < Core::CoreShell
	require 'socket'

	def initialize
		#Basic Info:
		module_name='WhatsMyIP'
		module_info={
			'Name'        => 'WhatsMyIP Plugin',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Plugin to easily find your Internal & External IP Addresses",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'None' => 'Required' } #None Needed,
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } 
		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			whatsmyip
		end
	end

	def getLocal
		orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  #RevDNS = Off, so dont resolve!
		UDPSocket.open do |sox|
			sox.connect '74.125.227.32', 1 #this is Google, but we dont actually send anything, just looking for how machine would if we did :p
			sox.addr.last
		end
		rescue SocketError => e # sox shit happens?
			puts "Socket Error!".light_red
			puts "\t=> #{e}".light_red
		ensure
			Socket.do_not_reverse_lookup = orig
	end

	def getExternal
		#Simply fetch the external from dyndns, not so much magic :p
		body, code, time = @http._get('http://checkip.dyndns.org/')
		if body =~ /(\d+\.\d+\.\d+\.\d+)/
			ip=$1
			@ip=ip.chomp
		end
	end

	def whatsmyip
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		@http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		getExternal
		puts "[".light_green + "*".white + "] External IP: ".light_green + "#{@ip}".white
		puts "[".light_green + "*".white + "] Internal IP: ".light_green + "#{getLocal}".white
	end
end

WhatsMyIP.new
