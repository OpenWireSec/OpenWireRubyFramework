# Admin Finder Script which leverages the Mechanize gem to check both server response code as well as parsing results pages for forms witih common names further confirming existance of admin pages and helping to reduce the number of false positives for sites which have custom error responses and those sites which embed them and respond 200 to all requests :/
#
# Finds General Admin Pages, phpMyAdmin Pages, & phpinfo() Pages depending on mode set, as well as robots.txt checker whcih should usually be consulted first before banging away like a monkey :p
#
class AdminFinder < Core::CoreShell
	def initialize
		#Basic Info:
		module_name='AdminFinder'
		module_info={
			'Name'        => 'Basic Admin Finder Plugin',
			'Version'     => 'v0.01b',
			'Description' => "This is a Simple Admin Page Finder. Give it a target base to start from and it will check for existance of common admin pages using built-in array of possibilities.\n\tTarget => Target Site to start search from \n\t\tEX: http://site.com/,\n\t\tEX: https://site.com/forum/\n\tLang => Language Type in use by default on target (PHP, ASP, ASPX, CGI, CFM, JS, JSP, HTM, or HTML)\n\tSearchType => Type of Check to Perform (Admin, Pinfo, PMA, or Robots)\n\t\tAdmin => Basic Admin Finder\n\t\tPinfo => PHPINFO() Page Finder\n\t\tPMA => PhpMyAdmin Login Panel Finder\n\t\tRobots => Remote robots.txt File Check",
			'Author'      => 'Hood3dRob1n'
		}
