require 'json'
require 'securerandom'
require 'awesome_print'

require 'task_runner'
require 'core_client'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  require 'kim_users_jdbc'
else
  require 'kim_users'
end

class UserSynchronizer < TaskRunner
  KEY = 'username'

  def ruby_engine
    unless @ruby_engine
      @ruby_engine = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jruby' : 'mri'
    end
    @ruby_engine
  end

  def jruby?
    ruby_engine == 'jruby'
  end

  def has_errors?
    !!(@results && !@results[:errors].empty?)
  end

  def show_results
    ap @results
  end

  def check_core_status(params_or_path = nil)
    set_env(params_or_path) if params_or_path
    core.check_status
  end

  def check_kim_status(params_or_path = nil)
    set_env(params_or_path) if params_or_path
    kim.ping ? true : false
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

  def dry_run(params_or_path = nil, args = {})
    args.merge!(dry_run: true)
    run(params_or_path, args)
  end

  def peek(username, params_or_path = nil)
    set_env(params_or_path) if params_or_path
    b = find_kim_user(username)
    a = core_user(username) 

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
    if a && b
      puts "COMPARE #{compare_user(a, b)}"
      puts '-' * 80
    end
  end

  def force_update(username)
    original = find_kim_user(username)
    if original
      puts "KIM User Found"
    else
      puts "KIM User Not Found: #{username}"
      return
    end
    user = core_user(username) 
    if user
      puts "Core User Found"
    end

    if original['active'] == 'Y'
      if user
        if compare_user(original, user)
          puts "SAME: No Update"
        else
          core_update_user(user, original, false)
          puts "Updated"
        end
      else
        core_add_user(original, false)
        puts "Added"
      end
    else
      if user
        core_delete_user(user, false)
      else
        puts "Ignored"
      end
    end
  end

  def user_to_s(r)
    sprintf("[%-5s] %8d %-12s %s", r['role'], r['schoolId'], r['username'], r['email']) 
  end

  # Ignore leading and trailing spaces of name; ??? core removes them ???
  # Ignore case of email; ??? core make it all lowercase ???
  def compare_user(a, b)
    a['username'] == b['username'] && 
    a['schoolId'] == b['schoolId'] && 
    a['email'].downcase == b['email'].downcase && 
    a['firstName'].strip == b['firstName'].strip && 
    a['lastName'].strip == b['lastName'].strip && 
    a['name'].strip == b['name'].strip && 
    a['role'] == b['role']
  end

  private

  def do_task(args = {})
    dry = args[:dry_run] ? true : false
    sync_users(dry)
  end

  def reset!
    @params = nil
    @results = nil
    @kim = nil
    @kim_users = nil
    @kim_admins = nil
    @core = nil
    @core_users = nil
    @core_map = nil
  end

  def sync_users(dry)
    logger.info 'Start Synchronizing Users'
    @results = nil
    cnt = { total: 0, added: 0, updated: 0, removed: 0, same: 0, inactive: 0, 
      add_errors: 0, update_errors: 0, remove_errors: 0 }
    kim_users.each do |original|
      cnt[:total] += 1
      #original['role'] = kim_admins.include?(original['schoolId']) ? 'admin' : 'user'
      user = core_user(original['username'])
      if original['active'] == 'Y'
        if user
          if compare_user(original, user)
            cnt[:same] += 1
          else
            if core_update_user(user, original, dry)
              cnt[:updated] += 1
            else
              cnt[:update_errors] += 1
            end
          end
        else
          if core_add_user(original, dry)
            cnt[:added] += 1
          else
            cnt[:add_errors] += 1
          end
        end
      else
        if user
          if core_delete_user(user, dry)
            cnt[:removed] += 1
          else
            cnt[:remove_errors] += 1
          end
        else
          cnt[:inactive] += 1
        end
      end
    end 
    @results = cnt
    logger.info "RESULTS: #{@results}"
    logger.info "End Successfully"
    @results
  end

  def core_add_user(new_user, dry = false)
    logger.info "ADD: #{user_to_s(new_user)}"
    unless dry
      new_user['password'] = SecureRandom.uuid
      core.add_user(new_user)
      return true unless core.error? || core.failure?
      show_core_error
      false
    end
  end

  def core_update_user(cur_user, updated_user, dry = false)
    logger.info "UPD: #{user_to_s(cur_user)} => #{user_to_s(updated_user)}"
    unless dry
      core.update_user(cur_user['id'], updated_user)
      return true unless core.error? || core.failure?
      show_core_error
      false
    end
  end

  def core_delete_user(cur_user, dry = false)
    logger.info "DLT: #{user_to_s(cur_user)}"
    unless dry
      core.delete_user(cur_user['id'])
      return true unless core.error? || core.failure?
      show_core_error
      false
    end
  end

  def show_core_error
    if core.error?
      core.show_fatal_error(logger)
    elsif core.failure?
      core.show_error_response(logger)
    end
  end

  def kim_user_client
    jruby? ? KimUsersJdbc : KimUsers
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
      @kim_users = kim.users
    end
    @kim_users
  end

  def find_kim_user(username)
    return nil unless kim
    kim.find_user(username)
  end

  def kim_admins
    unless @kim_admins
      return [] unless kim
      @kim_admins = kim.admin_users
    end
    @kim_admins
  end

  def core_users
    unless @core_users
      @core_users = core.get_users
    end
    @core_users
  end

  def core_user(username)
    core_user_map[username]
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
end
