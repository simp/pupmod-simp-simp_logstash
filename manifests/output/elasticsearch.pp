# A Logstash output to Elasticsearch
#
# Though this class has a great deal repeated with the other output classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# @param absolute_healthcheck_path When a healthcheck_path config is provided,
#   this additional flag can be used to specify whether the healthcheck_path
#   is appended to the existing path (default) or is treated as the absolute
#   URL path.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param action The Elasticsearch action to perform.
#   Allowed Values: index, delete, create, update
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param codec The codec used for output data.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param doc_as_upsert Create a new document with source if
#   `document_id` doesn't exist in Elasticsearch.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param document_id The document ID for the index.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param document_type The document type to write events to.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param enable_metric Whether to enable metric logging for this plugin
#   instance.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param failure_type_logging_whitelist Elasticsearch errors you don't want
#   to log.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param flush_size Maximum sized bulk request.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param healthcheck_path When a backend is marked down a HEAD request will be
#   sent to this path in the background to see if it has come back again
#   before it is once again eligible to service requests.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param host The host of the remote instance.
#   @note It is highly recommended that you couple an Elasticsearch ingest node
#   with the LogStash server itself.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param port The port on the remote instance to which to connect.
#
# @param id Unique ID for this output plugin configuration.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param idle_flush_time The amount of time since last flush before a
#   flush is forced.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param index The index to write events to.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param manage_template If set, apply a default mapping template
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param parameters Pass a set of key value pairs as the URL query string.
#   This query string is added to the host listed in the host configuration.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param parent The ID of the associated parent document.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param path HTTP path at which the Elasticsearch server lives.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param pipeline Which ingest pipeline you wish to execute for an event.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param pool_max Maximum number of open connections the output will create.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param pool_max_per_route Maximum number of open connections per endpoint
#   the output will create.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param resurrect_delay How frequently, in seconds, to wait between
#   resurrection attempts.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param retry_initial_interval Initial interval in seconds between bulk
#   retries.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param retry_max_interval Set max interval between bulk retries.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param retry_on_conflict Number of times Elasticsearch should internally
#   retry an update/upserted document.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param routing A routing override to be applieid to all events.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script Set script name for scripted update module.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_lang Set the language of the used script.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_type Define the type of script referenced by `$script`.
#   Allowed Values: 'inline', 'indexed', 'file'
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param script_var_name Variable name passed to script.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param scripted_upsert If set, `$script` is in charge of creating
#   non-existent document
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template The path to your own template.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template_name The name of the template in Elasticsearch.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param template_overwrite If set, overwrite the indicated template
#   in ES with either the one dicated by `template` or the included one.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param timeout Timeout for network operations.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param upsert Upsert content for update mode.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param validate_after_inactivity How long to wait before checking if
#   the connection is stale before executing a request on a connection
#   using keepalive.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param version Version to use for indexing.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param version_type version_type to use for indexing.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param workers Number of workers to use for this output.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param order The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @param stunnel_port The port on the local host to which to connect to
#   use the stunnel connection to the remote ES system. This is not required if
#   you are connecting to an ES server on the local system.
#
# @param stunnel_verify
#   Level of mutual authentication to perform                                                            
#                                                                                                        
#   * RHEL 6 Options:                                                                                    
#       * level 1 - verify peer certificate if present                                                   
#       * level 2 - verify peer certificate                                                              
#       * level 3 - verify peer with locally installed certificate                                       
#       * default - no verify                                                                            
#                                                                                                        
#   * RHEL 7 Options:                                                                                    
#       * level 0 - Request and ignore peer certificate.                                                 
#       * level 1 - Verify peer certificate if present.                                                  
#       * level 2 - Verify peer certificate.                                                             
#       * level 3 - Verify peer with locally installed certificate.                                      
#       * level 4 - Ignore CA chain and only verify peer certificate.                                    
#       * default - No verify
#
# @param stunnel_elasticsearch If set, use a stunnel connection to
#   connect to ES. This is necessary if you are using ES behind an HTTPS proxy.
#   If you're using ES on the same host, and using the `::simp_elasticsearch`
#   class (the default), then the system will auto-adjust to ignore this
#   setting.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_logstash::output::elasticsearch (
  Optional[Boolean]                                 $absolute_healthcheck_path = undef,
  Optional[Enum['index','delete','create']]         $action                = undef,
  Optional[String]                                  $codec                 = undef,
  Optional[Boolean]                                 $doc_as_upsert         = undef,
  Optional[String]                                  $document_id           = undef,
  Optional[String]                                  $document_type         = undef,
  Optional[Boolean]                                 $enable_metric         = undef,
  Optional[Array[String]]                           $failure_type_logging_whitelist = undef,
  Optional[Integer[0]]                              $flush_size            = undef,
  Optional[Stdlib::Absolutepath]                    $healthcheck_path      = undef,
  Simplib::Host                                     $host                  = 'localhost',
  Optional[String]                                  $id                    = 'simp_elasticsearch',
  Simplib::Port                                     $port                  = 9199,
  Optional[Integer[0]]                              $idle_flush_time       = undef,
  Optional[String]                                  $index                 = undef,
  Optional[Boolean]                                 $manage_template       = undef,
  Optional[Hash]                                    $parameters            = undef,
  Optional[String]                                  $parent                = undef,
  Optional[Stdlib::Absolutepath]                    $path                  = undef,
  Optional[String]                                  $pipeline              = undef,
  Optional[Integer[1]]                              $pool_max              = undef,
  Optional[Integer[1]]                              $pool_max_per_route    = undef,
  Optional[Integer[0]]                              $resurrect_delay       = undef,
  Optional[Integer[0]]                              $retry_initial_interval = undef,
  Optional[Integer[0]]                              $retry_max_interval    = undef,
  Optional[Integer[0]]                              $retry_on_conflict     = undef,
  Optional[String]                                  $routing               = undef,
  Optional[String]                                  $script                = undef,
  Optional[String]                                  $script_lang           = undef,
  Optional[Array[Enum['inline','indexed','file']]]  $script_type           = undef,
  Optional[String]                                  $script_var_name       = undef,
  Optional[Boolean]                                 $scripted_upsert       = undef,
  Optional[Stdlib::Absolutepath]                    $template              = undef,
  Optional[String]                                  $template_name         = undef,
  Optional[Boolean]                                 $template_overwrite    = undef,
  Optional[Integer[0]]                              $timeout               = undef,
  Optional[String]                                  $upsert                = undef,
  Optional[Integer[0]]                              $validate_after_inactivity = undef,
  Optional[String]                                  $version               = undef,
  Optional[Enum['internal','external',
    'external_gt', 'external_gte', 'force']]        $version_type          = undef,
  Optional[Integer[0]]                              $workers               = undef,
  Integer[0]                                        $order                 = 50,
  Optional[String]                                  $content               = undef,
  Integer                                           $stunnel_verify        = 2,
  Simplib::Port                                     $stunnel_port          = 9200,
  Boolean                                           $stunnel_elasticsearch = true
) {

  $_is_local = simplib::host_is_me($host)

  if $stunnel_elasticsearch {
    $_host = '127.0.0.1'

    if $_is_local {
      $_port = $port
    }
    else {
      include '::stunnel'

      stunnel::connection { 'logstash_elasticsearch':
        client  => true,
        connect => ["${host}:${stunnel_port}"],
        accept  => "${_host}:${stunnel_port}",
        verify  => $stunnel_verify
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
