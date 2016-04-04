require 'active_record'
require 'assert'

module Ardb

  class DbTests < Assert::Context
    around do |block|
      ActiveRecord::Base.transaction do
        block.call
        raise ActiveRecord::Rollback
      end
    end
  end

end
