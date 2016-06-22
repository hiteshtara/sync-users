module KimClientSwitcher
  def self.included(base)
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
      require 'kim_users_jdbc'
    else
      require 'kim_users'
    end
  end

  def ruby_engine
    unless @ruby_engine
      @ruby_engine = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jruby' : 'mri'
    end
    @ruby_engine
  end

  def jruby?
    ruby_engine == 'jruby'
  end

  private

  def kim_user_client
    jruby? ? ::KimUsersJdbc : ::KimUsers
  end
end
