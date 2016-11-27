require 'spec_helper'

describe 'simp_logstash' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts){ facts }

      context "on #{os}" do
        let(:params) {{
          :inputs => ['tcp_syslog_tls','syslog','tcp_json_tls'],
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash') }
        it { is_expected.to create_simp_logstash__input('syslog') }
        it { is_expected.to create_simp_logstash__input('tcp_syslog_tls') }
        it { is_expected.to create_simp_logstash__input('tcp_json_tls') }

        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_syslog_tls.conf'
          ).without_content(/=>\s*$/)
        }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-10_input-50-syslog.conf'
          ).without_content(/=>\s*$/)
        }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_json_tls.conf'
          ).without_content(/=>\s*$/)
        }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-20_filter-10-simp_syslog.conf'
          ).without_content(/=>\s*$/)
        }

        it { is_expected.to contain_class('simp_logstash::config::pki') }

        it { is_expected.to create_class('iptables') }

        it { is_expected.to create_iptables_rule('tcp_logstash_syslog_redirect')}

        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf'
          ).without_content(/=>\s*$/)
        }

        it { is_expected.to create_simp_logstash__filter('sshd') }
        it { is_expected.to create_simp_logstash__filter('yum') }
        it { is_expected.to create_simp_logstash__filter('audispd') }
        it { is_expected.to create_simp_logstash__filter('httpd') }
        it { is_expected.to create_simp_logstash__filter('puppet_agent') }
        it { is_expected.to create_simp_logstash__filter('puppet_server') }
=begin
        # Re-enable this once the slapd filter is fixed
        it { is_expected.to create_simp_logstash__filter('slapd_audit') }
=end
        it { is_expected.to create_simp_logstash__output('elasticsearch') }
      end
    end
  end
end
