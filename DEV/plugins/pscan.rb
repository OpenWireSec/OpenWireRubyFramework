# Simple Port Scanner using basic sockets connections to test if port is open or not

class Pscan < Core::CoreShell

	#Our Initialize Class which makes sure our plugin is loaded properly! Re-Use this template and add what you need to the end of it
	def initialize
		#Basic Info:
		module_name='pScan' 
		module_info={
			'Name'        => 'pScan Port Scanner',
			'Version'     => 'v0.01b',
			'Description' => "Simple Ruby TCPSockets Based Port Scanner. Provide the target IP, start and end ports for scanning and it will run a simple check and report the findings.\n\tTarget => Target IP or Domain to Scan\n\tStart => Starting Port to Scan from\n\tEnd - Ending Port to Stop Scan on\n\tCSV => takes a comma separated list of ports to scan. This overrides the default Start/End options and only tests those passed",
			'Author'      => 'Hood3dRob1n'
		}

		#Currently no checks on required vs option so set defaults whcih you plugin can handle and re-act to till new design....
		module_required={ 'Target' => "74.125.225.242", 'Start' => '0', 'End' => '1024' } #Hash full of "Required" Options
		module_optional={ 'CSV' => 'nil' }

		@non_set_private_options={}

		#If this is our first load, then make sure we register our plugin with the CORE::CoreShell Class so we can share nicely
		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			target="#{$module_required['Target']}"

			if not /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{$module_required['Target']}")
				url = URI.parse(target)
				if url.scheme == 'http' || url.scheme =='https'
					domainName = url.host.sub(/www./, '')
				else 
					domainName = target
				end
				@ip = Resolv.getaddress(domainName)
			else
				@ip = target
			end
			if $module_optional['CSV'] == 'nil'
				if (not $module_required['Start'].to_i < 65535 and not $module_required['Start'].to_i > 0) or (not $module_required['End'].to_i < 65536 and not $module_required['End'].to_i < $module_required['Start'].to_i)
					puts "[".light_red + "X".white + "] Provided Start/Ending Port are not valid".light_red + "!".white
				else
					@bad=[]
					@good=[]
					portcheckrange($module_required['Start'], $module_required['End'])
				end
			else
				if not $module_optional['CSV'] =~ /\d+,{1,}/
					puts "[".light_red + "X".white + "] Provided CSV Port Listing doesnt seem to be a valid comma separated port list".light_red + "!".white
				else
					@bad=[]
					@good=[]
					arrayofports = $module_optional['CSV'].split(',')
					portcheckspecifics(arrayofports)
				end
			end
		end
	end

	def portcheckrange(starting, ending)
		puts "[".light_green + "*".white + "] Running Port Scan using provided info".light_green + "....".white
		puts "[".light_green + "*".white + "] Starting Port".light_green + ": #{starting}".white
		puts "[".light_green + "*".white + "] Ending Port".light_green + ": #{ending}".white
		sleep(2)
		#Run Port Scan from Starting Port through Ending Port (0-65535)
		while starting.to_i < ending.to_i
			portchecker(@ip, starting)
			starting = starting.to_i + 1
		end
		if @good.empty?
			puts "[".light_red + "X".white + "] Doesn't appear any open ports were found".light_red + "!".white
		end
	end

	def portcheckspecifics(arrayofports)
		puts "[".light_green + "*".white + "] Running Port Scan using provided info".light_green + "....".white
		puts "[".light_green + "*".white + "] Checking Ports".light_green + ": #{arrayofports.join(',')}".white
		sleep(2)
		#Run Port Scan on specific ports provided in array [ 21, 22, 23, 80, 8080, 3389 ]
		arrayofports.each do |port|
			portchecker(@ip, port)
		end
		if @good.empty?
			puts "[".light_red + "X".white + "] Doesn't appear any open ports were found".light_red + "!".white
		end
	end

	def portchecker(ip, port)
		begin
			pscan = TCPSocket.open(ip, port.to_i)
			pscan.close
		rescue  
			@bad << port
		else
			@good << port
			presentports(port)
		end
	end

	def presentports(portopen)
		#Present the results....
		if portopen.to_i == 21
			puts "\t#{portopen}".white + " => ".light_green + "FTP".white
		elsif portopen.to_i == 22
			puts "\t#{portopen}".white + " => ".light_green + "SSH".white
		elsif portopen.to_i == 25
			puts "\t#{portopen}".white + " => ".light_green + "SMTP".white
		elsif portopen.to_i == 43
			puts "\t#{portopen}".white + " => ".light_green + "WHOIS".white
		elsif portopen.to_i == 80
			puts "\t#{portopen}".white + " => ".light_green + "WWW/HTTP".white
		elsif portopen.to_i == 110
			puts "\t#{portopen}".white + " => ".light_green + "POP3".white
		elsif portopen.to_i == 111
			puts "\t#{portopen}".white + " => ".light_green + "RPC".white
		elsif portopen.to_i == 135
			puts "\t#{portopen}".white + " => ".light_green + "DCOM".white
		elsif portopen.to_i == 137 or portopen.to_i == 138 or portopen.to_i == 139
			puts "\t#{portopen}".white + " => ".light_green + "NetBIOS/SMB".white
		elsif portopen.to_i == 143
			puts "\t#{portopen}".white + " => ".light_green + "IMAP4".white
		elsif portopen.to_i == 161
			puts "\t#{portopen}".white + " => ".light_green + "SNMP".white
		elsif portopen.to_i == 220
			puts "\t#{portopen}".white + " => ".light_green + "IMAP3".white
		elsif portopen.to_i == 389
			puts "\t#{portopen}".white + " => ".light_green + "LDAP".white
		elsif portopen.to_i == 443
			puts "\t#{portopen}".white + " => ".light_green + "HTTPS".white
		elsif portopen.to_i == 445
			puts "\t#{portopen}".white + " => ".light_green + "SMB".white
		elsif portopen.to_i == 888
			puts "\t#{portopen}".white + " => ".light_green + "CD DBP/AccessBuilder".white
		elsif portopen.to_i == 990
			puts "\t#{portopen}".white + " => ".light_green + "SFTP".white
		elsif portopen.to_i == 993
			puts "\t#{portopen}".white + " => ".light_green + "Secure IMAP".white
		elsif portopen.to_i == 995
			puts "\t#{portopen}".white + " => ".light_green + "Secure POP3".white
		elsif portopen.to_i == 1352
			puts "\t#{portopen}".white + " => ".light_green + "LotusNotes".white
		elsif portopen.to_i == 1433
			puts "\t#{portopen}".white + " => ".light_green + "MS-SQL".white
		elsif portopen.to_i == 1521
			puts "\t#{portopen}".white + " => ".light_green + "Oracle".white
		elsif portopen.to_i == 2082 or portopen.to_i == 2083 or portopen.to_i == 2086 or portopen.to_i == 2087 or portopen.to_i == 2095 or portopen.to_i == 2096
			puts "\t#{portopen}".white + " => ".light_green + "cPanel".white
		elsif portopen.to_i == 2222
			puts "\t#{portopen}".white + " => ".light_green + "DirectAdmin".white
		elsif portopen.to_i == 3306
			puts "\t#{portopen}".white + " => ".light_green + "MySQL".white
		elsif portopen.to_i == 3389
			puts "\t#{portopen}".white + " => ".light_green + "RDP".white
		elsif portopen.to_i == 5632
			puts "\t#{portopen}".white + " => ".light_green + "PCAnywhere".white
		elsif portopen.to_i == 5800 or portopen.to_i == 5900
			puts "\t#{portopen}".white + " => ".light_green + "VNC".white
		elsif portopen.to_i == 6000
			puts "\t#{portopen}".white + " => ".light_green + "X-Server".white
		elsif portopen.to_i == 8080
			puts "\t#{portopen}".white + " => ".light_green + "HTTP".white
		elsif portopen.to_i == 8087 or portopen.to_i == 8443
			puts "\t#{portopen}".white + " => ".light_green + "PleskPanel".white
		elsif portopen.to_i == 10000
			puts "\t#{portopen}".white + " => ".light_green + "WebMin".white
		else
			puts "[".light_green + " #{portopen} ".white + "]".light_green
		end
	end
end

Pscan.new
