# This takes a path string relative to the configured root path and tranforms
# to the full qualifed root path.  The goal here is to specify path options
# with root-relative path strings.

module Ardb; end
class Ardb::RootPath < String

  def initialize(path_string)
    super(Ardb.config.root_path.join(path_string).to_s)
  end

end
