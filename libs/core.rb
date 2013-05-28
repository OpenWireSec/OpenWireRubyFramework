module Core
	class CoreShell
		require "readline"

		trap('INT', 'SIG_IGN') #Trap interupts and force user to exit via core_shell menu option! Prevents errors with readline...

		def initialize
			#Initialize CORE by loading libs and module list
			preloadLibs
			preloadModules
			$results="#{Dir.pwd}/results/"
			Dir.mkdir($results) unless File.exists?($results)
		end

		def cls
			#Function to clear terminal
			if RUBY_PLATFORM =~ /win32/ 
				system('cls')
			else
				system('clear')
			end
		end

		def banner
			#App Banner
			puts
			puts "  _|_|                                  _|          _|  _|                     ".light_green
			puts "_|    _|  _|_|_|      _|_|    _|_|_|    _|          _|      _|  _|_|    _|_|   ".light_green
			puts "_|    _|  _|    _|  _|_|_|_|  _|    _|  _|    _|    _|  _|  _|_|      _|_|_|_| ".light_green
			puts "_|    _|  _|    _|  _|        _|    _|    _|  _|  _|    _|  _|        _|       ".light_green
			puts "  _|_|    _|_|_|      _|_|_|  _|    _|      _|  _|      _|  _|          _|_|_| ".light_green
			puts "         _|                                                                    ".light_green
			puts "         _|                                                                    ".light_green
			puts "                                      OpenWire Ruby Framework, v0.1-beta       ".light_red
			puts
		end

		def showUsage
			#basic Shell Instructions
			puts "List of commands and description of usage".light_yellow + ": ".white
			puts "\tbanner".light_yellow + " => ".white + "Display Banner".light_yellow
			puts "\tclear".light_yellow + "/".white + "cls".light_yellow + " => ".white + "Clear Screen".light_yellow
			puts "\thelp ".light_yellow + "=> ".white + "Display this Help Menu".light_yellow
			puts "\tlibs".light_yellow + " => ".white + "List Current Libraries".light_yellow
			puts "\tlist".light_yellow + " => ".white + "List Available Modules".light_yellow
			puts
			puts "\tuse".light_yellow + "/".white + "load <ModuleName>".light_yellow + " => ".white + "Load a Module".light_yellow
			puts "\tunset".light_yellow + " => ".white + "Unset the Currently Loaded Module".light_yellow
			puts "\tcmod".light_yellow + " => ".white + "Show the Current Loaded Module Name".light_yellow
			puts "\tshow variables".light_yellow + " => ".white + "Show the Global and Module Specific Variables".light_yellow
			puts "\tset <variable> <value>".light_yellow + " => ".white + "Set a variable to value (ex. target host)".light_yellow
			puts "\texploit".light_yellow + "/".white + "run".light_yellow + " => ".white + "Run the Currently Loaded (exploit) Module".light_yellow
			puts
			puts "\trb <code>".light_yellow + " => ".white + "Evaluates Passed Ruby Code".light_yellow
			puts "\tlocal".light_yellow + " => ".white + "Drop to Local OS Shell to Execute Commands".light_yellow
			puts
		end

		def core_shell
			#Use readline module to keep history of commands while in sudo shell
