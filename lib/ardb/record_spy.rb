module Ardb

  module RecordSpy

    def self.new(&block)
      block ||= proc{ }
      record_spy = Class.new{ include Ardb::RecordSpy }
      record_spy.class_eval(&block)
      record_spy
    end

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods

      attr_reader :associations, :callbacks, :validations

      [ :belongs_to, :has_many, :has_one ].each do |method_name|

        define_method(method_name) do |*args|
          @associations ||= []
          @associations << Association.new(method_name, *args)
        end

      end

      [ :validates_acceptance_of, :validates_confirmation_of,
        :validates_exclusion_of,  :validates_format_of, :validates_inclusion_of,
        :validates_length_of, :validates_numericality_of,
        :validates_presence_of, :validates_size_of, :validates_uniqueness_of
      ].each do |method_name|
        type = method_name.to_s.match(/\Avalidates_(.+)_of\Z/)[1]

        define_method(method_name) do |*args|
          @validations ||= []
          @validations << Validation.new(type, *args)
        end

      end

      def validates_associated(*args)
        @validations ||= []
        @validations << Validation.new(:associated, *args)
      end

      def validates_with(*args)
        @validations ||= []
        @validations << Validation.new(:with, *args)
      end

      def validates_each(*args, &block)
        @validations ||= []
        @validations << Validation.new(:each, *args, &block)
      end

      def validate(method_name = nil, &block)
        @validations ||= []
        @validations << Validation.new(:custom, method_name, &block)
      end

      [ :before_validation, :after_validation,
        :before_create,  :around_create,  :after_create,
        :before_update,  :around_update,  :after_update,
        :before_save,    :around_save,    :after_save,
        :before_destroy, :around_destroy, :after_destroy,
        :after_commit, :after_rollback,
        :after_initialize, :after_find
      ].each do |method_name|

        define_method(method_name) do |*args, &block|
          @callbacks ||= []
          @callbacks << Callback.new(method_name, *args, &block)
        end

      end

    end

    module InstanceMethods

    end

    class Association
      attr_reader :type, :name, :options

      def initialize(type, name, options)
        @type = type.to_sym
        @name = name
        @options = options
      end
    end

    class Callback
      attr_reader :type, :args, :options, :block

      def initialize(type, *args, &block)
        @type  = type.to_sym
        @options = args.last.kind_of?(::Hash) ? args.pop : {}
        @args  = args
        @block = block
      end
    end

    class Validation
      attr_reader :type, :args, :options, :method_name, :block
      alias :columns :args
      alias :associations :args
      alias :classes :args

      def initialize(type, *args, &block)
        @type  = type.to_sym
        @options = args.last.kind_of?(::Hash) ? args.pop : {}
        @args = args
        @block = block
        if @type == :custom
          @method_name = @args.first
        end
      end
    end

  end

end
