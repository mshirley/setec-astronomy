require 'rubygems'
require 'aws-sdk'
require 'open-uri'
require 'net/scp'

tcvolume = "#{ENV['HOME']}/Dropbox/newdropbox"
cfnpath = "/opt/aws-cloudformation-tools/"
credfile = "#{ENV['HOME']}/.ec2/creds"
templatefile = "#{ENV['HOME']}/src/setec-astronomy/aws/setec-astronomy.template"
stack = "setec-astronomy"
keyname = "setec-astronomy"
webport = 1234
localkeys = "#{ENV['HOME']}/Downloads/"

def readcreds(credfile)
  puts "Reading EC2 credentials file, #{credfile}"
  if !File.exist?(credfile)
    puts "EC2 credientials file #{credfile} not found"
    exit
  else
    puts "EC2 credentials file found"
    creds = File.read(credfile)
    awsaccesskey = creds.split[0].split('=')[1]
    awssecretkey = creds.split[1].split('=')[1]
    return awsaccesskey, awssecretkey
  end 
end

def mounttc(tcvolume)
  puts "Mount true crypt volume? (y/n)"
  answer = gets.downcase.strip
  if answer == "y"
    puts "Mounting #{tcvolume}"
    result = %x["truecrypt #{tcvolume}"]
  elsif answer == "n"
    puts "Not mounting tc volume, continuing..."
    result = "notmounted"
  else 
    puts "Invalid entry, please use y or n, exiting"
    exit
  end
  return result
end

def check4stack(cfm, stack)
  begin
    puts "Checking for existing stack"
    if !cfm.stacks[stack].exists?
      puts "doesn't exist"
      stackstatus = "not running"
    else
      puts "it exists"
      stackstatus = "running" 
    end
    return stackstatus
  rescue
    puts "there was an error checking for a stack"
  end
end

def killstack(cfm, stack)
  begin
    puts "Would you like to kill your existing stack? (y/n)"
    answer = gets.downcase.strip
    if answer == "y"
      puts "Deleting #{stack}"
      cfm.stacks[stack].delete
      sleep 3
      setecstack = cfm.stacks[stack]
      setecstatus = check4stack(cfm, stack) 
      # this is causing an error
      # 
      #while setecstatus == "DELETE_IN_PROGRESS" do
      while setecstatus == "running"
        puts "Deletion still in progress, waiting..."
        sleep 3 
        setecstatus = check4stack(cfm, stack)  
      end
      puts "Deleted"
    elsif answer == "n"
      puts "Not deleting, running multiple stacks may cost you money"
    else
      puts "Invalid entry, please use y or n, exiting"
      exit
    end
  rescue
    puts "there was an error killing the stack"
  end
end

def createstack(cfm, stack, templatefile, keyname)
  begin
    puts "Would you like to create a new stack? (y/n)"
    answer = gets.downcase.strip
    if answer == "y"
      puts "Creating stack"
      template = File.read(templatefile)
      cfm.stacks.create(stack, template, :parameters => { 'KeyName' => keyname })
      setecstack = cfm.stacks[stack]
      puts "create signal sent"
      stackstatus = setecstack.status
      puts "current status is #{stackstatus}"
      while stackstatus == "CREATE_IN_PROGRESS" do
        puts "creation still in progress, waiting..."
        break if stackstatus == "CREATE_COMPLETE"
        sleep 3
        stackstatus = setecstack.status
      end
      puts "Created"
    elsif answer == "n"
      puts "Exiting"
      #exit
    else
      puts "Invalid entry, please use y or n, exiting"
      exit
    end
  rescue
    puts "there was an error trying to create stack"
  end
end

def getip(cfm, stack)
  begin  
    puts "Checking for ip address"
    puts "pulling ip address of stack" 
    setecstack = cfm.stacks[stack]
    stackip = setecstack.outputs[2].value 
    while stackip.nil? do 
      puts "no ip address yet, waiting" 
      #break if !stackip.nil?
      sleep 3
      stackip = setecstack.outputs[2].value
    end
    puts "Stack ip address is #{stackip}"
    return stackip
  rescue
    puts "there was an error getting the ip"
    return "notset"
  end
