require 'spec_helper'

describe 'simp_logstash::input::syslog' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts){ facts }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::input::syslog') }
        it { is_expected.to create_sysctl('net.ipv4.conf.all.route_localnet') }

        context 'with listen_plain_tcp=true' do
          let (:params) { {:listen_plain_tcp => true} }
          it { is_expected.to create_sysctl('net.ipv4.conf.all.route_localnet') }
        end

        context 'with listen_plain_udp=true' do
          let (:params) { {:listen_plain_udp => true} }
          it { is_expected.to create_iptables_rule('udp_logstash_syslog_redirect')}
        end

        context 'with manage_sysctl=false' do
          let (:params) { {:manage_sysctl => false} }
          it { is_expected.to_not create_sysctl('net.ipv4.conf.all.route_localnet') }
        end
      end
    end
  end
end
