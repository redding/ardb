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

      [ :validates_presence_of, :validates_uniqueness_of,
        :validates_inclusion_of
      ].each do |method_name|
        type = method_name.to_s.match(/\Avalidates_(.+)_of\Z/)[1]

        define_method(method_name) do |*args|
          @validations ||= []
          @validations << Validation.new(type, *args)
        end

      end

      def validate(method_name = nil, &block)
        @validations ||= []
        @validations << Validation.new(:custom, method_name, &block)
      end

      [ :after_initialize, :before_validation, :after_save ].each do |method_name|

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
      attr_reader :type, :columns, :options, :method_name, :block

      def initialize(type, *args, &block)
        @type  = type.to_sym
        @block = block
        if type != :custom
          @options = args.last.kind_of?(::Hash) ? args.pop : {}
          @columns = args
        else
          @method_name = args.first
        end
      end
    end

  end

end
