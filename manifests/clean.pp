# Create a cron job to clean your ElasticSearch indices on a regular basis
# using elasticsearch-curator.
#
# @param ensure [String] Whether to add, or delete, the index job.
#   Allowed Values: *present*, absent
#
# @param host [Hostname] The host upon which to operate. Ideally, you will
#   position this job locally but it will work over thet network just as well
#   provided your access controls allow it.
#
# @param keep_days [Integer] The number of days to keep within ElasticSearch.
#   Mutually exclusive with keep_hours and keep_space.
#
# @param keep_hours [Integer] The number of hours to keep within ElasticSearch.
#   Mutually exclusive with keep_days and keep_space.
#
# @param keep_space [Integer] The number of Gigabytes to keep within
#   ElasticSearch. This applies to each index individually, not the entire
#   storage space used by the prefix. Mutually exclusive with keep_days and
#   keep_hours.
#
# @param prefix [String] The prefix to use to identify relevant logs.  This is
#   a match so 'foo' will match 'foo', 'foosball', and 'foot'.
#
# @param port [Port] The port to which to connect. Since this is SIMP tailored,
#   we use our local unencrypted default.
#
# @param separator [Char] The index separator.
#
# @param es_timeout [Integer] The timeout, in seconds, to wait for a response
#   from Elasticsearch.
#
# @param log_file [Absolute Path] The log file to which to print curator
#   output.
#
# @param cron_hour [Integer or '*'] The hour at which to run the index cleanup.
#
# @param cron_minute [Integer or '*'] The minute at which to run the index
#   cleanup.
#
# @param cron_month [Integer or '*'] The month within which to run the index
#   cleanup.
#
# @param cron_monthday [Integer or '*'] The day of the month upon which to run
#   the index cleanup.
#
# @param cron_weekday [Integer or '*'] The day of the week upon which to run
#   the index cleanup.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
class simp_logstash::clean (
  $ensure = 'present',
  $host = '127.0.0.1',
  $keep_days = '356',
  $keep_hours = '',
  $keep_space = '',
  $prefix = 'logstash-',
  $port = '9199',
  $separator = '.',
  $es_timeout = '30',
  $log_file = '/var/log/logstash/curator_clean.log',
  $cron_hour = '1',
  $cron_minute = '15',
  $cron_month = '*',
  $cron_monthday = '*',
  $cron_weekday = '*'
) {
  validate_array_member($ensure,['present','absent'])

  if defined('$::simp_logstash::auto_clean') and getvar('::simp_logstash::auto_clean') {
    $_simp_ls_auto_clean = true
  }
  else {
    $_simp_ls_auto_clean = false
  }

  if ($ensure == 'present') and $_simp_ls_auto_clean {
    validate_string($prefix)
    validate_port($port)
    validate_string($separator)
    validate_integer($es_timeout)
    validate_absolute_path($log_file)
    if ($cron_hour != '*') { validate_integer($cron_hour) }
    if ($cron_minute != '*') { validate_integer($cron_minute) }
    if ($cron_month != '*') { validate_integer($cron_month) }
    if ($cron_monthday != '*') { validate_integer($cron_monthday) }
    if ($cron_weekday != '*') { validate_integer($cron_weekday) }

    if size(reject([$keep_days, $keep_hours, $keep_space],'^\s*$')) > 1 {
      fail('You may only specify one of $keep_days, $keep_hours, or $keep_space')
    }

    if !empty($keep_hours) {
      validate_integer($keep_hours)
      $_limit = "-T hours --older-than ${keep_hours}"
    }
    elsif ! empty($keep_days) {
      validate_integer($keep_days)
      $_limit = "-T days --older-than ${keep_days}"
    }
    elsif ! empty($keep_space) {
      validate_integer($keep_space)
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
