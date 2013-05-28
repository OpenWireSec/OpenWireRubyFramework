# Bing Search Plugin Script

#Make our new PLugin Inherits things from our Core::CoreShell Module/Class so we can properly register and load our code and functions properly between the two......
class BingSearch < Core::CoreShell
 #Require any special gems your plugin needs. We should probably build a basic check here to catch instances where used doesnt have gems installed. As these are plugins if your using non-std libs then check your self to be nice :p

	#Our Initialize Class which makes sure our plugin is loaded properly! Re-Use this template and add what you need to the end of it
	def initialize
		#Basic Info:
		module_name='BingSearch' #This is the Name of our Plugin Module
		#Next we establish some basic info which will be presented to the user
		#Hash Should include "Name", "Version", "Description", & "Author" entries
		module_info={
			'Name'        => 'Bing Search Module',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Bing Search Assistant. You provide it with the search term or query and it will run it through Bing! Search Engine and return all of the found links. Nothing more, nothing less....",
			'Author'      => 'Hood3dRob1n'
		}

		#Currently no checks on required vs option so set defaults whcih you plugin can handle and re-act to till new design....
		module_required={ 'SearchTerm' => ".php?id=1" } #Hash full of "Required" Options
		module_optional={ 'CountryCode' => "COM", 'ProxyIp' => 'nil', 'ProxyPort' => 'nil', 'Username' => 'nil', 'Password' => 'nil' } #Hash of "Optional" Options

		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil' } #These dont show up in menu as we dont use them here, but the underlying HTTP Module does so we need to have them so we can set them to nil to initialize our Http::EasyCurb Module & class effectively

		#If this is our first load, then make sure we register our plugin with the CORE::CoreShell Class so we can share nicely
		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			#Start things up we are being re-loaded by the run/exploit commadn
			search
		end
	end

	def search
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],$module_optional['Username'],$module_optional['Password'])
		#Now we can make requests.....

		puts "[".light_green + "*".white + "] Dork".light_green + ": #{$module_required['SearchTerm']}".white
		puts "[".light_green + "*".white + "] Country Code".light_green + ": #{$module_optional['CountryCode']}".white
		puts "[".light_green + "*".white + "] Searching some shit on Bing now".light_green + ".....".white

		#Quick Loop to grab the required pages we will need to fetch from Bing to get results
		count=9
		secondcount=1
		arrayoflinks=[]
		while count.to_i <= 225 do
			dork="#{$module_required['SearchTerm']}"
			bing = 'http://www.bing.com/search?q=' + dork.to_s + '&qs=n&pq=' + dork.to_s + '&sc=8-5&sp=-1&sk=&first=' + count.to_s + '&FORM=PORE'
			arrayoflinks << "#{bing}"
			count = count.to_i + 12
		end

		# Use Curl's Multi=Mode to make multiple requests faster given an array of GET links
		mresponses = http.multi_get(arrayoflinks)
		usablelinks=[]
		arrayoflinks.each do |url|
			page = Nokogiri::HTML(mresponses[url].body_str) #Wrap results with Nokogiri to make parsing easy peasy
			possibles = page.css("a") #parse out the <a> elements which contain our href links 
			possibles.select do |link| #cycle through possibles array and print links found
				begin
					url = URI.parse(link['href']) #use URI.parse to build check around for links
					if url.scheme == 'http' || url.scheme =='https' #if full http(s):// passed then use link
						usablelinks << link['href']
					end
				rescue URI::InvalidURIError => err 
					# If bad link cause error cause its not a link dont freak out....
				end
			end
			# Use \r to write over previous line (currently causes blank until last one finishes, meh)
			print "\r" + "[".light_green + "*".white + "] Number of Links Found: ".light_green + "#{usablelinks.length}".white 
		end
		puts
		goodlinks=[]
		usablelinks = usablelinks.uniq #remove any duplicate links
		usablelinks.each do |url|
			if url =~ /msn\.com/
				#Fuq MSN & Their BS
			elsif url =~ /microsoft\.com/
				#Fuq Microshit & Their BS too (one in of the same, no?)
			else
				goodlinks << url #Place our remaining good links in the goodlinks array to present to user in a sec....
			end
		end
		puts "[".light_green + "*".white + "] Number of Usable Links:".light_green + " #{goodlinks.length}".white 
		puts "[".light_green + "*".white + "] Found Links".light_green + ": ".white 
		results = File.open("./plugins/results/bing_search.results", "w+")  #Open our file handle (will overwrite existing file if present)
		goodlinks.each do |url|
			puts "#{url}".white
			results.puts url #print results to storage file for safe keeping (handle.puts)
		end
		results.close #close our file handle we opened a minute ago
		File.chmod(0644, "./plugins/results/bing_search.results") #Incase we run as sudo we want results readable after without too many issues.....
		FileUtils.chown("#{realuser}", "#{realuser}", "./plugins/results/bing_search.results")
		puts
	end
end

BingSearch.new
