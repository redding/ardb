require 'assert/factory'

module Factory
  extend Assert::Factory

  def self.migration_id
    # identifiers need to be plural b/c af activesupport's pluralize
    "#{Factory.string}_things"
  end

  def self.ardb_config
    Ardb::Config.new.tap do |c|
      c.adapter          = Factory.string
      c.database         = Factory.string
      c.encoding         = Factory.string
      c.host             = Factory.string
      c.port             = Factory.integer
      c.username         = Factory.string
      c.password         = Factory.string
      c.pool             = Factory.integer
      c.checkout_timeout = Factory.integer
      c.min_messages     = Factory.string
    end
  end

end
