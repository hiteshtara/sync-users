
require 'user_synchronizer/base'

describe UserSynchronizer::Base do
  let(:kim_users) {
    [
      {'schoolId'=>'11111111', 'username'=>'aaaaaa', 'active'=>'Y',
       'firstName'=>'Mary', 'lastName'=>'Turpin', 'name'=>'Turpin, Mary',
       'email'=>'aaaaaa@gmail.com', 'role'=>'user'},
      {'schoolId'=>'22222222', 'username'=>'bbbbbb', 'active'=>'N',
       'firstName'=>'Brent', 'lastName'=>'Stone', 'name'=>'Stone, Brent',
       'email'=>'bbbbbb@gmail.com', 'role'=>'user'},
      {'schoolId'=>'33333333', 'username'=>'cccccc', 'active'=>'Y',
       'firstName'=>'Alexis', 'lastName'=>'Rico', 'name'=>'Rico, Alexis',
       'email'=>'cccccc@gmail.com', 'role'=>'user'},
      {'schoolId'=>'44444444', 'username'=>'dddddd', 'active'=>'Y',
       'firstName'=>'Matthew', 'lastName'=>'Renner', 'name'=>'Renner, Matthew',
       'email'=>'dddddd@gmail.com', 'role'=>'user'},
      {'schoolId'=>'55555555', 'username'=>'eeeeee', 'active'=>'Y',
       'firstName'=>'Sarah', 'lastName'=>'Miller', 'name'=>'Miller, Sarah',
       'email'=>'eeeeee@gmail.com', 'role'=>'user'}
    ]
  }
  let(:kim_users_updated) {
    [
      {'schoolId'=>'11111111', 'username'=>'aaaaaa', 'active'=>'Y',
       'firstName'=>'Mary', 'lastName'=>'Turpin', 'name'=>'Turpin, Mary',
       'email'=>'xxxxx@gmail.com', 'role'=>'user'},
      {'schoolId'=>'22222222', 'username'=>'bbbbbb', 'active'=>'N',
       'firstName'=>'Brent', 'lastName'=>'Stone', 'name'=>'Stone, Brent',
       'email'=>'bbbbbb@gmail.com', 'role'=>'user'},
      {'schoolId'=>'33333333', 'username'=>'cccccc', 'active'=>'Y',
       'firstName'=>'Alexis', 'lastName'=>'Xxxx', 'name'=>'Rico, Alexis',
       'email'=>'cccccc@gmail.com', 'role'=>'user'},
      {'schoolId'=>'44444444', 'username'=>'dddddd', 'active'=>'N',
       'firstName'=>'Matthew', 'lastName'=>'Renner', 'name'=>'Renner, Matthew',
       'email'=>'dddddd@gmail.com', 'role'=>'user'},
      {'schoolId'=>'55555555', 'username'=>'eeeeee', 'active'=>'Y',
       'firstName'=>'Sarah', 'lastName'=>'Miller', 'name'=>'Miller, Sarah',
       'email'=>'eeeeee@gmail.com', 'role'=>'user'},
      {'schoolId'=>'66666666', 'username'=>'ffffff', 'active'=>'Y',
       'firstName'=>'Sarah', 'lastName'=>'Connor', 'name'=>'Connor, Sarah',
       'email'=>'ffffff@gmail.com', 'role'=>'user'}
    ]
  }
  let(:core_users) {
    [
      {'updatedAt'=>1462993066000, 'createdAt'=>1462993066000,
       'name'=>nil, 'firstName'=>nil, 'lastName'=>nil, 'email'=>nil,
       'username'=>'admin', 'role'=>'admin', 'schoolId'=>nil, 'phone'=>nil,
       'scopesCm'=>nil, 'id'=>'573380aac52ccac610f606d0',
      'displayName'=>'admin', 'ssoId'=>nil},
      {'updatedAt'=>1463004767000, 'createdAt'=>1463004767000,
       'name'=>'Gouldner', 'firstName'=>'Ronald', 'lastName'=>'Gouldner',
       'email'=>'gouldner@hawaii.edu', 'username'=>'Gouldner', 'role'=>'admin',
       'schoolId'=>nil, 'phone'=>nil, 'scopesCm'=>nil,
       'id'=>'5733ae5f5985f6f30f6c4f33', 'displayName'=>'Gouldner', 'ssoId'=>nil}
    ]
  }
  let(:core_users_updated) {
    [
      {'updatedAt'=>1462993066000, 'createdAt'=>1462993066000,
       'name'=>nil, 'firstName'=>nil, 'lastName'=>nil, 'email'=>nil,
       'username'=>'admin', 'role'=>'admin', 'schoolId'=>nil, 'phone'=>nil,
       'scopesCm'=>nil, 'id'=>'573380aac52ccac610f606d0',
      'displayName'=>'admin', 'ssoId'=>nil},
      {'updatedAt'=>1463004767000, 'createdAt'=>1463004767000,
       'name'=>'Gouldner', 'firstName'=>'Ronald', 'lastName'=>'Gouldner',
       'email'=>'gouldner@hawaii.edu', 'username'=>'Gouldner', 'role'=>'admin',
       'schoolId'=>nil, 'phone'=>nil, 'scopesCm'=>nil,
       'id'=>'5733ae5f5985f6f30f6c4f33', 'displayName'=>'Gouldner', 'ssoId'=>nil},
      {'schoolId'=>'11111111', 'username'=>'aaaaaa', 'active'=>'Y',
       'firstName'=>'Mary', 'lastName'=>'Turpin', 'name'=>'Turpin, Mary',
       'email'=>'aaaaaa@gmail.com', 'role'=>'user'},
      {'schoolId'=>'33333333', 'username'=>'cccccc', 'active'=>'Y',
       'firstName'=>'Alexis', 'lastName'=>'Rico', 'name'=>'Rico, Alexis',
       'email'=>'cccccc@gmail.com', 'role'=>'user'},
      {'schoolId'=>'44444444', 'username'=>'dddddd', 'active'=>'Y',
       'firstName'=>'Matthew', 'lastName'=>'Renner', 'name'=>'Renner, Matthew',
       'email'=>'dddddd@gmail.com', 'role'=>'user'},
      {'schoolId'=>'55555555', 'username'=>'eeeeee', 'active'=>'Y',
       'firstName'=>'Sarah', 'lastName'=>'Miller', 'name'=>'Miller, Sarah',
       'email'=>'eeeeee@gmail.com', 'role'=>'user'}
    ]
  }
  let(:expected_user) {
    {
      'schoolId'=>'77777777', 'username'=>'johnconnor', 'active'=>'Y',
      'firstName'=>'John', 'lastName'=>'Connor', 'name'=>'Connor, John',
      'email'=>'johnconnor@gmail.com', 'role'=>'user'
    }
  }
  let(:config) { './config/test.json' }

  describe '#run' do
    context 'with active/inactive users given' do
      let(:sync) { UserSynchronizer::Base.new }
      let(:cnt) { sync.send :counter }

      before do
        allow(sync).to receive(:kim_users).and_return(kim_users)
        allow(sync).to receive(:core_users).and_return(core_users)
        allow(sync).to receive(:core_update_user) do
          cnt[:updated] += 1
          true
        end
        allow(sync).to receive(:core_delete_user) do
          cnt[:removed] += 1
          true
        end
        allow(sync).to receive(:core_add_user) do
          cnt[:added] += 1
          true
        end
      end

      it 'inserts active users' do
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
      end
    end

    context 'with updated users given' do
      let(:sync) { UserSynchronizer::Base.new }
      let(:cnt) { sync.send :counter }

      before do
        allow(sync).to receive(:kim_users).and_return(kim_users_updated)
        allow(sync).to receive(:core_users).and_return(core_users_updated)
        allow(sync).to receive(:core_update_user) do
          cnt[:updated] += 1
          true
        end
        allow(sync).to receive(:core_delete_user) do
          cnt[:removed] += 1
          true
        end
        allow(sync).to receive(:core_add_user) do
          cnt[:added] += 1
          true
        end
      end

      it 'synchronizes users correctly' do
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

  describe '#sync_only_new_group_members' do
    let(:args) { { within_days: 3, dry_run: false } }

    context 'with active/inactive users given' do
      let(:sync) { UserSynchronizer::Base.new }
      let(:cnt) { sync.send :counter }
      let(:core_map) {
        core_users.inject({}) { |h, r| h[r['username']] = r; h }
      }

      before do
        allow(sync).to receive(:find_kim_new_group_members).and_return(kim_users)
        allow(sync).to receive(:core_update_user) do
          cnt[:updated] += 1
          true
        end
        allow(sync).to receive(:core_delete_user) do
          cnt[:removed] += 1
          true
        end
        allow(sync).to receive(:core_add_user) do
          cnt[:added] += 1
          true
        end
        allow(sync).to receive(:core_user_no_cache) do |username|
          core_map[username]
        end
      end

      it 'inserts active users' do
        expect(sync.sync_only_new_group_members(config, args)).to eq({
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
      end
    end

    context 'with updated users given' do
      let(:sync) { UserSynchronizer::Base.new }
      let(:cnt) { sync.send :counter }
      let(:core_map) {
        core_users_updated.inject({}) { |h, r| h[r['username']] = r; h }
      }

      before do
        allow(sync).to receive(:find_kim_new_group_members).and_return(kim_users_updated)
        allow(sync).to receive(:core_update_user) do
          cnt[:updated] += 1
          true
        end
        allow(sync).to receive(:core_delete_user) do
          cnt[:removed] += 1
          true
        end
        allow(sync).to receive(:core_add_user) do
          cnt[:added] += 1
          true
        end
        allow(sync).to receive(:core_user_no_cache) do |username|
          core_map[username]
        end
      end

      it 'synchronizes users correctly' do
        expect(sync.sync_only_new_group_members(config, args)).to eq({
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

  describe '#force_update' do
    let(:user) {
      {
        'schoolId'=>'11111111', 'username'=>'aaaaaa', 'active'=>'Y',
        'firstName'=>'Mary', 'lastName'=>'Turpin', 'name'=>'Turpin, Mary',
        'email'=>'aaaaaa@gmail.com', 'role'=>'user'
      }
    }

    before do
      #allow(sync).to receive(:find_kim_user).and_return(e)
      #allow(sync).to receive(:find_core_user).and_return(user)
      #allow(sync).to receive(:core_update_user) do
      #  cnt[:updated] += 1
      #  true
      #end
      #allow(sync).to receive(:core_delete_user) do
      #  cnt[:removed] += 1
      #  true
      #end
      #allow(sync).to receive(:core_add_user) do
      #  cnt[:added] += 1
      #  true
      #end
      #allow(sync).to receive(:increment_total) do
      #  cnt[:total] += 1
      #end
      #allow(sync).to receive(:increment_same) do
      #  cnt[:same] += 1
      #end
      #allow(sync).to receive(:increment_inactive) do
      #  cnt[:inactive] += 1
      #end
      #allow(sync).to receive(:core_user_no_cache) do |username|
      #  user
      #end
    end

    context 'with active user given' do
      context 'when it does not exist in core' do
        let(:sync) { UserSynchronizer::Base.new }
        let(:cnt) { sync.send :counter }

        before do
          allow(sync).to receive(:find_core_user).and_return(nil)
        end

        it 'inserts user' do
          expect(sync).to receive(:increment_total)
          expect(sync).to receive(:core_add_user).with(user, false)
          sync.force_update(user, config)
        end
      end

      context 'when it exists in core' do
        context 'and is updated' do
          let(:sync) { UserSynchronizer::Base.new }
          let(:cnt) { sync.send :counter }
          let(:e) { user.merge('firstName' => 'Xxxx', 'lastName' => 'Yyyy') }

          before do
            allow(sync).to receive(:core_user_no_cache).and_return(user)
          end

          it 'updates user' do
            expect(sync).to receive(:increment_total)
            expect(sync).to receive(:core_update_user).with(user, e, false)
            sync.force_update(e, config)
          end
        end

        context 'and is not updated' do
          let(:sync) { UserSynchronizer::Base.new }
          let(:cnt) { sync.send :counter }

          before do
            allow(sync).to receive(:core_user_no_cache).and_return(user)
          end

          it 'increments the number of same' do
            expect(sync).to receive(:increment_total)
            expect(sync).to receive(:increment_same)
            sync.force_update(user, config)
          end
        end
      end
    end

    context 'with inactive user given' do
      context 'when it exists in core' do
        let(:sync) { UserSynchronizer::Base.new }
        let(:cnt) { sync.send :counter }
        let(:current) { user.merge('active' => 'N') }

        before do
          allow(sync).to receive(:core_user_no_cache).and_return(user)
        end

        it 'deletes user' do
          expect(sync).to receive(:increment_total)
          expect(sync).to receive(:core_delete_user).with(user, false)
          sync.force_update(current, config)
        end
      end

      context 'when it does not exist in core' do
        let(:sync) { UserSynchronizer::Base.new }
        let(:cnt) { sync.send :counter }
        let(:current) { user.merge('active' => 'N') }

        before do
          allow(sync).to receive(:core_user_no_cache).and_return(nil)
        end

        it 'increments the number of inactive users' do
          expect(sync).to receive(:increment_total)
          expect(sync).to receive(:increment_inactive)
          sync.force_update(current, config)
        end
      end
    end
  end

  describe '#find_kim_user' do
    let(:sync) { UserSynchronizer::Base.new }
    let(:kim) { sync.send :kim }

    context 'with username given' do
      let(:query) { 'username' }

      it 'calls KimUsers#find_user' do
        expect(kim).to receive(:find_user).with(query, 'all')
        sync.find_kim_user(query)
      end
    end

    context 'with schoolId given' do
      let(:query) { '1234567' }

      it 'calls KimUsers#find_user' do
        expect(kim).to receive(:find_user_by_id).with(query, 'all')
        sync.find_kim_user(query)
      end
    end
  end

  describe '#find_kim_group_member' do
    let(:sync) { UserSynchronizer::Base.new }
    let(:kim) { sync.send :kim }
    let(:groups) { ['UH KC Users', 'UH COI Users'] }

    context 'with username given' do
      let(:query) { 'username' }

      it 'calls KimUsers#find_user' do
        expect(kim).to receive(:find_user).with(query, groups)
        sync.find_kim_group_member(query)
      end
    end

    context 'with schoolId given' do
      let(:query) { '1234567' }

      it 'calls KimUsers#find_user' do
        expect(kim).to receive(:find_user_by_id).with(query, groups)
        sync.find_kim_group_member(query)
      end
    end
  end
end
