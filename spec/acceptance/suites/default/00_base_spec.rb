require 'spec_helper_acceptance'

test_name 'simp_logstash class'

describe 'simp_logstash class' do

  logstash_servers = hosts_with_role(hosts, 'logstash_server')
  el7_hosts        = hosts_with_role(hosts, 'el7')

  # For the test log messages
  test_time = Time.now.strftime('%b %d %H:%M:%S')

  let(:ssh_allow) { <<-EOM
    include '::tcpwrappers'
    include '::iptables'

    tcpwrappers::allow { 'sshd':
      pattern => 'ALL'
    }

    iptables::listen::tcp_stateful { 'ssh_allow':
      order => 8,
      trusted_nets => ['any'],
      dports => 22
    }
    EOM
  }

  let(:manifest) {
    <<-EOS
      include '::simp_logstash'

      #{ssh_allow}
    EOS
  }

  let(:hieradata) {
    <<-EOS
---
simp_options::trusted_nets:
  - 'any'

# Required for following tests
simp_logstash::inputs: ['tcp_syslog_tls', 'syslog', 'tcp_json_tls']
simp_logstash::input::syslog::listen_plain_udp : true

simp_options::pki: true
simp_options::pki::source: '/etc/pki/simp-testing/pki'
simp_options::firewall: true

simp_logstash::outputs :
  - 'file'
    EOS
  }

  logstash_servers.each do |host|
    #Hack to Force second nic up
    interfaces = fact_on(host, 'interfaces').strip.split(',')
    interfaces.delete_if do |x|
      x =~ /^lo/
    end

    context 'on the el7_hosts' do
      interfaces.each do |iface|
        on(host, "ifup #{iface}", :accept_all_exit_codes => true)
      end
    end

    context "on logstash server #{host}" do
      it 'should work with no errors' do
        hdata = hieradata.dup
        if host.name == 'el6-server'
          # need newer JAVA version
          hdata += "\njava::package : 'java-1.8.0-openjdk-devel'\n"

          # Workaround until logstash module upstream sets the provider
          # correctly for OEL 6
          if fact_on(host, 'operatingsystem') == 'OracleLinux'
            hdata += "\nlogstash::service_provider: 'upstart'\n"
          end
        end
        set_hieradata_on(host, hdata)
        apply_manifest_on(host, manifest, :catch_failures => true)
        on(host, 'rpm -q logstash')
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
        log_msg = "SIMP-BASE-TEST-UDP-#{host}"
        on(host, %(echo '<34>#{test_time} 1.2.3.4 #{log_msg}' | nc -w 2 -u 127.0.0.1 51400))
        remote_log = '/var/log/logstash/file_output.log'
        wait_for_log_message(host, remote_log, log_msg)
      end

      it 'should accept TCP logs' do
        log_msg = "SIMP-BASE-TEST-TCP-#{host}"
        on(host, %(echo '<34>#{test_time} 1.2.3.4 #{log_msg}' | nc -w 2 127.0.0.1 51400))
        remote_log = '/var/log/logstash/file_output.log'
        wait_for_log_message(host, remote_log, log_msg)
      end
    end
  end
end
