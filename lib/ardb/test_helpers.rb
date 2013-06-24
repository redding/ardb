require 'active_record'
require 'ardb'

# Use theses helpers in your test suite.  They all generally assume Ardb has
# already been initialized by calling `Ardb.init`.

module Ardb; end
module Ardb::TestHelpers
  module_function

  def drop_tables
    Ardb.adapter.drop_tables
  end

  def load_schema
    Ardb.adapter.load_schema
  end

  def reset_db!
    Ardb.adapter.drop_db
    Ardb.adapter.create_db
    self.load_schema
  end

  def reset_db
    @reset_db ||= begin
      self.reset_db!
      true
    end
  end

end