end

def check4web(stackip, webport)
  begin
    puts "Checking for web port..."
    webresult = open("http://#{stackip}:#{webport}/services")
    if webresult.string.include?("vpn")
      puts "Web port available"
      hasweb = true
      return hasweb
    else
      puts "Web port available but didn't have the expected content"
      hasweb = true
      return hasweb 
    end
  rescue
    hasweb = false
    return hasweb 
  end
end

def checkservicesssh(stackip)
  puts "Starting services"
  #begin
    Net::SSH.start( stackip, 'ec2-user' ) do |session|
      session.open_channel do |channel|
        channel.request_pty
        channel.exec "sudo sh -c '/etc/init.d/openvpn start; /etc/init.d/named start; /etc/init.d/squid start'"
        channel.on_data do |ch, data|
          puts "got stdout: #{data}"
        end
        #services = [ "openvpn", "named", "squid" ]
        #services.each do |service|
        #  puts service
          #result = channel.exec "sudo sh -c '/etc/init.d/#{service} status'"
          #puts "result is #{result}"
          #case result
          #when "not running"
          #  puts "service #{service} is not running, starting"
        #  channel.exec "sudo sh -c '/etc/init.d/#{service} start'"
          #when "running"
          #  puts "service #{service} is running"
          #else
          #  puts "service message not recognized"
          #end
        #end
      end
    end
        #channel.exec "ps aux | grep openvpn"
  #rescue
  #  puts "an error occured checking services"
  #end
end

def checkservices(stackip, webport)
  puts "Checking status of existing services"
  services = [ "vpn", "bind", "squid" ]
  services.each do |service|
    begin
      serviceresult = open("http://#{stackip}:#{webport}/services/#{service}/status")
      case serviceresult.string
      when "not running"
        puts "service #{service} is not running, starting"
        runresult = open("http://#{stackip}:#{webport}/services/#{service}/start")
        open("http://#{stackip}:#{webport}/services/vpn/process")
      when "start"
        puts "service #{service} is running" 
      end
      puts "#{service} is #{serviceresult.string}"
    rescue
      puts "Something went wrong checking services"
    end
  end
end

def printmenu1(stackstatus, stackip)
puts %{
*************
* Main Menu *
*************

Existing stack: #{stackstatus}
Stack ip: #{stackip}

[1] Create Stack

[2] Delete Stack

[3] Get Stack IP

[4] Check Services

[5] Copy vpn files

[6] Create /etc/hosts file

[7] Enable vpn

[8] Disable vpn

[9] Enable proxy (ubuntu only)

[10] Disable proxy (ubuntu only)

[11] Exit

}
end

def pullkeys(stackip, localkeys, webport)
  begin
    puts "processing remote certificates"
    #open("http://#{stackip}:#{webport}/services/vpn/process")
    Net::SSH.start( stackip, 'ec2-user' ) do |session|
      session.open_channel do |channel|
        channel.request_pty
        channel.exec "sudo sh -c 'cp /tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/ca.crt /home/ec2-user/;cp /tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/client1.crt /home/ec2-user/;cp /tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/client1.key /home/ec2-user/; chown -R ec2-user:ec2-user /home/ec2-user/'"
      end
    end
    puts "pulling vpn certificates"
    Net::SCP.start(stackip, 'ec2-user') do |scp|
      # run multiple downloads in parallel
      d1 = scp.download("/home/ec2-user/ca.crt", "#{localkeys}/ca.crt")
      d2 = scp.download("/home/ec2-user/client1.crt", "#{localkeys}/client1.crt")
      d3 = scp.download("/home/ec2-user/client1.key", "#{localkeys}/client1.key")
      [d1, d2, d3].each { |d| d.wait }
    end  
    puts "cleaning up remote certificates"
    Net::SSH.start( stackip, 'ec2-user' ) do |session|
      session.open_channel do |channel|
        channel.request_pty
        channel.exec "sudo sh -c 'rm /home/ec2-user/ca.crt; rm /home/ec2-user/client1.crt; rm /home/ec2-user/client1.key'"
      end
    end
  rescue Net::SSH::AuthenticationFailed
    puts "authentication error, ensure you're setting SSHKEYS and that ssh-add is working.  if you have to just manually ssh-add your aws pem before running usercontrol.sh"
  rescue
    puts "an error occured while downloading keys"
  end
