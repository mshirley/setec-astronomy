$s3_base_url = "https://s3.amazonaws.com/setec-astronomy-s3/src/setec-astronomy"

# Package install
$basepkgs = [ "vim", "openssh-server", "tor", "ejabberd", "openvpn", "bind9" ] 
package { $basepkgs : ensure => "installed" } 

# stop and disable 
service { [ "tor", "ejabberd", "openvpn", "bind9" ] : 
  ensure => "stopped",
  enable => "false",
  require => Package[$basepkgs]
}

# download and install ejabberd.cfg
exec { "dl_ejabberd_cfg":
  command => "wget $s3_base_url/conf/ejabberd/ejabberd.cfg -O /tmp/ejabberd.cfg",
  cwd     => "/tmp/",
  creates => "/tmp/ejabberd.cfg",
  path    => ["/usr/bin", "/usr/sbin"],
  require => Package["ejabberd"]
}

file { "/etc/ejabberd/ejabberd.cfg":
  source => "/tmp/ejabberd.cfg",
  require => Exec["dl_ejabberd_cfg"]
}

