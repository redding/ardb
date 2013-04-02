require 'assert'
require 'ardb/adapter/base'

class Ardb::Adapter::Base

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @adapter = Ardb::Adapter::Base.new
    end
    subject { @adapter }

    should "test stuff" do
      skip 'TODO tests'
    end

  end

end
