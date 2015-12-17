require 'assert/factory'

module Factory
  extend Assert::Factory

  def self.migration_id
    # identifiers need to be plural b/c af activesupport's pluralize
    "#{Factory.string}_things"
  end

end
