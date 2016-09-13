require 'spec_helper'

describe 'simp_logstash' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts){ facts }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash') }
        it { is_expected.to create_simp_logstash__input('syslog') }

        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-10_input-50-syslog.conf'
          ).without_content(/=>\s*$/)
        }

        it { is_expected.to create_class('iptables') }

        it { is_expected.to_not create_iptables_rule('tcp_logstash_syslog_redirect')}
        it { is_expected.to_not create_iptables_rule('udp_logstash_syslog_redirect')}
        it { is_expected.to_not create_sysctl__value('net.ipv4.conf.all.route_localnet')}
        it { is_expected.to_not create_class('sysctl') }

        it { is_expected.to create_class('stunnel') }
        it { is_expected.to create_tcpwrappers__allow('logstash_syslog') }
        it { is_expected.to create_tcpwrappers__allow('logstash_syslog_tls') }
        it { is_expected.to create_stunnel__add('logstash_syslog_tls') }

        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf'
          ).without_content(/=>\s*$/)
        }

        it "creates file '/etc/logstash/conf.d/simp-logstash-20_filter-50-audispd.conf'"
=begin
# Re-enable this once the audispd filter is fixed
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-20_filter-50-audispd.conf'
          ).with_content(/filter {/)
        }
=end

        it { is_expected.to create_simp_logstash__filter('sshd') }
        it { is_expected.to create_simp_logstash__filter('yum') }
        it { is_expected.to create_simp_logstash__filter('httpd') }
        it { is_expected.to create_simp_logstash__filter('puppet_agent') }
        it { is_expected.to create_simp_logstash__filter('puppet_server') }
        it { is_expected.to create_simp_logstash__filter('slapd_audit') }
        it { is_expected.to create_simp_logstash__output('elasticsearch') }
      end
    end
  end
end
