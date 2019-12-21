module Ardb
  class RelationSpy
    attr_reader :applied
    attr_accessor :limit_value, :offset_value
    attr_accessor :pluck_values, :maximum_values, :minimum_values
    attr_accessor :results

    def initialize
      @applied, @results = [], []
      @offset_value, @limit_value = nil, nil

      @pluck_values   = {}
      @maximum_values = {}
      @minimum_values = {}
    end

    def initialize_copy(copied_from)
      super
      @applied = copied_from.applied.dup
      @results = copied_from.results.dup
    end

    def ==(other)
      other.kind_of?(self.class) ? @applied == other.applied : super
    end

    def to_sql
      @applied.map(&:to_sql).join(", ")
    end

    def reset!
      @applied.clear
      @results.clear
      @offset_value = nil
      @limit_value  = nil
    end

    # ActiveRecord::QueryMethods

    [ :select,
      :from,
      :includes,
      :joins,
      :where,
      :group,
      :having,
      :order,
      :reverse_order,
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
      self.dup.tap do |r|
        r.applied.reject!{ |a| skips.include?(a.type) }
        r.limit_value    = nil if skips.include?(:limit)
        r.offset_value   = nil if skips.include?(:offset)
      end
    end

    def only(*onlies)
      onlies = onlies.map(&:to_sym)
      self.dup.tap do |r|
        r.applied.reject!{ |a| !onlies.include?(a.type) }
        r.limit_value    = nil unless onlies.include?(:limit)
        r.offset_value   = nil unless onlies.include?(:offset)
      end
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

    def pluck(column_name)
      [@pluck_values[column_name]] * @results.size
    end

    def maximum(column_name)
      @maximum_values[column_name]
    end

    def minimum(column_name)
      @minimum_values[column_name]
    end

    class AppliedExpression < Struct.new(:type, :args)
      def to_sql
        "#{self.type}: #{self.args.inspect}"
      end
    end

    NotFoundError = Class.new(RuntimeError)
  end
end
