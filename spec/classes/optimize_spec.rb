require 'spec_helper'

describe 'simp_logstash::optimize' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      if "#{facts[:operatingsystem]}-#{facts[:operatingsystemmajrelease]}" == 'OracleLinux-6'
        let(:hieradata) { 'oel6' }
      end

      context 'with default parameters' do
        let(:params) { {} }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::optimize') }

        it { 
          cmd = []
          cmd << '/usr/bin/curator_cli' <<
                '--host 127.0.0.1' <<
                '--port 9199' <<
                '--timeout 21600' <<
                '--logfile /var/log/logstash/curator_optimize.log' <<
                'forcemerge' <<
                '--max_num_segments 2' <<
                '--ignore_empty_list' <<
                '--filter_list \'[{"filtertype":"pattern","kind":"prefix","value":"logstash-"}]\''

          is_expected.to create_cron('logstash_index_optimize').with({
            :ensure   => 'present',
            :command  => cmd.join(' '),
            :hour     => 3,
            :minute   => 15,
            :month    => '*',
            :monthday => '*',
            :weekday  => '*',
            :require  => 'Class[Simp_logstash::Curator]'
          }) 
        }
      end

      context "ensure='absent'" do
        let(:params) {{
          :ensure => 'absent'
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::optimize') }
        it { is_expected.to create_cron('logstash_index_optimize').with({
          :ensure => 'absent',
        }) }
      end

      context "most parameters different from defaults" do
        let(:params) {{
          :host             => '127.0.1.1',
          :prefix           => 'my-logstash-',
          :port             => 29199,
          :es_timeout       => 1000,
          :max_num_segments => 5,
          :log_file         => '/var/log/logstash/index_forcemerge.log',
          :cron_hour        => '*',
          :cron_minute      => '*',
          :cron_month       => 1,
          :cron_monthday    => 2,
          :cron_weekday     => 3
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::optimize') }
        it { 
          cmd = []
          cmd << '/usr/bin/curator_cli' <<
                '--host 127.0.1.1' <<
                '--port 29199' <<
                '--timeout 1000' <<
                '--logfile /var/log/logstash/index_forcemerge.log' <<
                'forcemerge' <<
                '--max_num_segments 5' <<
                '--ignore_empty_list' <<
                '--filter_list \'[{"filtertype":"pattern","kind":"prefix","value":"my-logstash-"}]\''

          is_expected.to create_cron('logstash_index_optimize').with({
            :ensure   => 'present',
            :command  => cmd.join(' '),
            :hour     => '*',
            :minute   => '*',
            :month    => 1,
            :monthday => 2,
            :weekday  => 3,
            :require  => 'Class[Simp_logstash::Curator]'
          }) 
        }
      end
    end
  end
end
