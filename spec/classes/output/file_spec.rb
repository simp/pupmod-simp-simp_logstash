require 'spec_helper'

describe 'simp_logstash::output::file' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      if "#{facts[:operatingsystem]}-#{facts[:operatingsystemmajrelease]}" == 'OracleLinux-6'
        let(:hieradata) { 'oel6' }
      end

      context 'with default parameters' do
        let(:params) { {} }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::output::file') }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-30-file.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  file {
    path => "/var/log/logstash/file_output.log"
    id => "simp_file"
  }
}
EOM
        ) }
      end

      context 'with optional template parameters except content' do
        let(:params) { {
          :codec             => 'json',
          :create_if_deleted => true,
          :dir_mode          => 0750,
          :enable_metric     => false,
          :file_mode         => 0640,
          :filename_failure  => 'filepath_failures_backup',
          :flush_interval    => 0,
          :gzip              => true,
          :workers           => 3
        } }

        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-30-file.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  file {
    path => "/var/log/logstash/file_output.log"
    codec => "json"
    create_if_deleted => true
    dir_mode => 0750
    enable_metric => false
    file_mode => 0640
    filename_failure => filepath_failures_backup
    flush_interval => 0
    gzip => true
    id => "simp_file"
    workers => 3
  }
}
EOM
        ) }
      end

      context 'with content template parameter' do
        let(:params) { {
          :content => <<EOM
output {
syslog { }
}
EOM
        } }

        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-30-file.conf').with_content(<<EOM
output {
syslog { }
}
EOM
        ) }
      end
    end
  end
end