######################################################ADD FILE OPTION?##############################################################
		module_required={ 'Target' => "http://site.com/", 'SearchType' => 'Robots' } #ADD FILE OPTION?
		module_optional={ 'Lang' => 'PHP', 'ProxyIp' => 'nil', 'ProxyPort' => 'nil' }

		@non_set_private_options={ 'Auth' => 0, 'Cookie' => 'nil', 'Username' => 'nil', 'Password' => 'nil' }

		if $module_name.nil?
			pluginRegistrar(module_name,module_info,module_required,module_optional)
		else
			if $module_required['SearchType'].downcase == 'pinfo' or $module_required['SearchType'].downcase == 'phpinfo' #Perform phpinfo() Check
				puts "[".light_green + "*".white + "] Searching for PHPINFO() Page(s)".light_green + "....".white
				findPInfo
			elsif $module_required['SearchType'].downcase == 'pma' #Perform phpMyAdmin Login Panel Check
				puts "[".light_green + "*".white + "] Searching for PhpMyAdmin Login Panel(s)".light_green + "....".white
				findPMA
			elsif $module_required['SearchType'].downcase =~ /^robot/ #Perform robots.tst check
				puts "[".light_green + "*".white + "] Checking for Robots.txt".light_green + "....".white
				findRobots
			else #Normal Admin Panel Check
				if $module_optional['Lang'].upcase == "ASP"
					@type = ".asp"
				elsif $module_optional['Lang'].upcase == "ASPX"
					@type = ".aspx"
				elsif $module_optional['Lang'].upcase == "CFM"
					@type = ".cfm"
				elsif $module_optional['Lang'].upcase == "CGI"
					@type = ".cgi"
				elsif $module_optional['Lang'].upcase == "JS"
					@type = ".js"
				elsif $module_optional['Lang'].upcase == "JSP"
					@type = ".jsp"
				elsif $module_optional['Lang'].upcase == "HTM"
					@type = ".htm"
				elsif $module_optional['Lang'].upcase == "HTML"
					@type = ".html"
				elsif $module_optional['Lang'].upcase == "SHTML"
					@type = ".shtml"
				else
					@type = ".php"
				end
				puts "[".light_green + "*".white + "] Searching for (Admin) Login Panel(s)".light_green + "....".white
				puts "[".light_green + "*".white + "] Base".light_green + ": #{$module_required['Target']}".white
				puts "[".light_green + "*".white + "] Language Type".light_green + ": #{@type.sub('.', '').upcase}".white
				findAdmin
			end
		end
	end

	def findRobots
		#Initialize our Http::EasyCurb request object with any special values needed, otherwise mark them to nil....
		http = Http::EasyCurb.new(@non_set_private_options['Cookie'],@non_set_private_options['Auth'],$module_optional['ProxyIp'],$module_optional['ProxyPort'],@non_set_private_options['Username'],@non_set_private_options['Password'])
		target = "#{$module_required['Target'].sub(/\/$/, '')}/robots.txt"
		body = http._get(target)
		if body[1] == 200
			if body[0] =~ /User-agent: .+/i and body[0] =~ /Disallow: .+/i
				puts "[".light_green + " PAGE FOUND ".white + "] ".light_green + "#{target}".white
				puts "[".light_green + "*".white + "] Parsing robots.txt file now".light_green + ".....".white
				body[0].split("\n").each do |line|
					if line =~ /User-agent: .+/i
						foo=line.split(' ')
						bar = foo.slice(1, foo.length)
						puts "#{foo[0]}".light_yellow + " #{bar.join(' ')}".white
					elsif line =~ /admin|moderator|cp|control panel|cpanel/i
						foo=line.split(' ')
						bar = foo.slice(1, foo.length)
						puts "#{foo[0]}".light_red + " #{bar.join(' ')}".light_green
					elsif line =~ /user|password|login|editor|manage/i
						foo=line.split(' ')
						bar = foo.slice(1, foo.length)
						puts "#{foo[0]}".light_red + " #{bar.join(' ')}".green
					elsif line =~ /upload|cgi|\/~\w+\//i
						foo=line.split(' ')
						bar = foo.slice(1, foo.length)
						puts "#{foo[0]}".light_red + " #{bar.join(' ')}".light_yellow
					elsif line =~ /sitemap: .+/i
						foo=line.split(' ')
						bar = foo.slice(1, foo.length)
						puts "#{foo[0]}".light_green + " #{bar.join(' ')}".white
					else
						if line =~ /Disallow: .+/i
							foo=line.split(' ')
							bar = foo.slice(1, foo.length)
							puts "#{foo[0]}".light_red + " #{bar.join(' ')}".white
						else
							puts "#{line}".white
						end
					end
				end
			else
				puts "[".light_red + "X".white + "] Robots File Not Found or Format is way off".light_red + "!".white
			end
		elsif body[1] == 301 or body[1] == 302
			puts "[".light_yellow + " REDIRECT ".white + "] ".light_yellow + "#{target}".white
		elsif body[1] == 403
			puts "[".light_red + " Forbidden ".white + "] ".light_red + "#{target}".white
		else
			puts "[".light_red + "X".white + "] Robots File Not Found".light_red + "!".white
		end
	end

	def findPInfo
		#Perform phpinfo() Check
		pinfo_list = [ "phpinfo/", "php-info/", "phpdetails/", "php_details/", "information/", "phpinformation/", "php-information/", "phpinfo.php", "php-info.php", "php_info.php", "pinfo.php", "p-info.php", "p_info.php", "info.php", "test.php", "infophp.php", "info_php.php", "info-php.php", "php.php", "p.php", "pop.php", "peep.php", "pip.php", "i.php", "z.php", "help.php", "information.php", "phpinformation.php", "PhPinfo.php", "something.php", "/misc/info.php", "/misc/phpinfo.php", "phpinfo/phpinfo.php", "phpinfo/info.php", "phpinfo/pinfo.php", "phpinfo/php-info.php", "phpinfo/php_info.php", "phpinfo/php.php", "phpinfo/phpdetails.php", "phpinfo/php-details.php", "phpinfo/php_details.php", "php-info/phpinfo.php", "php-info/info.php", "php-info/pinfo.php", "php-info/php-info.php", "php-info/php_info.php", "php-info/php.php", "php-info/phpdetails.php", "php-info/php-details.php", "php-info/php_details.php", "php_info/phpinfo.php", "php_info/info.php", "php_info/pinfo.php", "php_info/php-info.php", "php_info/php_info.php", "php_info/php.php", "php_info/phpdetails.php", "php_info/php-details.php", "php_info/php_details.php", "xampp/phpinfo.php", "xampp/php-info.php", "xampp/php_info.php", "xampp/pinfo.php", "xampp/p-info.php", "xampp/p_info.php", "xampp/info.php", "xampp/test.php", "xampp/infophp.php", "xampp/info_php.php", "xampp/test/php/phpinfo.php", "xampp/phpinfomation.php", "xampp/php.php" ]
		pinfo_list.shuffle.each do |page2find|
			#Cool Code Here
			target = "#{$module_required['Target'].sub(/\/$/, '')}/#{page2find.sub('.XXXX', "#{@type}")}"
			agent = Mechanize.new
			begin
				if not $module_optional['ProxyIp'] == 'nil' and not $module_optional['ProxyPort'] == 'nil'
					agent.set_proxy $module_optional['ProxyIp'], $module_optional['ProxyPort'].to_i
				end
				agent.get(target)
				if agent.page.code.to_i == 200
					puts "[".light_green + " #{agent.page.code.to_i} ".white + "] ".light_green + "#{target}".white
					if agent.page.body =~ /<tr><td class="e">Apache Version <\/td><td class="v">(.+)<\/td><\/tr>/
						puts "\tApache Version".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<h1 class="p">(PHP Version .+)<\/h1>/
						puts "\tPHP Version".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">System <\/td><td class="v">(.+)<\/td><\/tr>/
						puts "\tSystem".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">DOCUMENT_ROOT <\/td><td class="v">(.+)<\/td><\/tr>/
						puts "\tDocument Root".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">allow_url_fopen<\/td><td class="v">(.+)<\/td><td class="v">.+<\/td><\/tr>/
						puts "\tallow_url_fopen".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">magic_quotes_gpc<\/td><td class="v">(.+)<\/td><td class="v">.+<\/td><\/tr>/
						puts "\tmagic_quotes_gpc".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">safe_mode<\/td><td class="v">(.+)<\/td><td class="v">.+<\/td><\/tr>/
						puts "\tsafe_mode".light_green + ": #{$1.chomp}".white
					end
					if agent.page.body =~ /<tr><td class="e">session.save_path<\/td><td class="v">(.+)<\/td><td class="v">.+<\/td><\/tr>/
						puts "\tsession.save_path".light_green + ": #{$1.chomp}".white
					end
				else
					puts "[".light_red + " #{agent.page.code.to_i} ".white + "] ".light_red + "#{target}".white
				end
			rescue OpenSSL::SSL::SSLError => e
				if agent.page.code.to_i == 301 or agent.page.code.to_i == 302
					puts "[".light_green + " #{agent.page.code.to_i} ".light_red + "] ".light_green + "#{target}".white
					@blinks << target
				else
					puts "[".light_yellow + " #{agent.page.code.to_i} ".light_red + "] ".light_yellow + "#{target}".white
					puts "SSL Cert Issues, likely an admin page with self signed certs causing issue".yellow + "!".white
					puts "=> #{e}".light_red
				end
			rescue Mechanize::ResponseCodeError => e
				if e.to_s.split(' ')[0] == '404'
					puts "[".light_red + " 404 ".white + "] ".light_red + "#{target}".white
				elsif e.to_s.split(' ')[0] == '403'
					puts "[".light_yellow + " 403 ".light_yellow + "] ".light_yellow + "#{target}".white
					@blinks << target
				elsif e.to_s.split(' ')[0] == '401' #Auth Required!
					puts "[".light_green + " UnAuthorized ".white + "] ".light_green + "#{target}".white
					@blinks << target
				else
					puts "#{e}".light_red
				end
			end
		end
		
	end

	def findPMA
		#Perform phpMyAdmin Login Panel Check
		pma_list = [ "phpMyAdmin/", "phpmyadmin/", "PMA/", "admin/", "dbadmin/", "mysql/", "myadmin/", "phpmyadmin2/", "phpMyAdmin2/", "phpMyAdmin-2/", "php-my-admin/", "phpMyAdmin-2.2.3/", "phpMyAdmin-2.2.6/", "phpMyAdmin-2.5.1/", "phpMyAdmin-2.5.4/", "phpMyAdmin-2.5.5-rc1/", "phpMyAdmin-2.5.5-rc2/", "phpMyAdmin-2.5.5/", "phpMyAdmin-2.5.5-pl1/", "phpMyAdmin-2.5.6-rc1/", "phpMyAdmin-2.5.6-rc2/", "phpMyAdmin-2.5.6/", "phpMyAdmin-2.5.7/", "phpMyAdmin-2.5.7-pl1/", "phpMyAdmin-2.6.0-alpha/", "phpMyAdmin-2.6.0-alpha2/", "phpMyAdmin-2.6.0-beta1/", "phpMyAdmin-2.6.0-beta2/", "phpMyAdmin-2.6.0-rc1/", "phpMyAdmin-2.6.0-rc2/", "phpMyAdmin-2.6.0-rc3/", "phpMyAdmin-2.6.0/", "phpMyAdmin-2.6.0-pl1/", "phpMyAdmin-2.6.0-pl2/", "phpMyAdmin-2.6.0-pl3/", "phpMyAdmin-2.6.1-rc1/", "phpMyAdmin-2.6.1-rc2/", "phpMyAdmin-2.6.1/", "phpMyAdmin-2.6.1-pl1/", "phpMyAdmin-2.6.1-pl2/", "phpMyAdmin-2.6.1-pl3/", "phpMyAdmin-2.6.2-rc1/", "phpMyAdmin-2.6.2-beta1/", "phpMyAdmin-2.6.2-rc1/", "phpMyAdmin-2.6.2/", "phpMyAdmin-2.6.2-pl1/", "phpMyAdmin-2.6.3/", "phpMyAdmin-2.6.3-rc1/", "phpMyAdmin-2.6.3/", "phpMyAdmin-2.6.3-pl1/", "phpMyAdmin-2.6.4-rc1/", "phpMyAdmin-2.6.4-pl1/", "phpMyAdmin-2.6.4-pl2/", "phpMyAdmin-2.6.4-pl3/", "phpMyAdmin-2.6.4-pl4/", "phpMyAdmin-2.6.4/", "phpMyAdmin-2.7.0-beta1/", "phpMyAdmin-2.7.0-rc1/", "phpMyAdmin-2.7.0-pl1/", "phpMyAdmin-2.7.0-pl2/", "phpMyAdmin-2.7.0/", "phpMyAdmin-2.8.0-beta1/", "phpMyAdmin-2.8.0-rc1/", "phpMyAdmin-2.8.0-rc2/", "phpMyAdmin-2.8.0/", "phpMyAdmin-2.8.0.1/", "phpMyAdmin-2.8.0.2/", "phpMyAdmin-2.8.0.3/", "phpMyAdmin-2.8.0.4/", "phpMyAdmin-2.8.1-rc1/", "phpMyAdmin-2.8.1/", "phpMyAdmin-2.8.2/", "sqlmanager/", "mysqlmanager/", "p/m/a/", "PMA2005/", "pma2005/", "phpmanager/", "php-myadmin/", "phpmy-admin/", "webadmin/", "sqlweb/", "websql/", "webdb/", "mysqladmin/", "mysql-admin/" ]
		fetch(pma_list)
	end

	def findAdmin
		#Normal Admin Panel Check
		common_admin = [ "@dmin/", "_admin/", "_adm/", "admin/", "adm/", "admincp/", "admcp/", "cp/", "modcp/", "moderatorcp/", "adminare/", "admins/", "cpanel/", "controlpanel/", "0admin/", "0manager/", "admin1/", "admin2/", "ADMIN/", "administrator/", "ADMON/", "AdminTools/", "administrador/", "administracao/", "painel/", "administracao.XXXX", "administrateur/", "administrateur.XXXX", "beheerder/", "administracion/", "administracion.XXXX", "beheerder.XXXX", "amministratore/", "amministratore.XXXX", "v2/painel/", "db/", "dba/", "dbadmin/", "Database_Administration/", "ADMIN/login.XXXX", "ADMIN/login.XXXX", "Indy_admin/", "LiveUser_Admin/", "Lotus_Domino_Admin/", "PSUser/", "Server.XXXX", "Server/", "ServerAdministrator/", "Super-Admin/", "SysAdmin/", "SysAdmin2/", "UserLogin/", "WebAdmin/", "aadmin/", "acceso.XXXX", "acceso.XXXX", "access.XXXX", "access/", "account.XXXX", "accounts.XXXX", "accounts/", "acct_login/", "adm.XXXX", "adm/admloginuser.XXXX", "adm/index.XXXX", "adm_auth.XXXX", "admin-login.XXXX", "admin.XXXX", "admin/account.XXXX", "admin/admin-login.XXXX", "admin/admin.XXXX", "admin/adminLogin.XXXX", "admin/admin_login.XXXX", "admin/controlpanel.XXXX", "admin/cp.XXXX", "admin/home.XXXX", "admin/index.XXXX", "admin/Login.XXXX", "admin/login.XXXX", "admin1.XXXX", "admin1/", "admin2.XXXX", "admin2/index.XXXX", "admin2/login.XXXX", "admin4_account/", "admin4_colon/", "adminLogin.XXXX", "adminLogin/", "admin_area.XXXX", "admin_area/", "admin_area/admin.XXXX", "admin_area/index.XXXX", "admin_area/login.XXXX", "admin_login.XXXX", "adminarea/", "adminarea/admin.XXXX", "adminarea/index.XXXX", "adminarea/login.XXXX", "admincontrol.XXXX", "admincontrol/", "admincontrol/login.XXXX", "admincp/", "admincp/index.XXXX", "administer/", "administr8.XXXX", "administr8/", "administrador/", "administratie/", "administration.XXXX", "administration/", "administrator.XXXX", "administrator/", "administrator/account.XXXX", "administrator/index.XXXX", "administratoraccounts/", "administratorlogin.XXXX", "administratorlogin/", "administrators.XXXX", "administrators/", "administrivia/", "adminitem.XXXX", "adminitem/", "adminitems.XXXX", "adminitems/", "adminpanel.XXXX", "adminpanel/", "adminpro/", "admins.XXXX", "admins/", "adminsite/", "admloginuser.XXXX", "admon/", "affiliate.XXXX", "auth.XXXX", "authadmin.XXXX", "authenticate.XXXX", "authentication.XXXX", "authuser.XXXX", "autologin.XXXX", "autologin/", "backoffice/admin.XXXX", "banneradmin/", "bb-admin/", "bb-admin/admin.XXXX", "bb-admin/index.XXXX", "bb-admin/login.XXXX", "bbadmin/", "bigadmin/", "blogindex/", "cPanel/", "cadmins/", "ccms/", "ccms/index.XXXX", "cms/", "cms/admin.XXXX", "cms/index.XXXX", "ccp14admin/", "cgi-bin/login.XXXX", "cgi-bin/admin.XXXX", "cgi-bin/admin/index.XXXX", "cgi-bin/admin/admin.XXXX", "cgi-bin/admin/login.XXXX", "cgi/index.XXXX", "cgi/admin.XXXX", "cgi/login.XXXX", "cgi/admin/index.XXXX", "cgi/admin/admin.XXXX", "cgi/admin/login.XXXX", "check.XXXX", "checkadmin.XXXX", "CFIDE/administrator/", "CFIDE/admin/", "CFIDE/", "checklogin.XXXX", "checkuser.XXXX", "cmsadmin.XXXX", "cmsadmin/", "configuration/", "configure/", "control.XXXX", "control/", "controlpanel.XXXX", "controlpanel/", "cp.XXXX", "cp/", "cpanel/", "cpanel_file/", "customer_login/", "cvsadmin/", "database_administration/", "dir-login/", "directadmin/", "ezsqliteadmin/", "fileadmin.XXXX", "fileadmin/", "formslogin/", "globes_admin/", "gallery/login.XXXX", "gallery/admin/", "gallery/admin.XXXX", "gallery/users.XXXX",  "gallery_admin/", "home.XXXX", "hpwebjetadmin/", "instadmin/", "irc-macadmin/", "isadmin.XXXX", "kpanel/", "letmein.XXXX", "letmein/", "log-in.XXXX", "log-in/", "log_in.XXXX", "log_in/", "login-redirect/", "login-us/", "login.XXXX", "login/", "login1.XXXX", "login1/", "login_admin.XXXX", "login_admin/", "login_db/", "login_out.XXXX", "login_out/", "login_user.XXXX", "loginerror/", "loginflat/", "loginok/", "loginsave/", "loginsuper.XXXX", "loginsuper/", "logo_sysadmin/", "logout.XXXX", "logout/", "macadmin/", "maintenance/", "manage.XXXX", "manage/", "management.XXXX", "management/", "manager.XXXX", "manager/", "manuallogin/", "member.XXXX", "member/", "memberadmin.XXXX", "memberadmin/", "members.XXXX", "members/", "member/login.XXXX", "members/login.XXXX", "memlogin/", "meta_login/", "modelsearch/admin.XXXX", "modelsearch/index.XXXX", "modelsearch/login.XXXX", "moderator.XXXX", "moderator/", "moderator/admin.XXXX", "moderator/login.XXXX", "modules/admin/", "myadmin/", "navSiteAdmin/", "newsadmin/", "nsw/admin/login.XXXX", "openvpnadmin/", "pages/admin/", "pages/admin/admin-login.XXXX", "panel-administracion/", "panel-administracion/admin.XXXX", "panel-administracion/index.XXXX", "panel-administracion/login.XXXX", "panel.XXXX", "panel/", "panelc/", "paneldecontrol/", "pgadmin/", "phpSQLiteAdmin/", "phpldapadmin/", "phpmyadmin/", "phpMyAdmin/", "phppgadmin/", "platz_login/", "power_user/", "processlogin.XXXX", "project-admins/", "pureadmin/", "radmind-1/", "radmind/", "rcLogin/", "rcjakar/admin/login.XXXX", "relogin.XXXX", "CFIDE/componentutils/", "root/", "secret/", "secrets/", "secure/", "security/", "server/", "server_admin_small/", "showlogin/", "sign-in.XXXX", "sign-in/", "sign_in.XXXX", "sign_in/", "signin.XXXX", "signin/", "simpleLogin/", "siteadmin.XXXX", "siteadmin/", "CFIDE/adminapi/base.cfc?wsdl", "CFIDE/scripts/ajax/FCKeditor/editor/filemanager/connectors/cfm/upload.XXXX", "siteadmin/index.XXXX", "siteadmin/login.XXXX", "smblogin/", "sql-admin/", "ss_vms_admin_sm/", "sshadmin/", "staradmin/", "sub-login/", "super.XXXX", "super1.XXXX", "super1/", "super_index.XXXX", "super_login.XXXX", "superman.XXXX", "shopping-cart-admin-login.XXXX", "shop/manager/", "shop/admin/", "shop/login.XXXX", "shop/admin/login.XXXX", "store/admin/", "store/login.XXXX", "store/admin/login.XXXX", "store/manager/", "superman/", "supermanager.XXXX", "superuser.XXXX", "superuser/", "supervise/", "supervise/Login.XXXX", "supervisor/", "support_login/", "sys-admin/", "sysadm.XXXX", "sysadm/", "sysadmin.XXXX", "sysadmin/", "sysadmins/", "system-administration/", "system_administration/", "typo3/", "ur-admin.XXXX", "ur-admin/", "user.XXXX", "user/", "useradmin/", "user/login.XXXX", "userlogin.XXXX", "users.XXXX", "users/", "users/login.XXXX", "usr/", "utility_login/", "uvpanel/", "vadmind/", "vmailadmin/", "vorod.XXXX", "vorod/", "vorud.XXXX", "vorud/", "webadmin.XXXX", "webadmin/", "webadmin/admin.XXXX", "webadmin/index.XXXX", "webadmin/login.XXXX", "webmaster.XXXX", "webmaster/", "websvn/", "wizmysqladmin/", "blog/wp-admin/", "wp-admin/", "wp-admin/wp-login.XXXX", "wp/wp-login.XXXX", "blog/wp-login.XXXX", "wp-login.XXXX", "wp-login/", "xlogin/", "yonetici.XXXX", "yonetim.XXXX" ]
		fetch(common_admin)
	end

	def fetch(arrayofstuffwewant)
		# Check Standard Admin Pages
		@alinks=[] #placeholder for A link found pages!
		@blinks=[] #placeholder for B link found pages
		@clinks=[] #placeholder for C link found pages
		arrayofstuffwewant.shuffle.each do |page2find|
			#Cool Code Here
			target = "#{$module_required['Target'].sub(/\/$/, '')}/#{page2find.sub('.XXXX', "#{@type}")}"
			##### FIND FORMS FOR CONFIRMATION #####
			#Handle stupid servers which respond 200 to everything by checking for form fields!
			#inspired by UnSpok3n's admin finder & sites like: http://www.printlion.com/ (form confirms the real user login page)
			agent = Mechanize.new
			begin
				if not $module_optional['ProxyIp'] == 'nil' and not $module_optional['ProxyPort'] == 'nil'
					agent.set_proxy $module_optional['ProxyIp'], $module_optional['ProxyPort'].to_i
				end
				agent.get(target)
				if agent.page.code.to_i == 200
					forms = agent.page.forms
					if forms.length == 0
						puts "[".light_green + " #{agent.page.code.to_i} - NO FORMS ".light_yellow + "] ".light_green + "#{target}".white
						@clinks << target
					else
						##########################################################################################
						#Check if forms present in page response contain user/username/pass/password/email/member
						# If presemt in the field names, put in the A+ bucket :)
						##########################################################################################
						check=0
						agent.page.forms.each do |form|
							form.fields.each do |field|
								if field.name =~ /login|user|pass|email|member|usr|psswd|admin/i
									check = 1
								end
							end
						end
						if check.to_i == 0
							puts "[".light_yellow + " #{agent.page.code.to_i} - NO FORM MATCH ".white + "] ".light_yellow + "#{target}".white
							@clinks << target
						else
							puts "[".light_green + " #{agent.page.code.to_i} - FORM MATCH ".white + "] ".light_green + "#{target}".white
							@alinks << target
						end
					end
				else
					puts "[".light_red + " #{agent.page.code.to_i} ".white + "] ".light_red + "#{target}".white
				end
			rescue OpenSSL::SSL::SSLError => e
				if agent.page.code.to_i == 301 or agent.page.code.to_i == 302
					puts "[".light_green + " #{agent.page.code.to_i} ".light_red + "] ".light_green + "#{target}".white
					@blinks << target
				else
					puts "[".light_yellow + " #{agent.page.code.to_i} ".light_red + "] ".light_yellow + "#{target}".white
					puts "SSL Cert Issues, likely an admin page with self signed certs causing issue".yellow + "!".white
					puts "=> #{e}".light_red
				end
			rescue Net::HTTP::Persistent::Error
				next
			rescue Mechanize::ResponseCodeError => e
				if e.to_s.split(' ')[0] == '404'
					puts "[".light_red + " 404 ".white + "] ".light_red + "#{target}".white
				elsif e.to_s.split(' ')[0] == '403'
					puts "[".light_yellow + " 403 ".light_yellow + "] ".light_yellow + "#{target}".white
					@blinks << target
				elsif e.to_s.split(' ')[0] == '401' #Auth Required!
					puts "[".light_green + " UnAuthorized ".white + "] ".light_green + "#{target}".white
					@blinks << target
				else
					puts "#{e}".light_red
				end
			end
		end
		if not @alinks.nil?
			cls
			foo=[]
			@alinks = @alinks.uniq
			@blinks = @blinks.uniq
			@clinks = @clinks.uniq
			foo = @alinks + @blinks + @clinks
			puts "[".light_green + "*".white + "] Found the following ".light_green + "#{foo.length}".white + " links".light_green + ": ".white
			puts "[".light_green + "*".white + "] Primary Links".light_green + ": ".white
			@alinks.each do |admlinks|
				puts admlinks.white
			end
			if not @blinks.empty?
				puts "\n[".light_green + "*".white + "] Secondary Links".light_green + ": ".white
				@blinks.each do |admlinks|
					puts admlinks.white
				end
			end
			if not @clinks.empty?
				puts "\n[".light_green + "*".white + "] Other Links".light_green + ": ".white
				@clinks.each do |admlinks|
					puts admlinks.white
				end
			end
			puts "\n[".light_green + "*".white + "] Scan Complete".light_green + "!".white
		else
			puts "[".light_red + "X".white + "] Sorry, no pages were found".light_red + "!".white
			puts "[".light_red + "X".white + "] Check base link and try again or follow up manually".light_red + "....".white
		end
	end
end

AdminFinder.new
