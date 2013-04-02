require 'assert'
require 'fileutils'
require 'ardb/runner/create_command'

class Ardb::Runner::CreateCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::CreateCommand"
    setup do
      @cmd = Ardb::Runner::CreateCommand.new
    end
    subject{ @cmd }

    should have_instance_methods :run

  end

end
