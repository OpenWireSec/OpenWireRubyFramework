# ColdFusion Version Scanner Plugin
#
# Use to detect the Version of Cold Fusion running which might be helpful later....
#
class ColdFusionVersionCheck < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='ColdFusionVersionCheck'
		module_info={
			'Name'        => 'Cold Fusion Version Check',
			'Version'     => 'v0.01b',
			'Description' => "This runs a few checks for common files associated with ColdFusion Servers vulnerabilties and version leakage which may be usefull elsewhere. Just give it a web address to run check from and it will do its thing and present findings...\n\tTarget => The target site and base to run checks for ColdFusion files\n\tEX: http://www.site.co.za/\n\tEX: http://192.168.1.69:8080/",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'Target' => "http://www.papadi.co.za/" } 
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' }
		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			cfversion
		end
	end

	def cfversion
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		#Common Admin Page Files which can give away the version in one way or another....
		versionchecks = [ "/CFIDE/administrator/index.cfm", "/CFIDE/administrator/enter.cfm", "/CFIDE/componentutils/", "/CFIDE/componentutils/index.cfm", "/CFIDE/componentutils/login.cfm", "/CFIDE/adminapi/base.cfc?wsdl" ]

		puts "[".light_green + "*".white + "] Running ColdFusion Version Checker against".light_green + ": #{$module_required['Target']}".white
		alinks=[]
		versionchecks.each do |vchklnk|
			if vchklnk =~ /wsdl/
				admin=0
			else
				admin=1
			end
			test = "#{$module_required['Target'].sub(/\/$/, '')}#{vchklnk}"
			body = http._get(test)
			doc = Hpricot(body[0])

			if body[1] == 200
				if alinks.include?(test) #Did we already check this one?
					#do nothing
				else
					if admin.to_i == 1
						puts "[".light_green + " ADMIN ".white + "] ".light_green + "#{test}".white
					else
						puts "[".light_green + " WSDL ".white + "] ".light_green + "#{test}".white
					end
					alinks << "#{test}"
					if body[0] =~ />\s*Version:\s*(.*)<\/strong\><br\s\//m
						v = $1
						out = (v =~ /^6/) ? "Adobe ColdFusion MX6 #{v}" : "Adobe ColdFusion MX7 #{v}"
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /Version\s*(.*)\s+<\/strong\><br\s\//m
						v = $1
						out = (v =~ /^6/) ? "Adobe ColdFusion MX6 #{v}" : "Adobe ColdFusion MX7 #{v}"
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /<meta name=\"Author\" content=\"Copyright \(c\) 1995-2006 Adobe/m
						out = "Adobe ColdFusion 8"
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /<meta name=\"Author\" content=\"Copyright \(c\) 1995-2010 Adobe/m
						out = "Adobe ColdFusion 9"
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /<meta name=\"Author\" content=\"Copyright \(c\) 1995\-2009 Adobe Systems\, Inc\. All rights reserved/m
						out = "Adobe ColdFusion 9"
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /<meta name=\"Keywords\" content=\"(.*)\">\s+<meta name/m
						out = $1.split(/,/)[0]
						puts "\tVersion".light_green + ": #{out}".white
					elsif body[0] =~ /<!--WSDL created by (.+)-->/i
						out = $1
						puts "\tVersion".light_green + ": #{out}".white
					else
						puts "\t=> Can't Determine ColdFusion Version from this link".light_yellow + ".........".white
					end
				end
			elsif body[1] == 301 or body[1] == 302
				if alinks.include?("#{test}")
					#do nothing
				else
					puts "[".light_green + "*".white + "] ".light_green + "#{test}".white
					puts "\t=> Redirect".light_yellow + "!".white
					alinks << "#{test}"
				end
			elsif body[1] == 401 or body[1] == 403
				if alinks.include?("#{test}")
					#do nothing
				else
					puts "[".light_yellow + " FORBIDDEN ".white + "] ".light_yellow + "#{test}".white
					alinks << "#{test}"
				end
			else
				if alinks.include?("#{test}")
					#do nothing
				else
					puts "[".light_red + " Not Found ".white + "] ".light_red + "#{test}".white
					alinks << "#{test}"
				end
			end
		end

		##### ENTERPRISE vs. STANDARD TEST #####
		test = "#{$module_required['Target'].sub(/\/$/, '')}/#{randz(21)}.jsp"
		body = http._get(test)
		if body[1] == 200
			puts "[".light_green + " FOO TEST ".white + "] ".light_green + "#{test}".white
			puts "[".light_yellow + "X".white + "] Server responded 200 to our bogus request".light_yellow + "?".white
			puts "[".light_yellow + "X".white + "] CF Edition".light_yellow + ": Enterprise".white
		elsif body[1] == 404
			puts "[".light_green + " FOO TEST ".white + "] ".light_green + "#{test}".white
			puts "[".light_green + "*".white + "] CF Edition".light_green + ": Enterprise".white
		elsif body[1] == 500
			puts "[".light_green + " FOO TEST ".white + "] ".light_green + "#{test}".white
			puts "[".light_green + "*".white + "] CF Edition".light_green + ": Standard".white
		end

		#Find Server Type Using 'Server' Header Field in Server Response
		if body[3] =~ /server: (.+)/i
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
	end
end

ColdFusionVersionCheck.new
