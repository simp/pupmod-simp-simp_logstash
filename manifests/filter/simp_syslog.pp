# A Logstash filter for SIMP syslog parsing
#
# Though this class has a great deal repeated with the other filter classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# @param order [Integer] The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content [String] The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
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
  $order = '10',
  $content = '',
  $severity_labels = [
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

  validate_integer($order)
  validate_string($content)
  validate_array($severity_labels)

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
