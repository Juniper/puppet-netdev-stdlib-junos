node 'myswitch1234.mycorp.com' {

  domain_name { $hostname:}
  import 'syslogs.pp'
  import 'interface.pp'
  import 'services.pp'
  import 'event-options.pp'
}


