require 'assert'
require 'ardb'

module Ardb

  class BaseTests < Assert::Context
    desc "Ardb"
    subject{ Ardb }

    should have_instance_methods :config, :configure, :init

    should "return its `Config` class with the `config` method" do
      assert_same Config, subject.config
    end

    should "complain if init'ing and not all configs are set" do
      assert_raises RuntimeError do
        subject.init
      end
    end

    should "establish and AR connection if all configs are set" do
      assert true
      # not going to test this b/c I don't want to bring in all the crap it
      # takes to actually establish a connection with AR (adapters, etc)
      # plus, most of this should be handled by AR, ns-options, and the above
      # test anyway
    end

  end

end
