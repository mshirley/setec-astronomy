require 'rubygems'
require 'aws-sdk'
require 'open-uri'
require 'net/scp'

tcvolume = "#{ENV['HOME']}/Dropbox/newdropbox"
cfnpath = "/opt/aws-cloudformatino-tools/"
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
  puts "Checking for existing stack"
  if !cfm.stacks[stack].exists?
    puts "doesn't exist"
    stackstatus = "not running"
  else
    puts "it exists"
    stackstatus = "running" 
  end
  return stackstatus
end

def killstack(cfm, stack)
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
end

def createstack(cfm, stack, templatefile, keyname)
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
end

def getip(cfm, stack)
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
      puts "Something went wrong"
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

[6] Exit

}
end

def pullkeys(stackip, localkeys, webport)
  begin
    puts "processing vpn files"
    open("http://#{stackip}:#{webport}/services/vpn/process")
    puts "pulling ca.crt"
    Net::SCP::download!(stackip, "ec2-user", "/home/ec2-user/ca.crt", "#{localkeys}/ca.crt")
    puts "pulling client1.crt"
    Net::SCP::download!(stackip, "ec2-user", "/home/ec2-user/client1.crt", "#{localkeys}/client1.crt")
    puts "pulling client1.key"
    Net::SCP::download!(stackip, "ec2-user", "/home/ec2-user/client1.key", "#{localkeys}/client1.key")
    open("http://#{stackip}:#{webport}/services/vpn/cleanup")
    puts "remote files cleaned"
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
until menu1in == "6"
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
    stackstatus = "running"
  when "2"
    stackstatus = check4stack(cfm, stack)
    if stackstatus == "running"
      killstack(cfm, stack)
    else 
      puts "no stack to delete"
    end
    stackip = "notset"
  when "3"
    stackip = getip(cfm, stack)    
  when "4"
    hasweb = check4web(stackip, webport)
    until hasweb do
      puts "Web port not available yet, waiting..."
      sleep 10
      hasweb = check4web(stackip, webport)
    end
    checkservices(stackip, webport)  
  when "5"
    if stackip == "notset"
      puts "no stack ip set, start a stack"
    else
      pullkeys(stackip, localkeys, webport)
    end
  end
end

#stackstatus = check4stack(cfm, stack)
#if stackstatus
#  killstack(cfm, stack)
#end
#createstack(cfm, stack, templatefile, keyname)
#stackip = getip(cfm, stack) 
#hasweb = check4web(stackip, webport)
#until hasweb do
#  puts "Web port not available yet, waiting..."
#  sleep 10
#  hasweb = check4web(stackip, webport)
#end
#checkservices(stackip, webport)
