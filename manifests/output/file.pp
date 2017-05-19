# A Logstash output to a file on the system
#
# Though this class has a great deal repeated with the other output classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# @param path The destination for the file output.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param codec The codec used for output data.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param create_if_deleted Create the target file if necessary.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param dir_mode The mode for created directories.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param enable_metric Whether to enable metric logging for this plugin
#   instance.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param file_mode The mode for created files.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param filename_failure If the generated path is invalid, save
#   output to this filename instead.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param flush_interval Seconds in which to flush to log files.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param gzip Gzip the output stream before writing to disk.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param id Unique ID for this output plugin configuration.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param workers The number of workers to use for this output.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html
#
# @param order The relative order within the configuration group. If
#   omitted, the entries will fall in alphabetical order.
#
# @param content The content that you wish to have in your filter. If
#   set, this will override *all* template contents.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_logstash::output::file (
  Stdlib::Absolutepath  $path              = '/var/log/logstash/file_output.log',
  Optional[String]      $codec             = undef,
  Optional[Boolean]     $create_if_deleted = undef,
  Optional[Integer[0]]  $dir_mode          = undef,
  Optional[Boolean]     $enable_metric     = undef,
  Optional[Integer[0]]  $file_mode         = undef,
  Optional[String]      $filename_failure  = undef,
  Optional[Integer[0]]  $flush_interval    = undef,
  Optional[Boolean]     $gzip              = undef,
  Optional[String]      $id                = 'simp_file',
  Optional[String]      $content           = undef,
  Integer[0]            $order             = 30,
  Optional[Integer[0]]  $workers           = undef
) {

  ### Common material to all outputs
  include '::simp_logstash'

  $_component_name = 'file'
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
