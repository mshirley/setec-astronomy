tcvolume = "~/Dropbox/newdropbox"
cfnpath = "/opt/aws-cloudformatino-tools/"

puts "Mount true crypt volume? (y/n)"
answer = gets.downcase.strip
if answer == "y"
  puts "Mounting #{tcvolume}"
  result = %x["truecrypt #{tcvolume}"]
elsif answer == "n"
    puts "Not mounting tc volume, continuing..."
else 
  puts "Invalid entry, please use y or n, exiting"
  exit
end

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
end

if hasstack
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
end

puts "Would you like to create a new stack? (y/n)"
if answer == "y"
  result = %x[/opt/aws-cloudformation-tools/bin./cfn-create-stacksetec-astronomy "--template-file ~/src/setec-astronomy/aws/setec-astronomy.template --parameters=KeyName=setec-astronomy"]
elsif answer == "n"
  puts "Exiting"
  exit
else
  puts "Invalid entry, please use y or n, exiting"
  exit
end

puts "Waiting for stack ip to be populated..."
puts "Checking"
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
end

