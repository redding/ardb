require 'assert'
require 'ardb/adapter/sqlite'

class Ardb::Adapter::Sqlite

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Sqlite"
    setup do
      @adapter = Ardb::Adapter::Sqlite.new
    end
    subject { @adapter }

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError) { subject.foreign_key_add_sql }
      assert_raises(NotImplementedError) { subject.foreign_key_drop_sql }
    end

  end

end
