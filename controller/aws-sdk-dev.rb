require 'rubygems' 
require 'aws-sdk'

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

awsaccesskey, awssecretkey = readcreds(credfile)

cfm = AWS::CloudFormation.new( :access_key_id => awsaccesskey, :secret_access_key => awssecretkey)

puts cfm.methods.sort

setecstack = cfm.stacks['setec-astronomy']

puts setecstack.methods.sort

# this is what we would need to look at after creating a stack to determine when it is finished
# CREATE_COMPLETE
puts "Status is #{setecstack.status}"



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
