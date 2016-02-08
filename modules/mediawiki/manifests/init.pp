# == Class: mediawiki
#
# Full description of class mediawiki here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'mediawiki':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class mediawiki {

  $wikimetanamespace = hiera('mediawiki::wikimetanamespace')
  $wikisitename = hiera('mediawiki::wikisitename')
  $wikiserver = hiera('mediawiki::wikiserver')
  $wikidbserver = hiera('mediawiki::wikidbserver')
  $wikidbname = hiera('mediawiki::wikidbname')
  $wikidbuser = hiera('mediawiki::wikidbuser')
  $wikidbpassword = hiera('mediawiki::wikidbpassword')
  $wikiupgradekey = hiera('mediawiki::wikiupgradekey')

  $phpmysql = $osfamily ? {
    'redhat' => 'php-mysql',
    'debian' => 'php5-mysql',
    default => 'php-mysql',
  }

  package { $phpmysql :
    ensure => 'present',
  }

  if $osfamily == 'redhat' {
    package { 'php-xml' :
      ensure => 'present',
    }
  }

  class { '::apache' :
    docroot => '/var/www/html',
    mpm_module => 'prefork',
    subscribe => Package[$phpmysql],
  }

  class { '::apache::mod::php' : }

  vcsrepo { '/var/www/html' :
    ensure => 'present',
    provider => 'git',
    source => "https://github.com/wikimedia/mediawiki.git",
    revision => 'REL1_23',
  }

  file { '/var/www/html/index.html' :
    ensure => 'absent',
  }

  File['/var/www/html/index.html'] -> Vcsrepo['/var/www/html']

  class { '::mysql::server' :
    root_password => 'training',
  }

  class { '::firewall' : }

  firewall { '000 allow http access' :
    port => '80',
    proto => 'tcp',
    action => 'accept',
  }

  file { 'LocalSettings.php' :
    path => '/var/www/html/LocalSettings.php',
    ensure => 'file',
    content => template('mediawiki/LocalSettings.erb'),
  }

}
