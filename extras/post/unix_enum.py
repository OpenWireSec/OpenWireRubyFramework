#!/usr/bin/env python
#
# Unix System Enumeration Python Script
# By: MrGreen & Hood3dRob1n Adapted to python by elLocoGringo
#
"""
Documented Differences between inf0rm3r.py and inf0rm3r.rb:
	fileInfo()
		uses free -l -o -b -t instead of free --lohi --human as the latter would not run, this can be re-evaluated in future versions
	informer.log()
		uses universally to print to terminal as well as write to output file
"""

import os
import time
import glob
import fnmatch
import commands
import subprocess

class informer:

	def __init__(self):
		# time of Execution start
		self.start_time = time.time()
		# Time
		self.time = self.get_time()
		# Date
		self.date = time.strftime('%Y-%m-%d')
		# Output file
		self.logfile = open("inf0rmed.txt", "w+")
		# Add or remove files to search the filesystem for
		self.scanlist = ['config.php', 'config.inc.php', 'config.class.php', 'wp-config.php', 'db.php', 'db-conn.php', 'sql.php', 'security.php', 'service.pwd', '.htpasswd', '*.sql', '.bash_history', 'config.*']
		# Colours
		self.purple = '\033[95m'
		self.blue = '\033[94m'
		self.green = '\033[92m'
		self.yellow = '\033[93m'
		self.red = '\033[91m'
		self.clear = '\033[0m'

	def banner_logo(self):
		ban = """
	|<><><><><><><><><><><><><><><><><><><><><><><>|
	|            can       *       y0u             |
	|   /\~~~~~~~~~~~~~~~~~|~~~~~~~~~~~~~~~~~/\    |
	|  (o )                .                ( o)   |
	|   \/               .` `.               \/    |
	|   /\             .`     `.             /\    |
	|  (             .`         `.             )   |
	|   )          .`      N      `.          (    |
	|  (         .`   A    |        `.         )   |
	|   )      .`     <\> )|(         `.      (    |
	|  (     .`         \  |  (         `.     )   |
	|   )  .`         )  \ |    (         `.  (    |
	|    .`         )     \|      (         `.     |
	|  .`     W---)--------O--------(---E     `.   |
	|   `.          )      |\    (           .`    |
	|   ) `.          )    | \ (           .` (    |
	|  (    `.          )  |  \          .`    )   |
	|   )     `.          )|( <\>      .`     (    |
	|  (        `.         |         .`        )   |
	|   )         `.       S       .`         (    |
	|  (            `.           .`            )   |
	|   \/            `.       .`            \/    |
	|   /\              `.   .`              /\    |
	|  (o )               `.`               ( o)   |
	|   \/~~~~~~~~~~~~~~~~~|~~~~~~~~~~~~~~~~~\/    |
	|            find     -|-     r00t?            |
	|<><><><><><><><><><><><><><><><><><><><><><><>|

	"""
		return ban

	def cls(self):
		os.system('clear')
		return True

	def run(self):
		self.cls()
		self.log(self.banner_logo(), 'green')

		self.log("Unix System Enumerator Script", 'purple')
		self.log("By: Hood3dRob1n and Phaedrus", 'purple')
		self.log("Started: " + self.date + ", at " + self.time, 'purple')
		self.log(" ")
		self.log("Highlights will be displayed in console, check 'inf0rm3d.txt' file for full system enumeration details", 'green')

		self.basicInfo()
		time.sleep(5)

		self.getKernelSploits()
		time.sleep(5)

		self.interestingStuff()
		time.sleep(5)

		self.toolz()
		time.sleep(5)

		self.fileInfo()
		time.sleep(5)

		self.userInfo()
		time.sleep(5)

		self.networkInfo()
		time.sleep(5)

		self.miscInfo()
		time.sleep(5)

		self.closer()
		self.logfile.close()

	def fileInfo(self):

		mem = self.commandz('free -l -o -b -t 2> /dev/null')
		mountz = self.commandz('mount')
		sizez = self.commandz('df -h')

		self.log(" ")
		self.log("FileSystem Info:", 'green')

		if mountz:
			self.log(" ")
			self.log("Mounts: ", 'green')
			self.log(mountz, 'yellow')
		if sizez:
			self.log(" ")
			self.log("Disk Space: ", 'green')
			self.log(sizez, 'yellow')
		if mem:
			self.log(" ")
			self.log("Memory Space: ", 'green')
			self.log(mem, 'yellow')

	def getAV(self):
		tools = self.commandz('whereis avast bastille bulldog chkrootkit clamav firestarter iptables jailkit logrotate logwatch lynis  pwgen rkhunter snort tiger truecrypt ufw webmin')
		if tools:
			self.log(" ")
			self.log("Possible Security/AV Found: ", 'green')
			self.log(tools, 'yellow')

	def get_time(self):
		return time.strftime('%l:%M %p')

	def basicInfo(self):
		host = self.commandz('/bin/hostname')
		uptime = self.commandz('/usr/bin/uptime')
		shell = self.commandz("echo $SHELL")
		user = os.environ['USER']
		whoami = self.commandz('whoami')
		uid = os.getuid()
		euid = os.geteuid()
		home = self.commandz("echo $HOME")
		pwd = self.commandz("pwd")
		uname = self.commandz("uname -a")

		self.log("\n")
		self.log("Hostname: " + host.strip(), 'green')
		self.log("System Uptime: " + uptime.strip(), 'green')
		self.log("Current Shell in use: " + shell.strip(), 'green')
		self.log("Logged in user: " + user.strip(), 'green')
		self.log("Whoami: " + whoami.strip(), 'green')
		self.log("UID: " + str(uid), 'green')
		self.log("EUID: " + str(euid), 'green')
		self.log("User Home Directory: " + home.strip(), 'green')
		self.log("Current Working Directory: " + pwd.strip(), 'green')
		self.log("Kernel/Build: " + uname.strip(), 'green')

	def getKernelSploits(self):
		known_sploits = {"do_brk" : {"CVE" : "2003-0961", "versions" : ["2.4.0-2.4.22"], "exploits" : ["131"] },
						 "mremap missing do_munmap" : { "CVE" : "2004-0077", "versions" : ["2.2.0-2.2.25", "2.4.0-2.4.24", "2.6.0-2.6.2"], "exploits" : ["160"] },
						 "binfmt_elf Executable File Read" : { "CVE" : "2004-1073", "versions" : ["2.4.0-2.4.27", "2.6.0-2.6.8"], "exploits" : ["624"] },
						 "uselib()" : { "CVE" : "2004-1235", "versions" : ["2.4.0-2.4.29rc2", "2.6.0-2.6.10rc2"], "exploits" : ["895"] },
						 "bluez" : { "CVE" : "2005-1294", "versions" : ["2.6.0-2.6.11.5"], "exploits" : ["4756", "926"] },
						 "prctl()" : { "CVE" : "2006-2451", "versions" : ["2.6.13-2.6.17.4"], "exploits" : ["2031", "2006", "2011", "2005", "2004"] },
						 "proc" : { "CVE" : "2006-3626", "versions" : ["2.6.0-2.6.17.4"], "exploits" : ["2013"] },
						 "system call emulation" : { "CVE" : "2007-4573", "versions" : ["2.4.0-2.4.30", "2.6.0-2.6.22.7"], "exploits" : ["4460"] },
						 "vmsplice" : { "CVE" : "2008-0009", "versions" : ["2.6.17-2.6.24.1"], "exploits" : ["5092", "5093"] },
						 "ftruncate()/open()" : { "CVE" : "2008-4210", "versions" : ["2.6.0-2.6.22"], "exploits" : ["6851"] },
						 "eCryptfs (Paokara)" : { "CVE" : "2009-0269", "versions" : ["2.6.19-2.6.31.1"], "exploits" : ["spender"] },
						 "set_selection() UTF-8 Off By One" : { "CVE" : "2009-1046", "versions" : ["2.6.0-2.6.28.3"], "exploits" : ["9083"] },
						 "UDEV < 141" : { "CVE" : "2009-1185", "versions" : ["2.6.25-2.6.30"], "exploits" : ["8478", "8572"] },
						 "exit_notify()" : { "CVE" : "2009-1337", "versions" : ["2.6.0-2.6.29"], "exploits" : ["8369"] },
						 "ptrace_attach() Local Root Race Condition" : { "CVE" : "2009-1527", "versions" : ["2.6.29"], "exploits" : ["8678", "8673"] },
						 "sock_sendpage() (Wunderbar Emporium)" : { "CVE" : "2009-2692", "versions" : ["2.6.0-2.6.31rc3", "2.4.0-2.4.37.1"], "exploits" : ["9641", "9545", "9479", "9436", "9435", "spender"] },
						 "udp_sendmsg() (The Rebel)" : { "CVE" : "2009-2698", "versions" : ["2.6.0-2.6.9.2"], "exploits" : ["9575", "9574", "spender3"] },
						 "(32bit) ip_append_data() ring0" : { "CVE" : "2009-2698", "versions" : ["2.6.0-2.6.9"], "exploits" : ["9542"] },
						 "perf_counter_open() (Powerglove and Ingo m0wnar)" : { "CVE" : "2009-3234", "versions" : ["2.6.31"], "exploits" : ["spender"] },
						 "pipe.c (MooseCox)" : { "CVE" : "2009-3547", "versions" : ["2.6.0-2.6.32rc5", "2.4.0-2.4.37"], "exploits" : ["10018", "spender"] },
						 "CPL 0" : { "CVE" : "2010-0298", "versions" : ["2.6.0-2.6.11"], "exploits" : ["1397"] },
						 "ReiserFS xattr" : { "CVE" : "2010-1146", "versions" : ["2.6.0-2.6.34rc3"], "exploits" : ["12130"] },
						 "Unknown" : { "CVE" : 'nil', "versions" : ["2.6.18-2.6.20"], "exploits" : ["10613"] },
						 "SELinux/RHEL5 (Cheddar Bay)" : { "CVE" : 'nil', "versions" : ["2.6.9-2.6.30"], "exploits" : ["9208", "9191", "spender"] },
						 "compat" : { "CVE" : "2010-3301", "versions" : ["2.6.27-2.6.36rc4"], "exploits" : ["15023", "15024"] },
						 "BCM" : { "CVE" : "2010-2959", "versions" : ["2.6.0-2.6.36rc1"], "exploits" : ["14814"] },
						 "RDS protocol" : { "CVE" : "2010-3904", "versions" : ["2.6.0-2.6.36rc8"], "exploits" : ["15285"] },
						 "put_user() - full-nelson" : { "CVE" : "2010-4258", "versions" : ["2.6.0-2.6.37"], "exploits" : ["15704"] },
						 "sock_no_sendpage() - full-nelson" : { "CVE" : "2010-3849", "versions" : ["2.6.0-2.6.37"], "exploits" : ["15704"] },
						 "ACPI custom_method" : { "CVE" : "2010-4347", "versions" : ["2.6.0-2.6.37rc2"], "exploits" : ["15774"] },
						 "CAP_SYS_ADMIN" : { "CVE" : "2010-4347", "versions" : ["2.6.34-2.6.37"], "exploits" : ["15916", "15944"] },
						 "econet_sendmsg() - half-nelson" : { "CVE" : "2010-3848", "versions" : ["2.6.0-2.6.36.2"], "exploits" : ["17787"] },
						 "ec_dev_ioctl() - half-nelson" : { "CVE" : "2010-3850", "versions" : ["2.6.0-2.6.36.2"], "exploits" : ["17787", "15704"] },
						 "Mempodipper" : { "CVE" : "2012-0056", "versions" : ["2.6.39-3.1"], "exploits" : ["18411", "mempo"]},
						 "Archlinux x86-64 sock_diag_handlers[]" : { "CVE" : "2013-1763", "versions" : ["3.3-3.7"], "exploits" : ["24555"]},
						 "Fedora 18 x86-64 sock_diag_handlers[]" : { "CVE" : "2013-1763", "versions" : ["3.3-3.7"], "exploits" : ["ps1"]},
						 "Ubuntu 12.10 64-Bit sock_diag_handlers[]" : { "CVE" : "2013-1763", "versions" : ["3.3-3.7"], "exploits" : ["24746"]},
						 "ipc - half-nelson" : { "CVE" : "2010-4073", "versions" : ["2.6.0-2.6.37rc1"], "exploits" : ["17787"] }
						 }

		k = self.commandz("uname -r").strip()
		specialk = k.split("-")[0]
		exploit_db = "http://www.exploit-db.com/exploits/"
		mempo = "http://git.zx2c4.com/CVE-2012-0056/snapshot/CVE-2012-0056-master.zip"
		spender = "http://www.securityfocus.com/data/vulnerabilities/exploits/36423.tgz"
		ps1 = "http://packetstormsecurity.com/files/download/120784/fedora-sockdiag.c"
		self.log(" ")
		self.log("Possible Exploits: ", 'green')
		found = 0
		for key, value in known_sploits.items():
			versions = value['versions']
			vsize = len(versions)
			count = 0
			
			while count < vsize:
				for ver in versions:
					if '-' in ver:
						vrange = ver.split("-")
						min_val = vrange[0]
						max_val = vrange[1]
					else:
						min_val = max_val = ver
					specialk = '.'.join(specialk.split(".")[:2])
					min_val = '.'.join(min_val.split(".")[:2])
					max_val = '.'.join(max_val.split(".")[:2])

					if float(specialk) >= float(min_val) and float(specialk) <= float(max_val):
						foo = specialk.split(".")
						foo.pop()
						kfoo = '.'.join(foo)

						foo = min_val.split(".")
						foo.pop()
						minfoo = '.'.join(foo)

						foo = max_val.split(".")
						foo.pop()
						maxfoo = '.'.join(foo)

						if float(kfoo) >= float(minfoo) and float(kfoo) <= float(maxfoo):
							found += 1
							cve = value["CVE"]
							exploit = value["exploits"]
							self.log("Kernel: " + k, 'yellow')
							self.log("Possible Exploit: " + key, 'yellow')
							self.log("CVE: " + cve, 'yellow')
							self.log("Versions Affected: " + ', '.join(versions), 'yellow')
							self.log("Downloads Available for Possible Exploit: ", 'yellow')

							for sploit in exploit:
								if sploit == "spender":
									self.log(spender, 'yellow')
								elif sploit == "mempo":
									self.log(mempo, 'yellow')
								elif sploit == "ps1":
									self.log(ps1, 'yellow')
								else:
									self.log(exploit_db + sploit, 'yellow')
							self.log(" ")

				count += 1

		if found == 0:
			self.log("Sorry, didnt find any matching exploits for kernel....", 'red')
		else:
			self.log("Hopefully you can use the above to help find your way to r00t....", 'green')

	def getPassAndConfigs(self):
		self.log(" ")
		self.log("Checking for Password & Config Files....", 'green')
		for conf in self.scanlist:
			self.print_files(conf)
			self.log(" ")

	def getSSH(self):
		self.log(" ")
		self.log("SSH Goodness", 'green')
		paths = self.search_dirs('.ssh')
		for path in paths:
			files = self.commandz('ls ' + path).split("\n")
			for fil in files:
				data = self.commandz('cat ' + path + '/' + fil)
				self.log(data)

	def interestingStuff(self):
		self.log(" ")
		self.log("Interesting Info:", 'green')
		writable = self.commandz('find / -type d -perm -2 -ls 2> /dev/null')
		self.log(" ")
		self.log("World Writable Directories:", 'green')
		self.log(writable, 'yellow')
		suid = self.commandz('find / -type f -perm -04000 -ls 2> /dev/null')
		self.log(" ")
		self.log(suid, 'yellow')
		guid = self.commandz('find / -type f -perm -02000 -ls 2> /dev/null')
		self.log(" ")
		self.log(guid, 'yellow')
		self.getSSH()
		self.getAV()
		self.getPassAndConfigs()
		sudos = self.commandz('cat /etc/sudoers')
		if sudos:
			self.log(" ")
			self.log("/etc/sudoers Content: ", 'green')
			try:
				self.log(sudos, 'yellow')
			except:
				self.log("Failed....", "red")

	def miscInfo(self):
		logz = self.commandz('ls -lRa /var/log 2> /dev/null')
		etcls = self.commandz('ls -lRa /etc 2> /dev/null')
		tmp = self.commandz('ls -lRa /tmp 2> /dev/null')
		lgmsgz = self.commandz('cat /var/log/messages 2> /dev/null')
		last = self.commandz('last -50 2> /dev/null')
		self.log(" ")
		self.log("Misc Info: ", 'green')
		self.log(" ")
		self.log("Cron Jobs: ", 'green')
		for gold in glob.glob("/etc/cron*"):
			self.log(gold, 'yellow')
		if logz:
			self.log(" ")
			self.log("/var/log content: ", 'green')
			self.log(logz, 'yellow')
		if etcls:
			self.log(" ")
			self.log("/etc content: ", 'green')
			self.log(etcls, 'yellow')					
		if tmp:
			self.log(" ")
			self.log("/tmp content: ", 'green')
			self.log(tmp, 'yellow')
		if lgmsgz:
			self.log(" ")
			self.log("/var/log/messages content: ", 'green')
			self.log(lgmsgz, 'yellow')
		if last:
			self.log(" ")
			self.log("Last 50 logins: ", 'green')
			self.log(last, 'yellow')

	def networkInfo(self):
		interfaces = self.commandz('/sbin/ifconfig -a 2> /dev/null')
		hosts = self.commandz('cat /etc/hosts')
		resolvers = self.commandz('cat /etc/resolv.conf 2> /dev/null')
		route = self.commandz('route 2> /dev/null')
		ports = self.commandz('netstat -lpn 2> /dev/null')
		listening = self.commandz('netstat -n --listen 2> /dev/null')
		procs = self.commandz('ps axuw')

		self.log(" ")
		self.log("Known Interfaces: ", 'green')
		self.log(interfaces, 'yellow')
		self.log(" ")
		self.log("resolv.conf content: ", 'green')
		self.log(resolvers, 'yellow')
		self.log(" ")
		self.log("/etc/hosts content: ", 'green')
		self.log(hosts, 'yellow')
		self.log(" ")
		self.log("Routing Table: ", 'green')
		self.log(route, 'yellow')
		self.log(" ")
		self.log("Netstat - Open Ports and Services: ", 'green')
		self.log(ports, 'yellow')
		self.log(" ")
		self.log("Listening Ports: ", 'green')
		self.log(listening, 'yellow')
		self.log(" ")
		self.log("Process Listing: ", 'green')
		self.log(procs, 'yellow')

	def toolz(self):
		tools = self.commandz('which curl gcc java lynx nc ncat netcat nmap ftp perl php proxychains python ruby tcpdump wget wireshark')
		try:
			gcc = self.commandz('gcc --version')
		except:
			pass
		try:
			mysql = self.commandz('mysql --version')
		except:
			pass
		try:
			perl = self.commandz('perl -v')
		except:
			pass
		try:
			php = self.commandz('php -v')
		except:
			pass
		try:
			ruby = self.commandz('ruby -v ')
		except:
			pass
		try:
			java = self.commandz('java -version')
		except:
			pass
		try:
			python = self.commandz('python -V')
		except:
			pass

		self.log(" ")
		self.log("Local Tools: ", 'green')
		self.log(tools)
		self.log(" ")
		self.log("Version Info:", 'green')
		self.log("\nGCC:")
		self.log(gcc, 'yellow')
		self.log("\nMySQL:", 'green')
		self.log(mysql, 'yellow')
		self.log("\nPerl:", 'green')
		self.log(perl, 'yellow')
		self.log("\nPHP:", 'green')
		self.log(php, 'yellow')
		self.log("\nRuby:", 'green')
		self.log(ruby, 'yellow')
		self.log("\nJava:", 'green')
		self.log(java, 'yellow')
		self.log("\nPython:", 'green')
		self.log(python, 'yellow')

	def userInfo(self):
		userCount = self.commandz('cat /etc/passwd | /usr/bin/wc -l')
		shadow = self.commandz('cat /etc/shadow 2> /dev/null')
		users = self.commandz('cat /etc/passwd')
		group = self.commandz('cat /etc/group')

		self.log("User Info:", 'green')
		self.log(" ")
		self.log("Number of users: " + userCount[0].strip(), 'yellow')
		self.log(" ")
		self.log("/etc/shadow Content:", 'green')
		self.log(shadow, 'yellow')
		self.log(" ")
		self.log("/etc/passwd Content:", 'green')
		self.log(users, 'yellow')
		self.log(" ")
		self.log("/etc/group Content", 'green')
		self.log(group, 'yellow')

	def commandz(self, foo):
		
		bar = commands.getstatusoutput(foo)
		return bar[1]

	def closer(self):
		finish = time.time()
		exec_time = finish - self.start_time
		if exec_time < 60:
			self.log("Finished in " + str(exec_time) + " seconds", "blue")
		elif exec_time < 3600:
			exec_min = exec_time / 60
			exec_sec = exec_time % 60
			self.log("Finished in " + str(exec_min) + " minutes " + str(exec_sec) + " seconds", "blue")
		else:
			exec_hours = exec_time / 3600
			rem = exec_time % 3600
			exec_min = rem / 60
			exec_sec = rem % 60
			self.log("Finished in " + str(exec_hours) + " hours " + str(exec_min) + " minutes " + str(exec_sec) + " seconds", "blue")
		self.log("Bye Now!", 'purple')

	def log(self, logdata, col="yellow"):
		if col == "yellow":
			colour = self.yellow
		elif col == "red":
			colour = self.red
		elif col == "purple":
			colour = self.purple
		elif col == "green":
			colour = self.green
		elif col == "blue":
			colour = self.blue
		else:
			colour = self.yellow

		print colour + logdata + self.clear
		self.logfile.write(str(logdata)+"\n")
		self.logfile.flush()

	def search_files(self, filename):
		results = []
		for base, dirs, files in os.walk('/'):
			matches = fnmatch.filter(files, filename)
			results.extend(os.path.join(base, f) for f in matches)
		return results

	def search_dirs(self, dirname):
		results = []
		for base, dirs, files in os.walk('/'):
			matches = fnmatch.filter(dirs, dirname)
			results.extend(os.path.join(base, f) for f in matches)
		return results

	def print_files(self, filename):
		self.log("ALL "+filename+" Files:", 'green')
		for conf in self.search_files(filename):
			self.log(conf.strip(), 'yellow')

def main():
	
	try:
		inf = informer()
		inf.run()

	except KeyboardInterrupt:
		print
		print  inf.red + "\n[-] Terminating: User Aborted" + inf.clear
		inf.logfile.close()
				
	except EOFError:
		print
		print  inf.red + "\n[-] Terminating: Exit" + inf.clear
		inf.logfile.close()
		
	except SystemExit:
		pass

if __name__ == '__main__':
	main()
