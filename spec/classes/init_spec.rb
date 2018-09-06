require 'spec_helper'

shared_examples_for 'a simp_logstash profile' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('simp_logstash') }
  it { is_expected.to create_class('java') }
  it { is_expected.to create_class('logstash') }
end


describe 'simp_logstash' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }

      if "#{facts[:operatingsystem]}-#{facts[:operatingsystemmajrelease]}" == 'OracleLinux-6'
        let(:hieradata) { 'oel6' }
      end

      context 'with default parameters' do
        let(:params) { {} }

        it_should_behave_like 'a simp_logstash profile'

        it { is_expected.to create_simp_logstash__input('tcp_syslog_tls') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_syslog_tls.conf'
          )
        }

        # order on this filter is 10
        it { is_expected.to create_simp_logstash__filter('simp_syslog') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-20_filter-10-simp_syslog.conf'
          )
        }

        # order on these filters is 10
        #TODO add in 'slapd_audit' when this filter is fixed
        ['audispd', 'puppet_agent', 'puppet_server', 'sshd', 'sudosh',
            'httpd', 'yum'].each do |filter|
          it { is_expected.to create_simp_logstash__filter(filter) }
          it {
            filename = "/etc/logstash/conf.d/simp-logstash-20_filter-50-#{filter}.conf"
            is_expected.to create_file(filename)
           }
        end

        it { is_expected.to create_simp_logstash__output('elasticsearch') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf'
          )
        }

        # Even though we haven't specfied pki = 'simp' or pki = 'true', the
        # default input (TLS-based) includes the simp_logstash::config::pki
        # class, which in turn, does nothing because pki = false
        it { is_expected.to contain_class('simp_logstash::config::pki') }
        it { is_expected.to_not contain_pki__copy('logstash')}
        it { is_expected.to_not contain_class('pki')}

        it { is_expected.to_not create_class('iptables') }
        it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_tcp_syslog_tls')}
      end

      context "with pki=simp, firewall=ture and custom inputs, outputs, filters" do
        let(:params) {{
          :pki      => 'simp',
          :firewall => true,
          :inputs   => ['stdin','syslog','tcp_json_tls'],
          :filters  => [ 'sudosh', 'simp_syslog' ],
          :outputs  => [ 'file' ]
        }}

        it_should_behave_like 'a simp_logstash profile'
        ['stdin', 'syslog', 'tcp_json_tls'].each do |input|
          it { is_expected.to create_simp_logstash__input(input) }
          it {
            filename = "/etc/logstash/conf.d/simp-logstash-10_input-50-#{input}.conf"
            is_expected.to create_file(filename)
           }
        end

        it { is_expected.to create_simp_logstash__filter('simp_syslog') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-20_filter-10-simp_syslog.conf'
          )
        }

        it { is_expected.to create_simp_logstash__filter('sudosh') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-20_filter-50-sudosh.conf'
          )
        }
        it { is_expected.to create_simp_logstash__output('file') }
        it {
          is_expected.to create_file(
            '/etc/logstash/conf.d/simp-logstash-30_output-30-file.conf'
          )
        }

        it { is_expected.to contain_class('simp_logstash::config::pki') }
        it { is_expected.to contain_class('pki')}
        it { is_expected.to create_file('/etc/pki/simp_apps/logstash/x509')}

        it { is_expected.to create_sysctl('net.ipv4.conf.all.route_localnet') }
        it { is_expected.to create_class('iptables') }
        it { is_expected.to create_iptables_rule('tcp_logstash_syslog_redirect')}
        it { is_expected.to create_iptables__listen__tcp_stateful('logstash_syslog_tcp')}
        it { is_expected.to create_iptables_rule('logstash_syslog_tcp_allow')}
      end
    end
  end
end
