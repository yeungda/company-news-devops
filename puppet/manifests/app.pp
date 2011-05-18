import "base.pp"

class app inherits base {

  $prevayler_path = '/var/db/pravaylor'

  package { "tomcat6":
    ensure   => "present",
  }

  file { '/var/db/pravaylor':
    ensure => directory,
    owner => 'tomcat',
    group => 'tomcat',
    require => Package['tomcat6'],
  }

  file { '/etc/tomcat6/tomcat6.conf':
    content => template('tomcat6.conf.erb'),
    owner => "tomcat",
    group => "tomcat",
    require => Package['tomcat6'],
#    notify => Service['tomcat6']
  }

  service { "tomcat6":
    ensure  => "running",
    require => [Package['tomcat6'], File['/var/db/pravaylor'], File['/etc/tomcat6/tomcat6.conf']],
  }
 
}

include app
