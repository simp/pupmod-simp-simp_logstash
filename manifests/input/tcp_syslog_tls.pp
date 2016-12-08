# A Logstash input for syslog over TCP and TLS enabled.
#
# Though this class has a great deal repeated with the other input classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# It allows you to encrypt traffic to the LogStash log collector just like the
# SIMP rsyslog remote configuration.
#
# This is currently configured as a catch-all type of system. There is no
# output filtering. If you need logstash filters or additional inputs/outputs,
# you will need to configure them separately.
#
# @note This class is incompatible with the SIMP rsyslog::stock::server class!
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
# @param client_nets [Array(Net Address)] An array of networks that you trust
#   to connect to your server.
#
# @param daemon_port [Port] The port that logstash itself should listen on.
#
# @author Ralph Wright <rwright@onyxpoint.com>
#
#
class simp_logstash::input::tcp_syslog_tls (
  $add_field = {},
  $codec = '',
  $host = '0.0.0.0',
  $lstash_tags = '',
  $lstash_type = 'simp_syslog',
  $order = '50',
  $content = '',
  $client_nets        = defined('$::client_nets') ? { true => getvar('::client_nets'), default => hiera('client_nets','127.0.0.1') },
  $daemon_port        = '6514',
  $ssl_verify         = true,
  $lstash_tls_cert    = "/etc/logstash/pki/public/${::fqdn}.pub",
  $lstash_tls_key     = "/etc/logstash/pki/private/${::fqdn}.pem",
  $lstash_tls_cacert  = '/etc/logstash/pki/cacerts/cacerts.pem',
) {

  validate_hash($add_field)
  validate_string($codec)
  validate_net_list($host)
  validate_string($lstash_tags)
  validate_string($lstash_type)
  validate_integer($order)
  validate_string($content)
  validate_net_list($client_nets)
  validate_port($daemon_port)
  validate_bool($ssl_verify)
  validate_absolute_path($lstash_tls_cert)
  validate_absolute_path($lstash_tls_key)
  validate_absolute_path($lstash_tls_cacert)

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

  iptables::add_tcp_stateful_listen { "allow_${_component_name}":
    client_nets => $client_nets,
    dports      => $daemon_port
  }
}
