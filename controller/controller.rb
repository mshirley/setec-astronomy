require 'rubygems' # 1.8.7 love
require 'sinatra' #web frontend

def cleanup()
  `rm -rf /tmp/rdeploy_*`
end

def vpn()
  `openvpn --genkey --secret /etc/openvpn/static.key`
end

get '/' do
  "nothing to see here"
end

get '/vpn' do
  vpn()
  send_file '/etc/openvpn/static.key', :filename => 'hostname-static.key'
end

get '/cleanup' do
  cleanup()
end

#EM.run do
#  notifier = INotify::Notifier.new
#  notifier.watch("./test/", :moved_to, :create) do |newfile|
#    puts "New file #{newfile.name} found, processing..."
#    process_incoming(newfile.name)
#  end
#
#  EM.watch notifier.to_io do
#  #  notifier.process
#  end
#end
