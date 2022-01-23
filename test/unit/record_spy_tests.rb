# frozen_string_literal: true

require "assert"
require "ardb/record_spy"

require "much-mixin"

module Ardb::RecordSpy
  class UnitTests < Assert::Context
    desc "Ardb::RecordSpy"
    setup do
      @record_spy_class =
        Class.new do
          include Ardb::RecordSpy
          attr_accessor :name
        end
    end
    subject{ @record_spy_class }

    should have_accessors :table_name
    should have_imeths :associations
    should have_imeths :belongs_to, :has_many, :has_one
    should have_imeths :validations
    should have_imeths :validates_acceptance_of, :validates_confirmation_of
    should have_imeths :validates_exclusion_of,  :validates_format_of
    should have_imeths :validates_inclusion_of, :validates_length_of
    should have_imeths :validates_numericality_of, :validates_presence_of
    should have_imeths :validates_size_of, :validates_uniqueness_of
    should have_imeths :validates_associated, :validates_with, :validates_each
    should have_imeths :validate
    should have_imeths :callbacks
    should have_imeths :before_validation, :after_validation
    should have_imeths :before_create,  :around_create,  :after_create
    should have_imeths :before_update,  :around_update,  :after_update
    should have_imeths :before_save,    :around_save,    :after_save
    should have_imeths :before_destroy, :around_destroy, :after_destroy
    should have_imeths :after_commit, :after_rollback
    should have_imeths :after_initialize, :after_find
    should have_imeths :custom_callback_types, :define_model_callbacks
    should have_writers :relation_spy
    should have_imeths :relation_spy, :arel_table, :scoped
    should have_imeths :select, :from, :includes, :joins, :where
    should have_imeths :group, :having, :order, :reverse_order, :readonly
    should have_imeths :limit, :offset, :merge, :except, :only

    should "use much-mixin" do
      assert_includes MuchMixin, Ardb::RecordSpy
    end

    should "allow reading and writing the record's table name" do
      subject.table_name = "my_records"
      assert_equal "my_records", subject.table_name
    end

    should "default its associations" do
      assert_equal [], subject.associations
    end

    should "add an association config with #belongs_to" do
      subject.belongs_to :area, foreign_key: :area_id
      association = subject.associations.last
      assert_equal :belongs_to, association.type
      assert_equal :area,       association.name
      assert_equal :area_id,    association.options[:foreign_key]
    end

    should "add an association config with #has_many" do
      subject.has_many :comments, as: :parent
      association = subject.associations.last
      assert_equal :has_many, association.type
      assert_equal :comments, association.name
      assert_equal :parent,   association.options[:as]
    end

    should "add an association config with #has_one" do
      subject.has_one :linking, class_name: "Linking"
      association = subject.associations.last
      assert_equal :has_one,  association.type
      assert_equal :linking,  association.name
      assert_equal "Linking", association.options[:class_name]
    end

    should "default its validations" do
      assert_equal [], subject.validations
    end

    should "add a validation config for \"*_of\" validations" do
      subject.validates_presence_of :name, :email, on: :create
      validation = subject.validations.last
      assert_equal :presence, validation.type
      assert_equal :create,   validation.options[:on]
      assert_includes :name,  validation.columns
      assert_includes :email, validation.columns
    end

    should "add a validation config with #validates_associated" do
      subject.validates_associated :area, :linkings
      validation = subject.validations.last
      assert_equal :associated, validation.type
      assert_includes :area,     validation.associations
      assert_includes :linkings, validation.associations
    end

    should "add a validation config with #validates_with" do
      first_validation_class  = Class.new
      second_validation_class = Class.new
      subject.validates_with first_validation_class, second_validation_class
      validation = subject.validations.last
      assert_equal :with, validation.type
      assert_includes first_validation_class,  validation.classes
      assert_includes second_validation_class, validation.classes
    end

    should "add a validation config with #validates_each" do
      block = proc{}
      subject.validates_each(:name, :email, &block)
      validation = subject.validations.last
      assert_equal :each, validation.type
      assert_equal block, validation.block
      assert_includes :name,  validation.columns
      assert_includes :email, validation.columns
    end

    should "add a validation config with #validate" do
      subject.validate :some_method
      validation = subject.validations.last
      assert_equal :custom,      validation.type
      assert_equal :some_method, validation.method_name

      block = proc{}
      subject.validate(&block)
      validation = subject.validations.last
      assert_equal :custom, validation.type
      assert_equal block,   validation.block
    end

    should "default its callbacks" do
      assert_equal [], subject.validations
    end

    should "add a callback config with a method name" do
      subject.after_initialize :a_callback_method
      callback = subject.callbacks.last
      assert_equal :after_initialize, callback.type
      assert_includes :a_callback_method, callback.args
    end

    should "add a callback config with a block" do
      subject.before_validation(on: :create) do
        self.name = "test"
      end
      callback = subject.callbacks.last
      assert_equal :before_validation, callback.type
      assert_equal :create, callback.options[:on]
      record_spy = subject.new
      record_spy.instance_eval(&callback.block)
      assert_equal "test", record_spy.name
    end

    should "default its custom callback types" do
      assert_equal [], subject.custom_callback_types
    end

    should "add a custom callback type using `define_model_callbacks`" do
      name    = Factory.string
      options = { Factory.string => Factory.string }
      subject.define_model_callbacks(name, options)

      callback_type = subject.custom_callback_types.last
      assert_equal name,    callback_type.name
      assert_equal options, callback_type.options
    end

    should "define callback methods using `define_model_callbacks`" do
      name = Factory.string
      subject.define_model_callbacks(name)

      assert_respond_to "before_#{name}", subject
      assert_respond_to "around_#{name}", subject
      assert_respond_to "after_#{name}",  subject

      callback_name =
        [
          "before_#{name}",
          "around_#{name}",
          "after_#{name}",
        ].sample
      method_name = Factory.string
      subject.send(callback_name, method_name)
      callback = subject.callbacks.last
      assert_equal callback_name.to_sym, callback.type
      assert_equal [method_name],        callback.args

      name = Factory.string
      subject.define_model_callbacks(name, only: [:before])

      assert_respond_to "before_#{name}", subject
      assert_not_respond_to "around_#{name}", subject
      assert_not_respond_to "after_#{name}",  subject
    end

    should "know its relation spy" do
      assert_instance_of Ardb::RelationSpy, subject.relation_spy
      spy = subject.relation_spy
      assert_same spy, subject.relation_spy
    end

    should "know its arel table" do
      subject.table_name = Factory.string
      assert_instance_of Arel::Table, subject.arel_table
      assert_equal subject.table_name, subject.arel_table.name
    end

    should "return its relation spy using `scoped`" do
      assert_same subject.relation_spy, subject.scoped
    end

    should "demeter its scope methods to its relation spy" do
      relation_spy = subject.relation_spy

      select_args = [Factory.string]
      subject.select(*select_args)
      assert_equal :select,     relation_spy.applied.last.type
      assert_equal select_args, relation_spy.applied.last.args

      from_args = [Factory.string]
      subject.from(*from_args)
      assert_equal :from,     relation_spy.applied.last.type
      assert_equal from_args, relation_spy.applied.last.args

      includes_args = [Factory.string]
      subject.includes(*includes_args)
      assert_equal :includes,     relation_spy.applied.last.type
      assert_equal includes_args, relation_spy.applied.last.args

      joins_args = [Factory.string]
      subject.joins(*joins_args)
      assert_equal :joins,     relation_spy.applied.last.type
      assert_equal joins_args, relation_spy.applied.last.args

      where_args = [Factory.string]
      subject.where(*where_args)
      assert_equal :where,     relation_spy.applied.last.type
      assert_equal where_args, relation_spy.applied.last.args

      group_args = [Factory.string]
      subject.group(*group_args)
      assert_equal :group,     relation_spy.applied.last.type
      assert_equal group_args, relation_spy.applied.last.args

      having_args = [Factory.string]
      subject.having(*having_args)
      assert_equal :having,     relation_spy.applied.last.type
      assert_equal having_args, relation_spy.applied.last.args

      order_args = [Factory.string]
      subject.order(*order_args)
      assert_equal :order,     relation_spy.applied.last.type
      assert_equal order_args, relation_spy.applied.last.args

      subject.reverse_order
      assert_equal :reverse_order, relation_spy.applied.last.type

      readonly_args = [Factory.boolean]
      subject.readonly(*readonly_args)
      assert_equal :readonly,     relation_spy.applied.last.type
      assert_equal readonly_args, relation_spy.applied.last.args

      limit_args = [Factory.integer]
      subject.limit(*limit_args)
      assert_equal :limit,     relation_spy.applied.last.type
      assert_equal limit_args, relation_spy.applied.last.args

      offset_args = [Factory.integer]
      subject.offset(*offset_args)
      assert_equal :offset,     relation_spy.applied.last.type
      assert_equal offset_args, relation_spy.applied.last.args

      merge_args = [Factory.string]
      subject.merge(*merge_args)
      assert_equal :merge,     relation_spy.applied.last.type
      assert_equal merge_args, relation_spy.applied.last.args

      except_args = [Factory.string]
      except_called_with = nil
      Assert.stub(relation_spy, :except){ |*args| except_called_with = args }
      subject.except(*except_args)
      assert_equal except_args, except_called_with

      only_args = [Factory.string]
      only_called_with = nil
      Assert.stub(relation_spy, :only){ |*args| only_called_with = args }
      subject.only(*only_args)
      assert_equal only_args, only_called_with
    end
  end

  class GeneratorTests < UnitTests
    desc "to generate record spy classes"
    setup do
      @record_spy_class =
        Ardb::RecordSpy.new do
          attr_accessor :name
        end
      @instance = @record_spy_class.new
    end
    subject{ @record_spy_class }

    should "build a new record spy class and " \
           "used the passed proc to further defined it" do
      assert_includes Ardb::RecordSpy, subject.included_modules
      assert @instance.respond_to? :name
      assert @instance.respond_to? :name=
    end
  end

  class InstanceTests < UnitTests
    setup do
      @instance = MyRecord.new
    end
    subject{ @instance }

    should have_accessors :id
    should have_imeths :update_column
    should have_imeths :manually_run_callbacks, :run_callbacks

    should "allow spying the update_column method by just writing the value" do
      assert_not_equal "updated", subject.name

      subject.update_column(:name, "updated")
      assert_equal "updated", subject.name
    end

    should "have accessors for each association defined" do
      assert_nil subject.bt_thing
      subject.bt_thing = "something"
      assert_equal "something", subject.bt_thing

      assert_nil subject.ho_thing
      subject.ho_thing = "other thing"
      assert_equal "other thing", subject.ho_thing

      assert_empty subject.hm_things
      subject.hm_things = [1, 2, 3]
      assert_equal [1, 2, 3], subject.hm_things
    end

    should "default its manually run callbacks" do
      assert_equal [], subject.manually_run_callbacks
    end

    should "spy any callbacks that are manually run" do
      assert_empty subject.manually_run_callbacks
      name = Factory.string
      subject.run_callbacks(name)
      assert_includes name, subject.manually_run_callbacks

      name = Factory.string
      block_called = false
      subject.run_callbacks(name){ block_called = true }
      assert_includes name, subject.manually_run_callbacks
      assert_true block_called
    end
  end

  class MyRecord
    include Ardb::RecordSpy
    attr_accessor :name

    belongs_to :bt_thing
    has_one    :ho_thing
    has_many   :hm_things
  end
end
