require 'assert'
require 'ardb/adapter/sqlite'

class Ardb::Adapter::Sqlite

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Sqlite"
    setup do
      @adapter = Ardb::Adapter::Sqlite.new
    end
    subject { @adapter }

    should have_imeths :db_file_path, :validate!

    should "complain if the db file already exists" do
      FileUtils.mkdir_p(File.dirname(subject.db_file_path))
      FileUtils.touch(subject.db_file_path)
      assert_raises(Ardb::Runner::CmdError) { subject.validate! }
      FileUtils.rm(subject.db_file_path)
    end

    should "know its db_file_path" do
      exp_path = Ardb.config.root_path.join(Ardb.config.db.database).to_s
      assert_equal exp_path, subject.db_file_path
    end

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError) { subject.foreign_key_add_sql }
      assert_raises(NotImplementedError) { subject.foreign_key_drop_sql }
    end

  end

end
