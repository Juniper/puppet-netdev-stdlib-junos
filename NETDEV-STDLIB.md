# USING NETDEV STDLIB

All netdev resources types include the following two properties:

  * ensure => [ present* | absent ]
    * present: configuration will be present
    * absent: configuration will not be present
  * active => [ true* | false ]
    * true: configuration will be present and active
    * false: configuration will be present but not active

## netdev_device

There must be a single _netdev_device_ resource present in the catalog.  This resource is used to abstract the 
configuration controls of the network device.  All other netdev resources will have an implicit auto-require,
which causes the netdev_device resource to be evaluated prior to any other netdev resource-type.  You can
choose any name for the netdev_device resource as there is no naming dependency in the code.  

The following example uses the Facter variable __$hostname__:

````puppet
node "switch1234.mycorp.com" {

   netdev_device { $hostname: }
   
}

````

## netdev_interface

This resource models the properties of the physical interfaces:

  * admin => [ up* | down ]
  * description => _string_
  * mtu => _number_
  * speed => [ auto* | 100m | 1g | 10g ]
  * duplex => [ auto* | half | full ]

````puppet
node "switch1234.mycorp.com" {
    
  netdev_device { $hostname: }
       
  netdev_interface { "ge-0/0/0":
    admin => down,
    mtu => 2000
  }
  
}       
````  

## netdev_vlan

This resource models the properties of a VLAN.  VLANs are assigned to interfaces using the *netdev_l2_interface* resource.

  * vlan_id => _number_
  * description => _string_
  
````puppet
node "switch1234.mycorp.com" {
    
  netdev_device { $hostname: }
       
  netdev_vlan { "Blue":
     vlan_id => 100,
     description => "This is my Blue vlan."
  }
  
}       
````

## netdev_l2_interface

This resource models the assignment of VLANs to layer-2 switch ports:

  * description => _string_
  * untagged_vlan => _vlan-name_
  * tagged_vlans => _arrayof vlan-names_
  * vlan_tagging => [ enable | disable ]

````puppet  
node "switch1234.mycorp.com" {
    
  netdev_device { $hostname: }
       
  # access port, packets without VLAN tag

  netdev_l2_interface { 'ge-0/0/0':
     untagged_vlan => Red
  }
  
  # trunk port, multiple VLAN taggs
  
  netdev_l2_interface { 'xe-0/0/0':
     tagged_vlans => [ Red, Green, Blue ]
  }
  
  # trunk port, multiple VLAN tags +
  # untagged packets go to 'native VLAN'
  
  netdev_l2_interface { 'xe-0/0/2':
     tagged_vlans => [ Red, Green, Blue ],
     untagged_vlan => Yellow
  }
  
}
````

## netdev_lag

This resource models the properties of a Link Aggregation Group (LAG):

  * links => _arrayof interface names_
  * minimum_links => _number_
  * lacp => [ disable* | active | passive ]
  
````puppet
node "switch1234.mycorp.com" {
    
  netdev_device { $hostname: }
       
  $ae0_ports = [ 'ge-0/0/0', 'ge-1/0/0', 'ge-0/0/2', 'ge-1/0/2' ]

  # we don't want any VLANs configs on the LAG physical ports,
  # so ensure there is no config
  
  netdev_l2_interface { $ae0_ports: ensure => absent }

  # define the LAG port, and then assign VLANs 
  
  netdev_lag { 'ae0':
     links => $ae0_ports,
     lacp => active,
     minimum_links => 2
  }
  
  netdev_l2_interface { 'ae0':
     tagged_vlans => [ Red, Green, Blue ]
  }
  
}

````

## netdev_stdlib_junos::apply_group

This defined type apply_group used for Generic configuration using
puppet template resource:

  * template_path => _Template file path used to generate JUNOS configuration on device_
  * active => [ true | false ]
  * ensure => [ present | absent ]

````puppet
node "switch1234.mycorp.com" {

  netdev_device { $hostname: }

  # service variables passed in template file
  $services = [ [ 'ftp' ], [ 'ssh' ], [ 'telnet' ], [ 'netconf', 'ssh' ] ]

  netdev_stdlib_junos::apply_group{ "services_group":
    template_path => "netdev_stdlib_junos/services.set.erb",
    active        => true,
    ensure        => present,
  }

  # Interface variable passed in 'interface.set.erb' template file
  $interfaces = { 'ge-1/2/0' => {'unit' => 0, 'description' => 'to-A', 'family' => 'inet', 'address' => '10.10.10.1/30' },
                'ge-1/1/1' => {'unit' => 0, 'description' => 'to-B', 'family' => 'inet', 'address' => '10.10.10.5/30' },
                'ge-1/1/0' => {'unit' => 0, 'description' => 'to-C', 'family' => 'inet', 'address' => '10.10.10.9/30' },
                'ge-1/2/1' => {'unit' => 0, 'description' => 'to-D', 'family' => 'inet', 'address' => '10.21.7.1/30' }
  }

  netdev_stdlib_junos::apply_group{ "interface_group":
    template_path => "netdev_stdlib_junos/interface.set.erb",
    active        => true,
    ensure        => present,
  }

  # Syslog variable passed in 'syslog.text.erb' template file
  $syslog_names = {
  'messages' =>             [ { 'facility' => 'any', 'level' => 'critical' }, { 'facility' => 'authorization', 'level' => 'info' } ] ,
  'interactive-commands' => [ { 'facility' => 'interactive-commands', 'level' => 'error'} ]
  }

  netdev_stdlib_junos::apply_group{ "syslog_group":
    template_path => "netdev_stdlib_junos/syslog.text.erb",
    active        => true,
    ensure        => present,
  }

  
  # Event-policy variable passed in 'event-options.xml.erb' template file
  $policy = {
            'p1' => {
                        'events'       => [ 'TEST' ],
                        'action'       => 'then',
                        'event-script' => 'hello.slax'
                    }
          }
  $event_script = [ 'hello.slax' ]

  # file resource copies the file hello.slax from master to agent
  file { '/var/db/scripts/event/hello.slax':
    mode => 0644,
    source => "puppet:///modules/netdev_stdlib_junos/junoscripts/event/hello.slax",
  }
  
  # Configure event policy and event script
  netdev_stdlib_junos::apply_group{ "event_options_group":
    template_path => "netdev_stdlib_junos/event-options.xml.erb",
    active        => true,
    ensure        => present,
  }

}

````

