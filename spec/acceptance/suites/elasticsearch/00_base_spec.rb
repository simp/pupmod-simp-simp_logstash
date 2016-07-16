require 'spec_helper_acceptance'

test_name 'simp_logstash class with elasticsearch'

describe 'simp_logstash class with elasticsearch' do

  logstash_servers = hosts_with_role(hosts, 'logstash_server')
  elasticsearch_servers = hosts_with_role(hosts, 'elasticsearch_server')

  # For the test log messages
  test_time = Time.now.strftime('%b %d %H:%M:%S')

  ssh_allow = <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::add_tcp_stateful_listen { 'i_love_testing':
      order => '8',
      client_nets => 'ALL',
      dports => '22'
    }
  EOM

  let(:manifest) {
    <<-EOS
      include '::simp_logstash'

      # For output testing with File
      # include '::simp_logstash::output::file'

      # For output testing with ES
      # include '::simp_logstash::output::elasticsearch'

      #{ssh_allow}
    EOS
  }

  let(:es_manifest) {
    <<-EOF
      #{ssh_allow}

      include '::simp_elasticsearch'
    EOF
  }

  let(:hieradata) {
    <<-EOS
---
client_nets:
  - 'ALL'

pki_dir : '/etc/pki/simp-testing/pki'

stunnel::ca_source : "%{hiera('pki_dir')}/cacerts"
stunnel::cert : "%{hiera('pki_dir')}/public/%{fqdn}.pub"
stunnel::key : "%{hiera('pki_dir')}/private/%{fqdn}.pem"

use_simp_pki : false
use_iptables : true

# Elasticsearch Settings
#
# Single node for these tests. The 'simp_elasticsearch' module tests
# clustering.

simp_elasticsearch::cluster_name : 'test_cluster'
simp_elasticsearch::http_method_acl :
  'limits' :
    'hosts' :
      '#ES_CLIENT#' : 'defaults'

# Bind to the testing certificates
apache::ssl::use_simp_pki : false
apache::ssl::cert_source : "file://%{hiera('pki_dir')}"
apache::rsync_web_root : false

rsync::server : "%{::fqdn}"

# Logstash Settings

logstash::logstash_user : 'logstash'
logstash::logstash_group : 'logstash'

# Required for following tests

simp_logstash::input::syslog::listen_plain_tcp : true

simp_logstash::output::elasticsearch::host : '#ES_HOST#'

simp_logstash::outputs :
  - 'file'
  - 'elasticsearch'
    EOS
  }

  # Need to set up working ES hosts first
  elasticsearch_servers.each do |host|
    context 'to set up the ES hosts' do
      it 'should set up an ES node' do
        fqdn = fact_on(host, 'fqdn')

        hdata = hieradata.dup
        hdata.gsub!(/#ES_HOST#/m, fqdn)
        hdata.gsub!(/#ES_CLIENT#/m, fqdn)

        # Reset the ES serve to only allow this host through
        set_hieradata_on(host, hdata)
        apply_manifest_on(host, es_manifest)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, es_manifest)
      end
    end
  end

  logstash_servers.each do |host|
    elasticsearch_servers.each do |es_host|
      context 'on the servers' do
        let(:log_msg) { "SIMP-BASE-TEST-TCP-#{host}" }

        it 'should work with no errors' do
          # Set the ES host
          es_hostname = fact_on(es_host, 'fqdn')
          ls_hostname = fact_on(host, 'fqdn')

          hdata = hieradata.dup
          hdata.gsub!(/#ES_HOST#/m, es_hostname)
          hdata.gsub!(/#ES_CLIENT#/m, ls_hostname)

          # Reset the ES serve to only allow this host through
          set_hieradata_on(es_host, hdata)
          apply_manifest_on(es_host, es_manifest, :catch_failures => true)

          set_hieradata_on(host, hdata)
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'should be running logstash' do
          on(host, %(ps -ef | grep "[l]ogstash"))
          # Need to wait for logstash to wake up and allow connections.
          sleep(60)
        end

        it 'should have NetCat installed for sending local messages' do
          host.install_package('nc')
        end

        it "should send the log message to '#{es_host}'" do
          on(host, %(echo '<34>#{test_time} 1.2.3.4 #{log_msg}' | nc -w 2 127.0.0.1 51400))
          # Need to let the logs actually get there
          sleep(20)

          ls_index = on(es_host, %(curl --stderr /dev/null 'localhost:9199/_cat/indices/*?v' | grep logstash)).stdout.split(/\s+/)[2]

          expect(ls_index.to_s).to match(/^logstash/)

          on(es_host, %(curl --stderr /dev/null -XGET 'http://localhost:9199/#{ls_index}/_search?' | grep #{log_msg}))
        end
      end
    end
  end
end
