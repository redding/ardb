require 'assert'
require 'ardb/adapter/base'

class Ardb::Adapter::Base

  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @adapter = Ardb::Adapter::Base.new
    end
    subject{ @adapter }

    should have_readers :config_settings, :database
    should have_readers :ruby_schema_path, :sql_schema_path
    should have_imeths :foreign_key_add_sql, :foreign_key_drop_sql
    should have_imeths :create_db, :drop_db, :migrate_db
    should have_imeths :load_schema, :load_ruby_schema, :load_sql_schema
    should have_imeths :dump_schema, :dump_ruby_schema, :dump_sql_schema

    should "know its config settings " do
      assert_equal Ardb.config.db_settings, subject.config_settings
    end

    should "know its database" do
      assert_equal Ardb.config.db.database, subject.database
    end

    should "know its schema paths" do
      assert_equal "#{Ardb.config.schema_path}.rb",  subject.ruby_schema_path
      assert_equal "#{Ardb.config.schema_path}.sql", subject.sql_schema_path
    end

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError){ subject.foreign_key_add_sql }
      assert_raises(NotImplementedError){ subject.foreign_key_drop_sql }
    end

    should "not implement the create and drop db methods" do
      assert_raises(NotImplementedError){ subject.create_db }
      assert_raises(NotImplementedError){ subject.drop_db }
    end

    should "not implement the drop table methods" do
      assert_raises(NotImplementedError){ subject.drop_tables }
    end

    should "not implement the load and dump sql schema methods" do
      assert_raises(NotImplementedError){ subject.load_sql_schema }
      assert_raises(NotImplementedError){ subject.dump_sql_schema }
    end

  end

  class MigrateDbTests < UnitTests
    desc "`migrate_db`"
    setup do
      ENV["MIGRATE_VERSION"] = Factory.integer.to_s if Factory.boolean
      ENV["MIGRATE_QUIET"]   = Factory.boolean.to_s if Factory.boolean

      @migrator_called_with = []
      Assert.stub(ActiveRecord::Migrator, :migrate) do |*args|
        @migrator_called_with = args
      end

      @adapter.migrate_db
    end

    should "add the Ardb MigrationHelper Recorder to the ActiveRecord Command Recorder" do
      exp = Ardb::MigrationHelpers::RecorderMixin
      assert_includes exp, ActiveRecord::Migration::CommandRecorder
    end

    should "set the ActiveRecord Migrator's migrations path" do
      exp = Ardb.config.migrations_path
      assert_equal exp, ActiveRecord::Migrator.migrations_path
    end

    should "set the ActiveRecord Migration's verbose" do
      exp = ENV["MIGRATE_QUIET"].nil?
      assert_equal exp, ActiveRecord::Migration.verbose
    end

    should "call the ActiveRecord Migrator's migrate" do
      version = ENV.key?("MIGRATE_VERSION") ? ENV["MIGRATE_VERSION"].to_i : nil
      exp = [Ardb.config.migrations_path, version]
      assert_equal exp, @migrator_called_with
    end

  end

  class LoadAndDumpSchemaTests < UnitTests
    setup do
      @orig_stdout = $stdout.dup
      @captured_stdout = ""
      $stdout = StringIO.new(@captured_stdout)

      @orig_schema_format = Ardb.config.schema_format

      @adapter = SchemaSpyAdapter.new
    end
    teardown do
      Ardb.config.schema_format = @orig_schema_format
      $stdout = @orig_stdout
    end

    should "load a ruby schema using `load_schema` when the format is ruby" do
      Ardb.config.schema_format = :ruby
      adapter = SchemaSpyAdapter.new

      assert_false adapter.load_ruby_schema_called
      assert_false adapter.load_sql_schema_called
      adapter.load_schema
      assert_true adapter.load_ruby_schema_called
      assert_false adapter.load_sql_schema_called
    end

    should "load a SQL schema using `load_schema` when the format is sql" do
      Ardb.config.schema_format = :sql
      adapter = SchemaSpyAdapter.new

      assert_false adapter.load_ruby_schema_called
      assert_false adapter.load_sql_schema_called
      adapter.load_schema
      assert_false adapter.load_ruby_schema_called
      assert_true adapter.load_sql_schema_called
    end

    should "suppress stdout when loading the schema" do
      subject.load_schema
      assert_empty @captured_stdout
    end

    should "always dump a ruby schema using `dump_schema`" do
      Ardb.config.schema_format = :ruby
      adapter = SchemaSpyAdapter.new

      assert_false adapter.dump_ruby_schema_called
      assert_false adapter.dump_sql_schema_called
      adapter.dump_schema
      assert_true adapter.dump_ruby_schema_called
      assert_false adapter.dump_sql_schema_called

      Ardb.config.schema_format = :sql
      adapter = SchemaSpyAdapter.new

      assert_false adapter.dump_ruby_schema_called
      adapter.dump_schema
      assert_true adapter.dump_ruby_schema_called
    end

    should "dump a SQL schema using `dump_schema` when the format is sql" do
      Ardb.config.schema_format = :sql
      adapter = SchemaSpyAdapter.new

      assert_false adapter.dump_ruby_schema_called
      adapter.dump_schema
      assert_true adapter.dump_ruby_schema_called
    end

    should "suppress stdout when dumping the schema" do
      subject.load_schema
      assert_empty @captured_stdout
    end

  end

  class LoadRubySchemaTests < UnitTests
    setup do
      @orig_schema_path = Ardb.config.schema_path
      Ardb.config.schema_path = 'fake_schema'

      @adapter = Ardb::Adapter::Base.new
    end
    teardown do
      Ardb.config.schema_path = @orig_schema_path
    end

    should "load a ruby schema file using `load_ruby_schema`" do
      assert_nil defined?(FAKE_SCHEMA)
      subject.load_ruby_schema
      assert_not_nil defined?(FAKE_SCHEMA)
      assert_equal 1, FAKE_SCHEMA.load_count
      subject.load_ruby_schema
      assert_equal 2, FAKE_SCHEMA.load_count
    end

  end

  class SchemaSpyAdapter < Ardb::Adapter::Base
    attr_reader :load_ruby_schema_called, :dump_ruby_schema_called
    attr_reader :load_sql_schema_called, :dump_sql_schema_called

    def initialize(*args)
      super
      @load_ruby_schema_called = false
      @dump_ruby_schema_called = false
      @load_sql_schema_called  = false
      @dump_sql_schema_called  = false
    end

    def load_ruby_schema
      puts "[load_ruby_schema] This should be suppressed!"
      @load_ruby_schema_called = true
    end

    def dump_ruby_schema
      puts "[dump_ruby_schema] This should be suppressed!"
      @dump_ruby_schema_called = true
    end

    def load_sql_schema
      puts "[load_sql_schema] This should be suppressed!"
      @load_sql_schema_called = true
    end

    def dump_sql_schema
      puts "[dump_sql_schema] This should be suppressed!"
      @dump_sql_schema_called = true
    end
  end

end
