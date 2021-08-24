class sc_autoupdates(
  $autoupdate = 'yes',
  $weekday = undef,
  $hour = 9,
  $minute = undef,
  $run_scripts = [],
) {


# write auto update status to file
case $autoupdate {
  /(?i:yes)/: { $autoupdate_status = $autoupdate ; $cron_ensure = 'present'  }
  default: { $autoupdate_status = 'no' ;  $cron_ensure = 'absent' }
}
file{'/.autoupdate':
  content => $autoupdate_status,
}

# calculate weekday if not overwritten in hiera
if $weekday != undef {
  $cron_weekday = $weekday
  } else {
  case $hostname {
    # name conatins stage etc.
    /stage|test|dev/: { $cron_weekday = 'Monday' }
    # rname ends with a number
    /(\d)$/: {
      $number = Integer("${1}")
      if $number % 2 == 0 {
         # even number run on Wed
        $cron_weekday = 'Wednesday'
      } else {
        # odd numbers run on Thu
        $cron_weekday = 'Thursday'
      }
    }
    # aöll other servers
    default:   { $cron_weekday = 'Thursday' }
  }
}

$cron_runscripts = join($run_scripts, " ")

if $minute = undef {
  $minute = fqdn_rand(60, 'sc_autoupdate_cron_minute')
}

cron{'sc_autoupdate':
  ensure  => $cron_ensure,
  command => "/opt/repos/sc-lib/update/wrapper.sh $cron_runscripts >>/var/log/updates.log 2>&1",
  hour    => $hour,
  minute  => $minute,
  user    => 'root',
  weekday => $cron_weekday,
}

}
