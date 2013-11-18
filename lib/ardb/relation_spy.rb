module Ardb

  class RelationSpy

    attr_reader :applied
    attr_accessor :results

    def initialize
      @applied, @results = [], []
      @offset, @limit = 0, nil
    end

    [ :select,
      :joins,
      :where,
      :order,
      :group, :having,
      :merge
    ].each do |type|

      define_method(type) do |*args|
        @applied << AppliedExpression.new(type, args)
        self
      end

    end

    def limit(value)
      @limit = value ? value.to_i : nil
      @applied << AppliedExpression.new(:limit, [ value ])
      self
    end

    def offset(value)
      @offset = value ? value.to_i : 0
      @applied << AppliedExpression.new(:offset, [ value ])
      self
    end

    def all
      @results[@offset, (@limit || @results.size)] || []
    end

    def count
      all.size
    end

    def limit_value
      @limit
    end

    def offset_value
      @offset
    end

    def ==(other)
      @applied == other.applied
    end

    AppliedExpression = Struct.new(:type, :args)

  end

end
