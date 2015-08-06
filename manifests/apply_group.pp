# == Define: netdev_stdlib_junos::apply_group
#
define netdev_stdlib_junos::apply_group(
  $template_path,
  $ensure            = 'present',
  $active            = 'true',
  $config_file_owner = undef,
  $config_file_mode  = '0664'
) {

  $path = "/var/tmp/${title}"
  $extension = split($template_path, '\.')
  if $extension[1] != 'erb' {
    $format = $extension[1]
  }
  else {
    $format = 'xml'
  }

  file{ $path:
    ensure  => $ensure,
    path    => $path,
    content => template($template_path),
    owner   => $config_file_owner,
    mode    => $config_file_mode,
    notify  => netdev_group[ $title ],
    backup  => false
  }

  netdev_group{ $title:
    ensure => $ensure,
    path   => $path,
    format => $format,
    active => $active,
  }

}
