# A Logstash input for stdin
#
# The generic stdin input.
#
# @param add_field Add a field to an event.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param codec The codec used for input data.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param enable_metric Whether to enable metric logging for this plugin instance.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param id Unique ID for this input plugin configuration.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param lstash_tags Arbitrary tags for your events.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param lstash_type Type field to be added to all stdin events.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
#
# @param order The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
#
class simp_logstash::input::stdin (
  Optional[Hash]          $add_field     = undef,
  Optional[String]        $codec         = undef,
  Optional[Boolean]       $enable_metric = undef,
  Optional[String]        $id            = 'simp_stdin',
  Optional[Array[String]] $lstash_tags   = undef,
  String                  $lstash_type   = 'simp_stdin',
  Integer[0]              $order         = 50,
  Optional[String]        $content       = undef
){

  ### Common material to all inputs
  include '::simp_logstash'

  $_component_name = 'stdin'
  $_group = 'input'
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
  ### End common material
}
