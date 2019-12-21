require "assert"
require "ardb/adapter/sqlite"

class Ardb::Adapter::Sqlite
  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Sqlite"
    setup do
      @config  = Factory.ardb_config
      @adapter = Ardb::Adapter::Sqlite.new(@config)
    end
    subject{ @adapter }

    should have_imeths :db_file_path, :validate!

    should "complain if the db file already exists" do
      FileUtils.mkdir_p(File.dirname(subject.db_file_path))
      FileUtils.touch(subject.db_file_path)
      assert_raises(RuntimeError){ subject.validate! }
      FileUtils.rm(subject.db_file_path)
    end

    should "know its db file path" do
      exp = File.expand_path(@config.database, @config.root_path)
      assert_equal exp, subject.db_file_path

      @config.database = File.join(TMP_PATH, "abs_sqlite_db_test")
      adapter = Ardb::Adapter::Sqlite.new(@config)
      assert_equal @config.database, adapter.db_file_path
    end

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError){ subject.foreign_key_add_sql }
      assert_raises(NotImplementedError){ subject.foreign_key_drop_sql }
    end

    # not currently implemented, see: https://github.com/redding/ardb/issues/29
    should "not implement the drop tables method" do
      assert_raises(NotImplementedError){ subject.drop_tables }
    end
  end
end
