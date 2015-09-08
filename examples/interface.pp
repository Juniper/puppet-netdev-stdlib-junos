$interfaces = { 'ge-1/2/0' => {
                                'unit' => 0,
                                'description' => 'to-A',
                                'family' => 'inet',
                                'address' => '10.10.10.1/30'
                              },
                'ge-1/1/1' => {
                                'unit' => 0,
                                'description' => 'to-B',
                                'family' => 'inet',
                                'address' => '10.10.10.5/30'
                              },
                'ge-1/1/0' => {
                                'unit' => 0,
                                'description' => 'to-C',
                                'family' => 'inet',
                                'address' => '10.10.10.9/30'
                              },
                'ge-1/2/1' => {
                                'unit' => 0,
                                'description' => 'to-D',
                                'family' => 'inet',
                                'address' => '10.21.7.1/30'
                              }
}

netdev_stdlib_junos::apply_group{ 'interface_group':
  ensure        => present,
  template_path => 'netdev_stdlib_junos/interface.set.erb',
  active        => true,
}
