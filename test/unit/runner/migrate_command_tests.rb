require 'assert'
require 'ardb/runner/migrate_command'

class Ardb::Runner::MigrateCommand

  class UnitTests < Assert::Context
    desc "Ardb::Runner::MigrateCommand"
    setup do
      @cmd = Ardb::Runner::MigrateCommand.new
    end
    subject{ @cmd }

    should have_imeths :run

  end

end