#			prompt = "(".white + "OpenWire".light_green + ")".white + "> ".light_green
			prompt = "(OpenWire)> "
			while line = Readline.readline("#{prompt}", true)
				cmd = line.chomp
				case cmd
					when /^clear|^cls|^banner/i
						cls
						banner
						core_shell
					when /^help/i
						showUsage
						core_shell
					when /^libs/i
						listLibraries
						core_shell
					when /^list/i
						listModules
						core_shell
					when /^use (.+)/i
						mod=$1
						loadModule(mod)
						core_shell
					when /^load (.+)/i
						mod=$1
						loadModule(mod)
						core_shell
					when /^unset/i
						unsetModule
						puts "[".light_green + "*".white + "] Currently Loaded Module Dropped".light_green + "!".white
						puts
						core_shell
					when /^cmod/i
						currentModule
						core_shell
					when /^show (.+)/i
						if ($1.downcase.chomp == 'variables')
							showVariables
						else
							showUsage
						end
						core_shell
					when /^set (.+) (.+)/i
						variable=$1
						value=$2
						setValue(variable, value)
						core_shell
					when /^check/i
						checkExploit
						core_shell
					when /^exploit|^run/i
						runExploit
						core_shell
					when /^exit|^quit/i
						puts
						puts "OK, exiting OpenWire Ruby Framework ".light_red + "& closing things down".light_red + "....".white
						puts
						exit 69;
					when /^rb (.+)/i
						code=$1.chomp
						rubyme("#{code}")
						puts
						core_shell
					when /^local/i
						localShell
						puts
						core_shell
					else
						cls
						puts
						puts "Oops, Didn't quite understand that one".light_red + "!".white
						puts "Please Choose a Valid Option From Menu Below Next Time".light_red + ".....".white
						puts
						showUsage
						core_shell
					end
			end    
		end
		
		def core_web_shell
			puts
			puts "Web Method Not Implemented Yet".light_red + "\n\t=> ".white + "GUI is for fags anyway".light_red + "!".white
			puts
			exit 666;
		end

		def localShell
			cls
			banner
			prompt = "(localOS)> "
			while line = Readline.readline("#{prompt}", true)
				cmd = line.chomp
				case cmd
					when /^exit$|^quit$|^back$/i
						puts "[".light_red + "X".white + "] OK, Returning to Main Menu".light_red + "....".white
						break
					else
						begin
							rez = `#{cmd}` #Run command passed
							puts "#{rez}".cyan #print results nicely for user....
						rescue Errno::ENOENT => e
							puts "#{e}\n".light_red
						rescue => e
							puts "#{e}\n".light_yellow
						end
					end
			end
		end

		def rubyme(code)
			begin
				puts "#{eval("#{code}")}".white
			rescue NoMethodError => e
				puts "[".light_red + "X".white + "]".light_red + " #{e}".light_red
			rescue NameError => e
				puts "[".light_red + "X".white + "]".light_red + " #{e}".light_red
			rescue SyntaxError => e
				puts "[".light_red + "X".white + "]".light_red + " #{e}".light_red
			rescue TypeError => e
				puts "[".light_red + "X".white + "]".light_red + " #{e}".light_red
			end
		end

		def preloadLibs
			#Load up any lib files found in the ./lib/ dir so available in core from start
			$libs=[]
			Dir.glob("./libs/*.rb").each do |lib|
				require "#{lib}"
				$libs << "#{lib}"
			end
			@loaded_module=nil

			$module_name=nil
			$module_info=nil
			$module_required=nil
			$module_optional=nil
		end

		def listLibraries
			# Cycle through our array of loaded library files and present to user
			$libs.each do |lib|
				puts "[".light_green + "*".white + "] Loaded".light_green + ": #{lib}".white
				if lib =~ /core/
					puts "[".light_green + "*".white + "] Description".light_green + ": Main OpenWire Framework Core Lib".white 
				elsif lib =~ /http/
					puts "[".light_green + "*".white + "] Description".light_green + ": Mod-Curb HTTP Request Core Lib".white 
				elsif lib =~ /support/
					puts "[".light_green + "*".white + "] Description".light_green + ": Support functions which make development easier \n\t=> classes/functions can also be leveraged from rubyme menu option!".white 
				else
					puts "[".light_red + "X".white + "] Description".light_red + ": No Description Yet".white 
				end
			end
		########################################################################################################################
		# For Now you have to update the library description here. Maybe make included in library handling somehow like plugins?
		########################################################################################################################
			puts
		end

		def preloadModules
			#Load all of the found plugins from /plugions/ dir so we can offer as options to use for loading later.....
			$modules=[]
			Dir.glob("./plugins/*.rb").each do |mod|
				$modules << "#{mod}"
			end
		end

		def listModules
			#List the available modules/plugins
			puts "[".light_green + "*".white + "] Available Plugins".light_green + ": ".white
			if $modules.nil?
				puts "[".light_red + "X".white + "] No Modules Found".light_red + "!".white 
			else
				$modules.sort.each do |modz|
					puts "[".light_green + "*".white + "] ".light_green + "#{modz.sub('./plugins/', '').sub('.rb', '')}".white
				end
			end
			puts
		end

		def loadModule(moduleName)
			#Unset any currently loaded modules to be safe
			unsetModule
			check=0
			#If we find a module matching the request, then we call setModule to enable the loading of the plugin code....
			$modules.each do |availablemodule|
				if availablemodule.sub('./plugins/', '').sub('.rb', '') == moduleName.downcase.chomp
					check=1
					setModule(availablemodule)
				end
			end
			#If we dont find the referenced module/plugin then tell them to piss off!
			if check.to_i == 0
				puts "[".light_red + "X".white + "] No Plugin Found By That Name".light_red + "!".white
				puts
			end
		end

		def setModule(moduleName)
			unsetModule
			#We load the requested module and set to our loaded_module instance variable in case we check from elsewhere....
			@loaded_module="#{moduleName.sub('./plugins/', '').sub('.rb', '')}"
			@loaded_module_longname=moduleName
			load "#{moduleName}"
			puts "[".light_green + "*".white + "] Loaded Module".light_green + ": #{@loaded_module}".white
			puts
		end

		def unsetModule
			#Set ALL module related variables to nil to essentially unset it (hackish workaround due to me not being able to properly unset classes/modules that are loaded/required/whatevers - works though :p
			@loaded_module=nil

			$module_name=nil
			$module_info=nil
			$module_required=nil
			$module_optional=nil
		end

		def pluginRegistrar(module_name,module_info,module_required,module_optional)
			#We let our plugins call this function from their intialize call when intialially loaded, we set our initialize variables as global variables so we can share between classes (Core & PLugin Module)
			$module_name=module_name
			$module_info=module_info
			$module_required=module_required
			$module_optional=module_optional
		end

		def currentModule
			#Check if module/plugin is loaded or not, if so present the basic plugin info to user
			if not @loaded_module.nil?
				puts "[".light_green + "*".white + "] General Info for Currently Loaded Module".light_green + ": ".white
				if not $module_info.nil?
					puts "[".light_green + "*".white + "] Module Name".light_green + ": #{$module_info['Name']}".white
					puts "[".light_green + "*".white + "] Version".light_green + ": #{$module_info['Version']}".white
					puts "[".light_green + "*".white + "] Author".light_green + ": #{$module_info['Author']}".white
					puts "[".light_green + "*".white + "] Description".light_green + ": \n#{$module_info['Description']}".white
					puts
					puts "[".light_green + "*".white + "] Required Variables".light_green + ": ".white
					$module_required.each do |key,value|
						puts "[".light_green + "*".white + "] #{key}".light_green + ": #{value}".white
					end
					puts
					puts "[".light_green + "*".white + "] Optionsal Variables".light_green + ": ".white
					if not $module_optional.nil?
						$module_optional.each do |key,value|
							puts "[".light_green + "*".white + "] #{key}".light_green + ": #{value}".white
						end
					end
				end
			else
				puts "[".light_red + "X".white + "] No Plugin Currently Loaded".light_red + "!".white
			end
			puts
		end

		def showVariables
			#Check if a module/plugin has been loaded, if so present the current variable options for them
			if not $module_name.nil?
				puts "[".light_green + "*".white + "] Module Name".light_green + ": #{$module_info['Name']}".white
				puts "[".light_green + "*".white + "] REQUIRED Variables".light_green + ": ".white
				$module_required.each do |key,value|
					puts "[".light_green + "*".white + "] #{key}".light_green + ": #{value}".white
				end
				puts "[".light_green + "*".white + "] OPTIONAL Variables".light_green + ": ".white
				if not $module_optional.nil?
					$module_optional.each do |key,value|
						puts "[".light_green + "*".white + "] #{key}".light_green + ": #{value}".white
					end
				end
			else
				puts "[".light_red + "X".white + "] No Plugin Currently Loaded".light_red + "!".white
			end
			puts
		end

		def setValue(key, newValue)
			check=0
			#Check to make sure the value requesting to be set exists in either the Mandatory or Optional Variables Sets....
			if $module_required.has_key?(key)
				$module_required["#{key}"] = newValue
				check=1
			end
			if not check.to_i == 1
				if $module_optional.has_key?(key)
					$module_optional["#{key}"] = newValue
					check=1
				end
			end
			#If key was set, confirm for user, else let them know the requested key doesnt exist!
			if not check.to_i == 1
				puts "[".light_red + "X".white + "] Couldn't find requested KEY in Variables Options".light_red + "!".white
				puts "[".light_red + "X".white + "] Please double check and try again".light_red + "......".white
				puts "[".light_yellow + "*".white + "] Use ".light_yellow + "show variables".white + " to confirm the available options".light_yellow + "....".white
			else
				puts "[".light_green + "*".white + "] ".light_green + "#{key}".white + " Value Updated to".light_green + ": #{newValue}".white
				puts "[".light_green + "*".white + "] Use ".light_green + "show variables".white + " to confirm".light_green + "....".white
			end
			puts
		end

		def runExploit
			if not @loaded_module.nil?
				puts "[".light_green + "*".white + "] Running".light_green + ": #{$module_info['Name']}".white + "....".white
				$modules.each do |availablemodule|
					if availablemodule == @loaded_module_longname
						load "#{availablemodule}"
					end
				end
			else
				puts "[".light_red + "X".white + "] No Plugin Currently Loaded to Run".light_red + "!".white
			end
			puts
		end

		#Not super sure here, but taking a shot at things.....>
		private :preloadLibs, :listLibraries, :preloadModules, :listModules, :setModule, :unsetModule, :pluginRegistrar, :setValue, :rubyme
		protected :loadModule, :showVariables
		public :cls
	end
end
#EOF
