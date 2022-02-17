# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    module Authority

      module_function

      def record_types
        %w[citation concept location material organization person place taxon work]
      end

      def queries
        record_types.map{ |rectype| CMT::QB::Authority::RecordType.new(rectype) }
            .each{ |q| puts q.query; puts "\n------------------------------\n" }
      end

      def types
        record_types.map{ |rectype| CMT::QB::Authority::RecordType.new(rectype).service_type }
      end

      def services
        types.map{ |type| CollectionSpace::Service.get(type: type) }
      end

      def term_tables
        record_types.map{ |rectype| CMT::QB::Authority::RecordType.new(rectype).term_table }
      end
      
      # [{:identifier=>"shortIdentifier",
      #   :ns_prefix=>"citations",
      #   :path=>"citationauthorities/urn:cspace:name()/items",
      #   :term=>"citationTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"concepts",
      #   :path=>"conceptauthorities/urn:cspace:name()/items",
      #   :term=>"conceptTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"locations",
      #   :path=>"locationauthorities/urn:cspace:name()/items",
      #   :term=>"locTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"materials",
      #   :path=>"materialauthorities/urn:cspace:name()/items",
      #   :term=>"materialTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"organizations",
      #   :path=>"orgauthorities/urn:cspace:name()/items",
      #   :term=>"orgTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"persons",
      #   :path=>"personauthorities/urn:cspace:name()/items",
      #   :term=>"personTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"places",
      #   :path=>"placeauthorities/urn:cspace:name()/items",
      #   :term=>"placeTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"taxon",
      #   :path=>"taxonomyauthority/urn:cspace:name()/items",
      #   :term=>"taxonTermGroupList/0/termDisplayName"},
      #  {:identifier=>"shortIdentifier",
      #   :ns_prefix=>"works",
      #   :path=>"workauthorities/urn:cspace:name()/items",
      #   :term=>"workTermGroupList/0/termDisplayName"}]
    end
  end
end
