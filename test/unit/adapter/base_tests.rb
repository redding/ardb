require 'assert'
require 'ardb/adapter/base'

class Ardb::Adapter::Base

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @adapter = Ardb::Adapter::Base.new
    end
    subject { @adapter }

    should have_reader :config_settings, :database
    should have_imeths :foreign_key_add_sql, :foreign_key_drop_sql
    should have_imeths :create_db, :drop_db, :load_schema

    should "use the config's db settings " do
      assert_equal Ardb.config.db_settings, subject.config_settings
    end

    should "use the config's database" do
      assert_equal Ardb.config.db.database, subject.database
    end

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError) { subject.foreign_key_add_sql }
      assert_raises(NotImplementedError) { subject.foreign_key_drop_sql }
    end

    should "not implement the create and drop db methods" do
      assert_raises(NotImplementedError) { subject.create_db }
      assert_raises(NotImplementedError) { subject.drop_db }
    end

    should "not implement the drop table methods" do
      assert_raises(NotImplementedError) { subject.drop_tables }
    end

  end

  class LoadSchemaTests < BaseTests
    desc "given a schema"
    setup do
      ::FAKE_SCHEMA_LOAD = OpenStruct.new(:count => 0)
      @orig_schema_path = Ardb.config.schema_path
      Ardb.config.schema_path = 'fake_schema.rb'
    end
    teardown do
      Ardb.config.schema_path = @orig_schema_path
    end

    should "load the schema suppressing $stdout" do
      orig_stdout = $stdout.dup
      captured_stdout = ""
      $stdout = StringIO.new(captured_stdout)

      assert_equal 0, FAKE_SCHEMA_LOAD.count
      subject.load_schema
      assert_equal 1, FAKE_SCHEMA_LOAD.count
      subject.load_schema
      assert_equal 2, FAKE_SCHEMA_LOAD.count
      assert_empty captured_stdout

      $stdout = orig_stdout
    end

  end

end
