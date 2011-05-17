import "base.pp"

class admin inherits base {
  package { ["java-1.6.0-openjdk-devel", "git", "ant", "ruby-devel", "make", "gcc", "libxml2-devel", "libxslt-devel"]:
    ensure => "present"
  }

  package { "bundler":
    provider => gem,
  }

  package { "tanukiwrapper-3.2.3-1jpp":
    provider => "rpm",
    ensure   => "present",
    source   => "http://www.puppetlabs.com/downloads/mcollective/tanukiwrapper-3.2.3-1jpp.i386.rpm",
  }

  package { "activemq-5.4.0-2":
    provider => "rpm",
    ensure   => "present",
    source   => "http://www.puppetlabs.com/downloads/mcollective/activemq-5.4.0-2.el5.noarch.rpm",
    require  => Package["tanukiwrapper-3.2.3-1jpp"],
  }

  package { "activemq-info-provider-5.4.0-2":
    provider => "rpm",
    ensure   => "present",
    source   => "http://www.puppetlabs.com/downloads/mcollective/activemq-info-provider-5.4.0-2.el5.noarch.rpm",
    require  => Package["activemq-5.4.0-2"],
  }

  package { "go-server":
    provider => "rpm",
    ensure   => "present",
    source   => "http://s3-ap-southeast-1.amazonaws.com/company-news-bootstrap/go-server-2.1.0-11943.noarch.rpm",
    require  => Package["java-1.6.0-openjdk-devel"],
  }

  package { "go-agent":
    provider => "rpm",
    ensure   => "present",
    source   => "http://s3-ap-southeast-1.amazonaws.com/company-news-bootstrap/go-agent-2.1.0-11943.noarch.rpm",
    require  => Package["java-1.6.0-openjdk-devel"],
  }

  file { "/etc/go/cruise-config.xml":
    ensure  => "present",
    owner   => "go",
    group   => "go",
    mode    => 664,
    source  => "file://${files_dir}/cruise-config.xml",
    require => Package["go-server"],
  }

  file { "/etc/activemq/activemq.xml":
    ensure  => "present",
    source  => "file://${files_dir}/activemq.xml",
    owner   => "root",
    group   => "root",
    require => Package["activemq-info-provider-5.4.0-2"],
  }

  service { "activemq":
    ensure  => "running",
    require => File["/etc/activemq/activemq.xml"],
  }

  service { "go-server":
    ensure  => "running",
    require => Package["go-server"],
  }

  service { "go-agent":
    ensure  => "running",
    require => Package["go-agent"],
  }
}

include admin
