# Simple NMAP Wrapper
class NmapWrap < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='NmapWrap'
		module_info={
			'Name'        => 'NMAP Wrapper Module',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Wrapper Script for the NMAP Binary to run several types of port scans. If you don't like it, then exit and use the real one directly :p\n\n\tTarget => SINGLE IP/DOMAIN to Scan\n\tScanType => Defines the Scan Type, options include: SYN, ACK, XMAS, UDP\n\tSpecificPort => Overrides the NMAP defaults and only scans the defined port(s)\n\tPingCheck => Treat Host as Online (will Ping target before scan to check if up when set to 'True')\n\tOS => Enable OS Detection by setting to 'True' or 'False'\n\tVersion => Enable Version Detection by setting to 'True' or 'False'\n\tScripts => Enable or Disable the default NMAP NSE Script Scan by setting value to 'True' or 'False'\n\tOutput => Enable or Disable XML Output Logging of Scan Results to ./plugins/results/<target>.xml",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "192.168.1.69", 'ScanType' => 'SYN' } 
		module_optional={ 'Version' => 'True', 'OS' => 'True', 'PingCheck' => 'False', 'SpecificPort' => "nil", 'Scripts' => 'True' } #Hash of "Optional" Options

		@non_set_private_options={ 'Output' => 'True', 'Verbose' => 'True' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			@bin=`which nmap`.chomp #Find out the path to NMAP if it existis
			check=$?.to_s.split(' ')[3] #Check if we were able to find the path in step above or not (0=true, 1=false)
			if not check.to_i == 0
				puts "[".light_red + "X".white + "] NMAP Does Not appear to be installed on the underlying OS, can't use this plugin without it".light_red + "!".white
				puts
			else
				if not $module_optional['SpecificPort'] == 'nil'
					if not /^\d+,{1,}$/.match("#{$module_optional['SpecificPort']}") #Does it appear to be valid Port?
						puts "[".light_red + "X".white + "] Provided Ports are not valid digits or they are not in a valid comma separated format".light_red + "!".white
					else
						nmapwrap
					end
				else
					nmapwrap
				end
			end
		end
	end

	def nmapwrap
		nmapstr=''

		if $module_required['ScanType'].upcase == 'SYN'
			#Enable SYN Scan
			nmapstr += '-sS '
		elsif $module_required['ScanType'].upcase == 'ACK'
			#Enable ACK Scan
			nmapstr += '-sA '
		elsif $module_required['ScanType'].upcase == 'XMAS'
			#Enable XMAS Scan
			nmapstr += '-sX '
		elsif $module_required['ScanType'].upcase == 'UDP'
			#Enable UDP Scan
			nmapstr += '-sU '
		else
			#Enable SYN Scan by Default
			nmapstr += '-sS '
		end

		if $module_optional['PingCheck'].downcase == 'false'
			#Disable Host Discovery Ping Scan prior to scan
			nmapstr += '-Pn '
		end

		if $module_optional['Version'].downcase == 'true' and $module_optional['OS'].downcase == 'true'
			#Enable Aggressive Detection of OS, Services (& Scipt Scanning)
			nmapstr += '-A '
		else
			if $module_optional['Version'].downcase == 'true'
				#Enable Version Detection
				nmapstr += '-sV '
			end
			if $module_optional['OS'].downcase == 'true'
				#Enable OS Detection
				nmapstr += '-O '
			end
		end

		if not $module_optional['SpecificPort'] == 'nil'
			#Run Port Scan ONLY on defined ports
			nmapstr += "-p  #{$module_optional['SpecificPort'].gsub('&&', '').gsub(';', '')} "
		end

		if $module_optional['Scripts'].downcase == 'true'
			#Enable Script Scanning with Defaults
			nmapstr += '-sC '
		end

		if @non_set_private_options['Output'].downcase == 'true'
			#Create a XML Output File Based on Scan Results....
			resDir = "#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('&&', '').gsub(';', '').gsub('/', '_')}"
			Dir.mkdir(resDir) unless File.exists?(resDir)
			nmapstr += "-oX #{resDir}"
		end

		#Now run it all.....
		if not @non_set_private_options['Verbose'].downcase == 'false'
			system("#{@bin} #{nmapstr} #{$module_required['Target']}") #Can See All Results IN Terminal Console (as opposed to Shell.exec() or backticks methods)
		else
			################### STILL WORKING ON PARSING OUTPUT FULLY ###########################
			FileUtils.rm("#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}") if File.exists?("#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}")
			`nmap --host-timeout 90 #{nmapstr} #{$module_required['Target']}` #No results displayed, so need to use output option and parse from XML file and display accordingly.....
			xmlparsing #Go parse & present results for above....
		end
		File.chmod(0644, "#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}") if File.exists?("./plugins/results/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}") #Incase we run as sudo we want results readable after without too many issues.....
		FileUtils.chown("#{realuser}", "#{realuser}", "#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}") if File.exists?("#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}") 
	end

	def xmlparsing
		xml_file = File.open("#{$results}/#{$module_required['Target'].gsub('.', '_').gsub('/', '_')}")
		xml = Nokogiri::XML(xml_file) #Get our NMAP Results File Read into a Nokogiri XML Object we can further use to pick out data
		xml_file.close

		target = xml.xpath("//address")[0]['addr'] #Target Who Got NMAP'd
		portscount = xml.xpath("//port").size #Number of Port Results in NMAP Report

		count=0
		#Cycle Through Port Entries and Fish Out Results for each as we go....
		while count.to_i < portscount.to_i
			port = xml.xpath("//port")[count]['portid'] || '' #Port Number for Result
			protocol = xml.xpath("//port")[count]['protocol'] || ''#Protocol Running on Port
			portState = xml.xpath("//port//state")[count]['state'] || ''#Port State (open, filtered, closed)
			service = xml.xpath("//port//service")[count]['name'] || '' #Port Service if Known
			serviceName = xml.xpath("//port//service")[count]['product'] || ''#Port Service/Product Name If Known
			serviceVersion = xml.xpath("//port//service")[count]['version'] || '' #Port Service/Product Version If Known
			serviceExtra = xml.xpath("//port//service")[count]['extrainfo'] || ''#Additional Info Grabbed
			verinfo = serviceName + ' ' + serviceVersion + ' ' + "(#{serviceExtra})"

			if portState =~ /open/i
				puts "[".light_green + "*".white + "] Port(".light_green + "#{port}".white + ") Protocol(".light_green + "#{protocol.upcase}".white + ") Service(".light_green + "#{service}".white + ") Banner(".light_green + "#{verinfo}".white + ")".light_green
			elsif portState =~ /filtered/i
				puts "[".light_yellow + "-".white + "] Filtered Port".light_yellow + ": #{port}".white
			else
				puts "[".light_red + "X".white + "] Closed Port".light_red + ": #{port}".white
			end
			count = count.to_i + 1
		end
	end
end

NmapWrap.new
