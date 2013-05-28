module Http
	require 'curb'
	require 'net/http'
	require 'net/https'
	require 'mechanize'
	require 'openssl'
	require 'open-uri'
	class EasyCurb
		def initialize(cookie,auth,proxyip,proxyport,username,password)
			@cookie = cookie.chomp
			@auth = auth
			@proxyip = proxyip.chomp
			@proxyport = proxyport.chomp
			@username = username.chomp
			@password = password.chomp
		end

		def multi_get(arrayoflinks)
			@mresponses = {}
			m = Curl::Multi.new
			#add a few easy handles
			arrayoflinks.each do |url|
				@mresponses[url]=simple(url)
				m.add(@mresponses[url])
			end
			begin
				m.perform
			rescue Curl::Err::ConnectionFailedError
				puts "Problem with Connection".light_red + "!".white
				puts "Double check network or options set & try again".light_red + "....".white
				puts
			rescue Curl::Err::PartialFileError
				puts 'curl fail'.cyan
			rescue Curl::Err::RecvError
				puts 'curl fail'.yellow
			rescue Curl::Err::HostResolutionError
				puts 'Problem resolving host details'.light_red + "...".white
			end
			return @mresponses
		end

		def simple(link, postdata=nil)
			@ch = Curl::Easy.new(link) do |curl|
				curl.useragent = 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'
				if not @proxyip == 'nil'
					if @auth.to_i == 1
						#NO PASS CAN BE USED B/C basic_auth in use!
						curl.proxy_url = @pproxyip
						curl.proxy_port = @proxyport.to_i
					else
						#CAN USE AUTH HERE
						if @username == 'nil'
							curl.proxy_url = @proxyip
							curl.proxy_port = @proxyport.to_i
						else
							curl.proxy_url = @proxyip
							curl.proxy_port = @proxyport.to_i
							curl.proxypwd = "#{@username}:#{@password}"
						end
					end
				end
				curl.cookies = @cookie unless @cookie == 'nil'
				if @auth.to_i == 1
					curl.http_auth_types = :basic
					curl.username = @username
					curl.password = @password
				end
				begin
					curl.http_post(link, "#{postdata}") if not postdata.nil?
				rescue Curl::Err::ConnectionFailedError
					puts "Problem with Connection".light_red + "!".white
					puts "Double check network or options set & try again".light_red + "....".white
					puts
				rescue Curl::Err::PartialFileError
					puts 'curl fail'.cyan
				rescue Curl::Err::RecvError
					puts 'curl fail'.yellow
				rescue Curl::Err::HostResolutionError
					puts 'Problem resolving host details'.light_red + "...".white
				end
			end
		end
	
		def _get(getlink)
			simple(getlink)
			begin
				@ch.perform
			rescue Curl::Err::ConnectionFailedError
				puts "Problem with Connection".light_red + "!".white
				puts "Double check network or options set & try again".light_red + "....".white
				puts
			rescue Curl::Err::PartialFileError
				puts 'curl fail'.cyan
			rescue Curl::Err::RecvError
				puts 'curl fail'.yellow
			rescue Curl::Err::HostResolutionError
				puts 'Problem resolving host details'.light_red + "...".white
			end
			return @ch.body_str, @ch.response_code, @ch.total_time, @ch.header_str
		end

		def _post(postlink, postdata)
			simple(postlink, postdata)
			return @ch.body_str, @ch.response_code, @ch.total_time, @ch.header_str
		end
	end

	##########################
	# Work in Progress still.............> EasyMechanize
	##########################
	class EasyMechanize
		def initialize(proxyip,proxyport,username,password)
			@proxyip = proxyip.chomp
			@proxyport = proxyport.chomp
			@username = username.chomp
			@password = password.chomp
		end

		def mechsimple(link, postdata=nil)
			@agent = Mechanize.new do |agent|
				agent.user_agent = 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)'
				if not @proxyip == 'nil'
					if @auth.to_i == 1
						#NO PASS CAN BE USED B/C basic_auth in use!
						agent.proxy_addr = @pproxyip
						agent.proxy_port = @proxyport.to_i
					else
						#CAN USE AUTH HERE
						if @username == 'nil'
							agent.proxy_url = @proxyip
							agent.proxy_port = @proxyport.to_i
						else
							agent.proxy_addr = @proxyip
							agent.proxy_port = @proxyport.to_i
							agent.proxy_user = @username
							agent.proxy_pass = @password
						end
					end
				end
			end
		end

		def _mechget(getlink)
			mechsimple(getlink)
			@agent.get(getlink)
			return @agent.page @agent.page.code
		end

		def _mechpost(postlink, postdata)
			mechsimple(postlink, postdata)
			@agent.post(postlink, postdata)
			return @agent.page @agent.page.code
		end
	end
end
#EOF
