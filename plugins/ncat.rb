# Very Simple NCAT Wrapper
class NcatWrap < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='NcatWrap'
		module_info={
			'Name'        => 'Ncat Wrapper Module',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Wrapper Script for the Ncat Binary, from the makers of Nmap. Supports 'Listen' or 'Call' Modes for connecting with bind or reverse shells",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Mode' => "Listen", 'Ip' => "127.0.0.1", 'Port' => '31337' } 
		module_optional={ 'Verbose' => 'True' } #Hash of "Optional" Options

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
						ncatwrap
					else
						$module_optional['Verbose'] = 'True'
						ncatwrap
					end
				end
			end
		end
	end

	def ncatwrap
		@bin=`which ncat`.chomp #Find out the path to NCAT
		check=$?.to_s.split(' ')[3] #Check if we were able to find the path in step above or not (0=true, 1=false)
		if not check.to_i == 0
			puts "[".light_red + "X".white + "] NCAT Does Not appear to be installed on the underlying OS, can't use this plugin without it".light_red + "!".white
			puts
		else
			#Display basic Setup Info Used
			puts "[".light_green + "*".white + "] Mode".light_green + ": #{$module_required['Mode']}".white
			puts "[".light_green + "*".white + "] IP".light_green + ": #{$module_required['Ip']}".white
			puts "[".light_green + "*".white + "] Port".light_green + ": #{$module_required['Port']}".white
			if not $module_optional['Password'] == 'nil'
				puts "[".light_green + "*".white + "] Password".light_green + ": #{$module_optional['Password']}".white
			end
			if not $module_optional['Verbose'] == 'False'
				puts "[".light_green + "*".white + "] Verbose".light_green + ": #{$module_optional['Verbose']}".white
			end

			#Launch NCAT as needed....
			if $module_required['Mode'] == 'Listen'
				puts "[".light_green + "*".white + "] Setting Up Local Listener on port ".light_green + "#{$module_required['Port']}".white + " now".light_green + ".....".white
				ncatlisten
			elsif $module_required['Mode'] == 'Call'
				puts "[".light_green + "*".white + "] Trying to connect to ".light_green + "#{$module_required['Ip']}".white + " on port ".light_green + "#{$module_required['Port']}".white + " now".light_green + ".....".white
				ncatcall
			else
				puts "[".light_red + "X".white + "] Unknown Mode Set".light_red + "!".white
				puts "[".light_red + "X".white + "] Needs to be set to 'Listen' or 'Call'".light_red + "!".white
				puts "[".light_red + "X".white + "] Double check variables and try again".light_red + "......".white
				puts
			end
		end
	end

	def ncatlisten
		#use GSUB to remove any potential evil cmd trix someone might try to pass to our system call (that slipt passed our base checks in ncatwrap)
		if $module_optional['Verbose'].downcase == 'false'
			system("#{@bin} -l #{$module_required['Port'].gsub('&&', '').gsub(';', '')}") 
		else
			system("#{@bin} -lv #{$module_required['Port'].gsub('&&', '').gsub(';', '')}")
		end
	end

	def ncatcall
		#use GSUB to remove any potential evil cmd trix someone might try to pass to our system call
		if $module_optional['Verbose'].downcase == 'false'
			system("#{@bin} #{$module_required['Ip'].gsub('&&', '').gsub(';', '')} #{$module_required['Port'].gsub('&&', '').gsub(';', '')}")
		else
			system("#{@bin} -v #{$module_required['Ip'].gsub('&&', '').gsub(';', '')} #{$module_required['Port'].gsub('&&', '').gsub(';', '')}")
		end
	end
end

NcatWrap.new
