require 'oci8'
require 'awesome_print'

require 'kim_users_base'

class KimUsers < KimUsersBase

  attr_reader :oci

  def ping
    r = nil
    if open
      r = @oci.ping
      close
    end
    r
  end

  def url
    "#{params['db_host']}:#{params['db_port']}/#{params['db_sid']}"
  end

  private

  def select_one(sql)
    r = nil
    exec_sql(sql) do |cursor|
      r = cursor.fetch_hash
    end
    r
  end

  def select_all(sql)
    rslt = []
    exec_sql(sql) do |cursor|
      while r = cursor.fetch_hash
        rslt << r
      end
    end
    rslt
  end

  def exec_sql(sql)
    return false unless open
    rslt = nil
    begin
      cursor = @oci.exec(sql)
      rslt = yield cursor
      cursor.close
    rescue => e
      record_error(e)
      logger.error 'Cannot Excecute SQL: ' + sql
      @status = 'SQL Execution Error'
      return false
    end
    return false unless close
    rslt
  end

  def open
    return false if @oci
    begin
      @oci = OCI8.new(params['db_user'], params['db_pass'], url)
      logger.info '[KIM] Opened Connection Successfully'
      @status = 'Connected'
      return true
    rescue => e
      record_error(e)
      logger.error '[KIM] Cannot Open Connection'
      logger.error(e.to_s)
      logger.error(e.backtrace.join("\n"))
      @status = 'Open Error'
    end
    false
  end

  def close
    unless @oci
      logger.info '[KIM] Not Connected'
      return false
    end

    begin
      @oci.logoff
      logger.info '[KIM] Closed Connection Successfully'
      @oci = nil
      @status = 'Not Connected'
      return true
    rescue => e
      record_error(e)
      logger.error '[KIM] Cannot Close Connection'
      logger.error(e.to_s)
      logger.error(e.backtrace.join("\n"))
      @status = 'Close Error'
    end
    false
  end
end
