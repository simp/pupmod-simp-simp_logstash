require 'spec_helper_acceptance'

test_name 'simp_logstash class with elasticsearch'

describe 'simp_logstash class with elasticsearch' do

  logstash_servers = hosts_with_role(hosts, 'logstash_server')
  elasticsearch_servers = hosts_with_role(hosts, 'elasticsearch_server')

  # For the test log messages
  test_time = Time.now.strftime('%b %d %H:%M:%S')

  let(:ssh_allow) { <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::listen::tcp_stateful { 'ssh_allow':
      order        => 8,
      trusted_nets => ['any'],
      dports       => 22
    }
    EOM
  }

  let(:manifest) {
    <<-EOS
      include '::simp_logstash'

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
simp_options::trusted_nets:
  - 'ALL'

simp_options::pki: true
simp_options::pki::source : '/etc/pki/simp-testing/pki'
simp_options::firewall: true

# Elasticsearch Settings
#
# Single node for these tests. The 'simp_elasticsearch' module tests
# clustering.
#
simp_elasticsearch::apache::ssl_verify_client: 'none'
simp_elasticsearch::cluster_name : 'test_cluster'
simp_elasticsearch::http_method_acl :
  'limits' :
    'hosts' :
      '#ES_CLIENT#' : 'defaults'

# Bind to the testing certificates
apache::rsync_web_root : false
simp_apache::rsync_web_root: false
rsync::server : "%{::fqdn}"

# Logstash Settings
# Required for following tests
simp_logstash::inputs: ['tcp_syslog_tls', 'syslog', 'tcp_json_tls']
simp_logstash::output::elasticsearch::stunnel_verify : 0
simp_logstash::output::elasticsearch::host : '#ES_HOST#'
simp_logstash::outputs :
  - 'file'
  - 'elasticsearch'
    EOS
  }

  # Need to set up working ES hosts first
  elasticsearch_servers.each do |host|
    context "ES host #{host} setup" do
      it 'should set up an ES node' do
        # Hack to Force second nic up
        interfaces = fact_on(host, 'interfaces').strip.split(',')
        interfaces.delete_if do |x|
          x =~ /^lo/
        end

        interfaces.each do |iface|
          on(host, "ifup #{iface}", :accept_all_exit_codes => true)
        end

        fqdn = fact_on(host, 'fqdn')

        hdata = hieradata.dup
        hdata.gsub!(/#ES_HOST#/m, fqdn)
        hdata.gsub!(/#ES_CLIENT#/m, fqdn)
        if host.name == 'el6-es'
          # need newer JAVA version
          hdata += "\njava::package : 'java-1.8.0-openjdk-devel'\n"
        end

        # Reset the ES server to only allow this host through
        set_hieradata_on(host, hdata)
        apply_manifest_on(host, es_manifest)
        on(host, 'rpm -q elasticsearch')
      end

      it 'should be idempotent' do
        apply_manifest_on(host, es_manifest)
      end
    end
  end

  logstash_servers.each do |host|
    elasticsearch_servers.each do |es_host|
      context "on logstash server #{host} and ES server #{es_host}" do
        let(:log_msg) { "SIMP-BASE-TEST-TCP-#{host}" }

        it 'manifests for logstash and ES hosts should work with no errors' do
          # Hack to Force second nic up
          interfaces = fact_on(host, 'interfaces').strip.split(',')
          interfaces.delete_if do |x|
            x =~ /^lo/
          end

          interfaces.each do |iface|
            on(host, "ifup #{iface}", :accept_all_exit_codes => true)
          end

          # Set the ES host
          es_hostname = fact_on(es_host, 'fqdn')
          ls_hostname = fact_on(host, 'fqdn')

          hdata = hieradata.dup
          hdata.gsub!(/#ES_HOST#/m, es_hostname)
          hdata.gsub!(/#ES_CLIENT#/m, ls_hostname)
          if host.name == 'el6-server'
            # need newer JAVA version
            hdata += "\njava::package : 'java-1.8.0-openjdk-devel'\n"

            # Workaround until logstash module upstream sets the provider
            # correctly for OEL 6
            if fact_on(host, 'operatingsystem') == 'OracleLinux'
              hdata += "\nlogstash::service_provider: 'upstart'\n"
            end
          end

          # Reset the ES server to only allow this host through (hieradata change)
          set_hieradata_on(es_host, hdata)
          apply_manifest_on(es_host, es_manifest, :catch_failures => true)

          set_hieradata_on(host, hdata)
          apply_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'logstash manifest should be idempotent' do
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'logstash host should be running logstash' do
          on(host, %(ps -ef | grep "[l]ogstash"))
          # Need to wait for logstash to wake up and allow connections.
          sleep(60)
        end

        it 'logstash host should have NetCat installed for sending local messages' do
          host.install_package('nc')
        end

        it "logstash host #{host} should send the log message to ES host #{es_host}" do
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
