# Basic package install

$basepkgs = [ "vim", "openssh-server", "tor", "ejabberd", "openvpn", "bind9" ] 
package { $basepkgs : ensure => "installed" } 

service { "tor" : 
  ensure => "stopped",
  enable => "false"
}

service { "ejabberd" :
  ensure => "stopped",
  enable => "false"
}

service { "openvpn" :
  ensure => "stopped",
  enable => "false"
}

service { "bind9" :
  ensure => "stopped",
  enable => "false"
}

