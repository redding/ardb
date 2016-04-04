require 'assert'
require 'ardb/db_tests'

require 'active_record'

class Ardb::DbTests

  class UnitTests < Assert::Context
    desc "Ardb::DbTests"
    setup do
      @transaction_called = false
      Assert.stub(ActiveRecord::Base, :transaction) do |&block|
        @transaction_called = true
        block.call
      end
    end
    subject{ Ardb::DbTests }

    should "be an assert context" do
      assert subject < Assert::Context
    end

    should "add an around callback that runs tests in a transaction that rolls back" do
      assert_equal 1, subject.arounds.size
      callback = subject.arounds.first

      block_yielded_to = false
      assert_raises(ActiveRecord::Rollback) do
        callback.call(proc{ block_yielded_to = true })
      end
      assert_true @transaction_called
      assert_true block_yielded_to
    end

  end

end
