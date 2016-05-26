if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  require_relative '../lib/kim_users_jdbc'
  TARGET = KimUsersJdbc
else
  require_relative '../lib/kim_users'
  TARGET = KimUsers
end

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
end
