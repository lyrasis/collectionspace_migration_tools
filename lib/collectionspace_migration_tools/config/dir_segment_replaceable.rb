# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    module DirSegmentReplaceable
      # @param val [String]
      # @return [String]
      def replace_dir_segment(val)
        if val.start_with?("fixturesdir")
          val.sub("fixturesdir", File.join(
            Bundler.root.to_s, "spec", "support", "fixtures"
          ))
        else
          val
        end
      end
    end
  end
end
