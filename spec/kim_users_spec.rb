require 'kim_client_switcher'

include KimClientSwitcher
TARGET = send(:kim_user_client)

def create_target
  path = File.expand_path('../config/test.json', File.dirname(__FILE__))
  TARGET.new(config: path)
end

describe TARGET do
  describe '#ping' do
    let(:kim) { create_target }
    it 'returns true' do
      expect(kim.ping).to eq(true)
    end
  end

  describe '#admin_users' do
    let(:kim) { create_target }
    it 'returns MBR_IDs of admin users' do
      expect(kim.admin_users).to eq(["admin", "15340606", "21550012", "10953327", "20781608", "11363208"])
    end
  end

  describe '#top_user' do
    let(:kim) { create_target }
    it 'returns first Kim users' do
      expect(kim.top_user).not_to be_nil
    end
  end

  describe '#role_ids' do
    let(:kim) { create_target }
    it 'returns role ids of administrators' do
      expect(kim.role_ids).to eq(["10028", "63"])
    end
  end

  describe '#users' do
    let(:kim) { create_target }
    it 'returns all Kim users' do
      # NOTE takes a while
      #expect(kim.users).not_to be_empty
    end
  end

  describe '#find_new_group_members' do
    let(:kim) { create_target }
    let(:groups) { ['UH KC Users', 'UH COI Users'] }
    let(:within_days) { 365 }

    # NOTE if no group member is created within within_days, this test will fail
    #      make within_days enough large
    it 'returns users that were inserted into KC/COI groups' do
      expect(kim.find_new_group_members(groups, within_days)).not_to be_empty
    end
  end
end
