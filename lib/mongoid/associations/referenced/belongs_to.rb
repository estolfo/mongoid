require 'mongoid/associations/referenced/belongs_to/binding'
require 'mongoid/associations/referenced/belongs_to/builder'
require 'mongoid/associations/referenced/belongs_to/proxy'
require 'mongoid/associations/referenced/belongs_to/eager'

module Mongoid
  module Associations
    module Referenced

      # The BelongsTo type association.
      #
      # @since 7.0
      class BelongsTo
        include Relatable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        #
        # @since 7.0
        ASSOCIATION_OPTIONS = [
            :autobuild,
            :autosave,
            :counter_cache,
            :dependent,
            :foreign_key,
            :index,
            :polymorphic,
            :primary_key,
            :touch,
            :optional,
            :required
        ].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        #
        # @since 7.0
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The type of the field holding the foreign key.
        #
        # @return [ Object ]
        #
        # @since 7.0
        FOREIGN_KEY_FIELD_TYPE = Object

        # The list of association complements.
        #
        # @return [ Array<Association> ] The association complements.
        #
        # @since 7.0
        def relation_complements
          @relation_complements ||= [ HasMany, HasOne ].freeze
        end

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
          define_autosaver!
          define_counter_cache_callbacks!
          polymorph!
          define_dependency!
          create_foreign_key_field!
          setup_index!
          define_touchable!
          @owner_class.validates_associated(name) if validate?
          @owner_class.validates(name, presence: true) if require_association?
          self
        end

        # Does this association type store the foreign key?
        #
        # @return [ true ] Always true.
        #
        # @since 7.0
        def stores_foreign_key?; true; end

        # Is this association type embedded?
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def embedded?; false; end

        # The default for validation the association object.
        #
        # @return [ false ] Always false.
        #
        # @since 7.0
        def validation_default; false; end

        # Get the foreign key field for saving the association reference.
        #
        # @return [ String ] The foreign key field for saving the association reference.
        #
        # @since 7.0
        def foreign_key
          @foreign_key ||= @options[:foreign_key] ? @options[:foreign_key].to_s : relation.foreign_key(name)
        end

        # Get a builder object for creating a relationship of this type between two objects.
        #
        # @params [ Object ] The base.
        # @params [ Object ] The object to relate.
        #
        # @return [ Associations::BelongsTo::Builder ] The builder object.
        #
        # @since 7.0
        def builder(base, object)
          Builder.new(base, self, object)
        end

        # Get the relation proxy class for this association type.
        #
        # @return [ Associations::BelongsTo::Proxy ] The proxy class.
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
          :belongs_to
        end

        # The criteria used for querying this relation.
        #
        # @return [ Mongoid::Criteria ] The criteria used for querying this relation.
        #
        # @since 7.0
        def criteria(object, type)
          relation.criteria(self, object, type)
        end

        # Is this association polymorphic?
        #
        # @return [ true, false ] Whether this association is polymorphic.
        #
        # @since 7.0
        def polymorphic?
          @polymorphic ||= !!@options[:polymorphic]
        end

        # The name of the field used to store the type of polymorphic relation.
        #
        # @return [ String ] The field used to store the type of polymorphic relation.
        #
        # @since 7.0
        def inverse_type
          (@inverse_type ||= "#{name}_type") if polymorphic?
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

        # Get the path calculator for the supplied document.
        #
        # @example Get the path calculator.
        #   association.path(document)
        #
        # @param [ Document ] document The document to calculate on.
        #
        # @return [ Root ] The root atomic path calculator.
        #
        # @since 2.1.0
        def path(document)
          Mongoid::Atomic::Paths::Root.new(document)
        end

        private

        def index_spec
          if polymorphic?
            { key => 1, inverse_type => 1 }
          else
            { key => 1 }
          end
        end

        def default_primary_key
          PRIMARY_KEY_DEFAULT
        end

        def polymorph!
          if polymorphic?
            @owner_class.polymorphic = true
            @owner_class.field(inverse_type, type: String)
          end
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
          matches.collect { |m| m.name }
        end

        # If set to true, then the associated object will be validated when this object is saved
        def require_association?
          required = @options[:required] if @options.key?(:required)
          required = !@options[:optional] if @options.key?(:optional) && required.nil?
          required.nil? ? Mongoid.belongs_to_required_by_default : required
        end

        def create_foreign_key_field!
          @owner_class.field(
              foreign_key,
              type: FOREIGN_KEY_FIELD_TYPE,
              identity: true,
              overwrite: true,
              metadata: self,
              default: nil
          )
        end
      end
    end
  end
end