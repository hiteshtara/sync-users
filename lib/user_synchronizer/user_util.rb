class NilClass
  def downcase
    ""
  end

  def strip
    ""
  end
end

module UserSynchronizer
  module UserUtil
    def user_to_s(r)
      sprintf("[%-7s] %8s %-12s %s", r['role'], r['schoolId'], r['username'], r['email'])
    end

    def user_to_s_long(r)
      user_to_s(r) + sprintf(" %s, %s", r['firstName'], r['lastName'])
    end

    def diff_user(a, b)
      r = []
      r << 'username' unless a['username'] == b['username']
      r << 'schoolId' unless a['schoolId'] == b['schoolId']
      r << 'email' unless a['email'].downcase == b['email'].downcase
      r << 'firstName' unless a['firstName'].strip == b['firstName'].strip
      r << 'lastName' unless a['lastName'].strip == b['lastName'].strip
      #r << 'name' unless a['name'].strip == b['name'].strip
      r << 'role' unless a['role'] == b['role']
      r.map { |i| "[#{i.upcase}] #{a[i]} > #{b[i]}" }.join(', ')
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
  end
end
