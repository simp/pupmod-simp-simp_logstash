# A Logstash input for JSON over TCP and TLS enabled.
#
# Though this class has a great deal repeated with the other input classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# It allows you to encrypt traffic to a TCP port (5140) that expects JSON
# data.
#
# This is currently configured as a catch-all type of system. There is no
# output filtering. If you need logstash filters or additional inputs/outputs,
# you will need to configure them separately.
#
# @param add_field [Hash] Add a field to an event.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html
#
# @param codec [String] The codec used for input data.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html
#
# @param host [String] The address upon which to listen.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html
#
# @param lstash_tags [Array] Arbitrary tags for your events.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html
#
# @param order [Integer] The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content [String] The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @param daemon_port [Port] The port that logstash itself should listen on.
#
# @param ssl_verify [Absolutepath] Verify the SSL certificate of senders.
#
# @param lstash_tls_cert [Absolutepath] The SSL certificate to use for the TLS
#   listener.
#
# @param lstash_tls_key [Absolutepath] The SSL key to use for the TLS listener.
#
# @param lstash_tls_cacerts [Absolutepath] The file the contains the CA
#   certificates.
#
# @author Ralph Wright <rwright@onyxpoint.com>
#
class simp_logstash::input::tcp_json_tls (
  Optional[Hash]          $add_field          = {},
  Optional[String]        $codec              = 'json',
  Optional[Simplib::IP]   $host               = '0.0.0.0',
  Optional[Array[String]] $lstash_tags        = undef,
  String                  $lstash_type        = 'json',
  Integer[0]              $order              = 50,
  Optional[String]        $content            = undef,
  Simplib::Port           $daemon_port        = 5140,
  Boolean                 $ssl_verify         = true,
  Stdlib::Absolutepath    $lstash_tls_cert    = $::simp_logstash::app_pki_cert,
  Stdlib::Absolutepath    $lstash_tls_key     = $::simp_logstash::app_pki_key,
  Stdlib::Absolutepath    $lstash_tls_cacerts = $::simp_logstash::app_pki_ca
) {

  include '::simp_logstash'
  include 'simp_logstash::config::pki'

  $_component_name = 'tcp_json_tls'
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
