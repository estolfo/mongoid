module Mongoid
  class Criteria
    class Aggregation
      include Enumerable

      VALID_OPERATORS = {
          coll_states: '$collStats',
          project: '$project',
          match: '$match',
          redact: '$redact',
          limit: '$limit',
          skip: '$skip',
          unwind: '$unwind',
          group: '$group',
          sample: '$sample',
          sort: '$sort',
          geo_near: '$geoNear',
          out: '$out',
          index_stats: '$indexStats',
          facet: '$facet',
          bucket: '$bucket',
          bucket_auto: '$bucketAuto',
          sort_by_count: '$sortByCount',
          add_fields: '$addFields',
          replace_root: '$replaceRoot',
          count: '$count',
          graph_lookup: '$graphLookup'
      }

      attr_reader :options
      attr_reader :criteria
      attr_reader :pipeline

      # Create the methods for each mapping to tell if they are supported.
      #
      # @since 2.0.0
      VALID_OPERATORS.each do |method_name, operator_key|

        # Define methods for aggregation pipeline operators.
        #
        # @example Is a feature enabled?
        #   aggregation.match(name: 'emily')
        #
        # @return [ Criteria::Aggregation ] A new Aggregation object with that pipeline
        #   operator set.
        #
        # @since 7.0.0
        define_method("#{method_name}") do |expression|
          configure(operator_key, expression)
        end
      end

      def initialize(criteria, pipeline, options = {})
        @criteria = criteria
        @pipeline = pipeline.dup
        @options = BSON::Document.new(options).freeze
      end

      def set_option(option)
        new(pipeline, options.merge(option))
      end

      def raw_results!
        new(pipeline, options.merge(raw_results: true))
      end

      def model_results!
        #raise error if there is a lookup operator
        new(pipeline, options.merge(raw_results: false))
      end

      def lookup(relation, doc = {})
        if relation
          association = criteria.klass.relations[relation]
          @options = @options.merge(association: association)
          lookup_spec = make_lookup_spec(association).merge!(doc)
        elsif raw_results
          lookup_spec = doc
        else
          #raise error
        end
        configure('$lookup', lookup_spec)
      end

      def each
        raw_results = options[:raw_results]
        association = options[:association]
        view = @criteria.collection.aggregate(pipeline, options)

        return to_enum unless block_given?
        view.each do |doc|
          if raw_results
            yield(doc)
          else
            if lookup_as
              as = doc.delete(lookup_as)
              model = Factory.from_db(criteria.klass, doc)
              as.each do |association_doc|
                klass = association.klass
                obj = Factory.from_db(klass, association_doc)
                obj.send(association.inverse_setter, model)
              end
            else
              model = Factory.from_db(criteria.klass, doc)
            end
            yield(model)
          end
        end
      end

      private

      def make_lookup_spec(association)
        {
          from: association.klass.collection_name.to_s,
          localField: association.primary_key,
          foreignField: association.foreign_key,
          as: association.name.to_s
        }
      end

      def lookup_as
        if lookup_operator = @pipeline.find { |operator|  operator['$lookup'] }
          lookup_operator['$lookup'][:as]
        end
      end

      def new(pipeline, options)
        Aggregation.new(criteria, pipeline, options)
      end

      def configure(operator_key, expression)
        new(pipeline << { operator_key => expression }, options)
      end
    end
  end
end
