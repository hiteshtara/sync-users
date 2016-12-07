require 'java'
require 'ojdbc7-12.1.0.2.jar'

java_import 'oracle.jdbc.OracleDriver'
java_import 'java.sql.DriverManager'

require 'kim_users_base'

# Set ojdbc7-12.1.0.2.jar in either:
# 1) ./lib (use require_relative to include)
# 2) ~/.rbenv/versions/jruby-9.1.0.0/lib
class KimUsersJdbc < KimUsersBase

  attr_reader :oci

  def url
    "jdbc:oracle:thin:@#{params['db_host']}:#{params['db_port']}/#{params['db_sid']}"
  end

  def ping
    r = false
    if open
      r = true
      close
    end
    r
  end

  def permission_assignees
    @converter = :conv_to_hash
    super
  end

  def role_ids
    @converter = :conv_to_hash
    super
  end

  private

  def converter
    @converter ||= :conv_user
  end

  def select_one(sql)
    r = nil
    exec_sql(sql) do |cursor, meta|
      cnt = meta.get_column_count
      if cursor.next?
        r = send(converter, cursor, meta, cnt)
      end
    end
    r
  end

  def select_all(sql)
    rslt = []
    exec_sql(sql) do |cursor, meta|
      cnt = meta.get_column_count
      while cursor.next?
        rslt << send(converter, cursor, meta, cnt)
      end
    end
    rslt
  end

  def conv_user(cursor, meta = nil, cnt = nil)
    {
      'schoolId' => cursor.get_string(1),
      'username' => cursor.get_string(2),
      'active' => cursor.get_string(3),
      'firstName' => cursor.get_string(4),
      'lastName' => cursor.get_string(5),
      'name' => cursor.get_string(6),
      'email' => cursor.get_string(7),
      'role' => cursor.get_string(8),
    }
  end

  def conv_to_hash(cursor, meta = nil, cnt = nil)
    r = {}
    1.upto(cnt) do |i|
      r[meta.get_column_name(i)] =
        case meta.get_column_type_name(i)
        when 'NUMBER' then cursor.get_int(i)
        else
          cursor.get_string(i)
        end
    end
    r
  end

  def exec_sql(sql)
    return false unless open
    rslt = nil
    begin
      stmt = @oci.create_statement
      cursor = stmt.execute_query(sql)
      meta = cursor.get_meta_data
      rslt = yield(cursor, meta)
      cursor.close
      stmt.close
    rescue => e
      record_error(e)
      logger.error 'Cannot Excecute SQL: ' + sql
      @status = 'SQL Execution Error'
      return false
    ensure
      @converter = nil
    end
    return false unless close
    rslt
  end

  def open
    return false if @oci
    begin
      oracle_driver = OracleDriver.new
      DriverManager.registerDriver(oracle_driver)
      @oci = DriverManager.get_connection(url, params['db_user'], params['db_pass'])
      #@oci.auto_commit = false
      logger.info '[KIM JDBC] Opened Connection Successfully'
      @status = 'Connected'
      return true
    rescue => e
      record_error(e)
      logger.error '[KIM JDBC] Cannot Open Connection'
      logger.error(e.to_s)
      logger.error(e.backtrace.join("\n"))
      logger.error($CLASSPATH)
      @status = 'Open Error'
    end
    false
  end

  def close
    unless @oci
      logger.info '[KIM JDBC] Not Connected'
      return false
    end

    begin
      @oci.close
      logger.info '[KIM JDBC] Closed Connection Successfully'
      @oci = nil
      @status = 'Not Connected'
      return true
    rescue => e
      record_error(e)
      logger.error '[KIM JDBC] Cannot Close Connection'
      logger.error(e.to_s)
      logger.error(e.backtrace.join("\n"))
      @status = 'Close Error'
    end
    false
  end
end
