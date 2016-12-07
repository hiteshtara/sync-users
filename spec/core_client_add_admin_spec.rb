require 'core_client'
require 'user_synchronizer/user_util'

include UserSynchronizer::UserUtil

TESTDATA = {
  'schoolId'=>'99999999', 'username'=>'yyyyyyyy', 'active'=>'Y',
  'firstName'=>'Barack', 'lastName'=>'Obama', 'name'=>'Obama, Barack',
  'email'=>'barackobama@gmail.com', 'role'=>'admin'
}

def delete_test_user(client)
  res = client.get_user(TESTDATA['schoolId'])
  return unless res
  if r = res.last
    if r['firstName'] == TESTDATA['firstName'] &&
       r['lastName'] == TESTDATA['lastName'] &&
       r['username'] == TESTDATA['username']
      id = r['id']
      #puts "Deleting Test User: #{r['username']} #{r['schoolId']} #{r['email']} '#{id}'"
      client.delete_user(id) if id
    else
      puts 'Do not Delete Test User'
      p r
    end
  end
end

describe CoreClient do
  let(:url) { 'http://localhost:3000/api/v1/users' }
  let(:user) { TESTDATA }

  describe 'Admin insert' do
    context 'with admin token' do
      let(:config) {
        File.expand_path('../config/test.json', File.dirname(__FILE__))
      }
      let(:cc) { CoreClient.new(config: config) }

      before { delete_test_user(cc) }
      after { delete_test_user(cc) }

      it 'inserts an admin user' do
        cur = cc.add_user(user)
        expect(compare_user(cur, user)).to eq(true)
      end
    end

    context 'with service token' do
      let(:config) {
        File.expand_path('../config/test_service_token.json', File.dirname(__FILE__))
      }
      let(:cc) { CoreClient.new(config: config) }

      before { delete_test_user(cc) }
      after { delete_test_user(cc) }

      it 'inserts a normal user' do
        cur = cc.add_user(user)
        expect(cur['role']).to eq('user')
      end
    end
  end
end