end

#mounttc(tcvolume)

awsaccesskey, awssecretkey = readcreds(credfile)

cfm = AWS::CloudFormation.new( :access_key_id => awsaccesskey, :secret_access_key => awssecretkey)

stackstatus = check4stack(cfm, stack)
if stackstatus == "running"
  stackip = getip(cfm, stack)
else
  stackip = "notset"
end

menu1in = ""
until menu1in == "11"
  printmenu1(stackstatus, stackip)
  print " > "
  menu1in = gets.strip
  case menu1in
  when "1" 
    if stackstatus == "running"
      killstack(cfm, stack)
    end      
    puts "execute createstack()"
    createstack(cfm, stack, templatefile, keyname)
    stackstatus = check4stack(cfm, stack)
    stackip = getip(cfm, stack)
  when "2"
    stackstatus = check4stack(cfm, stack)
    if stackstatus == "running"
      killstack(cfm, stack)
      stackstatus = check4stack(cfm, stack) 
    else 
      puts "no stack to delete"
    end
    stackip = "notset"
  when "3"
    stackip = getip(cfm, stack)    
  when "4"
    #hasweb = check4web(stackip, webport)
    #until hasweb do
    #  puts "Web port not available yet, waiting..."
    #  sleep 10
    #  hasweb = check4web(stackip, webport)
    #end
    #checkservices(stackip, webport)  
    checkservicesssh(stackip)
  when "5"
    if stackip == "notset"
      puts "no stack ip set, start a stack"
    else
      pullkeys(stackip, localkeys, webport)
    end
  when "6"
    if stackip == "notset"
       puts "no stack ip set, start a stack and pull the ip"
    else
       system("sudo sh -c 'cp /etc/hosts /tmp/hosts-backup'")
       system("sed '/setec-astronomy/c\\' /etc/hosts > /tmp/newhosts")
       system("echo \"10.8.0.1 setec-astronomy-int\" >> /tmp/newhosts")
       system("sudo sh -c 'echo \"#{stackip} setec-astronomy\" >> /tmp/newhosts'")
       system("sudo sh -c 'mv /tmp/newhosts /etc/hosts'")
    end
  when "7"
    system("nmcli con up id setec-astronomy-vpn")
  when "8"
    system("nmcli con down id setec-astronomy-vpn")
  when "9"
    system("gsettings set org.gnome.system.proxy.socks host 'setec-astronomy-int'")
    system("gsettings set org.gnome.system.proxy.socks port 3128")
    system("gsettings set org.gnome.system.proxy.ftp host 'setec-astronomy-int'")
    system("gsettings set org.gnome.system.proxy.ftp port 3128")
    system("gsettings set org.gnome.system.proxy.http host 'setec-astronomy-int'")
    system("gsettings set org.gnome.system.proxy.http port 3128")
    system("gsettings set org.gnome.system.proxy.https host 'setec-astronomy-int'")
    system("gsettings set org.gnome.system.proxy.https port 3128")
    system("gsettings set org.gnome.system.proxy mode 'manual'")
  when "10"
    system("gsettings set org.gnome.system.proxy mode 'none'")
  # when 9, 10
  # nmcli con up id setec-astronomy-vpn
  # nmcli con down id setec-astronomy-vpn
  end
end
