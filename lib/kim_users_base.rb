require 'logger'
require 'awesome_print'

require 'configuration'

class KimUsersBase
  include Configuration

  DEFAULT_LOG_LEVEL = 'WARN'
  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1521 

  SELECT_KIM_USERS = <<-EOS
    SELECT p.PRNCPL_ID AS "schoolId"
          ,p.PRNCPL_NM AS "username"
          ,p.ACTV_IND AS "active"
          ,n.FIRST_NM AS "firstName"
          ,n.LAST_NM AS "lastName"
          ,n.LAST_NM || ', ' || n.FIRST_NM AS "name"
          ,e.email_addr AS "email"
          ,nvl(admins.role,'user') AS "role"
    FROM KRIM_PRNCPL_T p
         ,KRIM_ENTITY_NM_T n
         ,KRIM_ENTITY_EMAIL_T e
         ,(SELECT p.PRNCPL_ID, p.PRNCPL_NM AS userid, 'admin' AS role
           FROM KRIM_PERM_T perm
               ,KRIM_ROLE_PERM_T rp
               ,KRIM_ROLE_T r
               ,KRIM_ROLE_MBR_T m
               ,KRIM_PRNCPL_T p
           where perm.NM = 'Modify Entity'
             AND perm.PERM_ID = rp.PERM_ID
             AND r.ROLE_ID = rp.ROLE_ID
             AND m.ROLE_ID = r.ROLE_ID
             AND m.MBR_TYP_CD = 'P'
             AND m.ACTV_TO_DT is null
             AND m.MBR_ID = p.PRNCPL_ID) admins
    where p.PRNCPL_ID = n.ENTITY_ID
      AND n.DFLT_IND = 'Y' -- get default name
      AND n.ACTV_IND = 'Y' -- active name
      AND p.PRNCPL_ID = e.ENTITY_ID
      AND e.DFLT_IND = 'Y' -- get default email
      AND e.ACTV_IND = 'Y' -- active email
      AND p.PRNCPL_ID = admins.PRNCPL_ID (+)
  EOS

  SELECT_ROLE_IDS = <<-EOS
        SELECT ROLE_ID
          FROM KRIM_ROLE_PERM_T
         WHERE PERM_ID in (
           SELECT PERM_ID
             FROM KRIM_PERM_T
            WHERE NM = 'Modify Entity'
              AND NMSPC_CD = 'KR-IDM'
         )
  EOS

  SELECT_PERMISSION_ASSIGNEES = <<-EOS
    SELECT *
      FROM KRIM_ROLE_MBR_T
      WHERE (MBR_TYP_CD = 'P' OR MBR_TYP_CD = 'G')
        AND (ACTV_FRM_DT is null OR ACTV_FRM_DT <= TRUNC(SYSDATE))
        AND (ACTV_TO_DT is null OR ACTV_TO_DT >= TRUNC(SYSDATE))
        AND ROLE_ID in (
          #{SELECT_ROLE_IDS}
        )
  EOS

  attr_reader :status, :errors
  attr_accessor :params, :logger

  def initialize(args = {})
    @errors = []
    @status = 'Not Connected'
    set_env(args)
    set_log_level(args[:log_level])
  end

  def set_env(params_or_path = nil)
    super
    if params
      params['db_host'] = DEFAULT_HOST unless params['db_host']
      params['db_port'] = DEFAULT_PORT unless params['db_port']
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def set_log_level(level = nil)
    level ||= DEFAULT_LOG_LEVEL
    if Logger::SEV_LABEL.include?(level.upcase)
      logger.level = Logger.const_get(level)
    end
  end

  def show_env
    ap params
  end

  def find_user(username)
    select_one(SELECT_KIM_USERS + "      AND p.PRNCPL_NM = '#{username}'")
  end

  def top_user
    select_one(SELECT_KIM_USERS)
  end

  def users
    nil if has_error?
    unless @users
      @users = select_all(SELECT_KIM_USERS)
    end
    @users 
  end

  def admin_users
    return nil unless permission_assignees
    permission_assignees.select { |r|
      r['MBR_TYP_CD'] == 'P' || r['MBR_TYP_CD'] == 'G'
    }.map { |r| r['MBR_ID'] }.uniq
  end

  def permission_assignees
    nil if has_error?
    unless @permission_assignees
      @permission_assignees = select_all(SELECT_PERMISSION_ASSIGNEES)
    end
    @permission_assignees 
  end

  def role_ids
    nil if has_error?
    unless @role_ids
      @role_ids = select_all(SELECT_ROLE_IDS).map { |r| r['ROLE_ID']}
    end
    @role_ids 
  end

  def show_errors
    @errors.each do |h|
      puts '=' * 80
      puts h[:message]
      puts '-' * 80
      puts h[:stacktrace]
    end
    puts '-' * 80 unless @errors.empty?
  end

  def has_error?
    !@errors.empty?
  end

  def reset_errors
    @errors = []
  end

  def ping
    raise 'Must Override ping'
  end

  private

  def select_one(sql)
    raise 'Must Override select_one'
  end

  def select_all(sql)
    raise 'Must Override select_all'
  end
  
  def record_error(e)
    @errors << {
      message:  e.to_s,
      stacktrace: e.backtrace.join("\n"),
    }
  end

  def required_params
    %w(db_user db_pass db_host db_port db_sid log_level)
  end
end
