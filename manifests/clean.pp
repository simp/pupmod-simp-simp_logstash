# Create a cron job to clean your ElasticSearch indices on a regular basis
# using elasticsearch-curator.
#
# @param ensure Whether to add, or delete, the index job.
#   Allowed Values: *present*, absent
#
# @param host The host upon which to operate. Ideally, you will
#   position this job locally but it will work over thet network just as well
#   provided your access controls allow it.
#
# @param keep_days The number of days to keep within ElasticSearch.
#   Mutually exclusive with keep_hours and keep_space.
#
# @param keep_hours The number of hours to keep within ElasticSearch.
#   Mutually exclusive with keep_days and keep_space.
#
# @param keep_space The number of Gigabytes to keep within
#   ElasticSearch. This applies to each index individually, not the entire
#   storage space used by the prefix. Mutually exclusive with keep_days and
#   keep_hours.
#
# @param prefix The prefix to use to identify relevant logs.  This is
#   a match so 'foo' will match 'foo', 'foosball', and 'foot'.
#
# @param port The port to which to connect. Since this is SIMP tailored,
#   we use our local unencrypted default.
#
# @param separator The index separator.
#
# @param es_timeout The timeout, in seconds, to wait for a response
#   from Elasticsearch.
#
# @param log_file The log file to which to print curator
#   output.
#
# @param cron_hour The hour at which to run the index cleanup.
#
# @param cron_minute The minute at which to run the index
#   cleanup.
#
# @param cron_month The month within which to run the index
#   cleanup.
#
# @param cron_monthday The day of the month upon which to run
#   the index cleanup.
#
# @param cron_weekday  The day of the week upon which to run
#   the index cleanup.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_logstash::clean (
  Enum['present','absent']          $ensure         = 'present',
  Simplib::Host                     $host           = '127.0.0.1',
  Stdlib::Compat::Integer           $keep_days      = 356,
  Optional[Integer[0]]              $keep_hours     = undef,
  Optional[Integer[0]]              $keep_space     = undef,
  String                            $prefix         = 'logstash-',
  Simplib::Port                     $port           = 9199,
  String                            $separator      = '.',
  Integer[0]                        $es_timeout     = '30',
  Stdlib::Absolutepath              $log_file       = '/var/log/logstash/curator_clean.log',
  Variant[Enum['*'],Integer[0,23]]  $cron_hour      = '1',
  Variant[Enum['*'],Integer[0,59]]  $cron_minute    = '15',
  Variant[Enum['*'],Integer[1,12]]  $cron_month     = '*',
  Variant[Enum['*'],Integer[1,31]]  $cron_monthday  = '*',
  Variant[Enum['*'],Integer[0,7]]   $cron_weekday   = '*'
) {

  if defined('$::simp_logstash::auto_clean') and getvar('::simp_logstash::auto_clean') {
    $_simp_ls_auto_clean = true
  }
  else {
    $_simp_ls_auto_clean = false
  }

  if ($ensure == 'present') and $_simp_ls_auto_clean {

    if size(reject([$keep_days, $keep_hours, $keep_space],'^\s*$')) > 1 {
      fail('You may only specify one of $keep_days, $keep_hours, or $keep_space')
    }

    if ! nil($keep_hours) {
      $_limit = "-T hours --older-than ${keep_hours}"
    }
    elsif ! nil($keep_days) {
      $_limit = "-T days --older-than ${keep_days}"
    }
    elsif ! nil($keep_space) {
      $_limit = "--disk-space ${keep_space}"
    }
    else {
      fail('You must specify one of $keep_days, $keep_hours, or $keep_space')
    }

    cron { 'logstash_index_cleanup' :
      ensure   => $ensure,
      command  => "/usr/bin/curator --host ${host} --port ${port} -t ${es_timeout} delete -p '${prefix}' -s '${separator}' ${_limit} >> ${log_file} 2>&1",
      hour     => $cron_hour,
      minute   => $cron_minute,
      month    => $cron_month,
      monthday => $cron_monthday,
      weekday  => $cron_weekday,
      require  => Class['simp_logstash::curator']
    }
  }
  else {
    cron { 'logstash_index_cleanup' : ensure => 'absent' }
  }
}
