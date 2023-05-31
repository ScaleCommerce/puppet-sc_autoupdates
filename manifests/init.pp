class sc_autoupdates(
  $autoupdate = 'enable',
  $weekday = undef,
  $hour = 9,
  $minute = undef,
  $run_scripts = [],
) {

# write auto update status to file
case $autoupdate {
  /(?i:enable)/: { $autoupdate_status = $autoupdate ; $cron_ensure = 'present'  }
  default: { $autoupdate_status = 'disable' ;  $cron_ensure = 'absent' }
}
file{'/.autoupdate':
  content => $autoupdate_status,
}

if $facts['os']['distro']['codename'] == 'bionic' or $facts['os']['distro']['codename'] == 'focal' {
  # calculate weekday if not set in hiera
  if $weekday != undef {
    $cron_weekday = $weekday
    } else {
    case $hostname {
      # name conatins stage etc.
      /stage|test|dev/: {
        $cron_weekday = 'Monday'
        $cron_hour = 8
        $update_enable = 1
        }
      # rname ends with a number
      /(\d)$/: {
        $number = Integer("${1}")
        if $number % 2 == 0 {
          # even number run on Thu
          $cron_weekday = 'Thursday'
          $update_enable = 1
        } else {
          # odd numbers run on Wed
          $cron_weekday = 'Tuesday'
          $update_enable = 1
        }
      }
      # all other servers
      default:   {
        $cron_weekday = 'Thursday'
        $update_enable = 1
      }
    }
  }

  $cron_runscripts = join($run_scripts, ' ')

  if $minute == undef {
    $cron_minute = fqdn_rand(60, 'sc_autoupdate_cron_minute')
  } else {
    $cron_minute = $minute
  }
  if $cron_hour == undef {
    $cron_hour = $hour
  }
}



if $update_enable == 1 {
  cron{'sc_autoupdate':
    ensure  => $cron_ensure,
    command => "sudo -u root /opt/repos/sc-lib/update/wrapper.sh ${cron_runscripts} >> /var/log/updates.log 2>&1",
    hour    => $cron_hour,
    minute  => $cron_minute,
    user    => 'root',
    weekday => $cron_weekday,
  }
}

}
