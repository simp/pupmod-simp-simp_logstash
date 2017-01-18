#
# Class: simp_logstash::config::pki
#
# Manages certs in $::simp_logstash::app_pki_dir.
#
# == Authors
#
# * Ralph Wright <rwright@onyxpoint.com>
#
class simp_logstash::config::pki (
){
  assert_private()

  if $::simp_logstash::pki {
    pki::copy { 'logstash':
      source => $::simp_logstash::app_pki_external_source,
      pki    => $::simp_logstash::pki,
      owner  => $::logstash::logstash_user,
      notify => Class['logstash::service']
    }
  }
}
