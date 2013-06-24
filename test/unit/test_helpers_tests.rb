require 'assert'
require 'ardb/test_helpers'

module Ardb::TestHelpers

  class BaseTests < Assert::Context
    desc "Ardb test helpers"
    subject{ Ardb::TestHelpers }

    should have_imeths :drop_tables, :load_schema, :reset_db, :reset_db!

  end

end
