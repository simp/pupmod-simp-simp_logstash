# Sets up a cron job to optimize your ElasticSearch indices on a regular basis
# using elasticsearch-curator.
#
# @param ensure [String] Whether to add, or delete, the index job.
#   Allowed Values: *present*, absent
#
# @param host [Hostname] The host upon which to operate. Ideally, you will
#   position this job locally but it will work over thet network just as well
#   provided your access controls allow it.
#
# @param optimize_days [Integer] The number of days to keep within
#   ElasticSearch. Mutually exclusive with optimize_hours.
#
# @param optimize_hours [Integer] The number of hours to keep within
#   ElasticSearch. Mutually exclusive with optimize_days.
#
# @param prefix [String] The prefix to use to identify relevant logs. This is
#   a match so 'foo' will match 'foo', 'foosball', and 'foot'.
#
# @param port* [Port] The port to which to connect. Since this is SIMP
#   tailored, we use our local unencrypted default.
#
# @param separator [Char] The index separator.
#
# @param es_timeout [Integer] The timeout, in seconds, to wait for a response
#   from Elasticsearch.
#
# @param max_num_segments [Integer] Optimize segment count to $max_num_segments
#   per shard.
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
class simp_logstash::optimize (
  Enum['present','absent']          $ensure           = 'present',
  Simplib::Host                     $host             = '127.0.0.1',
  Optional[Integer[0]]              $optimize_days    = '2',
  Optional[Integer[0]]              $optimize_hours   = '',
  String                            $prefix           = 'logstash-',
  Simplib::Port                     $port             = '9199',
  String                            $separator        = '.',
  Integer[0]                        $es_timeout       = '21600',
  Integer[0]                        $max_num_segments = '2',
  Stdlib::Absolutepath              $log_file         = '/var/log/logstash/curator_optimize.log',
  Variant[Enum['*'],Integer[0,23]]  $cron_hour        = '3',
  Variant[Enum['*'],Integer[0,59]]  $cron_minute      = '15',
  Variant[Enum['*'],Integer[1,12]]  $cron_month       = '*',
  Variant[Enum['*'],Integer[1,31]]  $cron_monthday    = '*',
  Variant[Enum['*'],Integer[0,7]]   $cron_weekday     = '*'
) {

  if defined('$::simp_logstash::auto_optimize') and getvar('::simp_logstash::auto_optimize') {

    if size(reject([$optimize_days, $optimize_hours],'^\s*$')) > 1 {
      fail('You may only specify one of $optimize_days or $optimize_hours')
    }

    if !empty($optimize_hours) {
      $_limit = "-T hours --older-than ${optimize_hours}"
    }
    elsif !empty($optimize_days) {
      $_limit = "-T days --older-than ${optimize_days}"
    }
    else {
      fail('You must specify one of $optimize_days or $optimize_hours')
    }

    cron { 'logstash_index_optimize':
      ensure   => $ensure,
      command  => "/usr/bin/curator --host ${host} --port ${port} -t ${es_timeout} optimize -p '${prefix}' -s '${separator}' ${_limit} --max_num_segments ${max_num_segments} >> ${log_file} 2>&1",
      hour     => $cron_hour,
      minute   => $cron_minute,
      month    => $cron_month,
      monthday => $cron_monthday,
      weekday  => $cron_weekday,
      require  => Class['simp_logstash::curator']
    }
  }
  else {
    cron { 'logstash_index_optimize': ensure => 'absent' }
  }
}
