# Create a cron job to clean your Elasticsearch indices on a regular basis
# using elasticsearch-curator.
#
# In a SIMP environment, this should be installed on a Elasticsearch
# host and then configured to use the local, unencrypted connection to
# Elasticsearch.
#
# @param ensure Whether to add, or delete, the index cleaning cron job.
#
# @param host The host upon which to operate. Default is set for the
#   local unencrypted connection to Elasticsearch.
#
# @param keep_type The type of filtering to be applied during
#   the cleaning process.
#
# @param keep_amount The filtering threshold to apply to the
#   $keep_type.  When $keep_type is 'space', the units for
#   $keep_amount is gigabytes. So a value of 10 results in
#   a threshold of 10 gigabytes.
#
# @param prefix The index prefix to use to identify relevant logs.  This is
#   a match so 'foo' will match 'foo', 'foosball', and 'foot'.
#
# @param port The port to which to connect.  Default is set for the
#   local unencrypted connection to Elasticsearch.
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
  Enum['days', 'hours', 'space']    $keep_type      = 'days',
  Integer[0]                        $keep_amount    = 356,
  String                            $prefix         = 'logstash-',
  Simplib::Port                     $port           = 9199,
  Integer[0]                        $es_timeout     = 30,
  Stdlib::Absolutepath              $log_file       = '/var/log/logstash/curator_clean.log',
  Variant[Enum['*'],Integer[0,23]]  $cron_hour      = 1,
  Variant[Enum['*'],Integer[0,59]]  $cron_minute    = 15,
  Variant[Enum['*'],Integer[1,12]]  $cron_month     = '*',
  Variant[Enum['*'],Integer[1,31]]  $cron_monthday  = '*',
  Variant[Enum['*'],Integer[0,7]]   $cron_weekday   = '*'
) {

  if ($ensure == 'present') {

    if $keep_type == 'hours'{
      $_limit_filter = "{\"filtertype\":\"age\",\"source\":\"creation_date\",\"direction\":\"older\",\"unit\":\"hours\",\"unit_count\":${keep_amount}}"
    }
    elsif $keep_type == 'days' {
      $_limit_filter = "{\"filtertype\":\"age\",\"source\":\"creation_date\",\"direction\":\"older\",\"unit\":\"days\",\"unit_count\":${keep_amount}}"
    }
    else {
      $_limit_filter = "{\"filtertype\":\"space\",\"disk_space\":${keep_amount}}"
    }

    $_prefix_filter = "{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${prefix}\"}"

    $_filter_list = "[${_limit_filter},${_prefix_filter}]"

    include '::simp_logstash::curator'

    cron { 'logstash_index_cleanup' :
      ensure   => $ensure,
      command  => "/usr/bin/curator_cli --host ${host} --port ${port} --timeout ${es_timeout} --logfile ${log_file} delete_indices --ignore_empty_list --filter_list '${_filter_list}'",
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
