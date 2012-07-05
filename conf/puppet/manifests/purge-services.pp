# packages to purge
$basepkgs = [ "tor", "ejabberd", "openvpn", "bind9" ]
package { $basepkgs :
  ensure => "purged",
  require => Exec["service_cleanup"]
}

# stop and disable
service { [ "tor", "ejabberd", "openvpn", "bind9" ] :
  ensure => "stopped",
  enable => "false"
}

# cleanup misc files
exec { "service_cleanup":
  command => "rm /tmp/ejabberd.cfg",
  path    => ["/bin"]
}

