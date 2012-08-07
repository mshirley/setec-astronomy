. ~/.ec2/sourceme
unset http_proxy 
unset HTTP_PROXY 
unset https_proxy 
unset HTTPS_PROXY 
unset ftp_proxy 
unset FTP_PROXY 
# setting key for doing scp
if [ -f $SSHKEY ]
then
  ssh-add $SSHKEY
else
  echo "mounting tcvolume $TCVOLUME"
  truecrypt --mount-options=ro $TCVOLUME /media/truecrypt1/
  ssh-add $SSHKEY
fi
ruby usercontrol.rb
