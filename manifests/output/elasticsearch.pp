# A Logstash output to Elasticsearch
#
# Though this class has a great deal repeated with the other output classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# @param action [String] The Elasticsearch action to perform.
#   Allowed Values: index, delete, create, update
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param codec [String] The codec used for output data.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param doc_as_upsert [Boolean] Create a new document with source if
#   `document_id` doesn't exist in Elasticsearch.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param document_id [String] The document ID for the index.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param document_type [String] The document type to write events to.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @parm flush_size [Integer] Maximum sized bulk request.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param host [Net Address] The host of the remote instance.
#   @note It is highly recommended that you couple an Elasticsearch ingest node
#   with the LogStash server itself.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param port [Port] The port on the remote instance to which to connect.
#
# @param idle_flush_time [Integer] The amount of time since last flush before a
#   flush is forced.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param index [String] The index to write events to.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param manage_template [Boolean] If set, apply a default mapping template
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param parent [String] The ID of the associated parent document.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param path [Absolute Path] HTTP path at which the Elasticsearch server lives.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param retry_max_interval [Integer] Set max interval between bulk retries.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param routing [String] A routing override to be applieid to all events.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script [String] Set script name for scripted update module.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_lang [String] Set the language of the used script.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_type [String] Define the type of script referenced by `$script`.
#   Allowed Values: 'inline', 'indexed', 'file'
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_var_name [String] Variable name passed to script.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param scripted_upsert [Boolean] If set, `$script` is in charge of creating
#   non-existent document
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template [Absolute Path] The path to your own template.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template_name [String] The name of the template in Elasticsearch.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template_overwrite [Boolean] If set, overwrite the indicated template
#   in ES with either the one dicated by `template` or the included one.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param timeout [Integer] Timeout for network operations.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param upsert [String] Upsert content for update mode.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param workers [Integer] Number of workers to use for this output.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param order [Integer] The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content [String] The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @param stunnel_port [Port] The port on the local host to which to connect to
#   use the stunnel connection to the remote ES system. This is not required if
#   you are connecting to an ES server on the local system.
#
# @param stunnel_elasticsearch [Boolean] If set, use a stunnel connection to
#   connect to ES. This is necessary if you are using ES behind an HTTPS proxy.
#   If you're using ES on the same host, and using the `::simp_elasticsearch`
#   class (the default), then the system will auto-adjust to ignore this
#   setting.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
class simp_logstash::output::elasticsearch (
  $action                = '',
  $codec                 = '',
  $doc_as_upsert         = '',
  $document_id           = '',
  $document_type         = '',
  $flush_size            = '',
  $host                  = 'localhost',
  $port                  = '9199',
  $idle_flush_time       = '',
  $index                 = '',
  $manage_template       = '',
  $parent                = '',
  $path                  = '',
  $retry_max_interval    = '',
  $routing               = '',
  $script                = '',
  $script_lang           = '',
  $script_type           = '',
  $script_var_name       = '',
  $scripted_upsert       = '',
  $template              = '',
  $template_name         = '',
  $template_overwrite    = '',
  $timeout               = '',
  $upsert                = '',
  $workers               = '',
  $order                 = '50',
  $content               = '',
  $stunnel_port          = '9200',
  $stunnel_elasticsearch = true
) {

  if !empty($action) {
    validate_string($action)
    validate_array_member($action, ['index', 'delete', 'create', 'update'])
  }
  validate_string($codec)
  if !empty($doc_as_upsert) { validate_bool($doc_as_upsert) }
  validate_string($document_id)
  validate_string($document_type)
  if !empty($flush_size) { validate_integer($flush_size) }
  validate_net_list($host)
  validate_port($port)
  if !empty($idle_flush_time) { validate_integer($idle_flush_time) }
  validate_string($index)
  if !empty($manage_template) { validate_bool($manage_template) }
  validate_string($parent)
  if !empty($path) { validate_absolute_path($path) }
  if !empty($retry_max_interval) { validate_integer($retry_max_interval) }
  validate_string($routing)
  validate_string($script)
  validate_string($script_lang)
  if !empty($script_type) {
    validate_string($script_type)
    validate_array_member($script_type, ['inline', 'indexed', 'file'])
  }
  validate_string($script_var_name)
  if !empty($scripted_upsert) { validate_bool($scripted_upsert) }
  if !empty($template) { validate_absolute_path($template) }
  validate_string($template_name)
  if !empty($template_overwrite) { validate_bool($template_overwrite) }
  if !empty($timeout) { validate_integer($timeout) }
  validate_string($upsert)
  if !empty($workers) { validate_integer($workers) }
  validate_integer($order)
  validate_string($content)
  validate_bool($stunnel_elasticsearch)

  $_is_local = host_is_me($host)

  if $stunnel_elasticsearch {
    include '::stunnel'

    $_host = '127.0.0.1'

    if $_is_local {
      $_port = $port
    }
    else {
      stunnel::add { 'logstash_elasticsearch':
        client  => true,
        connect => ["${host}:${stunnel_port}"],
        accept  => "${_host}:${stunnel_port}"
      }

      $_port = $stunnel_port
    }
  }
  else {
    $_host = $host
    $_port = $port
  }

  ### Common material to all outputs
  include '::simp_logstash'

  $_component_name = 'elasticsearch'
  $_group = 'output'
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
