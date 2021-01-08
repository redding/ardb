require "assert"
require "ardb/use_db_default"

require "much-mixin"
require "ardb/record_spy"

module Ardb::UseDbDefault
  class UnitTests < Assert::Context
    desc "Ardb::UseDbDefault"
    setup do
      @record_class = Class.new do
        include UseDbDefaultRecordSpy
        include Ardb::UseDbDefault
      end
    end
    subject{ @record_class }

    should have_imeths :use_db_default, :ardb_use_db_default_attrs

    should "use much-mixin" do
      assert_includes MuchMixin, Ardb::UseDbDefault
    end

    should "know its use db default attrs" do
      assert_equal [], subject.ardb_use_db_default_attrs
    end

    should "add use db default attributes using `use_db_default`" do
      an_attr_name = Factory.string
      subject.use_db_default(an_attr_name)
      assert_includes an_attr_name, subject.ardb_use_db_default_attrs

      attr_names = [Factory.string, Factory.string.to_sym]
      subject.use_db_default(*attr_names)
      attr_names.each do |attr_name|
        assert_includes attr_name.to_s, subject.ardb_use_db_default_attrs
      end
    end

    should "not add duplicate attributes using `use_db_default`" do
      attr_name = Factory.string
      subject.use_db_default(attr_name)
      assert_equal [attr_name], subject.ardb_use_db_default_attrs

      subject.use_db_default(attr_name)
      assert_equal [attr_name], subject.ardb_use_db_default_attrs

      more_attr_names = [attr_name, Factory.string]
      subject.use_db_default(*more_attr_names)
      exp = ([attr_name] + more_attr_names).uniq
      assert_equal exp, subject.ardb_use_db_default_attrs
    end

    should "add an around create callback" do
      callback = subject.callbacks.first
      assert_equal :around_create, callback.type
      exp = [:ardb_allow_db_to_default_attrs]
      assert_equal exp, callback.args
    end
  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @attr_names = Factory.integer(3).times.map{ Factory.string }
      @record_class.use_db_default(*@attr_names)

      @record = @record_class.new

      # simulate activerecords `@attributes` hash
      @original_attrs = @attr_names.inject({}) do |h, n|
        h.merge!(n => [nil, Factory.string, Factory.integer].sample)
      end
      @original_attrs.merge!(Factory.string => Factory.string)
      @record.attributes = @original_attrs.dup

      # randomly pick a use-db-default attribute to be changed
      @record.changed_use_db_default_attrs = [@attr_names.sample]
      @unchanged_attr_names = @attr_names - @record.changed_use_db_default_attrs

      # we should always get the record we just inserted back
      @record_class.relation_spy.results = [@record]
      # add pluck values into the relation spy
      @record_class.relation_spy.pluck_values = @attr_names.inject({}) do |h, n|
        h.merge!(n => Factory.string)
      end
    end
    subject{ @record }

    should "remove use-db-default attributes before being created" do
      # around create callbacks yield to create the record so we have to pass a
      # block, this will allow us to see what was done to the attributes hash
      # when it was created (yielded)
      attrs_before_yield = nil
      subject.instance_eval do
        ardb_allow_db_to_default_attrs{ attrs_before_yield = self.attributes.dup }
      end

      assert_instance_of Hash, attrs_before_yield
      @unchanged_attr_names.each do |name|
        assert_false attrs_before_yield.key?(name)
      end

      # the non use-db-default attrs and changed use-db-default attrs hash
      # values should have their original values when yielded
      (@original_attrs.keys - @unchanged_attr_names).each do |name|
        assert_equal @original_attrs[name], attrs_before_yield[name]
      end
    end

    should "set use-db-default values after its created" do
      # around create callbacks yield to create the record so we have to pass a
      # block, this simulates creating the record by setting the id
      subject.instance_eval do
        ardb_allow_db_to_default_attrs{ self.id = Factory.integer }
      end

      applied_expr = @record_class.relation_spy.applied.first
      assert_equal :where, applied_expr.type
      assert_equal [{ :id => subject.id }], applied_expr.args

      @unchanged_attr_names.each do |name|
        exp = @record_class.relation_spy.pluck_values[name]
        assert_equal exp, subject.attributes[name]
      end

      # the non use-db-default attrs and changed use-db-default attrs hash
      # values should still have their original values
      (@original_attrs.keys - @unchanged_attr_names).each do |name|
        assert_equal @original_attrs[name], subject.attributes[name]
      end
    end
  end

  module UseDbDefaultRecordSpy
    def self.included(klass)
      klass.class_eval{ include Ardb::RecordSpy }
    end

    attr_accessor :id
    attr_accessor :attributes, :changed_use_db_default_attrs

    def use_db_default_attr_changed?(attr_name)
      self.changed_use_db_default_attrs.include?(attr_name)
    end

    def method_missing(method, *args, &block)
      match_data = method.to_s.match(/(\w+)_changed\?/)
      if match_data && match_data[1]
        self.use_db_default_attr_changed?(match_data[1])
      else
        super
      end
    end
  end
end
