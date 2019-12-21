require "assert"
require "ardb/adapter_spy"

class Ardb::AdapterSpy
  class UnitTests < Assert::Context
    desc "Ardb::AdapterSpy"
    setup do
      @adapter_spy_class = Ardb::AdapterSpy
    end
    subject{ @adapter_spy_class }

    should "be a kind of ardb adapter" do
      assert subject < Ardb::Adapter::Base
    end
  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @config      = Factory.ardb_config
      @adapter_spy = @adapter_spy_class.new(@config)
    end
    subject{ @adapter_spy }

    should have_accessors :drop_tables_called_count
    should have_accessors :dump_schema_called_count, :load_schema_called_count
    should have_accessors :drop_db_called_count, :create_db_called_count
    should have_accessors :connect_db_called_count, :migrate_db_called_count
    should have_imeths :foreign_key_add_sql, :foreign_key_drop_sql
    should have_imeths :create_db_called?, :drop_db_called?, :drop_tables_called?
    should have_imeths :connect_db_called?, :migrate_db_called?
    should have_imeths :dump_schema_called?, :load_schema_called?
    should have_imeths :create_db, :drop_db, :drop_tables
    should have_imeths :connect_db, :migrate_db
    should have_imeths :dump_schema, :load_schema

    should "default all call counts to zero" do
      assert_equal 0, subject.create_db_called_count
      assert_equal 0, subject.drop_db_called_count
      assert_equal 0, subject.drop_tables_called_count
      assert_equal 0, subject.connect_db_called_count
      assert_equal 0, subject.migrate_db_called_count
      assert_equal 0, subject.load_schema_called_count
      assert_equal 0, subject.dump_schema_called_count
    end

    should "know its add and drop foreign key sql" do
      exp = "FAKE ADD FOREIGN KEY SQL :from_table :from_column " \
            ":to_table :to_column :name"
      assert_equal exp, subject.foreign_key_add_sql
      exp = "FAKE DROP FOREIGN KEY SQL :from_table :from_column " \
            ":to_table :to_column :name"
      assert_equal exp, subject.foreign_key_drop_sql
    end

    should "know if and how many times a method is called" do
      assert_equal false, subject.create_db_called?
      subject.create_db
      assert_equal 1, subject.create_db_called_count
      assert_equal true, subject.create_db_called?

      assert_equal false, subject.drop_db_called?
      subject.drop_db
      assert_equal 1, subject.drop_db_called_count
      assert_equal true, subject.drop_db_called?

      assert_equal false, subject.drop_tables_called?
      subject.drop_tables
      assert_equal 1, subject.drop_tables_called_count
      assert_equal true, subject.drop_tables_called?

      assert_equal false, subject.connect_db_called?
      subject.connect_db
      assert_equal 1, subject.connect_db_called_count
      assert_equal true, subject.connect_db_called?

      assert_equal false, subject.migrate_db_called?
      subject.migrate_db
      assert_equal 1, subject.migrate_db_called_count
      assert_equal true, subject.migrate_db_called?

      assert_equal false, subject.dump_schema_called?
      subject.dump_schema
      assert_equal 1, subject.dump_schema_called_count
      assert_equal true, subject.dump_schema_called?

      assert_equal false, subject.load_schema_called?
      subject.load_schema
      assert_equal 1, subject.load_schema_called_count
      assert_equal true, subject.load_schema_called?
    end
  end
end
