# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Media
    # Use API calls to generate detailed report of derivatives present
    #   for given blobs
    class DerivReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)


      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param csv_path [nil, String] path to CSV of blob_data
      def initialize(csv_path: nil)
        @csv_path = csv_path
        # from imageTypes static variable used in `isImageMedia` function in:
        #   https://github.com/collectionspace/services/blob/master/services/common/src/main/java/org/collectionspace/services/common/imaging/nuxeo/NuxeoBlobUtils.java
        @derivable_image_types = %w[jpeg bmp gif png tiff octet-stream]
      end

      def call
        puts "Setting up to produce deriv report..."

        client = yield CMT::Client.call
        if csv_path
          path = File.expand_path(csv_path)
        else
          _blob_data = yield CMT::Media.blob_data_report
          path = yield CMT::Media.blob_data_path
        end
        row_getter = yield CMT::Csv::FirstRowGetter.new(path)
        csvchecker = yield CMT::Csv::FileChecker.call(path, row_getter)
        blob_row = csvchecker[1]

        checker = yield CMT::Media::DerivChecker.new(client: client)

        headers = [
          blob_row.headers,
          'derivable?', 'check_success?',
          'deriv_ct',
          CMT::Media::DerivData::DERIV_TYPES,
          'error_msgs'
          ].flatten
        grouped_rows = yield group_rows(path)
        derivable = yield CMT::Media::DerivCheckProcessor.call(
          checker: checker,
          rows: grouped_rows[:derivable]
        )
        underivable = yield get_underivable(grouped_rows[:underivable])

        _written = yield write_report(
          headers: headers,
          rows: [derivable, underivable].flatten
        )

        Success()
      end

      private

      attr_reader :csv_path, :derivable_image_types

      def write_report(headers:, rows:)
        outpath = File.join(
          CMT.config.client.base_dir,
          'blob_derivative_report.csv'
        )
        CSV.open(outpath, 'w') do |csv|
          csv << headers
          rows.each{ |row| csv << row.values_at(*headers) }
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        puts "Wrote derivatives report to #{outpath}..."
        Success()
      end

      # @param rows [Array<CSV::Row>]
      # @param checker [CMT::Media::DerivChecker]
      def get_derivable(rows, checker)
        start_time = Time.now
        result = rows.map do |row|
          CMT::Media::DerivableData.new(
            blob: row,
            deriv: checker.call(blobcsid: row['blobcsid'])
          ).to_h
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        elap = Time.now - start_time
        puts "Derivative checking time: #{elap}"

        Success(result)
      end

      def get_underivable(rows)
        result = rows.map do |row|
          row.to_h
            .merge({
              'derivable?'=>'n',
              'check_success?'=> 'n/a'
            })
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        Success(result)
      end

      def group_rows(path)
        derivable = []
        underivable = []
        CSV.foreach(path, headers: true) do |row|
          derivable?(row['mimetype']) ? derivable << row : underivable << row
        end
        result = {derivable: derivable, underivable: underivable}
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        Success(result)
      end

      def image?(mimetype)
        return false unless mimetype

        mimetype.start_with?('image/')
      end

      def derivable?(mimetype)
        return false unless mimetype
        return false unless image?(mimetype)

        derivable_image_types.any?(
          mimetype.split('/').last
        )
      end
    end
  end
end
