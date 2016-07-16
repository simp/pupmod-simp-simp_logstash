# A Logstash input for Syslog messages
#
# Though this class has a great deal repeated with the other input classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# It allows you to encrypt traffic to the LogStash log collector just like the
# SIMP rsyslog remote configuration.
#
# IPTables NAT rules are modified so that LogStash can run as a normal user
# while collecting syslog traffic from other hosts.
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
# @param facility_labels [Array] Labels for facility levels.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param host [String] The address upon which to listen.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param locale [String] The locale to use used for date parsing.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param severity_labels [String] Labels for severity levels.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param lstash_tags [Array] Arbitrary tags for your events.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param timezone [String] A time zone canonical ID to be used for date
#  parsing.
#  @see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html
#
# @param use_labels [Boolean] Use label parsing for severity and facility levels.
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
# @param listen_plain_tcp [Boolean] If set, listen on the default unencrypted
#   TCP syslog port.
#
# @param listen_plain_udp [Boolean] If set, listen on the default unencrypted
#   UDP syslog port.
#
# @param tcp_port [Port] The port upon which to listen for TCP syslog
#   connections.
#
# @param udp_port [Port] The port upon which to listen for UDP syslog
#   connections.
#
# @param daemon_port [Port] The port that logstash itself should listen on.
#
# @param stunnel_syslog_input [Boolean] Whether or not to set up a stunnel
#   connection on port 5140 for allowing clients to send logs to the server
#   over an encrypted channel. The usual 514 port will also listen for
#   connections on both TCP and UDP for devices which simply do not support
#   encrypted connections.
#
# @param simp_sysctl [Boolean] If set, this class will manage the following
#   sysctl variables.
#   * net.ipv4.conf.all.route_localhost
#
# @param simp_iptables [Boolean] If set, use IPTables rules to forward remote
#   connections to the logstash syslog listener. This prevents logstash itself
#   from needing to run as the 'root' user.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
#
class simp_logstash::input::syslog (
  $add_field = {},
  $codec = '',
  $facility_labels = [],
  $host = '127.0.0.1',
  $locale = '',
  $severity_labels = [
    'Emergency',
    'Alert',
    'Critical',
    'Error',
    'Warning',
    'Notice',
    'Informational',
    'Debug'
  ],
  $lstash_tags = '',
  $timezone = '',
  $lstash_type = '',
  $use_labels = true,
  $order = '50',
  $content = '',
  $client_nets           = defined('$::client_nets') ? { true => getvar('::client_nets'), default => hiera('client_nets','127.0.0.1') },
  $listen_plain_tcp      = false,
  $listen_plain_udp      = false,
  $tcp_port              = '514',
  $udp_port              = '514',
  $daemon_port          = '51400',
  $stunnel_syslog_input  = true,
  $stunnel_syslog_port   = '6514',
  $simp_sysctl           = true,
  $simp_iptables         = defined('$::use_iptables') ? { true => getvar('::use_iptables'), default => hiera('use_iptables',true) }
) {

  validate_hash($add_field)
  validate_string($codec)
  validate_array($facility_labels)
  validate_net_list($host)
  validate_string($locale)
  validate_array($severity_labels)
  validate_string($lstash_tags)
  validate_string($timezone)
  validate_string($lstash_type)
  validate_bool($use_labels)
  validate_integer($order)
  validate_string($content)
  validate_net_list($client_nets)
  validate_bool($listen_plain_tcp)
  validate_bool($listen_plain_udp)
  validate_port($udp_port)
  validate_port($tcp_port)
  validate_port($daemon_port)
  validate_bool($stunnel_syslog_input)
  validate_port($stunnel_syslog_port)
  validate_bool($simp_sysctl)
  validate_bool($simp_iptables)

  ### Common material to all inputs
  include '::simp_logstash'

  $_component_name = 'syslog'
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

  if $simp_iptables {
    if $listen_plain_tcp or $listen_plain_udp {
      if $listen_plain_tcp {
        # IPTables rules so that LogStash doesn't have to run as root.
        iptables_rule { 'tcp_logstash_syslog_redirect':
          table    => 'nat',
          absolute => true,
          first    => true,
          order    => '1',
          header   => false,
          content  => "-A PREROUTING -p tcp -m tcp --dport ${tcp_port} -j DNAT --to-destination ${host}:${daemon_port}"
        }
      }

      if $listen_plain_udp {
        # IPTables rules so that LogStash doesn't have to run as root.
        iptables_rule { 'udp_logstash_syslog_redirect':
          table    => 'nat',
          absolute => true,
          first    => true,
          order    => '1',
          header   => false,
          content  => "-A PREROUTING -p udp -m udp --dport ${udp_port} -j DNAT --to-destination ${host}:${daemon_port}"
        }
      }

      if $simp_sysctl {
        include '::sysctl'

        # Allow the iptables NAT rules to work properly.
        sysctl::value { 'net.ipv4.conf.all.route_localnet': value => '1' }
      }
    }

    if $listen_plain_tcp {
      iptables::add_tcp_stateful_listen { 'logstash_syslog_tcp':
        client_nets => $client_nets,
        dports      => $tcp_port
      }
      iptables_rule { 'logstash_syslog_tcp_allow':
        content => "-d ${host} -p tcp -m tcp -m multiport --dports ${daemon_port} -j ACCEPT"
      }
    }
    if $listen_plain_udp {
      iptables::add_udp_listen { 'logstash_syslog_udp':
        client_nets => $client_nets,
        dports      => $udp_port
      }
      iptables_rule { 'logstash_syslog_udp_allow':
        content => "-d ${host} -p udp -m udp -m multiport --dports ${daemon_port} -j ACCEPT"
      }
    }
  }

  if $stunnel_syslog_input {
    include '::stunnel'
    include '::tcpwrappers'

    stunnel::add { 'logstash_syslog_tls':
      client  => false,
      connect => [$daemon_port],
      accept  => $stunnel_syslog_port
    }

    tcpwrappers::allow { ['logstash_syslog','logstash_syslog_tls']: pattern => 'ALL' }
  }
}
