require 'spec_helper'

shared_examples_for 'a simp_logstash::input::syslog' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('simp_logstash::input::syslog') }
  it { is_expected.to create_class('simp_logstash::filter::simp_syslog') }
end

describe 'simp_logstash::input::syslog' do
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
          it_should_behave_like 'a simp_logstash::input::syslog'
          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-syslog.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  tcp {
    host => "127.0.0.1"
    port => 51400
    id => "simp_syslog-tcp"
    type => "simp_syslog"
  }

}
EOM
          ) }

          it { is_expected.to_not create_class('iptables') }
          it { is_expected.to_not create_sysctl('net.ipv4.conf.all.route_localnet') }
        end

        context 'with optional template parameters except content and listen_plain_udp=true' do
          let(:params) { {
            :add_field      => { 'received_at' => '%{@timestamp}', 'received_from' => '%{host}' },
            :codec          => 'json',
            :enable_metric  => false,
            :lstash_tags    => [ 'my_tag1', 'my_tag2' ],
            :proxy_protocol => false,
            :listen_plain_udp => true
          } }
          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-syslog.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  tcp {
    add_field => {
      "received_at" => "%{@timestamp}"
      "received_from" => "%{host}"
    }

    codec => "json"
    host => "127.0.0.1"
    port => 51400
    proxy_protocol => false
    id => "simp_syslog-tcp"
    type => "simp_syslog"
    tags => [ "my_tag1", "my_tag2" ]
    enable_metric => false
  }

  udp {
    add_field => {
      "received_at" => "%{@timestamp}"
      "received_from" => "%{host}"
    }
    codec => "json"
    host => "127.0.0.1"
    port => 51400
    proxy_protocol => false
    id => "simp_syslog-udp"
    type => "simp_syslog"
    tags => [ "my_tag1", "my_tag2" ]
    enable_metric => false
  }
}
EOM
          ) }

          it { is_expected.to_not create_class('iptables') }
          it { is_expected.to_not create_sysctl('net.ipv4.conf.all.route_localnet') }
        end

        context 'with content template parameter' do
          let(:params) { {
            :content => <<EOM
input {
  syslog { }
}
EOM
          } }

          it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-syslog.conf').with_content(<<EOM
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

        context 'with default parameters' do
          let(:params) { {} }
          it_should_behave_like 'a simp_logstash::input::syslog'
          it { is_expected.to create_class('iptables') }
          it { is_expected.to create_sysctl('net.ipv4.conf.all.route_localnet') }
          it { is_expected.to create_iptables_rule('tcp_logstash_syslog_redirect') }
          it { is_expected.to_not create_iptables_rule('udp_logstash_syslog_redirect') }
          it { is_expected.to create_sysctl('net.ipv4.conf.all.route_localnet') }
        end

        context 'with listen_plain_tcp=false' do
          let(:params) { {:listen_plain_tcp => false} }
          it { is_expected.to_not create_iptables_rule('tcp_logstash_syslog_redirect') }
        end

        context 'with listen_plain_udp=true' do
          let(:params) { {:listen_plain_udp => true} }
          it { is_expected.to create_iptables_rule('udp_logstash_syslog_redirect')}
        end

        context 'with manage_sysctl=false' do
          let(:params) { {:manage_sysctl => false} }
          it { is_expected.to_not create_sysctl('net.ipv4.conf.all.route_localnet') }
        end
      end
    end
  end
end
