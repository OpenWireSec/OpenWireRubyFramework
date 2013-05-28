class Test < Core::CoreShell

	#Our Initialize Class which makes sure our plugin is loaded properly! Re-Use this template and add what you need to the end of it
	def initialize
		#Basic Info:
		module_name='Test' 
		module_info={
			'Name'        => 'Test Module',
			'Version'     => 'v0.01b',
			'Description' => "Test String with spaces",
			'Author'      => 'Hood3dRob1n'
		}

		#Currently no checks on required vs option so set defaults whcih you plugin can handle and re-act to till new design....
		module_required={ 'SearchTerm' => "thisisateststringtomesswith" } #Hash full of "Required" Options
		module_optional={ 'CountryCode' => "COM", 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Hash of "Optional" Options

		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' } #These dont show up in menu as we dont use them here, but the underlying HTTP Module does so we need to have them so we can set them to nil to initialize our Http::EasyCurb Module & class effectively

		#If this is our first load, then make sure we register our plugin with the CORE::CoreShell Class so we can share nicely
		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			#Start things up we are being re-loaded by the run/exploit commadn
			showsupport
		end
	end

	def showsupport
		# DEMONSTRATION OF THE SUPPORT FUNCTIONS ENABLED THROUGH INHERITANCE
		puts "#{$module_required['SearchTerm'].hexme}".yellow
		foo = $module_required['SearchTerm'].hexme
		puts "#{foo.dehexme}".cyan
		puts "#{$module_required['SearchTerm'].asciime}".green
		puts "#{$module_required['SearchTerm'].rot13}".cyan
		puts "#{$module_required['SearchTerm'].mysqlhex}".red
		foo = $module_required['SearchTerm'].mysqlhex
		puts "#{foo.mysqlhexdecode}".light_green
		puts "#{$module_required['SearchTerm'].mysqlchar}".light_yellow
		puts "#{$module_required['SearchTerm'].mssqlchar}".white
		puts "#{$module_required['SearchTerm'].oraclechar}".yellow
		puts "foo/#{traverse(3)}".cyan
		puts "#{randz(26)}".light_green
		puts "#{$module_required['SearchTerm'].encode64.chomp}".cyan
		foo = "#{$module_required['SearchTerm'].encode64.chomp}"
		puts "#{foo.base64dec.chomp}".white
		puts "#{$module_required['SearchTerm'].wafcap}".red
		puts "#{$module_required['SearchTerm'].wafcap}".yellow
		puts "#{$module_required['SearchTerm'].wafcap}".green
		puts "MD5: #{md5($module_required['SearchTerm'])}".red
		puts "SHA1: #{sha1($module_required['SearchTerm'])}".yellow
		puts "JOOMLA: #{joomla($module_required['SearchTerm'])}".green
		puts "Current User: #{osuser}".cyan
		puts "UID: #{osuid}".cyan
		puts "EUID: #{oseuid}".cyan
		puts "REAL User: #{realuser}".yellow
		puts "#{$module_required['SearchTerm']} SELECT concat(something) benchmark(something, 10000) group_concat(somethingelse), FROM information_schema.tables or union select(substring(1,2,3)) FROM infroamtion_schema.columns or sleep(10)".wafcap.space2comment
		puts "#{$module_required['SearchTerm']} SELECT concat(something) benchmark(something, 10000) group_concat(somethingelse), FROM information_schema.tables or union select(substring(1,2,3)) FROM infroamtion_schema.columns or sleep(10)".wafcap.space2comment.commoncomment
		puts "#{$module_required['SearchTerm']} SELECT concat(something) benchmark(something, 10000) group_concat(somethingelse), FROM information_schema.tables or union select(substring(1,2,3)) FROM infroamtion_schema.columns or sleep(10)".wafcap.space2oa
		puts "#{$module_required['SearchTerm']} SELECT concat(something) benchmark(something, 10000) group_concat(somethingelse), FROM information_schema.tables or union select(substring(1,2,3)) FROM infroamtion_schema.columns or sleep(10)".wafcap.space2oa.commoncomment
		puts "#{$module_required['SearchTerm']} SELECT concat(something) benchmark(something, 10000) group_concat(somethingelse), FROM information_schema.tables or union select(substring(1,2,3)) FROM infroamtion_schema.columns or sleep(10)".commoncomment.wafcap
	end
end

Test.new
