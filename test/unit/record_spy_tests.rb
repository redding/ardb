require 'assert'
require 'ardb/record_spy'

module Ardb::RecordSpy

  class MyRecord
    include Ardb::RecordSpy
    attr_accessor :name
  end

  class BaseTests < Assert::Context
    desc "Ardb::RecordSpy"
    setup do
      @instance = MyRecord.new
    end
    subject{ MyRecord }

    should have_readers :associations, :callbacks, :validations
    should have_imeths :belongs_to, :has_many, :has_one
    should have_imeths :validates_presence_of, :validates_uniqueness_of
    should have_imeths :validates_inclusion_of, :before_validation, :after_save

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

    should "add a validation config with #validates_presence_of" do
      subject.validates_presence_of :name, :email, :on => :create
      validation = subject.validations.last
      assert_equal :presence, validation.type
      assert_includes :name, validation.columns
      assert_includes :email, validation.columns
      assert_equal :create, validation.options[:on]
    end

    should "add a validation config with #validates_uniqueness_of" do
      subject.validates_uniqueness_of :name, :scope => :area_id
      validation = subject.validations.last
      assert_equal :uniqueness, validation.type
      assert_includes :name, validation.columns
      assert_equal :area_id, validation.options[:scope]
    end

    should "add a validation config with #validates_inclusion_of" do
      subject.validates_inclusion_of :active, :in => [ true, false]
      validation = subject.validations.last
      assert_equal :inclusion, validation.type
      assert_includes :active, validation.columns
      assert_equal [ true, false], validation.options[:in]
    end

    should "add a callback config with #before_validation" do
      subject.before_validation(:on => :create) do
        self.name = 'test'
      end
      callback = subject.callbacks.last
      assert_equal :before_validation, callback.type
      assert_equal :create, callback.options[:on]
      @instance.instance_eval(&callback.block)
      assert_equal 'test', @instance.name
    end

    should "add a callback config with #after_save" do
      subject.after_save :a_callback_method
      callback = subject.callbacks.last
      assert_equal :after_save, callback.type
      assert_includes :a_callback_method, callback.args
    end

  end

  class GeneratorTests < BaseTests
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

end
