class base {
  package { ["unzip", "rubygems"]:
    ensure  => "present",
    require => Package["elff-release-5-3"],
  }

  package { "rubygem-stomp":
    ensure  => "present",
    require  => Package["rubygems"],
  }

  package { "elff-release-5-3":
    provider => "rpm",
    ensure   => "present",
    source   => "http://download.elff.bravenet.com/5/i386/elff-release-5-3.noarch.rpm",
    require => Package["epel-release-5-4"],
  }

  package { "epel-release-5-4":
    provider => "rpm",
    ensure   => "present",
    source   => "http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm",
  }

  package { "mcollective-common":
    provider => "rpm",
    ensure   => "present",
    source   => "http://www.puppetlabs.com/downloads/mcollective/mcollective-common-1.1.3-1.el5.noarch.rpm",
    require  => Package["rubygem-stomp"],
  }

  package { "mcollective":
    provider => "rpm",
    ensure   => "present",
    source   => "http://www.puppetlabs.com/downloads/mcollective/mcollective-1.1.3-1.el5.noarch.rpm",
    require  => Package["mcollective-common"],
  }

  file { "/etc/mcollective/server.cfg":
    ensure => "present",
    owner  => "root",
    mode   => "600",
    content => template("server.cfg.erb"),
    require => Package["mcollective"],
  }

  file { "/usr/libexec/mcollective/mcollective/agent/deploy.rb":
    ensure => "present",
    owner  => "root",
    mode   => "644",
    source  => "file://${files_dir}/deploy.rb",
    require => Package["mcollective"],
  }

  service { "mcollective":
    ensure  => "running",
    require => File["/etc/mcollective/server.cfg"],
  }

  service { "iptables":
    ensure => "stopped",
    status => "/usr/bin/test -f /var/lock/subsys/iptables",
  }
}
