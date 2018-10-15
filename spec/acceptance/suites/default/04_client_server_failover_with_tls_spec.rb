# This test requires that the 00_base_spec test has run
#
# For full tests of the rsyslog client-side capabilities, see the rsyslog
# module.

require 'spec_helper_acceptance'

test_name 'rsyslog client -> 2 logstash servers with TLS with failover'

describe 'rsyslog client -> 2 logstash servers with TLS with failover' do
  before(:all) do
    # Ensure that our test doesn't match messages from other tests
    sleep(1)
    @msg_uuid = Time.now.to_f.to_s.gsub('.','_') + '_WITH_TLS'
  end

  clients = hosts_with_role( hosts, 'client' )
  servers = hosts_with_role( hosts, 'logstash_server' )
  primary_server = servers.first
  failover_server = servers.last

  if primary_server == failover_server
    fail('You must define more than one server!')
  end

  # 'puppet resource service' has to be told the service provider
  # is upstart.
  let(:primary_server_service_provider) {
    if primary_server.name == 'server-el6'
      provider = 'provider=upstart'
    else
      provider = ''
    end
    provider
  }

  let(:failover_server_service_provider) {
    if failover_server.name == 'server-el6'
      provider = 'provider=upstart'
    else
      provider = ''
    end
    provider
  }

  clients.each do |client|
    let(:client_manifest) {
      <<-EOS
        class { 'rsyslog':
          log_servers             => ['#{fact_on(primary_server, 'fqdn')}'],
          failover_log_servers    => ['#{fact_on(failover_server, 'fqdn')}'],
          logrotate               => true,
          enable_tls_logging      => true,
          pki                     => true,
          app_pki_external_source => '/etc/pki/simp-testing/pki'
        }

        rsyslog::rule::remote { 'send_the_logs':
          rule => 'prifilt(\\'*.*\\')'
        }
      EOS
    }

    context "client #{client} with primary syslog server #{primary_server} and failover server #{failover_server}" do
      let(:remote_log) { '/var/log/logstash/file_output.log' }

      it 'should configure client without errors' do
        apply_manifest_on(client, client_manifest, :catch_failures => true)
      end

      it 'should configure client idempotently' do
        apply_manifest_on(client, client_manifest, :catch_changes => true)

        # Ensure that the server on the primary is running for the initial
        # tests
        on(primary_server, "puppet resource service logstash ensure=running #{primary_server_service_provider}")

        # Ensure the failover server restarts to force any connections back to
        # the primary for other hosts
        on(failover_server, "puppet resource service logstash ensure=stopped #{failover_server_service_provider}")
        sleep(20)
        on(failover_server, "puppet resource service logstash ensure=running #{failover_server_service_provider}")

        # Give it a bit to start
        sleep(60)
      end


      it 'should successfully send log messages to the primary server but not the failover server' do
        msg = "01-TEST-#{@msg_uuid}-#{client}"

        on(client, "logger -t FOO #{msg}")
        sleep(10)

        on(primary_server, "test -f #{remote_log}")
        on(primary_server, "grep #{msg} #{remote_log}")

        on(failover_server, "(! grep #{msg} #{remote_log} )")
      end

      it 'should successfully failover' do
        # Unfortunately, rsyslog considers a successful TLS connection to be
        # all that it requires to bind to a system. As such, we have to stop
        # logstash
        on(primary_server, "puppet resource service logstash ensure=stopped #{primary_server_service_provider}")

        # Give it a bit to die
        sleep(25)

        # Sleeping wasn't working.  A Hack to force the clients to stop and start
        # rsyslog seems to work.
        on(client, 'puppet resource service rsyslog ensure=stopped')
        on(client, 'puppet resource service rsyslog ensure=running')
        sleep(25)

        # Log test messages
        (11..20).each do |msg|
          on(client, "logger -t FOO 01-TEST-#{msg}-#{@msg_uuid}-MSG-#{client}")
          sleep(2)
        end

        # Validate Failover
        # For some reason, messages 11 and 12 never make it to the failover.
        # They also don't make it to the primary.  That should be addressed in the
        # rsyslog module.
        wait_for_log_message(failover_server, remote_log, "01-TEST-13-#{@msg_uuid}-MSG-#{client}")
        wait_for_log_message(failover_server, remote_log, "01-TEST-19-#{@msg_uuid}-MSG-#{client}")

        on(primary_server, "(! grep 01-TEST-13-#{@msg_uuid}-MSG-#{client} #{remote_log} )")
        on(primary_server, "(! grep 01-TEST-19-#{@msg_uuid}-MSG-#{client} #{remote_log} )")
      end
    end
  end
end
