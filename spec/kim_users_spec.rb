require 'kim_client_switcher'

include KimClientSwitcher
KIMCLIENT = send(:kim_user_client)

def create_kim_client
  path = File.expand_path('../config/test.json', File.dirname(__FILE__))
  KIMCLIENT.new(config: path)
end

describe KIMCLIENT do
  let(:kim) { create_kim_client }
  let(:e) { kim.top_user }

  describe '#ping' do
    it 'returns true' do
      expect(kim.ping).to eq(true)
    end
  end

  describe '#admin_users' do
    let(:admin_ids) { kim.admin_users.select{ |i| i =~ /^\d+$/ } }

    it 'returns not empty array' do
      expect(admin_ids).not_to be_empty
    end

    it 'returns active admin ids' do
      admin_ids.each do |id|
        user = kim.find_user_by_id(id)
        expect(user).not_to be_nil
        expect(user['role']).to eq('admin')
      end
    end
  end

  describe '#top_user' do
    it 'returns first Kim users' do
      expect(kim.top_user).not_to be_nil
    end
  end

  describe '#find_user' do
    let(:r) { kim.find_user(e['username']) }

    it 'find a user by username' do
      expect(r).to eq(e)
    end
  end

  describe '#find_user_by_id' do
    let(:r) { kim.find_user_by_id(e['schoolId']) }

    it 'find a user by username' do
      expect(r).to eq(e)
    end
  end

  describe '#role_ids' do
    it 'returns role ids of administrators' do
      expect(kim.role_ids).to eq(["10028", "63"])
    end
  end

  describe '#users' do
    it 'returns all Kim users' do
      # NOTE takes a while
      #expect(kim.users).not_to be_empty
    end
  end

  describe '#find_new_group_members' do
    let(:groups) { ['UH KC Users', 'UH COI Users'] }
    let(:within_days) { 365 }

    # NOTE if no group member is created within within_days, this test will fail
    #      make within_days enough large
    it 'returns users that were inserted into KC/COI groups' do
      expect(kim.find_new_group_members(groups, within_days)).not_to be_empty
    end
  end
end
