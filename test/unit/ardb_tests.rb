require 'assert'
require 'ardb'

module Ardb

  class BaseTests < Assert::Context
    desc "Ardb"
    subject{ Ardb }
    setup do
      @orig_ar_logger = ActiveRecord::Base.logger
    end
    teardown do
      Adapter.reset
      ActiveRecord::Base.logger = @orig_ar_logger
    end

    should have_imeths :config, :configure, :adapter, :validate!, :init

    should "return its `Config` class with the `config` method" do
      assert_same Config, subject.config
    end

    should "complain if init'ing and not all configs are set" do
      orig_adapter = Ardb.config.db.adapter
      Ardb.config.db.adapter = nil
      assert_raises(NotConfiguredError) { subject.init }
      Ardb.config.db.adapter = orig_adapter
    end

    should "init the adapter on init" do
      assert_nil Adapter.current
      begin
        subject.init
      rescue LoadError
      end

      assert_not_nil Adapter.current
      exp_adapter = Adapter.send(subject.config.db.adapter)
      assert_equal exp_adapter, Adapter.current
      assert_same Adapter.current, subject.adapter
    end

    should "establish an AR connection on init" do
      assert_raises(LoadError) do
        # not going to test this b/c I don't want to bring in all the crap it
        # takes to actually establish a connection with AR (adapters, etc)
        # plus, most of this should be handled by AR, ns-options, and the above
        # tests anyway
        subject.init
      end
    end

  end

end
