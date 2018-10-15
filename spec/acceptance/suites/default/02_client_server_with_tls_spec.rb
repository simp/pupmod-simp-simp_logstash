require 'spec_helper_acceptance'

test_name 'rsyslog clients -> 1 logstash server with TLS'

describe 'rsyslog client -> 1 logstash server with TLS' do
  clients = hosts_with_role( hosts, 'client' )
  servers = hosts_with_role( hosts, 'logstash_server' )

  clients.each do |client|
    servers.each do |server|
      client_manifest = <<-EOS
          class { 'rsyslog':
            log_servers             => ['#{fact_on(server, 'fqdn')}'],
            logrotate               => true,
            enable_tls_logging      => true,
            pki                     => true,
            app_pki_external_source => '/etc/pki/simp-testing/pki',
          }

          rsyslog::rule::remote { 'send_the_logs':
            rule => 'prifilt(\\'*.*\\')'
          }
        EOS

      context "client #{client}-> logstash server #{server} using TLS" do
        it 'should configure client without errors' do
          apply_manifest_on(client, client_manifest, :catch_failures => true)
        end

        it 'should configure client idempotently' do
          apply_manifest_on(client, client_manifest, :catch_changes => true)
        end

        it 'should successfully send log messages' do
          log_msg = "02-TEST-WITH-TLS-#{client}"
          on client, "logger -t FOO #{log_msg}"
          remote_log = '/var/log/logstash/file_output.log'
          wait_for_log_message(server, remote_log, log_msg)
        end
      end
    end
  end
end
