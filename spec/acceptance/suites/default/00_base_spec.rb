require 'spec_helper_acceptance'

test_name 'simp_logstash class'

describe 'simp_logstash class' do

  logstash_servers = hosts_with_role(hosts, 'logstash_server')

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

      # For output testing without ES
      include '::simp_logstash::output::file'

      #{ssh_allow}
    EOS
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

logstash::logstash_user : 'logstash'
logstash::logstash_group : 'logstash'

# Required for following tests
simp_logstash::input::syslog::listen_plain_tcp : true
simp_logstash::input::syslog::listen_plain_udp : true

simp_logstash::outputs :
  - 'file'
    EOS
  }

  logstash_servers.each do |host|
    context 'on the servers' do
      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
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

      it 'should accept UDP logs' do
        log_msg = 'SIMP-BASE-TEST-UDP'
        on(host, %(echo '<34>#{test_time} 1.2.3.4 #{log_msg}' | nc -w 2 -u 127.0.0.1 51400))
        remote_log = '/var/log/logstash/file_output.log'
        sleep(5)
        on(host, %(test -f #{remote_log}))
        on(host, %(grep #{log_msg} #{remote_log}))
      end

      it 'should accept TCP logs' do
        log_msg = 'SIMP-BASE-TEST-TCP'
        on(host, %(echo '<34>#{test_time} 1.2.3.4 #{log_msg}' | nc -w 2 127.0.0.1 51400))
        remote_log = '/var/log/logstash/file_output.log'
        sleep(5)
        on(host, %(test -f #{remote_log}))
        on(host, %(grep #{log_msg} #{remote_log}))
      end
    end
  end
end
