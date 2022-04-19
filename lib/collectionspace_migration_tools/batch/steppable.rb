# frozen_string_literal: true

require 'fileutils'

module CollectionspaceMigrationTools
  module Batch
    # Mixin containing methods for dealing with data about batch workflow step
    #
    # Mixed in by individual step mixin modules (e.g. Mappable, Uploadable), which are mixed in by Batch
    #
    # Modules mixing in this module must define the following methods:
    #   - :#{steptype}_step_headers
    #   - :#{steptype}_step_report_paths
    #   - :#{steptype}_next_step
    module Steppable
      include Dry::Monads::Do.for(:rollback_step)

      def rollback_step(steptype)
        _checked = yield(rollbackable?(steptype))
        _cleared = yield(clear_step_fields(steptype))
        _rewritten = yield(rewrite)
        _deleted = yield(delete_step_reports(steptype))

        Success()
      end

      ## private methods
      
      def clear_step_fields(steptype)
        meth = "#{steptype}_step_headers".to_sym
        send(meth).each do |header|
          data[header] = '' if data.key?(header)
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end
      private :clear_step_fields

      def delete_step_reports(steptype)
        meth = "#{steptype}_step_report_paths".to_sym
        send(meth).each do |path|
          FileUtils.rm(path) if File.exists?(path)
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end
      private :delete_step_reports

      def rollbackable?(steptype)
        next_step = send("#{steptype}_next_step".to_sym)
        value = data[next_step]
        return Success() if value.nil? || value.empty?

        Failure("#{next_step} is not blank. Cannot rollback #{steptype}")
      end
    end
  end
end
