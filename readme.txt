Firstly you need to put this script in your metasploit directory under the following location:

./metasploit/scripts/meterpreter/secdump.rb
Secondly you need to make sure that the script knows where your gsecdump binary is, either edit the script, line 93, or place it here:

~/windows_tools/gsecdump-v2b5.exe
