# frozen_string_literal: true

# Service class for removing leftover Cyndi database objects.
#
# The legacy Cyndi (inventory syndication) integration provisioned the following
# inside the application database via Clowder:
#   - schema:  inventory
#   - table:   inventory.hosts_v1_<generation-id>  (opaque numeric suffix, may be >1)
#   - view:    inventory.hosts
#   - roles:   cyndi, cyndi_admin, cyndi_reader
#
# The code/config was removed in RHINENG-23305, but these objects remain in the
# already-provisioned databases. This service discovers and drops them.
#
# SAFETY:
#   - Callers run in DRY-RUN mode by default; destructive DDL only executes when
#     confirm: true is passed.
#   - Object drops and role drops each run inside their own transaction so a
#     partial failure rolls back cleanly rather than leaving a half-dropped DB.
#   - Role removal is gated behind drop_roles: true AND is preceded by an
#     ownership pre-check (local + cluster-wide) that aborts the role phase if a
#     cyndi role still owns anything, rather than failing mid-DROP.
#   - Only the known cyndi roles (see ROLE_DROP_ORDER) are dropped, in a fixed
#     dependency order. Any unexpected cyndi* role is reported and skipped — the
#     ordering for an unknown role's dependency graph is not assumed.
# rubocop:disable Metrics/ClassLength
class CyndiCleaner
  SCHEMA = 'inventory'
  TABLE_PATTERN = '^hosts_v1_[0-9]+$'
  # The only Cyndi-provisioned view. We do NOT drop arbitrary views that may
  # exist in the schema — only this documented one.
  VIEW_NAME = 'hosts'
  # Ordered dependents-first: readers/members before the base role.
  ROLE_DROP_ORDER = %w[cyndi_reader cyndi_admin cyndi].freeze

  class RolePreconditionError < StandardError; end

  def initialize(logger:)
    @logger = logger
  end

  # Inspect the database for leftover Cyndi objects.
  def discover
    {
      schema: discover_schema,
      tables: discover_tables,
      views: discover_views,
      roles: discover_roles
    }
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def run(confirm:, drop_roles:)
    found = discover

    if empty?(found)
      @logger.info('cyndi:cleanup: no Cyndi objects found — nothing to remove.')
      return
    end

    log_plan(found, drop_roles)

    unless confirm
      @logger.info('cyndi:cleanup: DRY RUN — no changes made. Re-run with CONFIRM=true to execute.')
      return
    end

    drop_objects(found)
    drop_cyndi_roles(found[:roles]) if drop_roles
    @logger.info('cyndi:cleanup: completed.')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def connection
    ActiveRecord::Base.connection
  end

  def empty?(found)
    found[:schema].nil? && found[:tables].empty? && found[:views].empty? && found[:roles].empty?
  end

  def discover_schema
    connection.select_values(
      "SELECT nspname FROM pg_namespace WHERE nspname = '#{SCHEMA}'"
    ).first
  end

  def discover_tables
    connection.select_values(<<~SQL.squish)
      SELECT c.relname
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = '#{SCHEMA}'
        AND c.relkind = 'r'
        AND c.relname ~ '#{TABLE_PATTERN}'
      ORDER BY c.relname
    SQL
  end

  # Only the documented Cyndi view (inventory.hosts). Other views that happen to
  # live in the schema are intentionally left alone.
  def discover_views
    connection.select_values(<<~SQL.squish)
      SELECT c.relname
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = '#{SCHEMA}'
        AND c.relkind = 'v'
        AND c.relname = '#{VIEW_NAME}'
      ORDER BY c.relname
    SQL
  end

  def discover_roles
    connection.select_values(
      "SELECT rolname FROM pg_roles WHERE rolname ~ 'cyndi' ORDER BY rolname"
    )
  end

  # rubocop:disable Metrics/AbcSize
  def log_plan(found, drop_roles)
    @logger.info('cyndi:cleanup: the following Cyndi leftovers were found:')
    found[:views].each { |v| @logger.info("  VIEW   #{qualified(v)}") }
    found[:tables].each { |t| @logger.info("  TABLE  #{qualified(t)}") }
    @logger.info("  SCHEMA #{quote_ident(found[:schema])}") if found[:schema]
    if drop_roles
      found[:roles].each { |r| @logger.info("  ROLE   #{quote_ident(r)}") }
    elsif found[:roles].any?
      @logger.info("  (#{found[:roles].size} cyndi role(s) present; pass DROP_ROLES=true to remove them)")
    end
  end
  # rubocop:enable Metrics/AbcSize

  # Drop view(s) first, then versioned table(s), then the (empty) schema.
  # Wrapped in a transaction: if DROP SCHEMA ... RESTRICT aborts (unexpected
  # objects remain), the view/table drops roll back so the DB stays consistent.
  def drop_objects(found)
    connection.transaction(requires_new: true) do
      found[:views].each do |view|
        execute(%(DROP VIEW IF EXISTS #{qualified(view)}))
      end

      # RESTRICT (default): the view was dropped just above, so nothing legitimate
      # depends on the table anymore. If some unexpected object still does, fail
      # loudly rather than cascade-dropping it.
      found[:tables].each do |table|
        execute(%(DROP TABLE IF EXISTS #{qualified(table)} RESTRICT))
      end

      next unless found[:schema]

      # RESTRICT: fail loudly if unexpected objects remain rather than cascading blindly.
      execute(%(DROP SCHEMA IF EXISTS #{quote_ident(found[:schema])} RESTRICT))
    end
  end

  # Drop the known cyndi roles, after verifying none still own objects.
  # Wrapped in a transaction so a mid-sequence failure rolls back cleanly.
  def drop_cyndi_roles(roles)
    droppable = partition_roles(roles)
    return if droppable.empty?

    assert_roles_own_nothing!(droppable)

    connection.transaction(requires_new: true) do
      # Two passes: DROP OWNED for ALL roles must precede any DROP ROLE, since a
      # role cannot be dropped while another still references it via grants.
      # Do not combine these loops.
      #
      # RESTRICT (default): assert_roles_own_nothing! above guarantees the roles
      # own no objects, so DROP OWNED only revokes grants here. RESTRICT keeps it
      # from cascade-dropping objects owned by *other* users if that guarantee is
      # ever violated.
      # rubocop:disable Style/CombinableLoops
      droppable.each { |role| execute(%(DROP OWNED BY #{quote_ident(role)} RESTRICT)) }
      droppable.each { |role| execute(%(DROP ROLE IF EXISTS #{quote_ident(role)})) }
      # rubocop:enable Style/CombinableLoops
    end
  rescue RolePreconditionError => e
    @logger.warn("cyndi:cleanup: role removal aborted — #{e.message}")
    raise
  end

  # Return only the known roles, in fixed dependency order. Unknown cyndi* roles
  # are reported and skipped — their dependency ordering is not assumed.
  def partition_roles(roles)
    unknown = roles - ROLE_DROP_ORDER
    unknown.each do |role|
      @logger.warn(
        "cyndi:cleanup: skipping unexpected role #{quote_ident(role)} — not in the known " \
        'drop order; inspect its membership/ownership and drop it manually.'
      )
    end
    ROLE_DROP_ORDER & roles
  end

  # Abort before dropping if any target role still owns objects in THIS database
  # (pg_class) or ANY database in the cluster (pg_shdepend). DROP OWNED only
  # affects the current DB, so cross-DB ownership would make DROP ROLE fail
  # mid-sequence — we detect it up front instead.
  # rubocop:disable Metrics/MethodLength
  def assert_roles_own_nothing!(roles)
    local = connection.select_values(
      ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL.squish, roles]
          SELECT n.nspname || '.' || c.relname
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE pg_get_userbyid(c.relowner) IN (?)
        SQL
      )
    )

    cluster = connection.select_values(
      ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL.squish, roles]
          SELECT DISTINCT d.datname
          FROM pg_shdepend s
          JOIN pg_roles r ON r.oid = s.refobjid
          LEFT JOIN pg_database d ON d.oid = s.dbid
          WHERE r.rolname IN (?)
            AND s.deptype IN ('o', 'a')
        SQL
      )
    )

    return if local.empty? && cluster.empty?

    raise RolePreconditionError,
          "cyndi role(s) still own objects (local: #{local.presence || 'none'}; " \
          "other databases: #{cluster.presence || 'none'}). Run DROP OWNED BY in each " \
          'listed database, or reassign ownership, before dropping the roles.'
  end
  # rubocop:enable Metrics/MethodLength

  def execute(sql)
    @logger.info("cyndi:cleanup: executing: #{sql}")
    connection.execute(sql)
  end

  def qualified(relation)
    "#{quote_ident(SCHEMA)}.#{quote_ident(relation)}"
  end

  def quote_ident(identifier)
    connection.quote_column_name(identifier)
  end
end
# rubocop:enable Metrics/ClassLength
