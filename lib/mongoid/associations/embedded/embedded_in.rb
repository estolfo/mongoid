require 'mongoid/associations/embedded/embedded_in/binding'
require 'mongoid/associations/embedded/embedded_in/builder'
require 'mongoid/associations/embedded/embedded_in/proxy'

module Mongoid
  module Associations
    module Embedded

      # The EmbeddedIn type association.
      #
      # @since 7.0
      class EmbeddedIn
        include Relatable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
        ASSOCIATION_OPTIONS = [
            :autobuild,
            :cyclic,
            :polymorphic,
            :touch
        ].freeze

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
          define_counter_cache_callbacks!
          define_touchable!
          self
        end

        # Is this association type embedded?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def embedded?; true; end

        # The primary key
        #
        # @return [ nil ] Not relevant for this relation
        def primary_key; end

        # Does this association type store the foreign key?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def stores_foreign_key?; false; end

        # The default for validation the association object.
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def validation_default; false; end

        # The key that is used to get the attributes for the associated object.
        #
        # @return [ String ] The name of the relation.
        #
        # @since 7.0
        def key
          @key ||= name.to_s
        end

        # Get a builder object for creating a relationship of this type between two objects.
        #
        # @params [ Object ] The base.
        # @params [ Object ] The object to relate.
        #
        # @return [ Associations::Embedded::EmbeddedIn::Builder ] The builder object.
        #
        # @since 7.0
        def builder(base, object)
          Builder.new(base, self, object)
        end

        # Get the relation proxy class for this association type.
        #
        # @return [ Associations::Embedded::EmbeddedIn::Proxy ] The proxy class.
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
          :embedded_in
        end

        # Is this association polymorphic?
        #
        # @return [ true, false ] Whether this association is polymorphic.
        #
        # @since 7.0
        def polymorphic?
          !!@options[:polymorphic]
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
          @relation_complements ||= [ Embedded::EmbedsMany,
                                      Embedded::EmbedsOne ].freeze
        end

        def polymorphic_inverses(other = nil)
          if other
            matches = other.relations.values.select do |rel|
              relation_complements.include?(rel.class) &&
                  rel.as == name &&
                  rel.relation_class_name == inverse_class_name
            end
            matches.collect { |m| m.name }
          end
        end

        def determine_inverses(other)
          matches = (other || relation_class).relations.values.select do |rel|
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