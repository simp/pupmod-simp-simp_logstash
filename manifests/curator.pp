# A class to include the ElasticSearch curator
#
# This should probably be moved into the simp_elasticsearch module
class simp_logstash::curator {
  package { 'elasticsearch-curator': ensure => 'latest' }
}
