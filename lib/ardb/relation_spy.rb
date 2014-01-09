module Ardb

  class RelationSpy

    attr_reader :applied
    attr_accessor :limit_value, :offset_value
    attr_accessor :results

    def initialize
      @applied, @results = [], []
      @offset_value, @limit_value = nil, nil
    end

    def ==(other)
      other.kind_of?(self.class) ? @applied == other.applied : super
    end

    # ActiveRecord::QueryMethods

    [ :select,
      :includes, :joins,
      :where,
      :group, :having,
      :order, :reverse_order,
      :readonly
    ].each do |type|

      define_method(type) do |*args|
        @applied << AppliedExpression.new(type, args)
        self
      end

    end

    def limit(value)
      @limit_value = value ? value.to_i : nil
      @applied << AppliedExpression.new(:limit, [ value ])
      self
    end

    def offset(value)
      @offset_value = value ? value.to_i : nil
      @applied << AppliedExpression.new(:offset, [ value ])
      self
    end

    # ActiveRecord::SpawnMethods

    def merge(other)
      return self if self.equal?(other)
      if other.kind_of?(self.class)
        other.applied.each{ |a| self.send(a.type, *a.args) }
      else
        @applied << AppliedExpression.new(:merge, [ other ])
      end
      self
    end

    def except(*skips)
      skips = skips.map(&:to_sym)
      @applied.reject!{ |a| skips.include?(a.type) }
      @limit_value    = nil if skips.include?(:limit)
      @offset_value   = nil if skips.include?(:offset)
      self
    end

    def only(*onlies)
      onlies = onlies.map(&:to_sym)
      @applied.reject!{ |a| !onlies.include?(a.type) }
      @limit_value    = nil unless onlies.include?(:limit)
      @offset_value   = nil unless onlies.include?(:offset)
      self
    end

    # ActiveRecord::FinderMethods

    def find(id)
      record = @results.detect{ |result| result.id == id }
      record || raise(NotFoundError)
    end

    def first
      self.all.first
    end

    def first!
      self.first || raise(NotFoundError)
    end

    def last
      self.all.last
    end

    def last!
      self.last || raise(NotFoundError)
    end

    def all
      @results[(@offset_value || 0), (@limit_value || @results.size)] || []
    end

    # ActiveRecord::Calculations

    def count
      all.size
    end

    AppliedExpression = Struct.new(:type, :args)

    NotFoundError = Class.new(RuntimeError)

  end

end
