module KimUsersSql
  SQL_SELECT_BASE = <<-EOS
    SELECT p.PRNCPL_ID AS "schoolId"
          ,p.PRNCPL_NM AS "username"
          ,p.ACTV_IND AS "active"
          ,n.FIRST_NM AS "firstName"
          ,n.LAST_NM AS "lastName"
          ,n.LAST_NM || ', ' || n.FIRST_NM AS "name"
          ,e.EMAIL_ADDR AS "email"
          ,nvl(admins.role,'user') AS "role"
  EOS

  SQL_FROM_BASE = <<-EOS
      FROM KRIM_PRNCPL_T p
          ,KRIM_ENTITY_NM_T n
          ,KRIM_ENTITY_EMAIL_T e
          ,(SELECT p.PRNCPL_ID, p.PRNCPL_NM AS userid, 'admin' AS role
              FROM KRIM_PERM_T perm
                  ,KRIM_ROLE_PERM_T rp
                  ,KRIM_ROLE_T r
                  ,KRIM_ROLE_MBR_T m
                  ,KRIM_PRNCPL_T p
             WHERE perm.NM = 'Modify Entity'
               AND perm.PERM_ID = rp.PERM_ID
               AND r.ROLE_ID = rp.ROLE_ID
               AND m.ROLE_ID = r.ROLE_ID
               AND m.MBR_TYP_CD = 'P'
               AND m.ACTV_TO_DT is null
               AND m.MBR_ID = p.PRNCPL_ID) admins
  EOS

  SQL_WHERE_BASE = <<-EOS
     WHERE p.PRNCPL_ID = n.ENTITY_ID
       AND n.DFLT_IND = 'Y' -- get default name
       AND n.ACTV_IND = 'Y' -- active name
       AND p.PRNCPL_ID = e.ENTITY_ID
       AND e.DFLT_IND = 'Y' -- get default email
       AND e.ACTV_IND = 'Y' -- active email
       AND p.PRNCPL_ID = admins.PRNCPL_ID(+)
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

  SELECT_GROUPS = <<-EOS
    SELECT GRP_NM AS "name"
          ,GRP_DESC AS "description"
          ,ACTV_IND AS "active"
      FROM KRIM_GRP_T
      WHERE ACTV_IND = 'Y'
  EOS

  def select_kim_users_sql(groups = nil, &block)
    if groups == 'all'
      all_users_sql(&block)
    else
      group_members_sql(groups, &block)
      #group_active_members_sql(groups, &block)
    end
  end

  def all_users_sql(&block)
    generate_sql(&block)
  end

  # Returns users that belong to a group
  def group_members_sql(groups = [], &block)
    opt = {
      tbls: [
        'KRIM_GRP_MBR_T gm',
        'KRIM_GRP_T g',
      ],
      conds: [
        'gm.GRP_ID = g.GRP_ID',
        'gm.ACTV_TO_DT is null',
        'gm.MBR_ID = p.PRNCPL_ID',
      ]
    }
    unless groups.nil? || groups.empty?
      opt[:conds] << "g.GRP_NM in ('" + groups.join("', '") + "')"
    end
    generate_sql(opt, &block)
  end

  def select_kim_user_by_name_sql(name, groups = [])
    select_kim_users_sql(groups) do |opt|
      opt[:conds] << "p.PRNCPL_NM = '#{name}'"
    end
  end

  def select_kim_user_by_email_sql(email, groups = [])
    select_kim_users_sql(groups) do |opt|
      opt[:conds] << "e.EMAIL_ADDR = '#{email}'"
    end
  end

  def select_kim_user_by_id_sql(school_id, groups = [])
    select_kim_users_sql(groups) do |opt|
      opt[:conds] << "p.PRNCPL_ID = '#{school_id}'"
    end
  end

  def select_new_group_members_sql(groups, days = 1)
    group_members_sql(groups) do |opt|
      opt[:conds] << "gm.LAST_UPDT_DT > sysdate-#{days}"
    end
  end

  def select_permission_assignees_sql
    return SELECT_PERMISSION_ASSIGNEES
  end

  def select_groups_sql
    return SELECT_GROUPS
  end

  def select_role_ids_sql
    return SELECT_ROLE_IDS
  end

  private

  # opt: { selects, tbls, conds }
  def generate_sql(opt = {}, &block)
    adjust_sql_options(opt)
    yield opt if block_given?
    generate_select_phrase(opt[:selects]) +
    generate_from_phrase(opt[:tbls]) +
    generate_where_phrase(opt[:conds])
  end

  def adjust_sql_options(opt = {})
    opt[:selects] = [] unless opt[:selects]
    opt[:tbls] = [] unless opt[:tbls]
    opt[:conds] = [] unless opt[:conds]
    opt[:selects] = [ opt[:selects] ] if opt[:selects].is_a? String
    opt[:tbls] = [ opt[:tbls] ] if opt[:tbls].is_a? String
    opt[:conds] = [ opt[:conds] ] if opt[:conds].is_a? String
  end

  def generate_select_phrase(selects = nil)
    return SQL_SELECT_BASE
  end

  def generate_from_phrase(tbls = nil)
    sql = SQL_FROM_BASE
    padx = ' ' * 10
    if tbls && !tbls.empty?
      tbls.each do |t|
        sql += padx + ',' + t + "\n"
      end
    end
    sql
  end

  def generate_where_phrase(conds = nil)
    sql = SQL_WHERE_BASE
    pad7 = ' ' * 7
    if conds && !conds.empty?
      conds.each do |c|
        sql += pad7 + 'AND ' + c + "\n"
      end
    end
    sql
  end
end
