require 'spec_helper'

shared_examples_for 'a simp_logstash::input::tcp_json_tls' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('simp_logstash::input::tcp_json_tls') }
  it { is_expected.to create_class('simp_logstash::config::pki') }
end

describe 'simp_logstash::input::tcp_json_tls' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      if "#{facts[:operatingsystem]}-#{facts[:operatingsystemmajrelease]}" == 'OracleLinux-6'
        let(:hieradata) { 'oel6' }
      end

      context 'with simp_logstash::firewall=false' do
        let(:pre_condition){<<EOM
class{'simp_logstash':
  firewall => false,
  trusted_nets => [ '1.2.0.0/16' ]
}
EOM
        }

        context 'with default parameters' do
          let(:params) { {} }
          it_should_behave_like 'a simp_logstash::input::tcp_json_tls'
          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_json_tls.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  tcp {
    codec => "json"
    host => "0.0.0.0"
    port => 5140
    id => "simp_tcp_json_tls"
    type => "json"
    ssl_enable => true
    ssl_verify => true
    ssl_extra_chain_certs => [ "/etc/pki/simp_apps/logstash/x509/cacerts/cacerts.pem" ]
    ssl_key   => "/etc/pki/simp_apps/logstash/x509/private/foo.example.com.pem"
    ssl_cert  => "/etc/pki/simp_apps/logstash/x509/public/foo.example.com.pub"
  }
}
EOM
          ) }

          it { is_expected.to_not create_class('iptables') }
        end

        context 'with optional template parameters except content' do
          let(:params) { {
            :add_field      => { 'received_at' => '%{@timestamp}', 'received_from' => '%{host}' },
            :enable_metric  => false,
            :lstash_tags    => [ 'my_tag1', 'my_tag2' ],
            :proxy_protocol => false,
          } }
          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_json_tls.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  tcp {
    add_field => {
      "received_at" => "%{@timestamp}"
      "received_from" => "%{host}"
    }
    codec => "json"
    host => "0.0.0.0"
    port => 5140
    proxy_protocol => false
    id => "simp_tcp_json_tls"
    tags => [ "my_tag1", "my_tag2" ]
    type => "json"
    enable_metric => false
    ssl_enable => true
    ssl_verify => true
    ssl_extra_chain_certs => [ "/etc/pki/simp_apps/logstash/x509/cacerts/cacerts.pem" ]
    ssl_key   => "/etc/pki/simp_apps/logstash/x509/private/foo.example.com.pem"
    ssl_cert  => "/etc/pki/simp_apps/logstash/x509/public/foo.example.com.pub"
  }
}
EOM
          ) }

          it { is_expected.to_not create_class('iptables') }
        end

        context 'with content template parameter' do
          let(:params) { {
            :content => <<EOM
input {
  syslog { }
}
EOM
          } }

          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-tcp_json_tls.conf').with_content(<<EOM
input {
  syslog { }
}
EOM
          ) }
        end
      end

      context 'with simp_logstash::firewall=true' do
        let(:pre_condition){<<EOM
class{'simp_logstash':
  firewall => true,
  trusted_nets => [ '1.2.0.0/16' ]
}
EOM
        }

        let(:params) { {} }
        it_should_behave_like 'a simp_logstash::input::tcp_json_tls'
        it { is_expected.to create_class('iptables') }
        it { is_expected.to create_iptables__listen__tcp_stateful('allow_tcp_json_tls') }
      end
    end
  end
end
