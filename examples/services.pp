$services = [ [ 'ftp' ], [ 'ssh' ], [ 'telnet' ], [ 'netconf', 'ssh' ] ]

netdev_stdlib_junos::apply_group{ "services_group":
  template_path => "netdev_stdlib_junos/services.set.erb",
  active        => true,
  ensure        => present,

}

