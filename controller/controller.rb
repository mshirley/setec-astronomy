require 'rubygems' # 1.8.7 love
require 'sinatra' #web frontend

def cleanup()
  `rm -rf /tmp/rdeploy_*`
end

def vpn()
  `openvpn --genkey --secret /etc/openvpn/static.key`
end

def all_services(action)
  case action
  when "start"
    vpn_service("start")
    ejabberd_service("start")
    bind_service("start")
    squid_service("start")
  when "stop"
    vpn_service("stop")
    ejabberd_service("stop")
    bind_service("stop")
    squid_service("stop")
  when "restart"
    vpn_service("restart")
    ejabberd_service("stop")
    ejabberd_service("start")
    bind_service("restart")
    squid_service("restart")
  else
    "bad action"
  end
end

def vpn_service(action)
  case action
  when "start"
    `/etc/init.d/openvpn start`
    "started"
  when "stop"
    `/etc/init.d/openvpn stop`
    "stopped"
  when "restart"
    `/etc/init.d/openvpn restart`
    "restarted"
  when "data"
    "<a href='/vpn/get-ca'>ca.crt</a><p>
    <a href='/vpn/get-client-crt'>client.crt</a><p>
    <a href='/vpn/get-client-key'>client.key</a><p>"
  when "status"
    vpnout = `/etc/init.d/openvpn status`
    if vpnout.include?("written")
      vpnstatus = "running"
    else
      vpnstatus = "not running"
    end
    return vpnstatus
  else
    "bad action"
  end
end

def ejabberd_service(action)
  case action
  when "start"
    `/opt/ejabberd-2.1.11/bin/ejabberctl start &`
    "started"
  when "stop"
    `/opt/ejabberd-2.1.11/bin/ejabberctl stop &`
    "stopped"
  when "restart"
    "restart for ejabberd not supported, stop then start"
  when "status"
    ejabberdout = `/opt/ejabberd-2.1.11/bin/ejabberctl status`
    if ejabberdout.include?("started")
      ejabberdstatus = "running"
    else
      ejabberdstatus = "not running"
    end     
  else
    "bad action"
  end
end

def bind_service(action)
  case action
  when "start"
    `/etc/init.d/named start`
    "started"
  when "stop"
    `/etc/init.d/named stop`
    "stopped"
  when "restart"
    `/etc/init.d/named restart`
    "restarted"
  when "status"
    bindout = `/etc/init.d/named status`
    if bindout.include?("running")
      bindstatus = "running"
    else
      bindstatus = "not running"
    end
  else
    "bad action"
  end
end

def squid_service(action)
  case action
  when "start"
    `/etc/init.d/squid start`
    "started"
  when "stop"
    `/etc/init.d/squid stop`
    "stopped"
  when "restart"
    `/etc/init.d/squid restart`
    "restarted"
  when "status"
    squidout = `/etc/init.d/squid status`
    if squidout.include?("running")
      squidstatus = "running"
    else
      squidstatus = "not running"
    end
  else
    "bad action"
  end
end

get '/' do
  "nothing to see here"
end

get '/services' do
  "*NOTE* vpn service should be running before starting the other services<p>
  all services: <a href='/services/all/start'>start</a> -- <a href='/services/all/stop'>stop</a> -- <a href='/services/all/restart'>restart</a><p>
  vpn: status = #{vpn_service("status")} || <a href='/services/vpn/start'>start</a> -- <a href='/services/vpn/stop'>stop</a> -- <a href='/services/vpn/restart'>restart</a> -- <a href='/services/vpn/data'>get data</a><p>
  ejabberd: status = #{ejabberd_service("status")} || <a href='/services/ejabberd/start'>start</a> -- <a href='/services/ejabberd/stop'>stop</a> -- <a href='/services/ejabberd/restart'>restart</a><p>
  bind: status = #{bind_service("status")} || <a href='/services/bind/start'>start</a> -- <a href='/services/bind/stop'>stop</a> -- <a href='/services/bind/restart'>restart</a><p>
  squid: status = #{squid_service("status")} || <a href='/services/squid/start'>start</a> -- <a href='/services/squid/stop'>stop</a> -- <a href='/services/squid/restart'>restart</a>
  "
end

get '/services/:service/:action' do
  case params[:service]
  when "all"
    all_services(params[:action])
  when "vpn"
    vpn_service(params[:action])
  when "ejabberd"
    ejabberd_service(params[:action])
  when "bind"
    bind_service(params[:action])
  when "squid"
    squid_service(params[:action])
  else
    "service request failed"
  end
    
end


get '/services/vpn/data' do
 # send_file '/etc/openvpn/static.key', :filename => 'hostname-static.key'
 # send_file '/tmp/easy-rsa-new/keys/ca.crt'
 # send_file '/tmp/easy-rsa-new/keys/client1.crt'
 # send_file '/tmp/easy-rsa-new/keys/client1.key'
  "<a href='/vpn/get-ca'>ca.crt</a>
  <p>
  <a href='/vpn/get-client-crt'>client.crt</a>
  <p>
  <a href='/vpn/get-client-key'>client.key</a>
  <p>
  "
end

get '/vpn/get-ca' do
  send_file '/tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/ca.crt', :filename => 'ca.crt'
end

get '/vpn/get-client-crt' do
  send_file '/tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/client1.crt', :filename => 'client1.crt'
end

get '/vpn/get-client-key' do
  send_file '/tmp/setec-astronomy/conf/openvpn/easy-rsa-new/keys/client1.key', :filename => 'client1.key'
end


get '/cleanup' do
  cleanup()
end

get '/die' do
  pid = `ps ax | grep controller.rb | grep -v grep | cut -d" " -f 2`
  `kill #{pid}`
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
