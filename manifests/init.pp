type PublisherConfiguration = Struct[
  {
    'repository_name' => String,
    'repository_user' => String,
    'stratum0_url' => String,
    'gateway_url' => String,
    'certificate' => String,
    'public_key' => String,
    'api_key' => String,
    'server_conf' => Optional[Array[Tuple[String, String]]]
  }
]

class cvmfs_publisher (
  Hash[String, PublisherConfiguration] $repositories,
) {
  ensure_package( 'cvmfs-repo', {     
      ensure   => 'installed',
      provider => 'rpm',
      name     => 'cvmfs-release-3-2.noarch',
      source   => 'https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-3-2.noarch.rpm',
    }
  )
  ensure_package( 'cvmfs', {
      ensure  => 'installed',
      require => [Package['cvmfs-repo']],
    }
  )
  ensure_resource( 'file', '/cvmfs', { ensure => directory, seltype => 'root_t' } )

  package { 'cvmfs-server':
    ensure  => 'installed',
    require => [Package['cvmfs']],
  }

  file { '/etc/cvmfs/keys':
    ensure  => directory,
    seltype => 'root_t',
  }

  ensure_resources(cvmfs_publisher::repository, $repositories)
}

define cvmfs_publisher::repository (
  String $repository_name,
  String $repository_user,
  String $stratum0_url,
  String $gateway_url,
  String $certificate,
  String $public_key,
  String $api_key,
  Optional[Array[Tuple[String, String]]] $server_conf = undef,
) {
  file { "/etc/cvmfs/keys/${repository_name}.crt":
    content => $certificate,
    mode    => '0444',
    owner   => $repository_user,
    group   => 'root',
  }
  file { "/etc/cvmfs/keys/${repository_name}.pub":
    content => $public_key,
    mode    => '0444',
    owner   => $repository_user,
    group   => 'root',
  }
  file { "/etc/cvmfs/keys/${repository_name}.gw":
    content => "${api_key}\n",
    mode    => '0400',
    owner   => $repository_user,
    group   => 'root',
  }
  exec { "mkfs_${repository_name}":
    command => "cvmfs_server mkfs -w ${stratum0_url} -u gw,/srv/cvmfs/${repository_name}/data/txn,${gateway_url} -k /etc/cvmfs/keys -o ${repository_user} -a shake128 ${repository_name}",
    require => [File["/etc/cvmfs/keys/${repository_name}.crt"], File["/etc/cvmfs/keys/${repository_name}.pub"], File["/etc/cvmfs/keys/${repository_name}.gw"]],
    path    => ['/usr/bin'],
    returns => [0],
    # create only if it does not already exist
    creates => ["/var/spool/cvmfs/${repository_name}"]
  }

  if ($server_conf) {
    $server_conf.each | Integer $index, Tuple[String, String] $kv | {
      file_line { "server.conf_${repository_name}_${kv[0]}":
        ensure  => 'present',
        path    => "/etc/cvmfs/repositories.d/${repository_name}/server.conf",
        line    => "${kv[0]}=${kv[1]}",
        match   => "^${kv[0]}=.*",
        require => Exec["mkfs_${repository_name}"]
      }
    }
  }
}
