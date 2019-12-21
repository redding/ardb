require "assert"
require "ardb/adapter/mysql"

class Ardb::Adapter::Mysql
  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Mysql"
    setup do
      @config  = Factory.ardb_config
      @adapter = Ardb::Adapter::Mysql.new(@config)
    end
    subject{ @adapter }

    # not currently implemented, see: https://github.com/redding/ardb/issues/13
    should "not implement the create and drop db methods" do
      assert_raises(NotImplementedError){ subject.create_db }
      assert_raises(NotImplementedError){ subject.drop_db }
    end

    # not currently implemented, see: https://github.com/redding/ardb/issues/28
    should "not implement the drop tables method" do
      assert_raises(NotImplementedError){ subject.drop_tables }
    end
  end
end
