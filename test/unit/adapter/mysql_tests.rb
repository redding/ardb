require 'assert'
require 'ardb/adapter/mysql'

class Ardb::Adapter::Mysql

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Mysql"
    setup do
      @adapter = Ardb::Adapter::Mysql.new
    end
    subject { @adapter }

    should "know its foreign key add sql" do
      exp_add_sql = "ALTER TABLE :from_table"\
                    " ADD CONSTRAINT :name"\
                    " FOREIGN KEY (:from_column)"\
                    " REFERENCES :to_table (:to_column)"
      assert_equal exp_add_sql, subject.foreign_key_add_sql
    end

    should "know its foreign key drop sql" do
      exp_drop_sql = "ALTER TABLE :from_table"\
                     " DROP FOREIGN KEY :name"
      assert_equal exp_drop_sql, subject.foreign_key_drop_sql
    end

    # not currently implemented, see: https://github.com/redding/ardb/issues/13
    should "not implement the create and drop db methods" do
      assert_raises(NotImplementedError) { subject.create_db }
      assert_raises(NotImplementedError) { subject.drop_db }
    end

    # not currently implemented, see: https://github.com/redding/ardb/issues/28
    should "not implement the drop tables method" do
      assert_raises(NotImplementedError) { subject.drop_tables }
    end

  end

end
