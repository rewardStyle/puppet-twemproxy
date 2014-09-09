# = Class for Twemproxy installation
# TODO: Document the installation
# =Parameters
# [*version*]
#   The version to install. Default latest|master
# [*prefix*]
#   The install location. Defautl /usr/local
# [*debug_mode*]
#   Enable debug flags
# [*debug_opts*]
#   Debug options
# [*cflags*]
#   cflgs
# [*cflags_opts*]
#   cflags_opts
class twemproxy::install (
  $version        = $twemproxy::params::version,
  $prefix         = $twemproxy::params::prefix,
  $debug_mode     = $twemproxy::params::debug_mode,
  $debug_opts     = $twemproxy::params::debug_opts,
  $cflags         = $twemproxy::params::cflags,
  $cflags_opts    = $twemproxy::params::cflags_opts,
) inherits twemproxy::params {

  # Ensure /usr/local/src diretory exists
  if ! defined(File["${prefix}/src"]) {
    file { "${prefix}/src": ensure  => 'directory' }
  }
  $download_version = $version ? {
    'latest'   => 'master',
    'master'   => 'master',
    /(v)?(.*)/ => $2,
    default    => false,
  }

  if ($download_version == false) {
    fail("Version '$version' number not recognized")
  }

  $download_url = $version ? {
    /^(latest|master)$/ => "$twemproxy::params::download_path/master.tar.gz",
    default         => "$twemproxy::params::download_path/v$download_version.tar.gz"
  }

  $download_file = "twemproxy-$download_version"
  $download_archive = "$download_file.tar.gz"

  # Download sources from github
  exec { 'download_twemproxy_src':
    command     => "wget $download_url -O $download_archive",
    cwd         => "/usr/local/src",
    creates     => "$prefix/$download_archive",
  }

  # Untar the nutcracker file.
  exec { "tar xzf $download_archive":
    cwd         => "/usr/local/src",
    creates     => "/usr/local/src/$download_file",
    alias       => "untar-nutcracker-source",
    refreshonly => true,
    subscribe   => Exec["download_twemproxy_src"],
    user        => 'root',
    group       => 'root',
  }

  package { ['autoconf', 'libtool']:
    ensure => installed,
  }

  exec { 'autoreconf -fvi':
    cwd     => "/usr/local/src/$download_file",
    require => [Package['autoconf'], Exec['untar-nutcracker-source']],
    creates => "/usr/local/src/$download_file/configure",
  }

  # If debug and cflags are true, compile in debug mode
  # in other case compile it without debug.
  if ($debug == true or $cflags == true){
    exec { "/bin/ls | export CFLAGS=\"${cflags_opts}\"; ./configure --enable-debug=\"${debug_opts}\"":
      cwd     => "${prefix}/src/$download_file",
      require => [Exec['untar-nutcracker-source'], Exec['autoreconf -fvi']],
      creates => "${prefix}/src/$download_file/config.h",
      alias   => "configure-nutcracker",
      before  => Exec["make install"]
    }
  }
  else {

    notice ('Compiling Twemproxy without CFLAGS or DEBUG mode.')

    exec { "sh configure":
      cwd     => "${prefix}/src/$download_file",
      require => [Exec['untar-nutcracker-source'], Exec['autoreconf -fvi']],
      creates => "${prefix}/src/$download_file/config.h",
      alias   => "configure-nutcracker",
      before  => Exec["make install"]
    }
  }

  # Isn't if obvious? make install ;) 
  exec { "make && make install":
    cwd     => "/usr/local/src/$download_file",
    alias   => "make install",
    creates => [ "${prefix}/src/$download_file/src/nutcracker",
                 "${prefix}/sbin/nutcracker" ],
    require => Exec["configure-nutcracker"],
  }
  # TODO: Remove archive?
}
