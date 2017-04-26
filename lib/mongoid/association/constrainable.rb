# encoding: utf-8
module Mongoid
  module Association

    # Used for converting foreign key values to the correct type based on the
    # types of ids that the document stores.
    #
    # @note Durran: The name of this class is this way to match the metadata
    #   getter, and foreign_key was already taken there.
    module Constrainable

      # Convert the supplied object to the appropriate type to set as the
      # foreign key for a relation.
      #
      # @example Convert the object.
      #   constraint.convert("12345")
      #
      # @param [ Object ] object The object to convert.
      #
      # @return [ Object ] The object cast to the correct type.
      #
      # @since 2.0.0.rc.7
      def convert_to_foreign_key(object)
        return convert_polymorphic(object) if polymorphic?
        field = relation_class.fields["_id"]
        if relation_class.using_object_ids?
          BSON::ObjectId.mongoize(object)
        elsif object.is_a?(::Array)
          object.map!{ |obj| field.mongoize(obj) }
        else
          field.mongoize(object)
        end
      end

      private
      
      def convert_polymorphic(object)
        object.respond_to?(:id) ? object.id : object
      end
    end
  end
end
