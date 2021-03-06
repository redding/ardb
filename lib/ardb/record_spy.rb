# frozen_string_literal: true

require "arel"
require "much-mixin"
require "ardb/relation_spy"

module Ardb
  module RecordSpy
    include MuchMixin

    def self.new(&block)
      block ||= proc{}
      record_spy = Class.new{ include Ardb::RecordSpy }
      record_spy.class_eval(&block)
      record_spy
    end

    CallbackType = Struct.new(:name, :options)

    mixin_class_methods do
      attr_accessor :table_name

      # Associations

      def associations
        @associations ||= []
      end

      [:belongs_to, :has_one, :has_many].each do |method_name|
        define_method(method_name) do |assoc_name, *args|
          define_method(assoc_name) do
            instance_variable_get("@#{assoc_name}") ||
            (method_name == :has_many ? [] : nil)
          end
          define_method("#{assoc_name}=") do |value|
            instance_variable_set("@#{assoc_name}", value)
          end

          associations << Association.new(method_name, assoc_name, *args)
        end
      end

      # Validations

      def validations
        @validations ||= []
      end

      [
        :validates_acceptance_of,
        :validates_confirmation_of,
        :validates_exclusion_of,
        :validates_format_of,
        :validates_inclusion_of,
        :validates_length_of,
        :validates_numericality_of,
        :validates_presence_of,
        :validates_size_of,
        :validates_uniqueness_of,
      ].each do |method_name|
        type = method_name.to_s.match(/\Avalidates_(.+)_of\Z/)[1]

        define_method(method_name) do |*args|
          validations << Validation.new(type, *args)
        end
      end

      def validates_associated(*args)
        validations << Validation.new(:associated, *args)
      end

      def validates_with(*args)
        validations << Validation.new(:with, *args)
      end

      def validates_each(*args, &block)
        validations << Validation.new(:each, *args, &block)
      end

      def validate(method_name = nil, &block)
        validations << Validation.new(:custom, method_name, &block)
      end

      def callbacks
        @callbacks ||= []
      end

      # Callbacks

      [
        :before_validation,
        :after_validation,
        :before_create,
        :around_create,
        :after_create,
        :before_update,
        :around_update,
        :after_update,
        :before_save,
        :around_save,
        :after_save,
        :before_destroy,
        :around_destroy,
        :after_destroy,
        :after_commit,
        :after_rollback,
        :after_initialize,
        :after_find,
      ].each do |method_name|
        define_method(method_name) do |*args, &block|
          callbacks << Callback.new(method_name, *args, &block)
        end
      end

      def custom_callback_types
        @custom_callback_types ||= []
      end

      def define_model_callbacks(*args)
        options   = args.last.is_a?(Hash) ? args.pop : {}
        types     = options[:only] || [:before, :around, :after]
        metaclass = class << self; self; end

        args.each do |name|
          custom_callback_types << CallbackType.new(name, options)
          types.each do |type|
            method_name = "#{type}_#{name}"
            metaclass.send(:define_method, method_name) do |*args, &block|
              callbacks << Callback.new(method_name, *args, &block)
            end
          end
        end
      end

      # Scopes

      attr_writer :relation_spy
      def relation_spy
        @relation_spy ||= RelationSpy.new
      end

      def arel_table
        @arel_table ||= Arel::Table.new(table_name)
      end

      def scoped
        relation_spy
      end

      [
        :select,
        :from,
        :includes,
        :joins,
        :where,
        :group,
        :having,
        :order,
        :reverse_order,
        :readonly,
        :limit,
        :offset,
        :merge,
        :except,
        :only,
      ].each do |method_name|
        define_method(method_name) do |*args|
          relation_spy.send(method_name, *args)
        end
      end
    end

    mixin_instance_methods do
      attr_accessor :id

      def update_column(col, value)
        send("#{col}=", value)
      end

      def manually_run_callbacks
        @manually_run_callbacks ||= []
      end

      def run_callbacks(name, &block)
        manually_run_callbacks << name
        block&.call
      end
    end

    class Association
      attr_reader :type, :name, :options

      def initialize(type, name, options = nil)
        @type = type.to_sym
        @name = name
        @options = options || {}
      end
    end

    class Callback
      attr_reader :type, :args, :options, :block

      def initialize(type, *args, &block)
        @type = type.to_sym
        @options = args.last.is_a?(::Hash) ? args.pop : {}
        @args  = args
        @block = block
      end
    end

    class Validation
      attr_reader :type, :args, :options, :method_name, :block
      alias_method :columns, :args
      alias_method :associations, :args
      alias_method :classes, :args

      def initialize(type, *args, &block)
        @type = type.to_sym
        @options = args.last.is_a?(::Hash) ? args.pop : {}
        @args = args
        @block = block
        @method_name = @args.first if @type == :custom
      end
    end
  end
end
