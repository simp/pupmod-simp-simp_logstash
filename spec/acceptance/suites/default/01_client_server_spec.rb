# This test requires that the 00_base_spec test has run

require 'spec_helper_acceptance'

test_name 'rsyslog clients -> 1 logstash server without TLS'

describe 'rsyslog client -> 1 logstash server without TLS' do
  clients = hosts_with_role( hosts, 'client' )
  servers = hosts_with_role( hosts, 'logstash_server' )
  let(:remote_log)  { '/var/log/logstash/file_output.log' }

  clients.each do |client|
    servers.each do |server|
      client_manifest = <<-EOS
          class { 'rsyslog':
            log_servers        => ['#{fact_on(server, 'fqdn')}'],
            logrotate          => true,
            enable_tls_logging => false,
            pki                => false,
          }

          rsyslog::rule::remote { 'send_the_logs':
            rule => 'prifilt(\\'*.*\\')'
          }
        EOS

      context "client #{client}-> server #{server} without TLS" do
        it 'should configure client without errors' do
          apply_manifest_on(client, client_manifest, :catch_failures => true)
        end

        it 'should configure client idempotently' do
          apply_manifest_on(client, client_manifest, :catch_changes => true)
        end

        it 'should successfully send log messages' do
          log_msg = "01-TEST-WITHOUT-TLS-#{client}"
          on client, "logger -t FOO #{log_msg}"
          wait_for_log_message(server, remote_log, log_msg)
        end

        it 'should filter yum messages' do
          on server, "rm -f #{remote_log}"  # start with a clean log
          client.install_package('vim-X11')

          wait_for_log_message(server, remote_log, 'vim-X11')
          result = on(server, "grep 'vim-X11' #{remote_log}")
          log_lines = result.stdout.split("\n")
          log_lines.delete_if { |line| !line.include?('"program":"yum"') }
          fail("yum line match failed") if log_lines.empty?
          log_line = log_lines.last
          expect(log_line).to match(/"package":".+:vim-X11/)
          expect(log_line).to match(/"yum_action":"Installed"/)
          on(client, 'yum erase -y vim-X11') # prep for next yum test on this client
        end

        it 'should filter valid sshd login messages ' do
          # beaker opens and maintains ssh sessions into the VMs for
          # host operations. So need to open up a new ssh connection for this test.
          # host_hash[:ip] is the IP address of the host normally used for
          #   ssh access via vagrant user
          # host_hash[:ssh] has the ssh config setup required to get into the host
          #   behind the NAT
          Net::SSH.start(client.host_hash[:ip], 'vagrant', client.host_hash[:ssh]) do |ssh|
            puts ssh.exec!('find')
          end
          wait_for_log_message(server, remote_log, 'Accepted publickey for')
          result = on(server, "grep 'Accepted publickey for' #{remote_log}")
          log_line = result.stdout.split("\n").last
          match = log_line.match(/Accepted publickey for vagrant from (\S+) port (\S+) /)
          fail("sshd line match failed: #{log_line}") if match.nil?
          expect(log_line).to match(/"ssh_status":"Accepted"/)
          expect(log_line).to match(/"ssh_auth_type":"publickey"/)
          expect(log_line).to match(/"user":"vagrant"/)
          expect(log_line).to match(/"src_ip":"#{match[1]}"/)
          expect(log_line).to match(/"src_port":"#{match[2]}"/)
          expect(log_line).to match(/"src_protocol":"ssh2"/)
        end

        it 'should filter invalid sshd login messages' do
          begin
            Net::SSH.start(client.host_hash[:ip], 'bad_guy', client.host_hash[:ssh])
          rescue Net::SSH::AuthenticationFailed => e
          end
          wait_for_log_message(server, remote_log, 'user bad_guy from')
          result = on(server, "grep 'user bad_guy from' #{remote_log}")
          log_line = result.stdout.split("\n").last
          ip = log_line.match(/from ([0-9.]+)[" ]/)[1]
          expect(log_line).to match(/"user":"bad_guy"/)
          expect(log_line).to match(/"src_ip":"#{ip}"/)
        end

        # The proposed tests that follow require setup that may be better
        # suited to an integration test with a real SIMP server and clients.
        # One of the tests was mocked with example messages, but that test
        # won't tell us when our filter has been broken by a change in
        # an application's log messages that we are parsing.
        it 'should filter audispd log messages'
        it 'should filter httpd log messages'
        it 'should filter puppet agent log messages'
        it 'should filter puppet server log messages'
        it 'should filter slapd audit log messages'

        it 'should filter sudosh log messages' do
          # FIXME This simulates successful sudosh messages with message content
          # taken from an el7 server.  To really test this, need to install
          # sudosh puppet module, configure a user to have sudosh privileges
          # and then execute 'sudo sudosh' by that user.  Also need to execute
          # 'sudo sudosh' by an unauthorized user to see if that also triggers
          # an error message that get filtered.
          messages = [
            'starting session for user1 as root, session id 1494001737, tty /dev/pts/4, shell /bin/bash',
            '[1494001737]: msg: user1:root: #033]0;root@blade08:~#007#033[?1034h[root@blade08 ~]# ls#015#012anaconda-ks.cfg  puppet.bootstrap.log  #033[0m#033[38;5;34msimp6.sh#033[0m#015#012#033]0;root@blade08:~#007[root@blade08 ~]# which puppet#015#012/opt/puppetlabs/bin/puppet#015#012#033]0;root@blade08:~#007[root@blade08 ~]# exit#015#012logout#015',
            '[1494001737]: time: user1:root: 0.368416 19#012:0.101542 8#012:0.000358 18#012:1.603391 1#012:0.199875 1#012:0.175738 2#012:0.000184 67#012:0.002871 19#012:0.000577 18#012:11.996672 1#012:0.103868 1#012:0.095862 1#012:0.224277 1#012:0.120101 1#012:0.119602 1#012:0.120125 1#012:0.079826 1#012:0.056011 1#012:0.208254 1#012:0.480061 1#012:0.120003 1#012:0.135900 2#012:0.000177 28#012:0.002864 19#012:0.000455 18#012:0.756906 1#012:0.199762 1#012:0.119835 1#012:0.280119 1#012:0.464102 2#012:0.000194 8#012:',
            'stopping session for user1 as root, tty /dev/pts/4, shell /bin/bash'
          ]
          messages.each { |log_msg| on client, "logger -t sudosh '#{log_msg}'" }
          wait_for_log_message(server, remote_log, 'stopping session for user1 as root')

          # verify starting session message is filtered
          result = on(server, "grep 'starting session for user1 as root' #{remote_log}")
          log_line = result.stdout.split("\n").last
          expect(log_line).to match(/"user":"user1"/)
          expect(log_line).to match(/"sudosh_session_id":"1494001737"/)

          # verify messages containing session id are filtered
          result = on(server, "grep '\\[1494001737\\]: msg: ' #{remote_log}")
          log_line = result.stdout.split("\n").last
          expect(log_line).to match(/"sudosh_session_id":"1494001737"/)
          expect(log_line).to match(/"sudosh_type":"msg"/)
          expect(log_line).to match(/"user":"user1"/)
          expect(log_line).to match(Regexp.escape('"sudosh_message":"#033]0;root@blade08:~#007#033[?1034h[root@blade08 ~]# ls#015#012anaconda-ks.cfg  puppet.bootstrap.log  #033[0m#033[38;5;34msimp6.sh#033[0m#015#012#033]0;root@blade08:~#007[root@blade08 ~]# which puppet#015#012/opt/puppetlabs/bin/puppet#015#012#033]0;root@blade08:~#007[root@blade08 ~]# exit#015#012logout#015'))

          result = on(server, "grep '\\[1494001737\\]: time: ' #{remote_log}")
          log_line = result.stdout.split("\n").last
          expect(log_line).to match(/"sudosh_session_id":"1494001737"/)
          expect(log_line).to match(/"sudosh_type":"time"/)
          expect(log_line).to match(/"user":"user1"/)
          expect(log_line).to match(Regexp.escape('0.368416 19#012:0.101542 8#012:0.000358 18#012:1.603391 1#012:0.199875 1#012:0.175738 2#012:0.000184 67#012:0.002871 19#012:0.000577 18#012:11.996672 1#012:0.103868 1#012:0.095862 1#012:0.224277 1#012:0.120101 1#012:0.119602 1#012:0.120125 1#012:0.079826 1#012:0.056011 1#012:0.208254 1#012:0.480061 1#012:0.120003 1#012:0.135900 2#012:0.000177 28#012:0.002864 19#012:0.000455 18#012:0.756906 1#012:0.199762 1#012:0.119835 1#012:0.280119 1#012:0.464102 2#012:0.000194 8#012:'))
        end
      end
    end
  end
end
