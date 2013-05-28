# Shared Hosting Check using Alexa, SameIP, Bing, & Whois results

class SharedHosting < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='SharedHosting'
		module_info={
			'Name'        => 'Shared Hosting Check Module',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Plugin to run Shared Hosting and basic info lookup on provided target IP or DOMAIN",
			'Author'      => 'Hood3dRob1n'
		}
		module_required={ 'Target' => "google.com" }
		module_optional={ 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Hash of "Optional" Options

		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			checksharedhosting
		end
	end

	def checksharedhosting
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])

		shared="#{$module_required['Target']}"

		# Remote links we will use for some features
		alexa = 'http://www.alexa.com/search?q='
		sameip = 'http://sameip.org/ip/'

		url = URI.parse(shared) # so we can breakout link for some base checks in a few...

		#check scheme to see how our target link was passed and create host/domain accordinly
		if url.scheme == 'http' || url.scheme =='https' #if full http(s):// passed then use URI.parse value...
			domainName = url.host.sub(/www./, '') #remove www. from URI.parse host value for cleanest results
		else 
			domainName = shared #otherwise just use the domain name link passed (www.google.com or google.com)
		end

		ip = Resolv.getaddress(domainName) #Resolve Domain to IP to run check

		begin
			hostname = Resolv.getname(ip)  #Get hostname for IP
		rescue Resolv::ResolvError => e #If we get an error from Resolv due to unable to map to hostname
		  	$stderr.puts "[".light_red + "X".white + "] Unable to resolve IP to hostname".light_red + "...".white #print a message
			hostname = "Unable to Resolve" #set variable value so we can keep going instead of exiting ;)
		end

		#Check Alexa Ranking
		alexa += domainName # make new link combining base + domain name

		body = http._get("#{alexa}")
		doc = Hpricot(body[0]) # grab page and store in Hpricot Object for parsing....
		rank = doc.search("span[@class=\"traffic-stat-label\"]").first.inner_html # pull out the text we want
		rankNum = doc.search("span").search("a") # narrow down so we can pluck out results
		ranking = rankNum[1].inner_html.sub("\n", '')
		puts "[".light_green + "*".white + "] RECON RESULTS".light_green + ": ".white
		puts "[".light_green + "*".white + "] Domain: ".light_green + "#{domainName}".white #Domain Name
		puts "[".light_green + "*".white + "] Hostname: ".light_green + "#{hostname}".white #Hostname
		puts "[".light_green + "*".white + "] Main IP: ".light_green + "#{ip}".white #Main IP Domain resolves to
		puts "[".light_green + "*".white + "] #{rank}".light_green + " #{ranking}".white # Alexa Ranking
		puts
		puts "[".light_green + "*".white + "] All resolved IP addresses: ".light_green

		#Sometimes server loads split between many servers so might have multiple IP in use in such cases, see www.google.com for example
		i=0 # set base count
		ips = Resolv.each_address(domainName) do |x| 
			puts "[".light_green + "*".white + "] IP #{i+=1}: ".light_green + "#{x}".white #print ip and increment counter to keep unique
		end
		puts

		# Check for any MX or Mail Server records on target domain
		puts "[".light_green + "*".white + "] MX Records Found: ".light_green
		i=0 # set base count, again....
		Resolv::DNS.open do |dns| #Create DNS Resolv object
			mail_servers = dns.getresources(domainName, Resolv::DNS::Resource::IN::MX) # Pull MX records for domainName and place in variable mail_servers
			mail_servers.each do |mailsrv| # Create loop so we can print the MX results found w/ record preference
				puts "[".light_green + "*".white + "] MX Server #{i+=1}: ".light_green + "#{mailsrv.exchange.to_s}".white + " - ".cyan + "#{mailsrv.preference}".white
			end
		end
		puts

		# Check for Shared Hosting on target IP (using sameip.org)
		sameip += domainName # make new link combining base + domain name
		body = http._get(sameip)
		doc = Hpricot(body[0])


		foo=[] #prep array
		shared = doc.search("table").search("a") do |line| #narrow down page response to site lins held in table
			foo << line['href'] #place each referenced site link in our array
		end
		puts "[".light_green + "*".white + "] SameIp Results".light_green + ": ".white
		puts "[".light_green + "*".white + "] Found ".light_green + "#{foo.length}".white + " Sites hosted on Server at".light_green + ": #{ip}".white #use array length to determine how many sites there are

		foo.each do |site| #print out sites by cycling through our array
			puts "[".light_green + "*".white + "] ".light_green + "#{site}".white
		end
	end
end

SharedHosting.new


