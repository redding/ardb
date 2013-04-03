require 'active_record'
require 'ardb'

# Use theses helpers in your test suite.  They all generally assume Ardb has
# already been initialized by calling `Ardb.init`.

module Ardb; end
module Ardb::TestHelpers
  module_function

  def drop_tables
    ActiveRecord::Base.connection.tap do |conn|
      tables = conn.execute "SELECT table_name"\
                            " FROM information_schema.tables"\
                            " WHERE table_schema = 'public';"
      tables.each{ |row| conn.execute "DROP TABLE #{row['table_name']} CASCADE" }
    end
  end

  def load_schema
    # silence STDOUT
    current_stdout = $stdout.dup
    $stdout = File.new('/dev/null', 'w')
    load Ardb.config.schema_path
    $stdout = current_stdout
  end

end

