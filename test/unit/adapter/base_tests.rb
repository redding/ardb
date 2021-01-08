# frozen_string_literal: true

require "assert"
require "ardb/adapter/base"

require "active_record/migration"
require "ardb"
# This is needed by the schema dumper but it doesn't handle requiring it so we
# have to manually, otherwise this errors when you try to run the adapter base
# tests by themselves
require "active_support/core_ext/class/attribute_accessors"

class Ardb::Adapter::Base
  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @config  = Factory.ardb_config
      @adapter = Ardb::Adapter::Base.new(@config)
    end
    subject{ @adapter }

    should have_readers :config
    should have_imeths :connect_hash, :database, :migrations_path
    should have_imeths :schema_format, :ruby_schema_path, :sql_schema_path
    should have_imeths :escape_like_pattern
    should have_imeths :create_db, :drop_db, :drop_tables
    should have_imeths :connect_db, :migrate_db
    should have_imeths :load_schema, :load_ruby_schema, :load_sql_schema
    should have_imeths :dump_schema, :dump_ruby_schema, :dump_sql_schema

    should "know its config" do
      assert_equal @config, subject.config
    end

    should "demeter its config" do
      assert_equal @config.activerecord_connect_hash, subject.connect_hash
      assert_equal @config.database,                  subject.database
      assert_equal @config.migrations_path,           subject.migrations_path
      assert_equal @config.schema_format,             subject.schema_format
    end

    should "know its ruby and sql schema paths" do
      assert_equal "#{@config.schema_path}.rb",  subject.ruby_schema_path
      assert_equal "#{@config.schema_path}.sql", subject.sql_schema_path
    end

    should "know how to escape like patterns" do
      pattern = "#{Factory.string}%" \
                "#{Factory.string}_" \
                "#{Factory.string}\\" \
                "#{Factory.string} " \
                "#{Factory.string}"
      exp = pattern.gsub("\\"){ "\\\\" }.gsub("%", "\\%").gsub("_", "\\_")
      assert_equal exp, subject.escape_like_pattern(pattern)

      pattern = Factory.string
      assert_equal pattern, subject.escape_like_pattern(pattern)
    end

    should "allow using a custom escape char when escaping like patterns" do
      escape_char = "#"
      pattern = "#{Factory.string}%" \
                "#{Factory.string}_" \
                "#{Factory.string}\\" \
                "#{Factory.string}#{escape_char}" \
                "#{Factory.string} " \
                "#{Factory.string}"
      exp = pattern.gsub(escape_char, "#{escape_char}#{escape_char}")
      exp = exp.gsub("%", "#{escape_char}%").gsub("_", "#{escape_char}_")
      assert_equal exp, subject.escape_like_pattern(pattern, escape_char)
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

    should "know if its equal to another adapter" do
      matching_adapter = Ardb::Adapter::Base.new(@config)
      assert_equal matching_adapter, subject

      non_matching_adapter = Ardb::Adapter::Base.new(Factory.ardb_config)
      assert_not_equal non_matching_adapter, subject
    end
  end

  class ConnectDbTests < UnitTests
    desc "`connect_db`"
    setup do
      @ar_establish_connection_called_with = nil
      Assert.stub(ActiveRecord::Base, :establish_connection) do |options|
        @ar_establish_connection_called_with = options
      end

      @ar_connection_pool = FakeConnectionPool.new
      Assert.stub(ActiveRecord::Base, :connection_pool){ @ar_connection_pool }

      @ar_with_connection_called = false
      Assert.stub(@ar_connection_pool, :with_connection) do
        @ar_with_connection_called = true
      end

      subject.connect_db
    end

    should "use activerecord to establish and then checkout a connection" do
      assert_equal subject.connect_hash, @ar_establish_connection_called_with
      assert_true @ar_with_connection_called
    end
  end

  class MigrateTests < UnitTests
    setup do
      Assert.stub(ActiveRecord::MigrationContext, :new) do |*args|
        @fake_migration_context ||= FakeMigrationContext.new(*args)
      end
    end

    should "migrate the db with `migrate_db`" do
      subject.migrate_db

      assert_equal [subject.migrations_path], @fake_migration_context.init_with
      assert_equal [nil], @fake_migration_context.up_called_with
    end

    should "migrate the db with `migrate_db_up`" do
      subject.migrate_db_up
      assert_equal [nil], @fake_migration_context.up_called_with

      target = Factory.string
      subject.migrate_db_up(target)
      assert_equal [target], @fake_migration_context.up_called_with
    end

    should "migrate the db with `migrate_db_down`" do
      subject.migrate_db_down
      assert_equal [nil], @fake_migration_context.down_called_with

      target = Factory.string
      subject.migrate_db_down(target)
      assert_equal [target], @fake_migration_context.down_called_with
    end

    should "migrate the db with `migrate_db_forward`" do
      subject.migrate_db_forward
      assert_equal [1], @fake_migration_context.forward_called_with

      steps = Factory.integer(3)
      subject.migrate_db_forward(steps)
      assert_equal [steps], @fake_migration_context.forward_called_with
    end

    should "migrate the db with `migrate_db_backward`" do
      subject.migrate_db_backward
      assert_equal [1], @fake_migration_context.rollback_called_with

      steps = Factory.integer(3)
      subject.migrate_db_backward(steps)
      assert_equal [steps], @fake_migration_context.rollback_called_with
    end
  end

  class LoadAndDumpSchemaTests < UnitTests
    setup do
      @orig_stdout = $stdout.dup
      @captured_stdout = ""
      $stdout = StringIO.new(@captured_stdout)

      @adapter = SchemaSpyAdapter.new(@config)
    end
    teardown do
      $stdout = @orig_stdout
    end

    should "load a ruby schema using `load_schema` when the format is ruby" do
      @config.schema_format = Ardb::Config::RUBY_SCHEMA_FORMAT
      adapter = SchemaSpyAdapter.new(@config)

      assert_false adapter.load_ruby_schema_called
      assert_false adapter.load_sql_schema_called
      adapter.load_schema
      assert_true adapter.load_ruby_schema_called
      assert_false adapter.load_sql_schema_called
    end

    should "load a SQL schema using `load_schema` when the format is sql" do
      @config.schema_format = Ardb::Config::SQL_SCHEMA_FORMAT
      adapter = SchemaSpyAdapter.new(@config)

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
      @config.schema_format = Ardb::Config::RUBY_SCHEMA_FORMAT
      adapter = SchemaSpyAdapter.new(@config)

      assert_false adapter.dump_ruby_schema_called
      assert_false adapter.dump_sql_schema_called
      adapter.dump_schema
      assert_true adapter.dump_ruby_schema_called
      assert_false adapter.dump_sql_schema_called

      @config.schema_format = Ardb::Config::SQL_SCHEMA_FORMAT
      adapter = SchemaSpyAdapter.new(@config)

      assert_false adapter.dump_ruby_schema_called
      adapter.dump_schema
      assert_true adapter.dump_ruby_schema_called
    end

    should "dump a SQL schema using `dump_schema` when the format is sql" do
      @config.schema_format = Ardb::Config::SQL_SCHEMA_FORMAT
      adapter = SchemaSpyAdapter.new(@config)

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
      @config.schema_path = File.join(TEST_SUPPORT_PATH, "fake_schema")
      @adapter = Ardb::Adapter::Base.new(@config)
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

  class DumpRubySchemaTests < UnitTests
    setup do
      @config.schema_path =
        File.join(TMP_PATH, "testdb", "test_dump_ruby_schema")
      FileUtils.rm_rf(File.dirname(@config.schema_path))

      @schema_dumper_connection, @schema_dumper_file = [nil, nil]
      Assert.stub(ActiveRecord::SchemaDumper, :dump) do |connection, file|
        @schema_dumper_connection = connection
        @schema_dumper_file       = file
      end

      @fake_connection = FakeConnection.new
      Assert.stub(ActiveRecord::Base, :connection){ @fake_connection }

      @adapter = Ardb::Adapter::Base.new(@config)
    end
    teardown do
      FileUtils.rm_rf(File.dirname(@config.schema_path))
    end

    should "dump a ruby schema file using `dump_ruby_schema`" do
      assert_false File.exist?(subject.ruby_schema_path)
      subject.dump_ruby_schema
      assert_true File.exist?(subject.ruby_schema_path)
      assert_equal @fake_connection, @schema_dumper_connection
      assert_instance_of File, @schema_dumper_file
      assert_equal subject.ruby_schema_path, @schema_dumper_file.path
    end
  end

  class FakeConnection; end

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

  class FakeConnectionPool
    def with_connection(&block)
    end
  end

  class FakeMigrationContext
    attr_reader :init_with
    attr_reader :up_called_with, :down_called_with
    attr_reader :forward_called_with, :rollback_called_with

    def initialize(*args)
      @init_with = args
    end

    def up(*args)
      @up_called_with = args
    end

    def down(*args)
      @down_called_with = args
    end

    def forward(*args)
      @forward_called_with = args
    end

    def rollback(*args)
      @rollback_called_with = args
    end
  end
end
