require 'assert'
require 'ardb/adapter_spy'

module Ardb::AdapterSpy

  class MyAdapter
    include Ardb::AdapterSpy
  end

  class BaseTests < Assert::Context
    desc "Ardb::AdapterSpy"
    setup do
      @adapter = MyAdapter.new
    end
    subject{ @adapter }

    should have_accessors :drop_tables_called_count, :load_schema_called_count
    should have_accessors :drop_db_called_count, :create_db_called_count
    should have_imeths :drop_tables, :load_schema, :drop_db, :create_db

    should "included the record spy instance methods" do
      assert_includes Ardb::AdapterSpy::InstanceMethods, subject.class.included_modules
    end

    should "default all call counts to zero" do
      assert_equal 0, subject.drop_tables_called_count
      assert_equal 0, subject.load_schema_called_count
      assert_equal 0, subject.drop_db_called_count
      assert_equal 0, subject.create_db_called_count
    end

    should "add a call count when each method is called" do
      subject.drop_tables
      assert_equal 1, subject.drop_tables_called_count

      subject.load_schema
      assert_equal 1, subject.load_schema_called_count

      subject.drop_db
      assert_equal 1, subject.drop_db_called_count

      subject.create_db
      assert_equal 1, subject.create_db_called_count
    end

  end

  class NewMethTests < BaseTests
    desc "`new` method"
    setup do
      @adapter_spy_class = Ardb::AdapterSpy.new do
        attr_accessor :name
      end
      @adapter = @adapter_spy_class.new
    end
    subject{ @adapter }

    should "build a new spy class and use any custom definition" do
      assert_includes Ardb::AdapterSpy, subject.class.included_modules
      assert subject.respond_to? :name
      assert subject.respond_to? :name=
    end

  end

end
