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

      @ardb_has_slug_config = {}

    end

    module ClassMethods

      def has_slug(options = nil)
        options ||= {}
        raise(ArgumentError, "a source must be provided") unless options[:source]

        @ardb_has_slug_config.merge!({
          :attribute         => options[:attribute] || DEFAULT_ATTRIBUTE,
          :source_proc       => options[:source].to_proc,
          :preprocessor_proc => (options[:preprocessor] || DEFAULT_PREPROCESSOR).to_proc,
          :separator         => options[:separator] || DEFAULT_SEPARATOR,
          :allow_underscores => !!options[:allow_underscores]
        })

        # since the slug isn't written till an after callback we can't always
        # validate presence of it
        validates_presence_of(self.ardb_has_slug_config[:attribute], :on => :update)
        validates_uniqueness_of(self.ardb_has_slug_config[:attribute], {
          :case_sensitive => true,
          :scope          => options[:unique_scope]
        })

        after_create :ardb_has_slug_generate_slug
        after_update :ardb_has_slug_generate_slug
      end

      def ardb_has_slug_config
        @ardb_has_slug_config
      end

    end

    module InstanceMethods

      private

      def reset_slug
        self.send("#{self.class.ardb_has_slug_config[:attribute]}=", nil)
      end

      def ardb_has_slug_generate_slug
        attr_name = self.class.ardb_has_slug_config[:attribute]
        slug_source = if !self.send(attr_name) || self.send(attr_name).to_s.empty?
          self.instance_eval(&self.class.ardb_has_slug_config[:source_proc])
        else
          self.send(attr_name)
        end

        generated_slug = Slug.new(slug_source, {
          :preprocessor      => self.class.ardb_has_slug_config[:preprocessor_proc],
          :separator         => self.class.ardb_has_slug_config[:separator],
          :allow_underscores => self.class.ardb_has_slug_config[:allow_underscores]
        })
        return if self.send(attr_name) == generated_slug
        self.send("#{attr_name}=", generated_slug)
        self.update_column(attr_name, generated_slug)
      end

    end

    module Slug
      DEFAULT_PREPROCESSOR = proc{ |slug| slug } # no-op

      def self.new(string, options = nil)
        options ||= {}
        preprocessor       = options[:preprocessor] || DEFAULT_PREPROCESSOR
        separator          = options[:separator] || DEFAULT_SEPARATOR
        allow_underscores  = options[:allow_underscores]
        regexp_escaped_sep = Regexp.escape(separator)

        slug = preprocessor.call(string.to_s)
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
