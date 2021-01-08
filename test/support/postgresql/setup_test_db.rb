# frozen_string_literal: true

require "assert"
require "ardb"

class PostgresqlDbTests < Assert::Context
  setup do
    @orig_env_ardb_db_file    = ENV["ARDB_DB_FILE"]
    ActiveRecord::Base.logger = @orig_ar_loggerF

    # we"re manually configuring ardb so we don"t need this to do anything
    ENV["ARDB_DB_FILE"] = File.join(TEST_SUPPORT_PATH, "require_test_db_file")

    @ardb_config = Ardb::Config.new.tap do |c|
      c.adapter      = "postgresql"
      c.database     = "redding_ardb_test"
      c.encoding     = "unicode"
      c.min_messages = "WARNING"

      c.logger          = TEST_LOGGER
      c.root_path       = File.join(TEST_SUPPORT_PATH, "postgresql")
      c.migrations_path = "migrations"
      c.schema_path     = "schema"
      c.schema_format   = :ruby
    end
    Assert.stub(Ardb, :config){ @ardb_config }

    Ardb.init(false)

    Ardb.adapter.drop_db
    Ardb.adapter.create_db
    Ardb.adapter.load_schema
    Ardb.adapter.connect_db
  end
  teardown do
    Ardb.reset_adapter
    ActiveRecord::Base.logger = @orig_ar_logger
    ENV["ARDB_DB_FILE"]       = @orig_env_ardb_db_file
  end

  private

  # useful when testing creating/dropping/migrating DBs
  def silence_stdout
    current_stdout = $stdout.dup
    $stdout = File.new("/dev/null", "w")
    begin
      yield
    ensure
      $stdout = current_stdout
    end
  end
end
