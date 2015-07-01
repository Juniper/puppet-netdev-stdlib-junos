$policy = {
	    'p1' => {
			'events'       => [ 'TEST' ],
                        'action'       => 'then',
			'event-script' => 'hello.slax'
	  	    }
	  }
$event_script = [ 'hello.slax' ]
			
file { '/var/db/scripts/event/hello.slax':
  mode => 0644,
  source => "puppet:///modules/netdev_stdlib_junos/junoscripts/event/hello.slax",
}

netdev_stdlib_junos::apply_group{ "event_options_group":
  template_path => "netdev_stdlib_junos/event-options.xml.erb",
  active        => true,
  ensure        => present,
}

