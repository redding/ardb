require 'assert'
require 'ardb/default_order_by'

require 'ardb/record_spy'

module Ardb::DefaultOrderBy

  class UnitTests < Assert::Context
    desc "Ardb::DefaultOrderBy"
    setup do
      order_by_attribute = @order_by_attribute = Factory.string.to_sym
      @scope_proc = proc{ self.class.where(:grouping => self.grouping) }
      @record_class = Ardb::RecordSpy.new do
        include Ardb::DefaultOrderBy
        attr_accessor order_by_attribute, :grouping
      end
    end
    subject{ @record_class }

    should have_imeths :default_order_by
    should have_imeths :ardb_default_order_by_config

    should "know its default attribute, preprocessor and separator" do
      assert_equal :order_by, DEFAULT_ATTRIBUTE
      record = subject.new
      assert_equal subject.scoped, record.instance_eval(&DEFAULT_SCOPE_PROC)
    end

    should "not have any default-order-by config by default" do
      assert_equal({}, subject.ardb_default_order_by_config)
    end

    should "default its config using `default_order_by`" do
      subject.default_order_by

      config = subject.ardb_default_order_by_config
      assert_equal DEFAULT_ATTRIBUTE, config[:attribute]
      assert_same DEFAULT_SCOPE_PROC, config[:scope_proc]
    end

    should "allow customizing the config using `default_order_by`" do
      subject.default_order_by({
        :attribute => @order_by_attribute,
        :scope     => @scope_proc
      })

      config = subject.ardb_default_order_by_config
      assert_equal @order_by_attribute, config[:attribute]
      assert_same @scope_proc, config[:scope_proc]
    end

    should "add callbacks using `default_order_by`" do
      subject.default_order_by

      callback = subject.callbacks.find{ |v| v.type == :before_validation }
      assert_not_nil callback
      assert_equal [:ardb_default_order_by], callback.args
      assert_equal({ :on => :create }, callback.options)
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @record_class.default_order_by({
        :attribute => @order_by_attribute,
        :scope     => @scope_proc
      })
      @current_max = Factory.integer
      @record_class.relation_spy.maximum_values[@order_by_attribute] = @current_max

      @record = @record_class.new
      @record.grouping = Factory.string
    end
    subject{ @record }

    should "allow resetting its order-by to the current max + 1" do
      assert_not_equal @current_max + 1, subject.send(@order_by_attribute)
      subject.instance_eval{ reset_order_by }
      assert_equal @current_max + 1, subject.send(@order_by_attribute)
    end

    should "reset its order-by to a start value when there isn't a current max" do
      @record_class.relation_spy.maximum_values.delete(@order_by_attribute)

      subject.instance_eval{ reset_order_by }
      assert_equal 1, subject.send(@order_by_attribute)
    end

    should "use the configured scope when resetting its order-by" do
      assert_empty @record_class.relation_spy.applied
      subject.instance_eval{ reset_order_by }

      assert_equal 1, @record_class.relation_spy.applied.size
      applied_expression = @record_class.relation_spy.applied.last
      assert_equal :where, applied_expression.type
      assert_equal [{ :grouping => subject.grouping }], applied_expression.args
    end

    should "reset its order-by using `ardb_default_order_by`" do
      assert_not_equal @current_max + 1, subject.send(@order_by_attribute)
      subject.instance_eval{ ardb_default_order_by }
      assert_equal @current_max + 1, subject.send(@order_by_attribute)
    end

    should "not reset its order-by if its already set using `ardb_default_order_by`" do
      current_order_by = Factory.integer
      subject.send("#{@order_by_attribute}=", current_order_by)
      subject.instance_eval{ ardb_default_order_by }

      assert_equal current_order_by, subject.send(@order_by_attribute)
    end

  end

end
