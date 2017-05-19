# Sets up a cron job to optimize your Elasticsearch indices on a regular basis
# using elasticsearch-curator. This optimization merges Elasticsearch log
# segments to conserve storage space and speed up cluster recovery after
# Elasticsearch restart.
#
# In a SIMP environment, this should be installed on a Elasticsearch
# host and then configured to use the local, unencrypted connection to
# Elasticsearch.
#
# @param ensure Whether to add, or delete, the index optimization job.
#
# @param host The host upon which to operate.  Default is set for the
#   local unencrypted connection to Elasticsearch.
#
# @param prefix The prefix to use to identify relevant logs. This is
#   a match so 'foo' will match 'foo', 'foosball', and 'foot'.
#
# @param port The port to which to connect.  Default is set for the
#   local unencrypted connection to Elasticsearch.
#
# @param es_timeout The timeout, in seconds, to wait for a response
#   from Elasticsearch.
#
# @param max_num_segments Optimize segment count to $max_num_segments
#   per shard.
#
# @param log_file The log file to which to print curator
#   output.
#
# @param cron_hour The hour at which to run the index optimization.
#
# @param cron_minute The minute at which to run the index
#   optimization.
#
# @param cron_month The month within which to run the index
#   optimization.
#
# @param cron_monthday The day of the month upon which to run
#   the index optimization.
#
# @param cron_weekday The day of the week upon which to run
#   the index optimization.
#
class simp_logstash::optimize (
  Enum['present','absent']          $ensure           = 'present',
  Simplib::Host                     $host             = '127.0.0.1',
  String                            $prefix           = 'logstash-',
  Simplib::Port                     $port             = 9199,
  Integer[0]                        $es_timeout       = 21600,
  Integer[1]                        $max_num_segments = 2,
  Stdlib::Absolutepath              $log_file         = '/var/log/logstash/curator_optimize.log',
  Variant[Enum['*'],Integer[0,23]]  $cron_hour        = 3,
  Variant[Enum['*'],Integer[0,59]]  $cron_minute      = 15,
  Variant[Enum['*'],Integer[1,12]]  $cron_month       = '*',
  Variant[Enum['*'],Integer[1,31]]  $cron_monthday    = '*',
  Variant[Enum['*'],Integer[0,7]]   $cron_weekday     = '*'
) {


  if ($ensure == 'present') {
    $_prefix_filter = "{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${prefix}\"}"
    $_filter_list = "[${_prefix_filter}]"

    include '::simp_logstash::curator'

    cron { 'logstash_index_optimize':
      ensure   => $ensure,
      command  => "/usr/bin/curator_cli --host ${host} --port ${port} --timeout ${es_timeout} --logfile ${log_file} forcemerge --max_num_segments ${max_num_segments} --ignore_empty_list --filter_list '${_filter_list}'",
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
