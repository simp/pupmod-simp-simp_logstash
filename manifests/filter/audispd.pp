# A Logstash filter for the Auditd dispatcher
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
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
class simp_logstash::filter::audispd (
  $order = '50',
  $content = ''
){
  include '::simp_logstash'

  validate_integer($order)
  validate_string($content)

  $_component_name = 'audispd'
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

  # We need to add our the audit pattern file
  logstash::patternfile { 'audispd':
    source => 'puppet:///modules/simp_logstash/audispd'
  }
}
