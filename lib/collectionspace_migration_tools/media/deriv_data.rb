# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Media
    # Value object representing derivative data
    class DerivData
      DERIV_TYPES = %w[small medium thumbnail originaljpeg fullhd].freeze
      DERIV_TYPES.each do |type|
        define_method("#{type}?"){ derivs.any?(type) }
      end

      attr_reader :deriv_ct, :derivs

      def initialize(blobcsid:, response:)
        @blobcsid = blobcsid
        @response = response['abstract_common_list']
        @deriv_ct = get_count
        @derivs = get_derivs
      end

      def to_h
        DERIV_TYPES.map{ |type| [type, translate_type(type)] }
          .to_h
          .merge({'deriv_ct'=>deriv_ct})
      end

      private

      attr_reader :blobcsid, :response

      # @param item [Hash] element of response['list_item']
      def deriv_title(item)
        item['uri'].delete_prefix("/blobs/#{blobcsid}/derivatives/")
          .delete_suffix("/content")
          .downcase
      end

      def get_count
        items = response['list_item']
        return 0 unless items

        items.length
      end

      def get_derivs
        items = response['list_item']
        return [] unless items

        # if there is only one item, it returns item hash, not array
        [items].flatten
          .map{ |item| deriv_title(item) }
      end

      def translate_type(type)
        send(:"#{type}?") ? 'y' : nil
      end
    end
  end
end
