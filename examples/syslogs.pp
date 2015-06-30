$syslog_names = {
  'messages' =>             [ { 'facility' => 'any', 'level' => 'critical' }, { 'facility' => 'authorization', 'level' => 'info' } ] ,
  'interactive-commands' => [ { 'facility' => 'interactive-commands', 'level' => 'error'} ]       
}
          
netdev_stdlib_junos::apply_group{ "syslog_group":
  template_path => "netdev_stdlib_junos/syslog.text.erb",
  active        => true,
  ensure        => present,

}
