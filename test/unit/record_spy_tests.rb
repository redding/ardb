require 'assert'
require 'ardb/record_spy'

module Ardb::RecordSpy

  class UnitTests < Assert::Context
    desc "Ardb::RecordSpy"
    setup do
      @instance = MyRecord.new
    end
    subject{ MyRecord }

    should have_readers :associations, :callbacks, :validations
    should have_imeths :belongs_to, :has_many, :has_one
    should have_imeths :validates_acceptance_of, :validates_confirmation_of
    should have_imeths :validates_exclusion_of,  :validates_format_of
    should have_imeths :validates_inclusion_of, :validates_length_of
    should have_imeths :validates_numericality_of, :validates_presence_of
    should have_imeths :validates_size_of, :validates_uniqueness_of
    should have_imeths :validates_associated, :validates_with, :validates_each
    should have_imeths :validate
    should have_imeths :before_validation, :after_validation
    should have_imeths :before_create,  :around_create,  :after_create
    should have_imeths :before_update,  :around_update,  :after_update
    should have_imeths :before_save,    :around_save,    :after_save
    should have_imeths :before_destroy, :around_destroy, :after_destroy
    should have_imeths :after_commit, :after_rollback
    should have_imeths :after_initialize, :after_find

    should "included the record spy instance methods" do
      assert_includes Ardb::RecordSpy::InstanceMethods, subject.included_modules
    end

    should "add an association config with #belongs_to" do
      subject.belongs_to :area, :foreign_key => :area_id
      association = subject.associations.last
      assert_equal :belongs_to, association.type
      assert_equal :area,       association.name
      assert_equal :area_id,    association.options[:foreign_key]
    end

    should "add an association config with #has_many" do
      subject.has_many :comments, :as => :parent
      association = subject.associations.last
      assert_equal :has_many, association.type
      assert_equal :comments, association.name
      assert_equal :parent,   association.options[:as]
    end

    should "add an association config with #has_one" do
      subject.has_one :linking, :class_name => 'Linking'
      association = subject.associations.last
      assert_equal :has_one,  association.type
      assert_equal :linking,  association.name
      assert_equal 'Linking', association.options[:class_name]
    end

    should "add a validation config for '*_of' validations" do
      subject.validates_presence_of :name, :email, :on => :create
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
      block = proc{ }
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

      block = proc{ }
      subject.validate(&block)
      validation = subject.validations.last
      assert_equal :custom, validation.type
      assert_equal block,    validation.block
    end

    should "add a callback config with with a method name" do
      subject.after_initialize :a_callback_method
      callback = subject.callbacks.last
      assert_equal :after_initialize, callback.type
      assert_includes :a_callback_method, callback.args
    end

    should "add a callback config with a block" do
      subject.before_validation(:on => :create) do
        self.name = 'test'
      end
      callback = subject.callbacks.last
      assert_equal :before_validation, callback.type
      assert_equal :create, callback.options[:on]
      @instance.instance_eval(&callback.block)
      assert_equal 'test', @instance.name
    end

  end

  class GeneratorTests < UnitTests
    desc "to generate record spy classes"
    setup do
      @record_spy_class = Ardb::RecordSpy.new do
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
    subject{ @instance }

    should have_imeths :update_column

    should "allow spying the update_column method by just writing the value" do
      assert_not_equal 'updated', subject.name

      subject.update_column(:name, 'updated')
      assert_equal 'updated', subject.name
    end

  end

  class MyRecord
    include Ardb::RecordSpy
    attr_accessor :name
  end

end
