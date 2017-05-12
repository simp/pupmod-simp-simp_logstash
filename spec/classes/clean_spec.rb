require 'spec_helper'

describe 'simp_logstash::clean' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }

      context 'with default parameters' do
        let(:params) { {} }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::clean') }

        it { 
          cmd = []
          cmd << '/usr/bin/curator_cli' <<
                '--host 127.0.0.1' <<
                '--port 9199' <<
                '--timeout 30' <<
                '--logfile /var/log/logstash/curator_clean.log' <<
                'delete_indices' <<
                '--ignore_empty_list' <<
                '--filter_list \'[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":356},{"filtertype":"pattern","kind":"prefix","value":"logstash-"}]\''

          is_expected.to create_cron('logstash_index_cleanup').with({
            :ensure   => 'present',
            :command  => cmd.join(' '),
            :hour     => 1,
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
        it { is_expected.to create_class('simp_logstash::clean') }
        it { is_expected.to create_cron('logstash_index_cleanup').with({
          :ensure => 'absent',
        }) }
      end

      context "keep_type='hours' and most parameters different from defaults" do
        let(:params) {{
          :host           => '127.0.1.1',
          :keep_type      => 'hours',
          :keep_amount    => 48,
          :prefix         => 'my-logstash-',
          :port           => 29199,
          :es_timeout     => 60,
          :log_file       => '/var/log/logstash/index_purge.log',
          :cron_hour      => '*',
          :cron_minute    => '*',
          :cron_month     => 1,
          :cron_monthday  => 2,
          :cron_weekday   => 3
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::clean') }
        it { 
          cmd = []
          cmd << '/usr/bin/curator_cli' <<
                '--host 127.0.1.1' <<
                '--port 29199' <<
                '--timeout 60' <<
                '--logfile /var/log/logstash/index_purge.log' <<
                'delete_indices' <<
                '--ignore_empty_list' <<
                '--filter_list \'[{"filtertype":"age","source":"creation_date","direction":"older","unit":"hours","unit_count":48},{"filtertype":"pattern","kind":"prefix","value":"my-logstash-"}]\''

          is_expected.to create_cron('logstash_index_cleanup').with({
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

      context "keep_type='space'" do
        let(:params) {{
          :keep_type => 'space',
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::clean') }
        it { 
          cmd = []
          cmd << '/usr/bin/curator_cli' <<
                '--host 127.0.0.1' <<
                '--port 9199' <<
                '--timeout 30' <<
                '--logfile /var/log/logstash/curator_clean.log' <<
                'delete_indices' <<
                '--ignore_empty_list' <<
                '--filter_list \'[{"filtertype":"space","disk_space":356},{"filtertype":"pattern","kind":"prefix","value":"logstash-"}]\''

          is_expected.to create_cron('logstash_index_cleanup').with({
            :ensure   => 'present',
            :command  => cmd.join(' '),
            :hour     => 1,
            :minute   => 15,
            :month    => '*',
            :monthday => '*',
            :weekday  => '*',
            :require  => 'Class[Simp_logstash::Curator]'
          }) 
        }
      end
    end
  end
end
