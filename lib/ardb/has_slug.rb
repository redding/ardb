require 'much-plugin'

module Ardb

  module HasSlug
    include MuchPlugin

    DEFAULT_ATTRIBUTE    = :slug
    DEFAULT_PREPROCESSOR = :downcase
    DEFAULT_SEPARATOR    = '-'.freeze

    plugin_included do
      extend ClassMethods
      include InstanceMethods

      @ardb_has_slug_configs = Hash.new{ |h, k| h[k] = {} }
    end

    module ClassMethods

      def has_slug(options = nil)
        options ||= {}
        raise(ArgumentError, "a source must be provided") unless options[:source]

        attribute = (options[:attribute] || DEFAULT_ATTRIBUTE).to_sym
        @ardb_has_slug_configs[attribute].merge!({
          :source_proc       => options[:source].to_proc,
          :preprocessor_proc => (options[:preprocessor] || DEFAULT_PREPROCESSOR).to_proc,
          :separator         => options[:separator] || DEFAULT_SEPARATOR,
          :allow_underscores => !!options[:allow_underscores]
        })

        # since the slug isn't written till an after callback we can't always
        # validate presence of it
        validates_presence_of(attribute, :on => :update)

        if options[:skip_unique_validation] != true
          validates_uniqueness_of(attribute, {
            :case_sensitive => true,
            :scope          => options[:unique_scope]
          })
        end

        after_create :ardb_has_slug_generate_slugs
        after_update :ardb_has_slug_generate_slugs
      end

      def ardb_has_slug_configs
        @ardb_has_slug_configs
      end

    end

    module InstanceMethods

      private

      def reset_slug(attribute = nil)
        attribute ||= DEFAULT_ATTRIBUTE
        self.send("#{attribute}=", nil)
      end

      def ardb_has_slug_generate_slugs
        self.class.ardb_has_slug_configs.each do |attr_name, config|
          slug_source = if !self.send(attr_name) || self.send(attr_name).to_s.empty?
            self.instance_eval(&config[:source_proc])
          else
            self.send(attr_name)
          end

          generated_slug = Slug.new(slug_source, {
            :preprocessor      => config[:preprocessor_proc],
            :separator         => config[:separator],
            :allow_underscores => config[:allow_underscores]
          })
          next if self.send(attr_name) == generated_slug
          self.send("#{attr_name}=", generated_slug)
          self.update_column(attr_name, generated_slug)
        end
      end

    end

    module Slug
      def self.new(string, options = nil)
        options ||= {}
        preprocessor       = options[:preprocessor]
        separator          = options[:separator]
        allow_underscores  = options[:allow_underscores]
        regexp_escaped_sep = Regexp.escape(separator)

        slug = preprocessor.call(string.to_s.dup)
        # Turn unwanted chars into the separator
        slug.gsub!(/[^\w#{regexp_escaped_sep}]+/, separator)
        # Turn underscores into the separator, unless allowing
        slug.gsub!(/_/, separator) unless allow_underscores
        # No more than one of the separator in a row.
        slug.gsub!(/#{regexp_escaped_sep}{2,}/, separator)
        # Remove leading/trailing separator.
        slug.gsub!(/\A#{regexp_escaped_sep}|#{regexp_escaped_sep}\z/, '')
        slug
      end
    end

  end

end
