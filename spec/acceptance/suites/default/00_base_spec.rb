require 'spec_helper_acceptance'

test_name 'simp_logstash class'

describe 'simp_logstash class' do

  logstash_servers = hosts_with_role(hosts, 'logstash_server')
  el7_hosts        = hosts_with_role(hosts, 'el7')

  # For the test log messages
  test_time = Time.now.strftime('%b %d %H:%M:%S')

  ssh_allow = <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::listen::tcp_stateful { 'i_love_testing':
      order => 8,
      trusted_nets => ['any'],
      dports => 22
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
simp_options::trusted_nets:
  - 'any'

#use_simp_pki : false

logstash::logstash_user : 'logstash'
logstash::logstash_group : 'logstash'

# Required for following tests
simp_logstash::inputs: ['tcp_syslog_tls', 'syslog', 'tcp_json_tls']
simp_logstash::input::syslog::listen_plain_udp : true

simp_logstash::app_pki_external_source: '/etc/pki/simp-testing/pki'

simp_logstash::outputs :
  - 'file'
    EOS
  }

  logstash_servers.each do |host|
    #Hack to Force eth1 up
    context 'on the el7_hosts' do
      on(host, %(/sbin/ifup eth1))
    end

    context 'on the logstash_servers' do
      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should be running logstash' do
        # Need to wait to determine if logstash will die
        sleep(60)
        on(host, %(ps -ef | grep "[l]ogstash"))
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
