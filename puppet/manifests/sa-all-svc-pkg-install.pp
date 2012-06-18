class sabase {
  $basepkgs = [ "vim", "openssh-server", "tor", "ejabberd", "openvpn", "bind9" ] 
  package { $basepkgs : ensure => "installed" } 
}
