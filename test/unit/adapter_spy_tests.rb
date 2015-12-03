require 'assert'
require 'ardb/adapter_spy'

module Ardb::AdapterSpy

  class MyAdapter
    include Ardb::AdapterSpy
  end

  class UnitTests < Assert::Context
    desc "Ardb::AdapterSpy"
    setup do
      @adapter = MyAdapter.new
    end
    subject{ @adapter }

    should have_accessors :drop_tables_called_count
    should have_accessors :dump_schema_called_count, :load_schema_called_count
    should have_accessors :drop_db_called_count, :create_db_called_count
    should have_accessors :migrate_db_called_count
    should have_imeths :drop_tables_called?, :drop_tables
    should have_imeths :dump_schema_called?, :dump_schema
    should have_imeths :load_schema_called?, :load_schema
    should have_imeths :drop_db_called?, :drop_db
    should have_imeths :create_db_called?, :create_db
    should have_imeths :migrate_db_called?, :migrate_db

    should "included the record spy instance methods" do
      assert_includes Ardb::AdapterSpy::InstanceMethods, subject.class
    end

    should "default all call counts to zero" do
      assert_equal 0, subject.drop_tables_called_count
      assert_equal 0, subject.dump_schema_called_count
      assert_equal 0, subject.load_schema_called_count
      assert_equal 0, subject.drop_db_called_count
      assert_equal 0, subject.create_db_called_count
      assert_equal 0, subject.migrate_db_called_count
    end

    should "know if and how many times a method is called" do
      assert_equal false, subject.drop_tables_called?
      subject.drop_tables
      assert_equal 1, subject.drop_tables_called_count
      assert_equal true, subject.drop_tables_called?

      assert_equal false, subject.dump_schema_called?
      subject.dump_schema
      assert_equal 1, subject.dump_schema_called_count
      assert_equal true, subject.dump_schema_called?

      assert_equal false, subject.load_schema_called?
      subject.load_schema
      assert_equal 1, subject.load_schema_called_count
      assert_equal true, subject.load_schema_called?

      assert_equal false, subject.drop_db_called?
      subject.drop_db
      assert_equal 1, subject.drop_db_called_count
      assert_equal true, subject.drop_db_called?

      assert_equal false, subject.create_db_called?
      subject.create_db
      assert_equal 1, subject.create_db_called_count
      assert_equal true, subject.create_db_called?

      assert_equal false, subject.migrate_db_called?
      subject.migrate_db
      assert_equal 1, subject.migrate_db_called_count
      assert_equal true, subject.migrate_db_called?
    end

  end

  class NewMethTests < UnitTests
    desc "`new` method"
    setup do
      @adapter_spy_class = Ardb::AdapterSpy.new do
        attr_accessor :name
      end
      @adapter = @adapter_spy_class.new
    end
    subject{ @adapter }

    should "build a new spy class and use any custom definition" do
      assert_includes Ardb::AdapterSpy, subject.class
      assert subject.respond_to? :name
      assert subject.respond_to? :name=
    end

  end

end
