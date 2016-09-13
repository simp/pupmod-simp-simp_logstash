# This class enhances the electrical-logstash module in the configuration
# settings recommended for SIMP systems.
#
# To modify the sysconfig settings, you'll need to use the
# '::logstash::init_defaults' hash.
#
# Be aware that this will remove the *entire* file, it does not cherry-pick
# settings. See the Logstash documentation for a list of all options.
#
# Please do *not* change the default config directory. This is hard coded in
# the upstream `logstash` module and referenced in this module.
#
# @example Set the Heap Size to '10g' via Hiera
#   ---
#   logstash::init_defaults :
#     'LS_HEAP_SIZE' : '10g'
#
# See simp_logstash::clean if you want to automatically prune your logs to
# conserve ElasticSearch storage space.
#
# @param inputs [Array(String)] An Array of inputs to be enabled. These can
#   also be individually enabled by class.
#
# @param filters [Array(String)] An Array of filters to be enabled. These can
#   also be individually enabled by class.
#
# @param outputs [Array(String)] An Array of outputs to be enabled. These can
#   also be individually enabled by class.
#
# @config_purge [Boolean] If set, purge all unmanaged configuration files. Any
#   file matching the glob logstash*.conf will be preserved. This is to allow
#   users to explicitly set their own configuration files as well as to prevent
#   issues with the upstream logstash module.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
#
class simp_logstash (
  $inputs = [
    'syslog'
  ],
  $filters = [
    'puppet_agent',
    'puppet_server',
    'slapd_audit',
    'sshd',
    'sudosh',
    'httpd',
    'yum'
  ],
  $outputs = [
    'elasticsearch'
  ],
  $config_purge = true
) {

  validate_array($inputs)
  validate_array($filters)
  validate_array($outputs)
  validate_bool($config_purge)

  include '::java'
  include '::logstash'

  # This is due to a bug in the upstream Logstash code that sets the owner of
  # all files to 'root:root' when they should be 'root:logstash' if the package
  # is installed.

  if $::logstash::logstash_user != 'logstash' {
    fail('The $::logstash::logstash_user must be set to "logstash" via Hiera or your ENC')
  }
  if $::logstash::logstash_group != 'logstash' {
    fail('The $::logstash::logstash_group must be set to "logstash" via Hiera or your ENC')
  }

  Class['java'] -> Class['logstash']
  Class['logstash'] -> Class['simp_logstash']

  $_config_dir = "${::logstash::configdir}/conf.d"
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
