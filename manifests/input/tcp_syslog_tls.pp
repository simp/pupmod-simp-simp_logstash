# A Logstash input for TCP and TLS enabled. This input can be used for any
#  TCP inputs, but it's intened to be used for TLS enabled rsyslog clients
#  to send logs to logstash.
#
# Though this class has a great deal repeated with the other input classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# It allows you to encrypt traffic to a TCP port that expects to parse JSON
#
# This is currently configured as a catch-all type of system. There is no
# output filtering. If you need logstash filters or additional inputs/outputs,
# you will need to configure them separately.
#
# See simp_logstash::clean if you want to automatically prune your logs to
# conserve ElasticSearch storage space.
#
# @param add_field [Hash] Add a field to an event.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param codec [String] The codec used for input data.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param facility_labels [Array] Labels for facility levels.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param host [String] The address upon which to listen.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param lstash_tags [Array] Arbitrary tags for your events.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param order [Integer] The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content [String] The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @param trusted_nets [Array(Net Address)] An array of networks that you trust
#   to connect to your server.
#
# @param daemon_port [Port] The port that logstash itself should listen on.
#
# @author Ralph Wright <rwright@onyxpoint.com>
#
class simp_logstash::input::tcp_syslog_tls (
  Optional[Hash]          $add_field          = {},
  Optional[String]        $codec              = undef,
  Optional[Simplib::IP]   $host               = '0.0.0.0',
  Optional[Array[String]] $lstash_tags        = undef,
  String                  $lstash_type        = 'simp_syslog',
  Integer[0]              $order              = 50,
  Optional[String]        $content            = undef,
  Simplib::Port           $daemon_port        = 6514,
  Boolean                 $ssl_verify         = true,
  Stdlib::Absolutepath    $lstash_tls_cert    = $::simp_logstash::app_pki_cert,
  Stdlib::Absolutepath    $lstash_tls_key     = $::simp_logstash::app_pki_key,
  Stdlib::Absolutepath    $lstash_tls_cacerts = $::simp_logstash::app_pki_cacerts
) {

  include '::simp_logstash'
  include 'simp_logstash::config::pki'
  include 'simp_logstash::filter::simp_syslog'

  $_component_name = 'tcp_syslog_tls'
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

  iptables::listen::tcp_stateful { "allow_${_component_name}":
    trusted_nets => $::simp_logstash::trusted_nets,
    dports       => $daemon_port
  }
}
