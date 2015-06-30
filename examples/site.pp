node 'myswitch1234.mycorp.com' {

  netdev_device { $hostname:}
  import 'syslogs.pp'
  import 'interface.pp'
  import 'services.pp'
  import 'event-options.pp'
}


