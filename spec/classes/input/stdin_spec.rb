require 'spec_helper'

describe 'simp_logstash::input::stdin' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }

      context 'with default parameters' do
        let(:params) { {} }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::input::stdin') }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-stdin.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  stdin {
    id => "simp_stdin"
    type => "simp_stdin"
  }
}
EOM
        ) }

        it { is_expected.to_not create_class('iptables') }
      end

      context 'with optional template parameters except content' do
        let(:params) { {
          :add_field      => { 'received_at' => '%{@timestamp}', 'received_from' => '%{host}' },
          :codec          => 'json',
          :enable_metric  => false,
          :lstash_tags    => [ 'my_tag1', 'my_tag2' ],
        } }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-stdin.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

input {
  stdin {
    add_field => {
      "received_at" => "%{@timestamp}"
      "received_from" => "%{host}"
    }

    codec => "json"
    enable_metric => false
    id => "simp_stdin"
    type => "simp_stdin"
    tags => [ "my_tag1", "my_tag2" ]
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
  stdin { }
}
EOM
        } }

        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-10_input-50-stdin.conf').with_content(<<EOM
input {
  stdin { }
}
EOM
        ) }
      end
    end
  end
end
