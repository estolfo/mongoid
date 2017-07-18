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
          lookup: '$lookup',
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
        @options = BSON::Document.new(options)
      end

      def set_option(option)
        new(pipeline, options.merge(option))
      end

      def raw_results!
        new(pipeline, options.merge(raw_results: true))
      end

      def model_results!
        new(pipeline, options.merge(raw_results: false))
      end

      def each
        raw_results = options.delete(:raw_results)
        view = @criteria.collection.aggregate(pipeline, options)
        return to_enum unless block_given?
        view.each do |doc|
          yield(raw_results ? doc : Factory.from_db(criteria.klass, doc))
        end
      end

      private

      def new(pipeline, options)
        Aggregation.new(criteria, pipeline, options)
      end

      def configure(operator_key, expression)
        new(pipeline << { operator_key => expression }, options)
      end
    end
  end
end
