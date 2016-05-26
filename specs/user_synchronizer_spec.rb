require_relative '../lib/user_synchronizer'

describe UserSynchronizer do
  let(:kim_admins) {
    ["admin", "15340606", "21550012", "10953327", "20781608", "11363208"]
  }
  let(:kim_users) {
    [
      {"schoolId"=>"11111111", "username"=>"aaaaaa", "active"=>"Y",
       "firstName"=>"Mary", "lastName"=>"Turpin", "name"=>"Turpin, Mary",
       "email"=>"aaaaaa@gmail.com", "role"=>"user"},
      {"schoolId"=>"22222222", "username"=>"bbbbbb", "active"=>"N",
       "firstName"=>"Brent", "lastName"=>"Stone", "name"=>"Stone, Brent",
       "email"=>"bbbbbb@gmail.com", "role"=>"user"},
      {"schoolId"=>"33333333", "username"=>"cccccc", "active"=>"Y",
       "firstName"=>"Alexis", "lastName"=>"Rico", "name"=>"Rico, Alexis",
       "email"=>"cccccc@gmail.com", "role"=>"user"},
      {"schoolId"=>"44444444", "username"=>"dddddd", "active"=>"Y",
       "firstName"=>"Matthew", "lastName"=>"Renner", "name"=>"Renner, Matthew",
       "email"=>"dddddd@gmail.com", "role"=>"user"},
      {"schoolId"=>"55555555", "username"=>"eeeeee", "active"=>"Y",
       "firstName"=>"Sarah", "lastName"=>"Miller", "name"=>"Miller, Sarah",
       "email"=>"eeeeee@gmail.com", "role"=>"user"}
    ]
  }
  let(:kim_users_updated) {
    [
      {"schoolId"=>"11111111", "username"=>"aaaaaa", "active"=>"Y",
       "firstName"=>"Mary", "lastName"=>"Turpin", "name"=>"Turpin, Mary",
       "email"=>"xxxxx@gmail.com", "role"=>"user"},
      {"schoolId"=>"22222222", "username"=>"bbbbbb", "active"=>"N",
       "firstName"=>"Brent", "lastName"=>"Stone", "name"=>"Stone, Brent",
       "email"=>"bbbbbb@gmail.com", "role"=>"user"},
      {"schoolId"=>"33333333", "username"=>"cccccc", "active"=>"Y",
       "firstName"=>"Alexis", "lastName"=>"Xxxx", "name"=>"Rico, Alexis",
       "email"=>"cccccc@gmail.com", "role"=>"user"},
      {"schoolId"=>"44444444", "username"=>"dddddd", "active"=>"N",
       "firstName"=>"Matthew", "lastName"=>"Renner", "name"=>"Renner, Matthew",
       "email"=>"dddddd@gmail.com", "role"=>"user"},
      {"schoolId"=>"55555555", "username"=>"eeeeee", "active"=>"Y",
       "firstName"=>"Sarah", "lastName"=>"Miller", "name"=>"Miller, Sarah",
       "email"=>"eeeeee@gmail.com", "role"=>"user"},
      {"schoolId"=>"66666666", "username"=>"ffffff", "active"=>"Y",
       "firstName"=>"Sarah", "lastName"=>"Connor", "name"=>"Connor, Sarah",
       "email"=>"ffffff@gmail.com", "role"=>"user"}
    ]
  }
  let(:core_users) {
    [
      {"updatedAt"=>1462993066000, "createdAt"=>1462993066000,
       "name"=>nil, "firstName"=>nil, "lastName"=>nil, "email"=>nil,
       "username"=>"admin", "role"=>"admin", "schoolId"=>nil, "phone"=>nil,
       "scopesCm"=>nil, "id"=>"573380aac52ccac610f606d0",
      "displayName"=>"admin", "ssoId"=>nil},
      {"updatedAt"=>1463004767000, "createdAt"=>1463004767000,
       "name"=>"Gouldner", "firstName"=>"Ronald", "lastName"=>"Gouldner",
       "email"=>"gouldner@hawaii.edu", "username"=>"Gouldner", "role"=>"admin",
       "schoolId"=>nil, "phone"=>nil, "scopesCm"=>nil,
       "id"=>"5733ae5f5985f6f30f6c4f33", "displayName"=>"Gouldner", "ssoId"=>nil}
    ]
  }
  let(:core_users_updated) {
    [
      {"updatedAt"=>1462993066000, "createdAt"=>1462993066000,
       "name"=>nil, "firstName"=>nil, "lastName"=>nil, "email"=>nil,
       "username"=>"admin", "role"=>"admin", "schoolId"=>nil, "phone"=>nil,
       "scopesCm"=>nil, "id"=>"573380aac52ccac610f606d0",
      "displayName"=>"admin", "ssoId"=>nil},
      {"updatedAt"=>1463004767000, "createdAt"=>1463004767000,
       "name"=>"Gouldner", "firstName"=>"Ronald", "lastName"=>"Gouldner",
       "email"=>"gouldner@hawaii.edu", "username"=>"Gouldner", "role"=>"admin",
       "schoolId"=>nil, "phone"=>nil, "scopesCm"=>nil,
       "id"=>"5733ae5f5985f6f30f6c4f33", "displayName"=>"Gouldner", "ssoId"=>nil},
      {"schoolId"=>"11111111", "username"=>"aaaaaa", "active"=>"Y",
       "firstName"=>"Mary", "lastName"=>"Turpin", "name"=>"Turpin, Mary",
       "email"=>"aaaaaa@gmail.com", "role"=>"user"},
      {"schoolId"=>"33333333", "username"=>"cccccc", "active"=>"Y",
       "firstName"=>"Alexis", "lastName"=>"Rico", "name"=>"Rico, Alexis",
       "email"=>"cccccc@gmail.com", "role"=>"user"},
      {"schoolId"=>"44444444", "username"=>"dddddd", "active"=>"Y",
       "firstName"=>"Matthew", "lastName"=>"Renner", "name"=>"Renner, Matthew",
       "email"=>"dddddd@gmail.com", "role"=>"user"},
      {"schoolId"=>"55555555", "username"=>"eeeeee", "active"=>"Y",
       "firstName"=>"Sarah", "lastName"=>"Miller", "name"=>"Miller, Sarah",
       "email"=>"eeeeee@gmail.com", "role"=>"user"}
    ]
  }
  let(:expected_user) {
    {
      'schoolId'=>'77777777', 'username'=>'johnconnor', 'active'=>'Y',
      'firstName'=>'John', 'lastName'=>'Connor', 'name'=>'Connor, John',
      'email'=>'johnconnor@gmail.com', 'role'=>'user'
    }
  }

  let(:sync) { UserSynchronizer.new }
  let(:config) { './config/test.json' }

  before do
    allow(sync).to receive(:kim_users).and_return(kim_users, kim_users_updated)
    #allow(sync).to receive(:kim_admins).and_return(kim_admins)
    allow(sync).to receive(:core_users).and_return(core_users, core_users_updated)
    allow(sync).to receive(:core_add_user).and_return(true)
    allow(sync).to receive(:core_update_user).and_return(true)
    allow(sync).to receive(:core_delete_user).and_return(true)
  end

  describe '#run' do
    it 'synchronizes users correctly' do
      expect(sync.run(config)).to eq({
        total: 5,
        added: 4,
        updated: 0,
        removed: 0,
        same: 0,
        inactive: 1,
        add_errors: 0,
        update_errors: 0,
        remove_errors: 0,
      })

      expect(sync.run(config)).to eq({
        total: 6,
        added: 1,
        updated: 2,
        removed: 1,
        same: 1,
        inactive: 1,
        add_errors: 0,
        update_errors: 0,
        remove_errors: 0,
      })
    end
  end
end
