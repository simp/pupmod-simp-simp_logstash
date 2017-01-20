# A Logstash output to a file on the system
#
# Though this class has a great deal repeated with the other output classes,
# they remain separate in the event that variables need to be added in the
# future for ERB processing.
#
# @param path [Absolute_Path] The destination for the file output.
#
# @param codec [String] The codec used for output data.
#   @see https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html
#
# @param create_if_deleted [Boolean] Create the target file if necessary.
#
# @param dir_mode [Integer] The mode for created directories.
#
# @param file_mode [Integer] The mode for created files.
#
# @param filename_failure [String] If the generated path is invalid, save
#   output to this filename instead.
#
# @param flush_interval [Integer] Seconds in which to flush to log files.
#
# @param gzip [Boolean] Gzip the output stream before writing to disk.
#
# @param workers [Integer] The number of workers to use for this output.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
class simp_logstash::output::file (
  Stdlib::Absolutepath  $path              = '/var/log/logstash/file_output.log',
  Optional[String]      $codec             = undef,
  Optional[Boolean]     $create_if_deleted = undef,
  Optional[Integer[0]]  $dir_mode          = undef,
  Optional[Integer[0]]  $file_mode         = undef,
  Optional[String]      $filename_failure  = undef,
  Optional[Integer[0]]  $flush_interval    = undef,
  Optional[Boolean]     $gzip              = undef,
  Optional[String]      $content           = undef,
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

  file { "${::simp_logstash::config_prefix}-${_group_order}_${_group}-${_group_order}-${_component_name}${::simp_logstash::config_suffix}":
    ensure  => 'file',
    owner   => 'root',
    group   => $::logstash::logstash_group,
    mode    => '0640',
    content => $_content,
    notify  => Class['logstash::service']
  }
  ### End common material
}
