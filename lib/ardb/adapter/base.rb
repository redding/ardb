module Ardb; end
class Ardb::Adapter; end
class Ardb::Adapter::Base

  def foreign_key_add_sql(*args);  raise NotImplementedError; end
  def foreign_key_drop_sql(*args); raise NotImplementedError; end

  def ==(other_adapter)
    self.class == other_adapter.class
  end

end
