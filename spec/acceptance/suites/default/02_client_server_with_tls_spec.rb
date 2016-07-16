require 'spec_helper_acceptance'

test_name 'rsyslog clients -> 1 server with TLS'

describe 'rsyslog client -> 1 server with TLS' do
  clients = hosts_with_role( hosts, 'client' )
  servers = hosts_with_role( hosts, 'logstash_server' )

  clients.each do |client|
    servers.each do |server|
      client_manifest = <<-EOS
          class { 'rsyslog':
            log_server_list    => ['#{fact_on(server, 'fqdn')}'],
            enable_logrotate   => true,
            enable_tls_logging => true,
            enable_pki         => true,
            use_simp_pki       => false,
            cert_source        => '/etc/pki/simp-testing/pki'
          }

          rsyslog::rule::remote { 'send_the_logs':
            rule => '*.*'
          }
        EOS

      context 'client -> 1 server using TLS' do
        it 'should configure client without errors' do
          apply_manifest_on(client, client_manifest, :catch_failures => true)
        end

        it 'should configure client idempotently' do
          apply_manifest_on(client, client_manifest, :catch_changes => true)
        end

        it 'should successfully send log messages' do
          on client, 'logger -t FOO 02-TEST-WITH-TLS'
          sleep(5)
          remote_log = '/var/log/logstash/file_output.log'
          on server, "test -f #{remote_log}"
          on server, "grep 02-TEST-WITH-TLS #{remote_log}"
        end
      end
    end
  end
end
