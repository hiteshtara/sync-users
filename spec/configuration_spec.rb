require 'configuration'

class TestConfiguration
  include Configuration

  PATH =  File.expand_path('../config/example.json', File.dirname(__FILE__))

  def default_config_path
    PATH
  end
end

describe Configuration do
  context 'without argument' do
    describe '#set_env' do
      subject(:config) { TestConfiguration.new }

      it 'reads default configuration file and set the contents to @params' do
        config.set_env
        expect(config.params).to eq({
          'log' => 'log/example.log',
          'sync_errors' => 'log/sync.errors',
          'log_level' => 'INFO',
          'api_scheme' => 'http',
          'api_host' => 'localhost',
          'api_port' => '3000',
          'api_key' => 'ABCDEFGHIJKLMNOPQSTUVWXYZ012345678.abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789ABCD.A1aB2bC3cD4dE5eF6fG7gH8hI9iJ0jK1k-AbCdEfG',
          'db_user' => 'USERID',
          'db_pass' => 'PASSWORD',
          'db_host' => 'localhost',
          'db_port' => '1521',
          'db_sid' => 'ORACLE-SID',
          'target_user_groups' => ['UH KC Users', 'UH COI Users']
        })
      end
    end

    context 'with required_params defined' do
      describe '#set_env' do
        subject(:config) { TestConfiguration.new }
        before do
          config.instance_eval do
            def required_params
              %w(log api_host api_port)
            end
          end
        end

        it 'reads default configuration file and set only selected to @params' do
          config.set_env
          expect(config.params).to eq({
            'log' => 'log/example.log',
            'api_host' => 'localhost',
            'api_port' => '3000',
          })
        end
      end
    end
  end

  context 'given the path to configuration file' do
    subject(:config) { TestConfiguration.new }

    describe '#set_env' do
      it 'reads the configuration file and set the contents to @params' do
        config.set_env(TestConfiguration::PATH)
        expect(config.params).to eq({
          'log' => 'log/example.log',
          'sync_errors' => 'log/sync.errors',
          'log_level' => 'INFO',
          'api_scheme' => 'http',
          'api_host' => 'localhost',
          'api_port' => '3000',
          'api_key' => 'ABCDEFGHIJKLMNOPQSTUVWXYZ012345678.abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789ABCD.A1aB2bC3cD4dE5eF6fG7gH8hI9iJ0jK1k-AbCdEfG',
          'db_user' => 'USERID',
          'db_pass' => 'PASSWORD',
          'db_host' => 'localhost',
          'db_port' => '1521',
          'db_sid' => 'ORACLE-SID',
          'target_user_groups' => ['UH KC Users', 'UH COI Users']
        })
      end
    end
  end

  context 'given Hash as an argument' do
    subject(:config) { TestConfiguration.new }
    let(:args) { { a: 1, b: 'bbb', c: 333 } }

    describe '#set_env' do
      it 'set the given arguments to @params' do
        config.set_env(args)
        expect(config.params).to eq(args)
      end
    end
  end
end
