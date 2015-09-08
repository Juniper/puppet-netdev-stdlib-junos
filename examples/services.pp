$services = [ [ 'ftp' ], [ 'ssh' ], [ 'telnet' ], [ 'netconf', 'ssh' ] ]

netdev_stdlib_junos::apply_group{ 'services_group':
  ensure        => present,
  template_path => 'netdev_stdlib_junos/services.set.erb',
  active        => true,
}

