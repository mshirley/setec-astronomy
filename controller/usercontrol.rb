require 'rubygems'
require 'aws-sdk'

tcvolume = "#{ENV['HOME']}/Dropbox/newdropbox"
cfnpath = "/opt/aws-cloudformatino-tools/"
credfile = "#{ENV['HOME']}/.ec2/creds"

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

def check4stack()
  puts "Checking for existing stack"
  result = %x[/opt/aws-cloudformation-tools/bin/cfn-describe-stacks "setec-astronomy --show-long"]
  if result.include?("not set")
    puts "Please run usercontrol.sh, environmental variables not set"
  elsif result.include?("stack")
    existingstack = result.split(",")[1]
    puts "Stack found, #{existingstack}"
    hasstack = true
  elsif result.include?("Malformed")
    puts "Network connectivity issue, please ensure you have internet access, exiting"
    exit
  else
    puts "Stack not found"
    hasstack = false
  end
  return hasstack
end

def killstack()
  puts "Would you like to kill your existing stack? (y/n)"
  answer = gets.downcase.strip
  if answer == "y"
    puts "Deleting #{existingstack}"
    result = %x[/opt/aws-cloudformation-tools/bin/cfn-delete-stack "#{existingstack}"]
  elsif answer == "n"
    puts "Not deleting, running multiple stacks may cost you money"
  else
    puts "Invalid entry, please use y or n, exiting"
    exit
  end
  return result
end

def createstack()
  puts "Would you like to create a new stack? (y/n)"
  answer = gets.downcase.strip
  if answer == "y"
    result = %x[/opt/aws-cloudformation-tools/bin./cfn-create-stacksetec-astronomy "--template-file ~/src/setec-astronomy/aws/setec-astronomy.template --parameters=KeyName=setec-astronomy"]
  elsif answer == "n"
    puts "Exiting"
    exit
  else
    puts "Invalid entry, please use y or n, exiting"
    exit
  end
  return result
end

def verifystack()
  puts "Checking"
  result = %x[/opt/aws-cloudformation-tools/bin/cfn-describe-stacks "setec-astronomy --show-long"]
  if result.include?("not set")
    puts "Please run usercontrol.sh, environmental variables not set"
    return "error #{result}"
  elsif result.include?("stack")
    existingstack = result.split(",")[1]
    puts "Stack found, #{existingstack}"
    hasstack = true
    return existingstack 
  elsif result.include?("Malformed")
    puts "Network connectivity issue, please ensure you have internet access, exiting"
    return "error #{result}"
    exit
  end
end

mounttc(tcvolume)
awsaccesskey, awssecretkey = readcreds(credfile)
hasstack = check4stack()
if hasstack
  killstack()
end
createstack()
puts "Waiting 15seconds for stack ip to be populated..."
sleep 15
newstackip = verifystack()
if newstackip.nil?
elsif newstackip.include?("error")
  puts "error verifying new instance, #{newstackip}"
else
  puts "new stack ip is #{newstackip}"
end
