# Pure Ruby NetCat Listener & Connector
class RubyCat < Core::CoreShell
	require 'ostruct'
	require 'socket'

	def initialize
		#Basic Info:
		module_name='RubyCat'
		module_info={
			'Name'        => 'Pure Ruby NetCat Module',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Implementation of NetCat in Pure Ruby. Supports 'Listen' or 'Call' Modes for connecting with bind or reverse shells",
			'Author'      => "Module By: Hood3dRob1n\nOriginal Code: 4thmouse.com"
		}

		module_required={ 'Mode' => "Listen", 'Ip' => "127.0.0.1", 'Port' => '31337' } 
		module_optional={} #Don't Need for this one

		@non_set_private_options='' #Don't Need for this

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			#Make sure we don some basic checks before we pass things off to system() You'd be sooo cool if you sploited it :p
			if not /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{$module_required['Ip']}") #Match valid IP structure?
				puts "[".light_red + "X".white + "] Provided IP Is not a Valid IP".light_red + "!".white
			else
				if not /^\d{1,5}$/.match("#{$module_required['Port']}") #Does it appear to be valid Port?
					puts "[".light_red + "X".white + "] Provided Port Is not a Valid Port".light_red + "!".white
				else
					if $module_optional['Verbose'].downcase == 'false' or $module_optional['Verbose'].downcase == 'true'
						rbnc
					else
						$module_optional['Verbose'] = 'True'
						rbnc
					end
				end
			end
		end
	end

	def rbnc
		#Display basic Setup Info Used
		puts "[".light_green + "*".white + "] Mode".light_green + ": #{$module_required['Mode']}".white
		puts "[".light_green + "*".white + "] IP".light_green + ": #{$module_required['Ip']}".white
		puts "[".light_green + "*".white + "] Port".light_green + ": #{$module_required['Port']}".white

		#Launch RubyCat as needed....
		if $module_required['Mode'] == 'Listen'
			puts "[".light_green + "*".white + "] Setting Up Local Listener on port ".light_green + "#{$module_required['Port']}".white + " now".light_green + ".....".white
		elsif $module_required['Mode'] == 'Call'
			puts "[".light_green + "*".white + "] Trying to connect to ".light_green + "#{$module_required['Ip']}".white + " on port ".light_green + "#{$module_required['Port']}".white + " now".light_green + ".....".white
		end
		connect_socket
		forward_data
	end

	def connect_socket
		if($module_required['Mode'] == 'Call')
			@socket = TCPSocket.open($module_required['Ip'], $module_required['Port'])
		else
			server = TCPServer.new($module_required['Port'])
			server.listen( 1)
			@socket = server.accept
		end
	end

	def forward_data
		while(true)
			if(IO.select([],[],[@socket, STDIN],0))
				socket.close
				return
			end
			begin
				while( (data = @socket.recv_nonblock(100)) != "")
					STDOUT.write(data);
				end
				break
			rescue Errno::EAGAIN
			end
			begin
				while( (data = STDIN.read_nonblock(100)) != "")
					@socket.write(data);
				end
				break
			rescue Errno::EAGAIN
			rescue EOFError
				break
			end
			IO.select([@socket, STDIN], [@socket, STDIN], [@socket, STDIN])
		end
	end
end

RubyCat.new
