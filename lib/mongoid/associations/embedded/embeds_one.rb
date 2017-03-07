require 'mongoid/associations/embedded/embeds_many/binding'
require 'mongoid/associations/embedded/embeds_many/builder'
require 'mongoid/associations/embedded/embeds_many/proxy'

module Mongoid
  module Associations
    module Embedded

      # The EmbedsOne type association.
      #
      # @since 7.0
      class EmbedsOne
        include Relatable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
        ASSOCIATION_OPTIONS = [
            :autobuild,
            :as,
            :cascade_callbacks,
            :cyclic,
            :store_as
        ]

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        #
        # @since 7.0
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # Setup the instance methods on the class having this association type.
        #
        # @return [ self ]
        #
        # @since 7.0
        def setup_instance_methods!
          define_getter!
          define_setter!
          define_existence_check!
          define_builder!
          define_creator!
          @owner_class.cyclic = true if cyclic?
          @owner_class.validates_associated(name) if validate?
          self
        end

        # The field key used to store the association object.
        #
        # @return [ String ] The field name.
        #
        # @since 7.0
        def store_as
          @store_as ||= (@options[:store_as].try(:to_s) || name.to_s)
        end

        # The key that is used to get the attributes for the associated object.
        #
        # @return [ String ] The name of the field used to store the relation.
        #
        # @since 7.0
        def key
          store_as.to_s
        end

        # Is this association type embedded?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def embedded?; true; end

        # Get the default validation setting for the relation. Determines if
        # by default a validates associated will occur.
        #
        # @example Get the validation default.
        #   Proxy.validation_default
        #
        # @return [ true, false ] The validation default.
        #
        # @since 2.1.9
        def validation_default; true; end

        # Does this association type store the foreign key?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def stores_foreign_key?; false; end

        # The primary key
        #
        # @return [ nil ] Not relevant for this relation
        def primary_key; end

        # Get a builder object for creating a relationship of this type between two objects.
        #
        # @params [ Object ] The base.
        # @params [ Object ] The object to relate.
        #
        # @return [ Associations::Embedded::EmbedsOne::Builder ] The builder object.
        #
        # @since 7.0
        def builder(base, object)
          Builder.new(base, self, object)
        end

        # Get the relation proxy class for this association type.
        #
        # @return [ Associations::Embedded::EmbedsMany::Proxy ] The proxy class.
        #
        # @since 7.0
        def relation
          Proxy
        end

        # Get the macro for this association type.
        #
        # @return [ Symbol ] The macro.
        #
        # @since 7.0
        def macro
          :embeds_one
        end

        # Is this association polymorphic?
        #
        # @return [ true, false ] Whether this association is polymorphic.
        #
        # @since 7.0
        def polymorphic?
          @polymorphic ||= !!@options[:as]
        end

        # The field used to store the type of the related object.
        #
        # @note Only relevant if the association is polymorphic.
        #
        # @return [ String, nil ] The field for storing the associated object's type.
        #
        # @since 7.0
        def type
          @type ||= "#{as}_type" if polymorphic?
        end

        # The nested builder object.
        #
        # @params [ Hash ] The attributes to use to build the association object.
        # @params [ Hash ] The options for the association.
        #
        # @return [ Associations::Nested::One ] The Nested Builder object.
        #
        # @since 7.0
        def nested_builder(attributes, options)
          Nested::One.new(self, attributes, options)
        end

        private

        def relation_complements
          @relation_complements ||= [ Embedded::EmbeddedIn ].freeze
        end

        def polymorphic_inverses(other = nil)
          [ as ]
        end

        def determine_inverses(other)
          matches = relation_class.relations.values.select do |rel|
            relation_complements.include?(rel.class) &&
                rel.relation_class_name == inverse_class_name

          end
          if matches.size > 1
            raise Errors::AmbiguousRelationship.new(relation_class, @owner_class, name, matches)
          end
          matches.collect { |m| m.name } unless matches.blank?
        end
      end
    end
  end
end