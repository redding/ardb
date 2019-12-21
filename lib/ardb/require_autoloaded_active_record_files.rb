# ActiveRecord makes use of autoload to load some of its components as-needed.
# This doesn"t work well with threaded environments, and causes uninitialized
# constants. To avoid this, this file manually requires the following files that
# are not required using `require "active_record"`. Trying to automatically
# require every file in ActiveRecord is slow and inefficient. Many of the files
# fail to require and there are some we don"t want to require. Thus, this is a
# manual list of requires.

# To re-build this list of requires, run the following:
#   bundle exec ruby script/determine_autoloaded_active_record_files.rb

# For compatibility, we require active record first
require "active_record"

require "active_record/aggregations"
require "active_record/associations"
require "active_record/associations/alias_tracker"
require "active_record/associations/association"
require "active_record/associations/association_scope"
require "active_record/associations/belongs_to_association"
require "active_record/associations/belongs_to_polymorphic_association"
require "active_record/associations/builder/association"
require "active_record/associations/builder/belongs_to"
require "active_record/associations/builder/collection_association"
require "active_record/associations/builder/has_and_belongs_to_many"
require "active_record/associations/builder/has_many"
require "active_record/associations/builder/has_one"
require "active_record/associations/collection_association"
require "active_record/associations/collection_proxy"
require "active_record/associations/has_and_belongs_to_many_association"
require "active_record/associations/has_many_association"
require "active_record/associations/has_many_through_association"
require "active_record/associations/has_one_association"
require "active_record/associations/has_one_through_association"
require "active_record/associations/join_dependency"
require "active_record/associations/join_dependency/join_association"
require "active_record/associations/join_dependency/join_base"
require "active_record/associations/preloader"
require "active_record/associations/preloader/association"
require "active_record/associations/preloader/belongs_to"
require "active_record/associations/preloader/collection_association"
require "active_record/associations/preloader/has_and_belongs_to_many"
require "active_record/associations/preloader/has_many"
require "active_record/associations/preloader/has_many_through"
require "active_record/associations/preloader/has_one"
require "active_record/associations/preloader/has_one_through"
require "active_record/attribute_assignment"
require "active_record/attribute_methods/before_type_cast"
require "active_record/attribute_methods/deprecated_underscore_read"
require "active_record/attribute_methods/dirty"
require "active_record/attribute_methods/primary_key"
require "active_record/attribute_methods/query"
require "active_record/attribute_methods/read"
require "active_record/attribute_methods/serialization"
require "active_record/attribute_methods/time_zone_conversion"
require "active_record/autosave_association"
require "active_record/base"
require "active_record/dynamic_finder_match"
require "active_record/dynamic_scope_match"
require "active_record/observer"
require "active_record/relation"
require "active_record/relation/predicate_builder"
require "active_record/result"

# There are also issues with requiring ActiveSupport. This doesn"t require every
# ActiveSupport file though, only ones we"ve seen cause problems.
require "active_support"

require "active_support/multibyte/chars"
