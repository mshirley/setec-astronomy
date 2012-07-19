require 'rubygems' 
require 'aws-sdk'

credfile = "#{ENV['HOME']}/.ec2/creds"
templatefile = "#{ENV['HOME']}/src/setec-astronomy/aws/setec-astronomy.template"

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

awsaccesskey, awssecretkey = readcreds(credfile)

cfm = AWS::CloudFormation.new( :access_key_id => awsaccesskey, :secret_access_key => awssecretkey)

#puts cfm.methods.sort


# this will be used to determine if a stack exists, link with creation function
if !cfm.stacks['setec-astronomy'].exists?
  puts "doesn't exist"
else
  puts "it exists"
end

# this will create a new stack using the existing template
puts "creating stack"
template = File.read(templatefile)
cfm.stacks.create('setec-astronomy', template, :parameters => { 'KeyName' => 'setec-astronomy' })
setecstack = cfm.stacks['setec-astronomy']
puts "create signal sent"
stackstatus = setecstack.status
puts "current status is #{stackstatus}"

while stackstatus == "CREATE_IN_PROGRESS" do
  puts "creation still in progress, waiting..."
  break if stackstatus == "CREATE_COMPLETE"
  sleep 5 
  stackstatus = setecstack.status
end

#setecstack = cfm.stacks.create('name', template, :parameters => {
#  'KeyName' => 'setec-astronomy',
#})


#puts setecstack.methods.sort

# this is what we would need to look at after creating a stack to determine when it is finished
# CREATE_COMPLETE
# DELETE_IN_PROGRESS
# CREATE_IN_PROGRESS

#puts "Status is #{setecstack.status}"
puts "pulling ip address of stack"
stackip = setecstack.outputs[2].value
while stackip.nil? do
  puts "no ip address yet, waiting"
  #break if !stackip.nil?
  sleep 3
  stackip = setecstack.outputs[2].value
end

puts "ip address of stack is #{stackip}"

# this is how you pull the ip address from a stack.  this is specific to the template i'm currently using. 
#puts "ip is #{setecstack.outputs[2].value}"

# this will provide a list of events for the stack
setecstack.events.each do |event|
    puts "#{event.timestamp}: #{event.resource_status}"
end
#puts setecstack.methods.sort


# this should delete the stack
# puts "Deleting stack" 
# setecstack.delete

# setecstack.outputs.each do |outputs|
#   puts outputs.key
#   puts outputs.value
# end

# FROM TFM http://docs.amazonwebservices.com/AWSRubySDK/latest/frames.html
## enumerating all stack objects
#cfm.stacks.each do |stack|
#  # ...
#end
#
## enumerating stack summaries (hashes)
#cfm.stack_summaries.each do |stack_summary|
#  # ...
#end
#
## filtering stack summaries by status
#cfm.stack_summaries.with_status(:create_failed).each do |summary|
#  puts summary.to_yaml
#end
