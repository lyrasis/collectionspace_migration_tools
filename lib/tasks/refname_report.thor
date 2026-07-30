# frozen_string_literal: true

require "thor"

# tasks for writing authority refnames to CSV to be used as lookup tables
class RefnameReport < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  namespace :rr

  desc "list",
    "write refname report that includes terms in listed authority record types"
  option :rectypes,
    type: :array,
    aliases: "-r",
    required: true,
    desc: "Mappable record types for which to pull refname/CSID info",
    banner: "person-local person-ulan"
  option :outputpath,
    type: :string,
    aliases: "-o",
    required: false,
    desc: "Path where result will be written. Should be a .csv",
    default: CMT::RefnameReport.default_refname_data_path.value!
  def list
    rectypes = options[:rectypes].map do |rectype|
      CMT::RecordTypes.to_obj(rectype)
    end
    rectypes.select(&:failure?)
      .each { |rt| puts rt.failure }

    CMT::RefnameReport.write(
      rectypes: rectypes.select(&:success?).map(&:value!),
      path: options[:outputpath]
    )
  end
end
