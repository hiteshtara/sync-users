require 'task_runner'

class MockTask < TaskRunner
  def do_task(args = {}); end
end

describe MockTask do
  let(:sync) { MockTask.new }

  describe '#run' do
    it 'runs a task' do
      expect { sync.run }.not_to raise_error(Exception)
    end
  end

  describe '#params' do
    before { sync.set_env('./config/example.json') }

    it 'returns the current configuration in Hash' do
      expect(sync.params).to eq(
        {
          'log' => 'log/example.log',
          'sync_errors' => 'log/sync.errors',
          'log_level' => 'INFO',
          'api_scheme'=>'http',
          'api_host'=>'localhost',
          'api_port'=>'3000',
          'api_key' =>
            'ABCDEFGHIJKLMNOPQSTUVWXYZ012345678.' +
            'abcdefghijklmnopqrstuvwxyz012345678' +
            '9ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567' +
            '89abcdefghijklmnopqrstuvwxyz0123456' +
            '789ABCD.A1aB2bC3cD4dE5eF6fG7gH8hI9i' +
            'J0jK1k-AbCdEfG',
          'db_user'=>'USERID',
          'db_pass'=>'PASSWORD',
          'db_host'=>'localhost',
          'db_port'=>'1521',
          'db_sid'=>'ORACLE-SID',
          'target_user_groups' => ['UH KC Users', 'UH COI Users']
        }
      )
    end
  end
end
