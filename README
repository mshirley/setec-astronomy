Setec Astronomy
===============

Requirements
------------
### Ruby
Use rvm to install the latest version of ruby or just use 1.8.7 which is fairly well adopted.  


### AWS API Tools
### AWS Account with Credentials file
### Source
Please download the latest source at [source] 

Installation
------------
### Source
Unzip [source] to any directory.  This is the directory that contains all the scripts and configuration files.

### AWS Credentials
Create a directory that will contain private information.  This information will authenticate to aws.

This assumes [source] was downloaded and extracted to /opt/setec-astronomy

  mkdir ~/.ec2
  chmod 600 ~/.ec2
  cp /opt/setec-astronomy/aws/privatedir/* ~/.ec2/

Modify ~/.ec2/sourceme to set environmental variables.

Modify ~/.ec2/creds to set your aws account credentials.  Use the following format for the ~/.ec2/creds file.

AWSAccessKeyId=<insert your access key>
AWSSecretKey=<insert your secret key>

Ensure permissions are set properly on the private directory
  
  chmod -R 600 ~/.ec2


Execution
---------

From a command line, assuming [source] was downloaded and extracted to /opt/setec-astronomy

  cd /opt/setec-astronomy/controller/
  sh controller.sh

This will set some environmental variables based on the ~/.ec2/sourceme file you modified earlier.

Follow the directions on the screen.

If you have any issues ensure you have ruby and all the neccesary gems installed.  Api errors from aws usually indicate bad certs/private keys/access keys/secret keys.


[source]: https://github.com/mshirley/setec-astronomy
