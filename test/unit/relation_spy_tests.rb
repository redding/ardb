# frozen_string_literal: true

require "assert"
require "ardb/relation_spy"

class Ardb::RelationSpy
  class UnitTests < Assert::Context
    desc "Ardb::RelationSpy"
    setup do
      @relation_spy = Ardb::RelationSpy.new
    end
    subject{ @relation_spy }

    should have_readers :applied
    should have_accessors :results
    should have_accessors :limit_value, :offset_value
    should have_accessors :pluck_values
    should have_imeths :to_sql, :reset!
    should have_imeths :select
    should have_imeths :from
    should have_imeths :includes, :joins
    should have_imeths :where
    should have_imeths :order, :reverse_order
    should have_imeths :group, :having
    should have_imeths :readonly
    should have_imeths :limit, :offset
    should have_imeths :merge, :only, :except
    should have_imeths :find, :first, :first!, :last, :last!, :all
    should have_imeths :count, :pluck

    should "default it's attributes" do
      assert_equal [], subject.applied
      assert_equal [], subject.results
      assert_nil subject.limit_value
      assert_nil subject.offset_value
      assert_equal({}, subject.pluck_values)
    end

    should "dup its applied and results arrays when copied" do
      new_relation_spy = subject.dup
      assert_not_same subject.applied, new_relation_spy.applied
      assert_not_same subject.results, new_relation_spy.results
    end

    should "be comparable using there applied collections" do
      other_relation = Ardb::RelationSpy.new
      other_relation.select :column_a
      assert_not_equal other_relation, subject

      subject.select :column_a
      assert_equal other_relation, subject
    end

    should "build a fake sql string for its applied expressions using "\
           "`to_sql`" do
      subject.select "column"
      subject.from "table"
      subject.joins "my_table.my_column ON my_table.my_column = table.column"

      expected = subject.applied.map(&:to_sql).join(", ")
      assert_equal expected, subject.to_sql
    end

    should "be able to be reset" do
      Factory.integer(3).times.each{ subject.applied << Factory.string }
      Factory.integer(3).times.each{ subject.results << Factory.string }
      subject.limit_value  = Factory.integer
      subject.offset_value = Factory.integer
      subject.reset!
      assert_equal [], subject.applied
      assert_equal [], subject.results
      assert_nil subject.limit_value
      assert_nil subject.offset_value
    end
  end

  class SelectTests < UnitTests
    desc "select"
    setup do
      @relation_spy.select :column_a, :column_b
      @applied = subject.applied.first
    end

    should "add a select applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :select, @applied.type
      assert_equal [:column_a, :column_b], @applied.args
    end
  end

  class FromTests < UnitTests
    desc "from"
    setup do
      @relation_spy.from "some SQL"
      @applied = subject.applied.first
    end

    should "add a from applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :from, @applied.type
      assert_equal ["some SQL"], @applied.args
    end
  end

  class IncludesTests < UnitTests
    desc "includes"
    setup do
      @relation_spy.includes :table_a, :table_b
      @applied = subject.applied.first
    end

    should "add an includes applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :includes, @applied.type
      assert_equal [:table_a, :table_b], @applied.args
    end
  end

  class JoinsTests < UnitTests
    desc "joins"
    setup do
      @relation_spy.joins :table_a, :table_b
      @applied = subject.applied.first
    end

    should "add a joins applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :joins, @applied.type
      assert_equal [:table_a, :table_b], @applied.args
    end
  end

  class WhereTests < UnitTests
    desc "where"
    setup do
      @relation_spy.where column_a: "some value"
      @applied = subject.applied.first
    end

    should "add a where applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :where, @applied.type
      assert_equal [{ column_a: "some value" }], @applied.args
    end
  end

  class OrderTests < UnitTests
    desc "order"
    setup do
      @relation_spy.order :column_a, :column_b
      @applied = subject.applied.first
    end

    should "add an order applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :order, @applied.type
      assert_equal [:column_a, :column_b], @applied.args
    end
  end

  class ReverseOrderTests < UnitTests
    desc "reverse_order"
    setup do
      @relation_spy.reverse_order
      @applied = subject.applied.first
    end

    should "add a reverse order applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :reverse_order, @applied.type
    end
  end

  class GroupTests < UnitTests
    desc "group"
    setup do
      @relation_spy.group :column_a, :column_b
      @applied = subject.applied.first
    end

    should "add a group applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :group, @applied.type
      assert_equal [:column_a, :column_b], @applied.args
    end
  end

  class HavingTests < UnitTests
    desc "having"
    setup do
      @relation_spy.having "COUNT(column_a) > 0"
      @applied = subject.applied.first
    end

    should "add a having applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :having, @applied.type
      assert_equal ["COUNT(column_a) > 0"], @applied.args
    end
  end

  class ReadonlyTests < UnitTests
    desc "readonly"
    setup do
      @relation_spy.readonly true
      @applied = subject.applied.first
    end

    should "add a readonly applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :readonly, @applied.type
      assert_equal [true], @applied.args
    end
  end

  class LimitTests < UnitTests
    desc "limit"
    setup do
      @relation_spy.limit 100
      @applied = subject.applied.first
    end

    should "add a limit applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :limit, @applied.type
      assert_equal [100], @applied.args
    end

    should "set it's limit value" do
      assert_equal 100, subject.limit_value
    end
  end

  class OffsetTests < UnitTests
    desc "offset"
    setup do
      @relation_spy.offset 100
      @applied = subject.applied.first
    end

    should "add an offset applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :offset, @applied.type
      assert_equal [100], @applied.args
    end

    should "set it's offset value" do
      assert_equal 100, subject.offset_value
    end
  end

  class MergeWithARelationSpyTests < UnitTests
    desc "merge with a relation spy"
    setup do
      @other_relation_spy =
        Ardb::RelationSpy.new.select("column").joins("table")
      @relation_spy.merge @other_relation_spy
    end

    should "apply another relation's applied expressions using `merge`" do
      @other_relation_spy.applied.each do |applied|
        assert_includes applied, @relation_spy.applied
      end
    end
  end

  class MergeWithNonRelationSpyTests < UnitTests
    desc "merge without a relation spy"
    setup do
      @fake_relation = "relation"
      @relation_spy.merge @fake_relation
      @applied = subject.applied.first
    end

    should "add a merge applied expression with the passed args" do
      assert_instance_of AppliedExpression, @applied
      assert_equal :merge, @applied.type
      assert_equal [@fake_relation], @applied.args
    end
  end

  class MergeWithSelfTests < UnitTests
    desc "merge with itself"
    setup do
      @fake_relation = "relation"
      @relation_spy.merge @relation_spy
    end

    should "not alter the applied expressions" do
      assert_empty subject.applied
    end
  end

  class WithExpressionsTests < UnitTests
    setup do
      @relation_spy.select("column").includes("table").joins("table")
      @relation_spy.where(column: "value").order("column")
      @relation_spy.group("column").having("count(*) > 1")
      @relation_spy.limit(1).offset(1)
    end
  end

  class ExceptTests < WithExpressionsTests
    desc "except"

    should "return a new relation spy" do
      new_relation_spy = subject.except(:select)
      assert_not_same subject, new_relation_spy
    end

    should "remove any applied expressions in the passed types" do
      relation_spy = subject.except(:includes, :where, :group, :offset)
      applied_types = relation_spy.applied.map(&:type)
      [:select, :joins, :order, :having, :limit].each do |type|
        assert_includes type, applied_types
      end
      [:includes, :where, :group, :offset].each do |type|
        assert_not_includes type, applied_types
      end
    end

    should "unset the limit value if limit is included in the passed types" do
      relation_spy = subject.except(:select)
      assert_not_nil relation_spy.limit_value
      relation_spy = subject.except(:limit)
      assert_nil relation_spy.limit_value
    end

    should "unset the offset value if offset is included in the passed types" do
      relation_spy = subject.except(:select)
      assert_not_nil relation_spy.offset_value
      relation_spy = subject.except(:offset)
      assert_nil relation_spy.offset_value
    end
  end

  class OnlyTests < WithExpressionsTests
    desc "only"

    should "return a new relation spy" do
      new_relation_spy = subject.only(:select)
      assert_not_same subject, new_relation_spy
    end

    should "remove any applied expressions not in the passed types" do
      relation_spy = subject.only(:includes, :where, :group, :offset)
      applied_types = relation_spy.applied.map(&:type)
      [:includes, :where, :group, :offset].each do |type|
        assert_includes type, applied_types
      end
      [:select, :joins, :order, :having, :limit].each do |type|
        assert_not_includes type, applied_types
      end
    end

    should "unset the limit value if limit is not included in the passed "\
           "types" do
      relation_spy = subject.only(:limit)
      assert_not_nil relation_spy.limit_value
      relation_spy = subject.only(:select)
      assert_nil relation_spy.limit_value
    end

    should "unset the offset value if offset is not included in the passed "\
           "types" do
      relation_spy = subject.only(:offset)
      assert_not_nil relation_spy.offset_value
      relation_spy = subject.only(:select)
      assert_nil relation_spy.offset_value
    end
  end

  class WithResultsTests < UnitTests
    setup do
      @results = [*1..5].map{ |id| Result.new(id) }
      @relation_spy.results = @results
    end
  end

  class FindTests < WithResultsTests
    desc "find"

    should "return a result with the matching id" do
      result = subject.find(3)
      assert_equal 3, result.id
    end

    should "raise a not found error if a result can't be found" do
      assert_raises(NotFoundError){ subject.find(1000) }
    end
  end

  class FirstTests < WithResultsTests
    should "return the first item from `all` using `first`" do
      assert_equal subject.all.first, subject.first
      subject.offset 2
      assert_equal subject.all.first, subject.first
    end

    should "return the first item from `all` or " \
           "raise an exception if `all` is empty using `first!`" do
      assert_equal subject.all.first, subject.first!
      subject.limit 0
      assert_raises(NotFoundError){ subject.first! }
    end
  end

  class LastTests < WithResultsTests
    should "return the last item from `all` using `last`" do
      assert_equal subject.all.last, subject.last
      subject.limit 2
      assert_equal subject.all.last, subject.last
    end

    should "return the last item from `all` or " \
           "raise an exception if `all` is empty using `last!`" do
      assert_equal subject.all.last, subject.last!
      subject.limit 0
      assert_raises(NotFoundError){ subject.last! }
    end
  end

  class AllTests < WithResultsTests
    desc "all"

    should "return the spy's results" do
      assert_equal @results, subject.all
    end

    should "honor limit and offset values" do
      subject.limit 2
      subject.offset nil
      assert_equal @results[0, 2], subject.all

      subject.limit nil
      subject.offset 3
      assert_equal @results[3..-1], subject.all

      subject.limit 2
      subject.offset 2
      assert_equal @results[2, 2], subject.all
    end
  end

  class CountTests < WithResultsTests
    desc "count"

    should "return the size of `all`" do
      assert_equal subject.all.size, subject.count
      subject.limit 2
      assert_equal subject.all.size, subject.count
    end
  end

  class PluckTests < WithResultsTests
    desc "pluck"
    setup do
      @column_name  = Factory.string
      @column_value = Factory.string
      @relation_spy.pluck_values[@column_name] = @column_value
    end

    should "return a pluck value for every result" do
      exp = [@column_value] * @results.size
      assert_equal exp, @relation_spy.pluck(@column_name)
    end
  end

  class AppliedExpressionTests < UnitTests
    desc "AppliedExpression"
    setup do
      @applied_expression = AppliedExpression.new(:select, "column")
    end
    subject{ @applied_expression }

    should have_readers :type, :args
    should have_imeths :to_sql

    should "return a string representing the expression using `to_sql`" do
      expected = "#{subject.type}: #{subject.args.inspect}"
      assert_equal expected, subject.to_sql
    end
  end

  Result = Struct.new(:id)
end
