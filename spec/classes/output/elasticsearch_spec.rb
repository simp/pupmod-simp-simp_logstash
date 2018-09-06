require 'spec_helper'

describe 'simp_logstash::output::elasticsearch' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      if "#{facts[:operatingsystem]}-#{facts[:operatingsystemmajrelease]}" == 'OracleLinux-6'
        let(:hieradata) { 'oel6' }
      end

      context 'with default parameters' do
        let(:params) { {} }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('simp_logstash::output::elasticsearch') }
        it { is_expected.to_not create_class('stunnel') }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  elasticsearch {
    hosts => [ "127.0.0.1:9199" ]
    id => "simp_elasticsearch"
  }
}
EOM
        ) }
      end

      context 'with same host specified for ES host' do
        let(:params) { {
          :host => facts[:fqdn]
        } }

        it { is_expected.to_not create_class('stunnel') }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  elasticsearch {
    hosts => [ "127.0.0.1:9199" ]
    id => "simp_elasticsearch"
  }
}
EOM
       ) }
      end

      context 'with different ES host specified' do
        let(:params) { {
          :host => '8.8.8.8'
        } }
        it { is_expected.to create_class('stunnel') }
        it { is_expected.to create_stunnel__connection('logstash_elasticsearch').with( {
          'connect' => ['8.8.8.8:9200'],
          'accept'  => '127.0.0.1:9200'
        } ) }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  elasticsearch {
    hosts => [ "127.0.0.1:9200" ]
    id => "simp_elasticsearch"
  }
}
EOM
       ) }
      end

      context 'with stunnel_elasticsearch=false and different ES host specified' do
        let(:params) { {
          :stunnel_elasticsearch => false,
          :host                  => '8.8.8.8'
        } }

        it { is_expected.to_not create_class('stunnel') }
        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  elasticsearch {
    hosts => [ "8.8.8.8:9199" ]
    id => "simp_elasticsearch"
  }
}
EOM
       ) }
      end

      context 'with optional template parameters except content' do
        let(:params) { {
          :absolute_healthcheck_path      => true,
          :action                         => 'create',
          :codec                          => 'json',
          :doc_as_upsert                  => true,
          :document_id                    => 'doc-123',
          :document_type                  => 'lstash',
          :enable_metric                  => false,
          :failure_type_logging_whitelist => [
            'document_already_exists_exception',
            'es_rejected_execution_exception'
          ],
          :flush_size                     => 100,
          :healthcheck_path               => '/some/path/to/healthcheck',
          :idle_flush_time                => 2,
          :index                          => 'simp-events-%{+YYY.MM.dd}',
          :manage_template                => false,
          :parameters                     => { 'param1'=> 'value1', 'param2' => 'value2' },
          :parent                         => 'my-parent',
          :path                           => '/some/path',  #is this actually a url?
          :pipeline                       => '%{INGEST_PIPELINE}',
          :pool_max                       => 10,
          :pool_max_per_route             => 2,
          :resurrect_delay                => 3,
          :retry_initial_interval         => 4,
          :retry_max_interval             => 10,
          :retry_on_conflict              => 2,
          :routing                        => 'my-routing-override',
          :script                         => 'update-script',
          :script_lang                    => 'ruby',
          :script_type                    => [ 'indexed', 'file'],
          :script_var_name                => 'simp-event',
          :scripted_upsert                => true,
          :template                       => '/my/path/to/template',
          :template_name                  => 'simp-logstash',
          :template_overwrite             => true,
          :timeout                        => 120,
          :upsert                         => 'document {}',
          :validate_after_inactivity      => 14000,
          :version                        => '1.2',
          :version_type                   => 'internal',
          :workers                        => 3
        } }

        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
# This file managed by Puppet
# Any changes will be overwritten

output {
  elasticsearch {
    absolute_healthcheck_path => true
    action => "create"
    codec => "json"
    doc_as_upsert => true
    document_id => "doc-123"
    document_type => "lstash"
    enable_metric => false
    failure_type_logging_whitelist => [ "document_already_exists_exception", "es_rejected_execution_exception" ]
    flush_size => 100
    healthcheck_path => "/some/path/to/healthcheck"
    hosts => [ "127.0.0.1:9199" ]
    id => "simp_elasticsearch"
    idle_flush_time => 2
    index => "simp-events-%{+YYY.MM.dd}"
    manage_template => false
    parameters => {
      "param1" => "value1"
      "param2" => "value2"
    }
    parent => "my-parent"
    path => "/some/path"
    pipeline => "%{INGEST_PIPELINE}"
    pool_max => 10
    pool_max_per_route => 2
    resurrect_delay => 3
    retry_initial_interval => 4
    retry_max_interval => 10
    retry_on_conflict => 2
    routing => "my-routing-override"
    script => "update-script"
    script_lang => "ruby"
    script_type => "["indexed", "file"]"
    script_var_name => "simp-event"
    scripted_upsert => true
    template => "/my/path/to/template"
    template_name => "simp-logstash"
    template_overwrite => true
    timeout => 120
    upsert => "document {}"
    validate_after_inactivity => 14000
    version => "1.2"
    version_type => "internal"
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
elasticsearch { }
}
EOM
        } }

        it { is_expected.to create_file('/etc/logstash/conf.d/simp-logstash-30_output-50-elasticsearch.conf').with_content(<<EOM
output {
elasticsearch { }
}
EOM
        ) }
      end

    end
  end
end
