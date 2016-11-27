# This class sets up a logstash filter to process syslog traffic.  Since
#   there are aspect specific to SIMP log processing, it's called simp_syslog
#   so it won't conflict with any other more generic syslog processors.
#
# @param order [Integer] The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order. We set this filter to
#   10 so that it can process logs before the rest of our filters.
#
# @param content [String] The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @param severity_labels [String] Labels for severity levels.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-filters-syslog_pri.html
#
# @author Ralph Wright <rwright@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
class simp_logstash::filter::simp_syslog (
  Integer                       $order            = 10,
  Optional[String]              $content          = undef,
  $severity_labels  = [
    'Emergency',
    'Alert',
    'Critical',
    'Error',
    'Warning',
    'Notice',
    'Informational',
    'Debug'
    ]
){
  include '::simp_logstash'

  $_component_name = 'simp_syslog'
  $_group = 'filter'
  $_group_order = $::simp_logstash::config_order[$_group]

  if empty($content) {
    $_content = template("${module_name}/${_group}/${_component_name}.erb")
  }
  else {
    $_content = $content
  }

  file { "${::simp_logstash::config_prefix}-${_group_order}_${_group}-${order}-${_component_name}${::simp_logstash::config_suffix}":
    ensure  => 'file',
    owner   => 'root',
    group   => $::logstash::logstash_group,
    mode    => '0640',
    content => $_content,
    notify  => Class['logstash::service']
  }
}
