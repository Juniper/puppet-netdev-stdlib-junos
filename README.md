# OVERVIEW

Netdev is a vendor-neutral network abstraction framework developed by 
Juniper Networks and contributed freely to the DevOps community

This module contains the Junos specific Provider code implementing
the Resource Types defined in [netdevops/netdev_stdlib](https://github.com/NetdevOps/puppet-netdev-stdlib)

# EXAMPLE USAGE

This module has been tested against Puppet agent 2.7.19 and 3.6.1.  Here is a short example of a static manifest for a Junos EX switch.  This example assumes that you've also installed the Puppet _stdlib_ module as this example uses the _keys_ function.

~~~~
node "myswitch1234.mycorp.com" {
     
  netdev_device { $hostname: }
    
  $vlans = {
    'Blue'    => { vlan_id => 100, description => "This is a Blue vlan" },
    'Green'   => { vlan_id => 101, description => "This is a Green vLAN" },
    'Purple'  => { vlan_id => 102, description => "This is a Puple vlan" },
    'Red'     => { vlan_id => 103, description => "This is a Red vlan" },
    'Yellow'  => { vlan_id => 104, description => "This is a Yellow vlan" }   
  }
    
  create_resources( netdev_vlan, $vlans )
    
  $access_ports = [
    'ge-0/0/0',
    'ge-0/0/1',
    'ge-0/0/2'
  ]
    
  $uplink_ports = [
    'xe-0/0/0',
    'xe-0/0/2'
  ]
      
  netdev_l2_interface { $access_ports:
    untagged_vlan => Blue
  }
          
  netdev_l2_interface { $uplink_ports:
    tagged_vlans => keys( $vlans )
  }

  # service variables passed in template file
  $services = [ [ 'ftp' ], [ 'ssh' ], [ 'telnet' ], [ 'netconf', 'ssh' ] ]

  netdev_stdlib_junos::apply_group{ "services_group":
    template_path => "netdev_stdlib_junos/services.set.erb",
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
~~~~
  
# DEPENDENCIES

  * Puppet >= 2.7.19
  * Ruby Gem netconf 0.2.5
  * Puppet module netdevops/netdev_stdlib version >= 1.0.0
  * Junos OS release and jpuppet image by platform:
    * QFX3500, QFX3600: 
      - JUNOS 12.3X50-D20.1
      - jpuppet-qfx-1.0R1.1
    * EX4200, EX4500, EX4550: 
      - JUNOS 12.3R2.5
      - jpuppet-ex-1.0R1.1 
    * MX240, MX480, MX960:
      - JUNOS 12.3R2.5
      - jpuppet-mx-1.0R1.1
    * MX5, MX10, MX40, MX80: 
      - JUNOS 12.3R2.5
      - jpuppet-mx80-1.0R1.1
    * QFX5100:
	  - JUNOS >= 14.2
	  - jpuppet-3.6.1_1.junos.i386.tgz
	* EX4300
      - JUNOS >= 14.2
      - jpuppet-3.6.1_1.junos.powerpc.tgz
	  
# INSTALLATION ON PUPPET-MASTER

  * gem install netconf
  * puppet module install juniper/netdev_stdlib_junos

# RESOURCE TYPES

See RESOURCE-STDLIB.md for documentation and usage examples

# CONTRIBUTORS

   * Jeremy Schulman, Juniper Networks
   * Ganesh Nalawade, Juniper Networks 
   
# LICENSES

   See LICENSE-JUNIPER
