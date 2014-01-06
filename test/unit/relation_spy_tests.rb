require 'assert'
require 'ardb/relation_spy'

class Ardb::RelationSpy

  class UnitTests < Assert::Context
    desc "Ardb::RelationSpy"
    setup do
      @relation_spy = Ardb::RelationSpy.new
    end
    subject{ @relation_spy }

    should have_readers :applied
    should have_accessors :results
    should have_accessors :order_values, :reverse_order_value
    should have_accessors :limit_value, :offset_value
    should have_imeths :select, :joins, :where, :order, :group, :having, :merge
    should have_imeths :limit, :offset
    should have_imeths :all, :count

    should "default it's attributes" do
      assert_equal [],  subject.applied
      assert_equal [],  subject.results
      assert_equal [],  subject.order_values
      assert_equal nil, subject.reverse_order_value
      assert_equal nil, subject.limit_value
      assert_equal nil, subject.offset_value
    end

    should "add an applied expression using `select`" do
      subject.select :column_a, :column_b
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :select, applied_expression.type
      assert_equal [ :column_a, :column_b ], applied_expression.args
    end

    should "add an applied expression using `joins`" do
      subject.joins :table_a, :table_b
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :joins, applied_expression.type
      assert_equal [ :table_a, :table_b ], applied_expression.args
    end

    should "add an applied expression using `where`" do
      subject.where :column_a => 'some value'
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :where, applied_expression.type
      assert_equal [ { :column_a => 'some value' } ], applied_expression.args
    end

    should "add an applied expression using `order`" do
      subject.order :column_a, :column_b
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :order, applied_expression.type
      assert_equal [ :column_a, :column_b ], applied_expression.args
    end

    should "add args to it's `order_values` using `order" do
      subject.order :column_a, :column_b
      assert_includes :column_a, subject.order_values
      assert_includes :column_b, subject.order_values
    end

    should "add an applied expression using `group`" do
      subject.group :column_a, :column_b
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :group, applied_expression.type
      assert_equal [ :column_a, :column_b ], applied_expression.args
    end

    should "add an applied expression using `having`" do
      subject.having 'COUNT(column_a) > 0'
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :having, applied_expression.type
      assert_equal [ 'COUNT(column_a) > 0' ], applied_expression.args
    end

    should "add an applied expression using `merge`" do
      other_relation = Ardb::RelationSpy.new
      subject.merge other_relation
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :merge, applied_expression.type
      assert_equal [ other_relation ], applied_expression.args
    end

    should "add an applied expression using `limit`" do
      subject.limit 100
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :limit, applied_expression.type
      assert_equal [ 100 ], applied_expression.args
    end

    should "set it's limit value using `limit`" do
      subject.limit 100
      assert_equal 100, subject.limit_value
    end

    should "add an applied expression using `offset`" do
      subject.offset 100
      assert_equal 1, subject.applied.size
      applied_expression = subject.applied.first
      assert_instance_of AppliedExpression, applied_expression
      assert_equal :offset, applied_expression.type
      assert_equal [ 100 ], applied_expression.args
    end

    should "set it's offset value using `offset`" do
      subject.offset 100
      assert_equal 100, subject.offset_value
    end

    should "return it's results using `all`" do
      subject.results = [ 1, 2, 3 ]
      assert_equal [ 1, 2, 3 ], subject.all
    end

    should "honor limit and offset values using `all`" do
      subject.results = [ 1, 2, 3, 4, 5 ]

      subject.limit 2
      subject.offset nil
      assert_equal [ 1, 2 ], subject.all

      subject.limit nil
      subject.offset 3
      assert_equal [ 4, 5 ], subject.all

      subject.limit 2
      subject.offset 2
      assert_equal [ 3, 4 ], subject.all
    end

    should "return the size of `all` using `count`" do
      subject.results = [ 1, 2, 3, 4, 5 ]
      assert_equal 5, subject.count

      subject.limit 2
      subject.offset 2
      assert_equal 2, subject.count
    end

    should "be comparable using there applied collections" do
      other_relation = Ardb::RelationSpy.new
      other_relation.select :column_a
      assert_not_equal other_relation, subject

      subject.select :column_a
      assert_equal other_relation, subject
    end

  end

end
