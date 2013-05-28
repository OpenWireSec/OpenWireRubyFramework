# Very Simple Site Crawler
# Logs All output to results/<site>/crawler.links
# It's very basic, doesn't differentiate from GET vs POST,.....yet
#

class SiteCrawler < Core::CoreShell
	def initialize
		module_name='SiteCrawler'
		module_info={
			'Name'        => 'Simple Site Crawler',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Website Crawler. It will connect to provided base directory and scan source for all linked links and will store the raw results to results/<site>/crawler.links, with sorted results going in named files accordingly.\n\n\tTarget => The Target URL to run Crawler Session from\n\tThreads => Number of Crawler Threads to run (Default is safe at 10)\n\tLimit => Links Limit per Page while crawling (0=None)\n\tRobots => True/False Boolean as to whether or not to obey Robots.txt designations\n",
			'Author'      => 'Hood3dRob1n'
		}
		module_required={ 'Target' => "http://site.com/scan/only/from/here/" } 
		module_optional={ 'Threads' => '8', 'Limit' => '0', 'Robots' => 'False' }
		@non_set_private_options='' #Don't Need for this
		if $module_name.nil?
			begin #In case they don't have the proper gem installed to use the core of the crawler (anemone)
				require 'anemone' #<-=Heart&Soul=->
				pluginRegistrar(module_name,module_info,module_required,module_optional)
			rescue
				puts "[".light_red + "X".white + "] Requires '".light_red + "anemone".white + "' gem to run this plugin".light_red + ",".white + " sorry".light_red + "....".white
				puts "[".light_red + "X".white + "] Try installaning with".light_red + ": sudo gem install anemone".white
			end
		else
			base_crawl
		end
	end

	#Simple Site Craler
	def base_crawl
		cls
		banner
		puts "[".light_green + "*".white + "] Starting Crawler Session Site From".light_green + ": #{$module_required['Target']}".white

		@zsite = $module_required['Target'].to_s.chomp.sub('http://', '').sub('https://', '').sub('www.', '').sub(/\/$/, '') #I suppose you could just check uri.host but whatevers
		foo=@zsite.split('/')
		if foo.size > 1
			@zsite=foo[0]
		end
		if not File.directory?("#{$results}#{@zsite}")
			FileUtils.mkdir("#{$results}#{@zsite}") #confirm results dir exists, if not create it
		end
		outputz = "#{$results}#{@zsite}/crawler.links"


		#Actual Crawler Magic which uses Anemone for its core (Find base page, check all available linked pages and present findings)
		@emails_array=[]
		emails_regex = /[\w.!#\$%+-]+@[\w-]+(?:\.[\w-]+)+/ #Regex check for emails
		wcount=0
		while(true)
			trap("SIGINT") { puts "\n\nWARNING! CTRL+C Detected, shutting crawler down....."; break }
			Anemone.crawl($module_required['Target'].sub(/\/$/, ''), { :threads => $module_optional['Threads'].to_i, :user_agent => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)' }) do |anemone| #crawl provided site using options provided

				#limit crawl to $x number of links per page if requested, default is no limits
				if not $module_optional['Limit'].to_i == 0
					anemone.focus_crawl { |page| page.links.slice(0..$module_optional['Limit'].to_i) } 
				end

				anemone.on_every_page do |page| #on every page crawled
					if wcount.to_i < 1
						f = File.open(outputz, "w+")  #Open file handle to write
						wcount = wcount.to_i + 1
					else
						f = File.open(outputz, "a+")  #Open file handle to append
					end
					puts "Found Link: ".light_red + "#{page.url.to_s}".white #print links found for terminal viewing
					f.puts page.url #put links from crawling in file for safe keeping and parsing later....
					f.close #close our file handle

					#Check to see if we can find any emails present in page body, if found save them for reference later
					emails_regex.match(page.body) do |email|
						if not @emails_array.include?(email)
							@emails_array << email
						end
					end
				end
			end#end Anemone crawler
			break
		end

		czcount=0
		#How many links did we find?
		File.open(outputz, "r+").each do |link|
			czcount = czcount.to_i + 1
		end
		if czcount.to_i > 0
			cls
			banner
			puts "[".light_green + "*".white + "] Crawler Session Complete".light_green + "!".white
			puts "[".light_green + "*".white + "] Links Found".light_green + ": #{czcount}".white
			puts "[".light_green + "*".white + "] Results Stored In".light_green + ": #{outputz}".white
			puts "[".light_yellow + "?".white + "] Do you want to run the links parser for added sorting ".light_yellow + "&".white + " analysis (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow + "?".white
			answer = gets.chomp
			if answer.upcase == 'Y' or answer.upcase == 'YES'
				crawl_parser(outputz)
			else
				puts "[".light_green + "*".white + "] OK".light_green + ", ".white + "Returning to Main Menu".light_green + ".....".white
			end
		else
			puts
			puts "[".light_green + "*".white + "] Crawler Session Complete".light_green + "!".white
			puts "[".light_red + "-".white + "] Links Found".light_yellow + ": #{czcount}".white
			puts "[".light_red + "X".white + "] Doesn't appear any links were found, sorry".light_red + "......".white
			puts "[".light_red + "X".white + "] Check base path and try again or check things manually to confirm".light_red + "......".white
			puts
		end
	end

	#Parse & Sort the links found by the site crawler to help highlight additional usefull information that may otherwise be hard to see (or not)
	def crawl_parser(results)
		puts "[".light_green + "*".white + "] OK".light_green + ", ".white + "running parser on".light_green + ": #{results}".white
		important = File.open(results, "r") #place our found links in variable to manipulate and search as needed
		rezDir = "#{$results}#{@zsite}/" #Our results dir for this site which has been already created in first function cycles

		# placeholder arrays for sorting and finding unique testable links
		spreadsheetz=[]; executablez=[]; no_params=[]; test_keys=[]; noparamz=[]; archivez=[]; testlink=[]; opendocz=[]; outlookz=[]; paramz=[]; imagez=[];
		audioz=[]; videoz=[]; flashz=[]; multi=[]; vcardz=[]; bkupz=[]; jsz=[]; confz=[]; wordz=[]; xmlz=[]; pazz=[]; pdfz=[]; txtz=[]; pptz=[]; dbz=[];

		mcount=0 #Multi Parameter Links Count
		scount=0 #Single Parameter Links Count
		nocount=0 #No Parameter Links Count

		#loop through content of crawler.links file line by line...
		important.each do |line|
			begin
				#parse out parameters if they are present, if not will error NoMethodError and be handled there with rescue
				param = URI.parse(line).query

				#break paramaters into hash [ "@key" => "@value" ] formatting held in storage for easier manipulation
				paramsHash = Hash[URI.parse(line).query.split('&').map{ |q| q.split('=') }] 

				# Parse according to the number of parameters in link		
				###### Handle Single Parameter links ######
				if paramsHash.length == 1
					scount += 1
					paramz << line
					paramsHash.each do |key, value|
						if value =~ /\d+/ #if value is numerical replace with number and then we unique ;)
							testlink << line.sub(/#{value}/, '1') 
						else
							testlink << line #keep strings since they can be funky sometimes
						end
					end #finish cycle

				elsif "#{paramsHash.length}".to_i > 1
					###### Handle Multi Parameter links ######
					mcount += 1
					paramz << line
					#Test each link and see if the parameter key has been logged or not, this way we only get unique paramter links ;)
					paramsHash.keys.each do |key|
						if test_keys.include?(key)
							#Do Nothing, its already included in our test_keys array!
						else
							#Unique paramter, include key in test_key array and URL link in multi array for injector tests l8r
							test_keys << key #so we dont catch anymore links with this parameter
							multi << line.chomp #so we note the link for injection tests
						end
					end#end hash.key cycle
				end # parameter check looping

			###### Handle NO Parameter links ######
			rescue NoMethodError
				# We really only need to check a few links without params to see if they throw errors (URL re-write type stuff hiding)
				nocount += 1
				if nocount < 10 # gives us up to 15 no parameter links to check, more than enough
					no_params << line
				end

				#Parse over links we're ditching & sort into appropriate results files (in case that info is needed for follow up l8r)
				if /\/.+\.pdf/i.match(line)
					pdfz << line.chomp
				elsif /\/.+\.doc/i.match(line)
					wordz << line.chomp
				elsif /\/.+\.js|\/.+\.javascript/i.match(line)
					jsz << line.chomp
				elsif /\/.+\.txt|\/.+\.rtf/i.match(line)
					txtz << line.chomp
				elsif /\/.+\.png|\/.+\.jpg|\/.+\.jpeg|\/.+\.gif|\/.+\.bmp|\/.+\.exif|\/.+\.tiff/i.match(line)
					imagez << line.chomp
				elsif /\/.+\.msg/i.match(line)
					outlookz << line.chomp
				elsif /\/.+\.odt/i.match(line)
					opendocz << line.chomp
				elsif /\/.+\.csv|\/.+\.xlr|\/.+\.xls/i.match(line)
					spreadsheetz << line.chomp
				elsif /\/.+\.pps|\/.+\.ppt/i.match(line)
					pptz << line.chomp
				elsif /\/.+\.tar|\/.+\.zip|\/.+\.7z|\/.+\.cbr|\/.+\.deb|\/.+\.gz|\/.+\.bz|\/.+\.pkg|\/.+\.rar|\/.+\.rpm|\/.+\.sit/i.match(line)
					archivez << line.chomp
				elsif /\/.+\.vcf/i.match(line)
					vcardz << line.chomp
				elsif /\/.+\.xml/i.match(line)
					xmlz << line.chomp
				elsif /\/.+\.m3u|\/.+\.m4a|\/.+\.mp3|\/.+\.mpa|\/.+\.wav|\/.+\.wma/i.match(line)
					audioz << line.chomp
				elsif /\/.+\.avi|\/.+\.mov|\/.+\.mp4|\/.+\.mpg|\/.+\.srt|\/.+\.vob|\/.+\.wmv/i.match(line)
					videoz << line.chomp
				elsif /\/.+\.swf|\/.+\.flv/i.match(line)
					flashz << line.chomp
				elsif /\/.+\.sql|\/.+\.accdb|\/.+\.db|\/.+\.mdb|\/.+\.pdb/i.match(line)
					dbz << line.chomp
				elsif /\/.+\.apk|\/.+\.app|\/.+\.bat|\/.+\.cgi|\/.+\.exe|\/.+\.gadget|\/.+\.jar|\/.+\.pif|\/.+\.vbs|\/.+\.wsf/i.match(line)
					executablez << line.chomp
				elsif /\/.+\.bak|\/.+\.tmp|\/.+\.bk/i.match(line)
					bkupz << line.chomp
				elsif /\/.+\.conf/i.match(line)
					confz << line.chomp
				elsif /\/.+\.passwd|\/.+\.htpasswd/i.match(line)
					pazz << line.chomp
				else
					noparamz << line
				end
			end #End begin/rescue block
		end

		#make sure we dont have duplicates
		no_params = no_params.uniq
		test_keys = test_keys.uniq
		testlink = testlink.uniq
		multi = multi.uniq
		injtestlinks=[]

		puts "[".light_green + "*".white + "] Crawler Results".light_green + ": ".white
		#Write found NO parameter links to their own file just like everything else, just these dont fall into any group
		count=0
		if not noparamz.empty?
			zfile="NO_paramaters"
			noparamz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")  #Open our file handle in write mode
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")  #Open our file handle in append mode
				end
				lostANDfound.puts "#{line.chomp}" #write the hits to file 
				lostANDfound.close #close our file handle we opened a minute ago
			end
			puts "[".light_green + "*".white + "] Found #{noparamz.length} Links in total with NO paramaters in them".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not paramz.empty?
			count=0
			zfile="paramater"
			paramz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links in total with paramaters in them".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not jsz.empty?
			count=0
			zfile="JS"
			jsz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for JS Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not pdfz.empty?
			count=0
			zfile="PDF"
			pdfz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for PDF Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not wordz.empty?
			count=0
			zfile="MS_WORD"
			wordz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for MS Word Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not txtz.empty?
			count=0
			zfile="TEXT"
			txtz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for TEXT Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not outlookz.empty?
			count=0
			zfile="OUTLOOK-MSG"
			outlookz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for OUTLOOK-MSG Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not opendocz.empty?
			count=0
			zfile="OpenDoc"
			opendocz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for OpenDoc Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not spreadsheetz.empty?
			count=0
			zfile="SpreadSheet"
			spreadsheetz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for SpreadSheet Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not pptz.empty?
			count=0
			zfile="PowerPoint"
			pptz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for PowerPoint Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not archivez.empty?
			count=0
			zfile="ARCHIVE"
			archivez.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for ARCHIVE Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not vcardz.empty?
			count=0
			zfile="vCard"
			vcardz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for vCard Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not xmlz.empty?
			count=0
			zfile="XML"
			xmlz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for XML Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not audioz.empty?
			count=0
			zfile="AUDIO"
			audioz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for AUDIO Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not videoz.empty?
			count=0
			zfile="VIDEO"
			videoz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for VIDEO Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not flashz.empty?
			count=0
			zfile="FLASH"
			flashz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for FLASH Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not dbz.empty?
			count=0
			zfile="DATABASE"
			dbz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for DATABASE Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not executablez.empty?
			count=0
			zfile="EXECUTABLES"
			executablez.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for EXECUTABLES Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not bkupz.empty?
			count=0
			zfile="BackUp"
			bkupz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for BackUp Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not confz.empty?
			count=0
			zfile="CONFIG"
			confz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for CONFIG Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not pazz.empty?
			count=0
			zfile="PASSWORDS"
			pazz.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for PASSWORDS Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		if not imagez.empty?
			count=0
			zfile="IMAGE"
			imagez.each do |line|
				if count.to_i < 1
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "w+")
					count = count.to_i + 1
				else
					lostANDfound = File.new("#{rezDir}#{zfile}.links", "a+")
				end
				lostANDfound.puts "#{line.chomp}"
				lostANDfound.close
			end
			puts "[".light_green + "*".white + "] Found #{paramz.length} Links for IMAGE Files".light_green + ": #{rezDir}#{zfile}.links".white
		end
		puts "[".light_green + "*".white + "] Other Info".light_green + ".....".white
		if not test_keys.empty?
			puts "[".light_green + "*".white + "] Found #{test_keys.length} Testable Parameters".light_green + ": ".white
			puts "[".light_green + "*".white + "] ".light_green + "#{test_keys.join(', ').to_s}".white
		end
		if not testlink.empty?
			#print single parameter links we will test
			puts "[".light_green + "*".white + "] Found #{testlink.length} Unique Single Parameter Links (out of #{scount} total)".light_green + ": ".white
			testlink.each do |line|
				puts "\t#{line.chomp}".white
				injtestlinks << line
			end
		end
		if not multi.empty?
			#print multi parameter links we will test
			puts "[".light_green + "*".white + "] Found #{multi.length} Unique Multi Parameter Links (out of #{mcount} total)".light_green + ":".white
			multi.each do |line|
				puts "\t#{line.chomp}".white
				injtestlinks << line
			end
		end
		if not no_params.empty?
			if no_params.length < 9
				puts "[".light_green + "*".white + "] Found the following NO Parameter links".light_green + ": ".white
				nopam = no_params
			else
				puts "[".light_green + "*".white + "] 10 random No Parameter Links (out of #{nocount} total)".light_green + ": ".white
				nopam = no_params.sort_by{rand}[0..9]
			end
			#print no parameter links we will test
			nopam.each do |line|
				puts "\t#{line.chomp}".white
				injtestlinks << line
			end
		end
		if not injtestlinks.empty?
			#Write the suggested testable links to their own file for use with other tools
			f = File.new("#{rezDir}testable.links", "w+")
			injtestlinks.each do |link|
				f.puts link
			end
			f.close
			puts "[".light_green + "*".white + "] Suggested Testable Links".light_green + ": #{rezDir}testable.links".white
		end
		#Display the emails found now....
		if not @emails_array.empty?
			@emails_array.uniq!
			f=File.open("#{rezDir}temp.emails", 'w+')
			@emails_array.each do |email|
				f.puts email
			end
			f.close
			#Because Ruby built-in uniq function doesn't seem to be fully doing the job we use some OS magic to make sure it is unique emails only....
			system("cat #{rezDir}temp.emails | sort -u > #{rezDir}emails.txt")
			count=`wc -l #{rezDir}emails.txt | cut -d' ' -f1`
			FileUtils.rm("#{rezDir}temp.emails")
			puts "[".light_green + "*".white + "] Found #{count} emails while crawling".light_green + "....".white
			puts "[".light_green + "*".white + "] Find them here".light_green + ": #{rezDir}emails.txt".white
		end
	end
end

SiteCrawler.new
