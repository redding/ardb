module Ardb

  class RelationSpy

    attr_reader :applied
    attr_accessor :order_values, :reverse_order_value
    attr_accessor :limit_value, :offset_value
    attr_accessor :results

    def initialize
      @applied, @results = [], []
      @order_values = []
      @reverse_order_value = nil
      @offset_value, @limit_value = nil, nil
    end

    [ :select,
      :joins,
      :where,
      :group, :having,
      :merge
    ].each do |type|

      define_method(type) do |*args|
        @applied << AppliedExpression.new(type, args)
        self
      end

    end

    def order(*args)
      @order_values += args
      @applied << AppliedExpression.new(:order, args)
      self
    end

    def limit(value)
      @limit_value = value ? value.to_i : nil
      @applied << AppliedExpression.new(:limit, [ value ])
      self
    end

    def offset(value)
      @offset_value = value ? value.to_i : 0
      @applied << AppliedExpression.new(:offset, [ value ])
      self
    end

    def all
      @results[(@offset_value || 0), (@limit_value || @results.size)] || []
    end

    def count
      all.size
    end

    def ==(other)
      @applied == other.applied
    end

    AppliedExpression = Struct.new(:type, :args)

  end

end
