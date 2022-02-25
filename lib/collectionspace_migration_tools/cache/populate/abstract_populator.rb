# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Cache
    module Populate
      class AbstractPopulator
        include Dry::Monads[:result]

        class << self
          def call(data)
            self.new.call(data)
          end
        end
        
        def call(data)
          before_report(data)
          do_population(data).either(
            ->(result){ after_report },
            ->(result){ problem_report(result) }
          )
        end

        private

        def before_report(data)
          puts "Populating #{cache_name} cache (current size: #{@start_size}) with #{data.num_tuples} #{population_type}..."
        end

        def after_report
          puts "#{cache_name} for #{population_type} cached. Resulting cache size: #{@cache.size}"
          Success('ok')
        end

        # should be implemented in Abstract#{cache type}Populator classes
        def cache_name
          raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
        end

        def do_population(data)
          data.each{ |row| @cache.put(*signature(row)) }
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          Success('ok')
        end

        def population_type
          self.class.name.split('::').last.downcase
        end

        def problem_report(failure)
          puts "Problem populating #{cache_name} cache..."
          puts failure.to_s
          Failure(failure)
        end

        # should be implemented in Concrete population classes
        def signature(row)
          raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end
