# This class enhances the elastic-logstash module in the configuration
# settings recommended for SIMP systems.
#
# To modify the sysconfig settings, you'll need to use the
# '::logstash::startup_options' hash.
#
# Be aware that this will remove the *entire* file, it does not cherry-pick
# settings. See the Logstash documentation for a list of all options.
#
# Please do *not* change the default config directory. This is hard coded in
# the upstream `logstash` module and referenced in this module.
#
# To modify JAVA options, you'll need to use the
# '::logstash::java_options' hash.
#
# @example Set the Heap Size to '10g' via Hiera
#   ---
#   logstash::java_options : ['-Xms10g', '-Xmx10g']
#
# See simp_logstash::clean if you want to automatically prune your logs to
# conserve Elasticsearch storage space.
#
# See simp_logstash::optimize if you want to automatically merge
# Elasticsearch log segments to conserve storage space and speed up
# cluster recovery after Elasticsearch restart.
#
# @param inputs An Array of inputs to be enabled. These can
#   also be individually enabled by class.
#
# @param filters An Array of filters to be enabled. These can
#   also be individually enabled by class.
#
# @param outputs An Array of outputs to be enabled. These can
#   also be individually enabled by class.
#
# @param config_purge If set, purge all unmanaged configuration files. Any
#   file matching the glob logstash*.conf will be preserved. This is to allow
#   users to explicitly set their own configuration files as well as to prevent
#   issues with the upstream logstash module.
#
# @param trusted_nets  A list of networks and/or hostnames that are
#   allowed to connect to this service.
#
# @param pki
#   * If 'simp', include SIMP's pki module and use pki::copy to manage
#     application certs in /etc/pki/simp_apps/logstash/x509
#   * If true, do *not* include SIMP's pki module, but still use pki::copy
#     to manage certs in /etc/pki/simp_apps/logstash/x509
#   * If false, do not include SIMP's pki module and do not use pki::copy
#     to manage certs.  You will need to appropriately assign a subset of:
#     * app_pki_external_source
#     * app_pki_dir
#     * app_pki_key
#     * app_pki_cert
#     * app_pki_ca
#
# @param app_pki_external_source
#   * If pki = 'simp' or true, this is the directory from which certs will be
#     copied, via pki::copy.  Defaults to /etc/pki/simp/x509.
#
#   * If pki = false, this variable has no effect.
#
# @param app_pki_dir
#   This variable controls the basepath of $app_pki_key, $app_pki_cert,
#   $app_pki_ca, $app_pki_ca_dir, and $app_pki_crl.
#   It defaults to /etc/pki/simp_apps/logstash/x509.
#
# @param app_pki_key
#   Path and name of the private SSL key file
#
# @param app_pki_cert
#   Path and name of the public SSL certificate
#
# @param app_pki_ca
#   Path and name of the certificate authority
#
# @param firewall
#   Include the SIMP ``iptables`` module to manage the firewall.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
# @author Ralph Wright <rwright@onyxpoint.com>
#
class simp_logstash (
  Array[String]                 $inputs                   = [
    'tcp_syslog_tls'
  ],
  Array[String]                 $filters                  = [
    'audispd',
    'puppet_agent',
    'puppet_server',
    'sshd',
    'sudosh',
    'httpd',
    'yum',
    'simp_syslog'
  ],
  Array[String]                 $outputs                  = [
    'elasticsearch'
  ],
  Boolean                       $config_purge             = true,
  Simplib::Netlist              $trusted_nets             = simplib::lookup('simp_options::trusted_nets', {'default_value' =>   ['127.0.0.1/32'] }),
  Stdlib::Absolutepath          $app_pki_dir              = '/etc/pki/simp_apps/logstash/x509',
  Stdlib::Absolutepath          $app_pki_external_source  = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' }),
  Stdlib::Absolutepath          $app_pki_key              = "${app_pki_dir}/private/${facts['fqdn']}.pem",
  Stdlib::Absolutepath          $app_pki_cert             = "${app_pki_dir}/public/${facts['fqdn']}.pub",
  Stdlib::Absolutepath          $app_pki_ca               = "${app_pki_dir}/cacerts/cacerts.pem",
  Variant[Enum['simp'],Boolean] $pki                      = simplib::lookup('simp_options::pki', { 'default_value'         => false }),

  Boolean                       $firewall                 = simplib::lookup('simp_options::firewall', { 'default_value' => false }),

) {

  include '::java'
  include '::logstash'

  # This is due to a bug in the upstream Logstash code that sets the owner of
  # all files to 'root:root' when they should be 'root:logstash' if the package
  # is installed.
  #TODO verify this check is still needed
  if $::logstash::logstash_user != 'logstash' {
    fail('The $::logstash::logstash_user must be set to "logstash" via Hiera or your ENC')
  }
  if $::logstash::logstash_group != 'logstash' {
    fail('The $::logstash::logstash_group must be set to "logstash" via Hiera or your ENC')
  }
  # This is a workaround until upstream logstash gets PR merge for support
  if ("${::operatingsystem}-${::operatingsystemmajrelease}" == 'OracleLinux-6') and ($::logstash::service_provider != 'upstart') {
    fail('The $::logstash::service_provider setting must be set to "upstart" via Hiera or your ENC')
  }

  Class['java'] -> Class['logstash']
  Class['logstash'] -> Class['simp_logstash']

  $_config_dir = "${::logstash::config_dir}/conf.d"
  $config_prefix = "${_config_dir}/simp-logstash"
  $config_suffix = '.conf'

  $config_order = {
    'input'  => '10',
    'filter' => '20',
    'output' => '30'
  }

  if !empty($inputs)  { ::simp_logstash::input { $inputs: } }
  if !empty($filters) { ::simp_logstash::filter { $filters: } }
  if !empty($outputs) { ::simp_logstash::output { $outputs: } }

  # We need to be able to purge invalid configurations. Unfortunately, LogStash
  # doesn't allow more than one configuration directory, so we've had to be a
  # bit aggressive.
  File <| title == $_config_dir |> {
    recurse => true,
    purge   => $config_purge,
    ignore  => 'logstash*.conf'
  }
}
