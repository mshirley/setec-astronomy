# ejabberd.conf
exec { "wget https://s3.amazonaws.com/setec-astronomy-s3/src/setec-astronomy/conf/ejabberd/ejabberd.cfg":
  cwd     => "/etc/ejabberd/",
  creates => "/etc/jabberd/ejabberd.cfg",
  path    => ["/usr/bin", "/usr/sbin"]
}
