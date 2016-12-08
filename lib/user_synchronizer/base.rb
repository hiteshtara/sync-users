require 'json'
require 'securerandom'
require 'awesome_print'

require 'kim_client_switcher'
require 'task_runner'
require 'core_client'
require 'user_synchronizer/user_util'
require 'user_synchronizer/counter'
require 'user_synchronizer/error_recorder'

module UserSynchronizer
  class Base < TaskRunner
    include KimClientSwitcher
    include UserSynchronizer::UserUtil
    include UserSynchronizer::Counter
    include UserSynchronizer::ErrorRecorder

    KEY = 'username'

    def check_core_status(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      core.check_status
    end

    def check_kim_status(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      kim.ping ? true : false
    end

    def retry_errors(fname, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      reset_counter!
      logger.info 'Start Synchronizing Users'
      each_error(fname) do |h|
        increment_total
        case h['action']
        when 'add'
          core_add_user(h['new_user'], false)
        when 'update'
          core_update_user('new_user', h['cur_user'], false)
        when 'delete'
          core_delete_user(h['user'], false)
        end
      end
      logger.info "RESULTS: #{counter}"
      logger.info "End Successfully"
      counter
    end

    def analyze_duplicates(params_or_path = nil)
      each_error(params['sync_errors']) do |err|
        get_duplicate_errors(err).each do |dup|
          dup['fields'].each do |field|
            case field
            when 'email' then analyze_email_duplicates(err)
            when 'username' then analyze_username_duplicates(err)
            else
              raise "Unknown Duplicate Key: #{type}\n   #{h.inspect}\n"
            end
          end
        end
      end
    end

    def analyze_other_errors(params_or_path = nil)
      each_error(params['sync_errors']) do |err|
        unless get_other_errors(err).empty?
          ap err
        end
      end
    end

    def show_sync_errors(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      read_errors(params['sync_errors'])
    end

    def show_results
      ap counter
    end

    def show_sql(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      puts kim.select_kim_users_sql(params['target_user_groups'])
    end

    def show_env(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      puts '---< CONFIG >' + '-' * 67
      super
      puts '---< CORE >' + '-' * 69
      core.show_env
      puts '---< KIM >' + '-' * 70
      kim.show_env
      puts '-' * 80
    end

    def show_kim_only_users(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      only_kim = kim_only_users
      only_kim.each do |r|
        puts user_to_s(r)
      end
      puts "TOTAL KIM #{kim_users.length},  CORE #{core_users.length},  ONLY KIM #{only_kim.length}"
    end

    def show_core_only_users(params_or_path = nil)
      set_env(params_or_path) if params_or_path
      only_core = core_only_users
      only_core.each do |r|
        puts user_to_s(r)
      end
      puts "TOTAL KIM #{kim_users.length},  CORE #{core_users.length},  ONLY CORE #{only_core.length}"
    end

    def show_kim_new_group_members(within_days = 3, params_or_path = nil)
      r = find_kim_new_group_members(within_days, params_or_path)
      ap r
    end

    def peek(username_or_school_id, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      b = find_kim_user(username_or_school_id)
      a = find_core_user(username_or_school_id)

      puts '--< CORE >' + '-' * 70
      if a
        ap a
      else
        puts 'CORE USER NOT FOUND'
      end

      puts '--< KIM >' + '-' * 71
      if b
        ap b
      else
        puts 'KIM USER NOT FOUND'
      end
      puts '-' * 80
      if a && !a.empty? && b
        puts "COMPARE #{compare_user(a.first, b)}"
        puts '-' * 80
      end
    end

    #query: username or email or schoolId
    def find_core_user(query, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      core.get_user(query)
    end

    def find_kim_user(username_or_school_id)
      return nil unless kim
      if username_or_school_id =~ /^\d+$/
        kim.find_user_by_id(username_or_school_id)
      else
        kim.find_user(username_or_school_id)
      end
    end

    def find_all_kim_users_by_name(username, params_or_path = nil)
      return nil unless kim
      set_env(params_or_path) if params_or_path
      #kim.find_all_by_username(username)
      kim_users.select{ |h| h['username'] == username }
    end

    def find_all_kim_users_by_email(email, params_or_path = nil)
      return nil unless kim
      set_env(params_or_path) if params_or_path
      #kim.find_all_by_email(email)
      kim_users.select{ |h| h['email'] == email }
    end

    def find_all_kim_users_by_id(school_id, params_or_path = nil)
      return nil unless kim
      set_env(params_or_path) if params_or_path
      kim.find_all_by_id(school_id)
      #kim_users.select{ |h| h['schoolId'] == school_id }
    end

    #Returns users that were recently inserted into KC/COI user groups
    def find_kim_new_group_members(days = 1, params_or_path = nil)
      return nil unless kim
      set_env(params_or_path) if params_or_path
      kim.find_new_group_members(params['target_user_groups'], days)
    end

    def dry_run(params_or_path = nil, args = {})
      args.merge!(dry_run: true)
      run(params_or_path, args)
    end

    def sync_only_new_group_members(params_or_path = nil, args = {})
      days = args[:within_days] || 3
      args[:src] = find_kim_new_group_members(days, params_or_path)
      args[:core_no_cache] = true
      args[:dry_run] = args.has_key?(:dry_run) ? args[:dry_run] : false
      run(params_or_path, args)
    end

    def update_user(username_or_school_id, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      user = find_kim_user(username_or_school_id)
      unless user
        puts "No KIM User Found: #{username_or_school_id}"
        return
      end
      force_update(user, params_or_path)
    end

    def force_update(user, params_or_path = nil)
      unless user
        raise "No User Given"
      end
      args = {
        src: [ user ],
        core_no_cache: true
      }
      run(params_or_path, args)
    end

    private

    # args:
    #   dry_run (boolean): disable DB update if true. (default false)
    #   src (array of users): will be used for updating core MongoDB. (default kim_users)
    #   core_no_cache (boolean): bulk load and cache core users if true. (default false)
    def do_task(args = {})
      dry = args.has_key?(:dry_run) ? args[:dry_run] : false
      src = args[:src] || kim_users
      @core_access_method = args[:core_no_cache] ? :core_user_no_cache : :core_user
      sync_users(src, dry)
    end

    def reset!
      @params = nil
      @kim = nil
      @kim_users = nil
      @kim_admins = nil
      @core = nil
      @core_users = nil
      @core_map = nil
      @core_access_method = :core_user
    end

    def sync_users(src, dry)
      reset_counter!
      set_error_out(params['sync_errors']) if params['sync_errors']
      logger.info 'Start Synchronizing Users'
      src.each do |original|
        increment_total
        #original['role'] = kim_admins.include?(original['schoolId']) ? 'admin' : 'user'
        user = get_core_user(original['username'])
        if original['active'] == 'Y'
          if user
            if compare_user(original, user)
              increment_same
            else
              core_update_user(user, original, dry)
            end
          else
            core_add_user(original, dry)
          end
        else
          if user
            core_delete_user(user, dry)
          else
            increment_inactive
          end
        end
      end
      logger.info "RESULTS: #{counter}"
      logger.info "End Successfully"
      counter
    end

    def core_add_user(new_user, dry = false)
      logger.info "ADD: #{user_to_s(new_user)}"
      if dry
        increment_added
        return true
      end
      new_user['password'] = SecureRandom.uuid
      core.add_user(new_user)
      if core.error? || core.failure?
        increment_add_errors
        record_error(action: :add, new_user: new_user) if params['sync_errors']
        show_core_error
        false
      else
        increment_added
        true
      end
    end

    def core_update_user(cur_user, updated_user, dry = false)
      logger.info "UPD: #{user_to_s_long(cur_user)} => #{user_to_s_long(updated_user)} DIFF: #{diff_user(cur_user, updated_user)}"
      if dry
        increment_updated
        return true
      end
      core.update_user(cur_user['id'], updated_user)
      if core.error? || core.failure?
        increment_update_errors
        record_error(action: :update, cur_user: cur_user, new_user: updated_user) if params['sync_errors']
        show_core_error
        false
      else
        increment_updated
        true
      end
    end

    def core_delete_user(cur_user, dry = false)
      logger.info "DLT: #{user_to_s(cur_user)}"
      if dry
        increment_removed
        return true
      end
      core.delete_user(cur_user['id'])
      if core.error? || core.failure?
        increment_remove_errors
        record_error(action: :delete, cur_user: cur_user) if params['sync_errors']
        show_core_error
        false
      else
        increment_removed
        true
      end
    end

    def show_core_error
      core.show_error(logger)
    end

    def kim
      unless @kim
        @kim = kim_user_client.new(kim_params)
        @kim.logger = logger
        @kim.params = kim_params
      end
      @kim
    end

    def core
      @core ||= CoreClient.new(core_params)
    end

    def kim_params
      {
        'db_pass' => params['db_pass'],
        'db_user' => params['db_user'],
        'db_host' => params['db_host'],
        'db_port' => params['db_port'],
        'db_sid' => params['db_sid'],
      }
    end

    def core_params
      {
        'api_scheme' => params['api_scheme'],
        'api_host' => params['api_host'],
        'api_port' => params['api_port'],
        'api_key' => params['api_key'],
      }
    end

    def kim_users
      unless @kim_users
        return [] unless kim
        @kim_users = kim.users(params['target_user_groups'])
      end
      @kim_users
    end

    def kim_admins
      unless @kim_admins
        return [] unless kim
        @kim_admins = kim.admin_users
      end
      @kim_admins
    end

    # MAX 1,000,000
    def core_users
      unless @core_users
        @core_users = core.get_users
      end
      @core_users
    end

    def core_only_users
      only_core = core_user_map.clone
      kim_users.each do |r|
        only_core.delete(r['username']) if only_core[r['username']]
      end
      only_core.values
    end

    def kim_only_users
      only_kim = []
      kim_users.each do |r|
        only_kim << r unless core_user_map[r['username']]
      end
      only_kim
    end

    def get_core_user(username)
      send(@core_access_method, username)
    end

    def core_user(username)
      core_user_map[username]
    end

    def core_user_no_cache(username)
      core.get_user(username).first
    end

    def core_user_map
      unless @core_map
        @core_map = {}
        if src = core_users
          src.each { |r| @core_map[r['username']] = r }
        end
      end
      @core_map
    end

    def get_duplicate_errors(error)
      return [] unless error && error['error'] && error['error']['type'] == 'error'
      return [] unless details = error['error']['details']
      details.select { |h| h['name'] == 'DuplicateKeyError' }
    end

    def get_other_errors(error)
      return [] unless error && error['error'] && error['error']['details']
      error['error']['details'].reject { |h| h['name'] == 'DuplicateKeyError' }
    end

    def analyze_email_duplicates(err, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      email = err['new_user']['email']
      users = find_all_kim_users_by_email(email, params_or_path = nil)
      puts '--< EMAIL DUPLICATES >' + '-' * 78
      users.each do |r|
        puts user_to_s_long(r)
      end
      nil
    end

    def analyze_username_duplicates(err, params_or_path = nil)
      set_env(params_or_path) if params_or_path
      name = err['new_user']['username']
      users = find_all_kim_users_by_name(name, params_or_path = nil)
      puts '--< USERNAME DUPLICATES >' + '-' * 75
      users.each do |r|
        puts user_to_s_long(r)
      end
      nil
    end
  end
end
