# == Parameters
# [*version*]
#   Can be latest, master or the release version tag on github
class twemproxy::params {
  $version = 'master'
  $download_path = 'https://github.com/twitter/twemproxy/archive'

  $prefix = '/usr/local'

  $debug_mode = true
  $debug_opts = 'full'

  $cflags = true
  $cflags_opts = 'ggdb3 -O0'
}
