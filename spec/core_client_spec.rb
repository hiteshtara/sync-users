require 'core_client'

def compare(a, b)
  return false if a.nil? || b.nil?
  a['username'] == b['username'] && 
  a['schoolId'] == b['schoolId'] && 
  a['email'].downcase == b['email'].downcase && 
  a['firstName'].strip == b['firstName'].strip && 
  a['lastName'].strip == b['lastName'].strip && 
  a['name'].strip == b['name'].strip && 
  a['role'] == b['role']
end

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
    File.expand_path('../config/test.json', File.dirname(__FILE__))
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
      expect(compare(cur, user)).to eq(true)
      uid = cur['id']
      cur = cc.get_user_by_id(uid)
      expect(compare(cur, user)).to eq(true)
      cur = cc.update_user(uid, updated_user) 
      expect(compare(cur, updated_user)).to eq(true)
      cur = cc.get_user_by_id(uid)
      expect(compare(cur, updated_user)).to eq(true)
      cc.delete_user(uid)
      cur = cc.get_user_by_id(uid)
      expect(cur).to be_nil
    end
  end

  describe '#url' do
    context 'without params' do
      it 'returns the url of a specified resource' do
        expect(cc.url('users')).to eq(url)
      end 
    end

    context 'with params' do
      it 'returns the url of a specified resource' do
        expect(cc.url('users', limit: 1000, q: 'abc')).to eq(url + '?limit=1000&q=abc')
      end 
    end

    context 'with params including id' do
      it 'returns the url of a specified resource' do
        expect(cc.url('users', id: '12345', limit: 1000, q: 'abc')).to eq(url + '/12345?limit=1000&q=abc')
      end 
    end

    context 'with params including only id' do
      it 'returns the url of a specified resource' do
        expect(cc.url('users', id: '12345')).to eq(url + '/12345')
      end 
    end
  end

  describe '#base_url' do
    context 'without option' do
      let(:cc) { CoreClient.new }

      it 'returns base url of api' do
        expect(cc.base_url).to eq('http://localhost:3000/api/v1')
      end 
    end

    context 'with option' do
      let(:opt) { { 
        'api_scheme' => 'https',
        'api_host' => 'www.hawaii.edu',
        'api_port' => '9999',
        'api_key' => 'aaaaaaaaaaaaaaaaaaaaaa',
      }}
      let(:cc) { CoreClient.new(opt) }

      it 'returns base url of api' do
        expect(cc.base_url).to eq('https://www.hawaii.edu:9999/api/v1')
      end 
    end
  end

  describe '.new' do
    context 'without options' do
      let(:cc) { CoreClient.new }

      it 'uses default options' do
        expect(cc.scheme).to eq('http')
        expect(cc.host).to eq('localhost')
        expect(cc.port).to eq('3000')
        expect(cc.api_key).to eq(nil)
      end
    end

    context 'with options' do
      let(:opt) { { 
        'api_scheme' => 'https',
        'api_host' => 'www.hawaii.edu',
        'api_port' => '9999',
        'api_key' => 'aaaaaaaaaaaaaaaaaaaaaa',
      }}
      let(:cc) { CoreClient.new(opt) }

      it 'uses default options' do
        expect(cc.scheme).to eq('https')
        expect(cc.host).to eq('www.hawaii.edu')
        expect(cc.port).to eq('9999')
        expect(cc.api_key).to eq('aaaaaaaaaaaaaaaaaaaaaa')
      end
    end
  end
end
