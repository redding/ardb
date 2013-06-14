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

      attr_reader :validations, :callbacks

      [ :validates_presence_of, :validates_uniqueness_of,
        :validates_inclusion_of
      ].each do |method_name|
        type = method_name.to_s.match(/\Avalidates_(.+)_of\Z/)[1]

        define_method(method_name) do |*args|
          @validations ||= []
          @validations << Validation.new(type, *args)
        end

      end

      [ :before_validation, :after_save ].each do |method_name|

        define_method(method_name) do |*args, &block|
          @callbacks ||= []
          @callbacks << Callback.new(method_name, *args, &block)
        end

      end

    end

    module InstanceMethods

    end

    class Validation
      attr_reader :type, :columns, :options

      def initialize(type, *args)
        @type    = type.to_sym
        @options = args.last.kind_of?(::Hash) ? args.pop : {}
        @columns = args
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

  end

end
