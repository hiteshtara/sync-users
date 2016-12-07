require 'core_client'
require 'user_synchronizer/user_util'

include UserSynchronizer::UserUtil

def delete_user(client, school_id)
  res = client.get_user(school_id)
  return unless res
  if r = res.last
    if r['role'] == 'admin'
      puts 'Do not delete admin'
    else
      id = r['id']
      puts "Deleting User: #{r['username']} #{r['schoolId']} #{r['email']} '#{id}'"
      client.delete_user(id) if id
    end
  end
end

describe CoreClient do
  let(:config) {
    File.expand_path('../config/test_service_token.json', File.dirname(__FILE__))
  }
  let(:cc) { CoreClient.new(config: config) }
  let(:url) { 'http://localhost:3000/api/v1/users' }
  let(:user) {
    {
      'schoolId'=>'66666666', 'username'=>'zzzzzzzzzz', 'active'=>'Y',
      'firstName'=>'Sarah', 'lastName'=>'Connor', 'name'=>'Connor, Sarah',
      'email'=>'sarac@gmail.com', 'role'=>'user'
    }
  }
  let(:updated_user) { user.merge('email' => 'xxxx@hawaii.edu') }
  let(:user_attrs) { user.keys }

  describe '#get_users' do
    it 'returns array of users' do
      expect(cc.get_users.length > 0).to eq(true)
    end
  end

  describe 'REST actions' do
    it 'does CRUD actions correctly' do
      delete_user(cc, user['schoolId'])
      cur = cc.add_user(user)
      expect(cur).not_to be_nil
      expect(compare_user(cur, user)).to eq(true)
      uid = cur['id']
      cur = cc.get_user_by_id(uid)
      expect(cur).not_to be_nil
      expect(compare_user(cur, user)).to eq(true)
      cur = cc.update_user(uid, updated_user)
      expect(cur).not_to be_nil
      expect(compare_user(cur, updated_user)).to eq(true)
      cur = cc.get_user_by_id(uid)
      expect(compare_user(cur, updated_user)).to eq(true)
      cc.delete_user(uid)
      cur = cc.get_user_by_id(uid)
      expect(cur).to be_nil
    end
  end
end
