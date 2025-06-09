# frozen_string_literal: true

module CollectionspaceMigrationTools
  module_function

  def reset_config
    @config = Helpers.valid_config
  end
end

module Helpers
  module_function

  def fixtures_base = File.join(Bundler.root, "spec", "support", "fixtures")

  # returns system config parsed as hash
  def sys_config_hash
    CMT::Parse::YamlConfig.call(sys_config_path).value!
  end

  # returns path to system config
  def sys_config_path
    File.join(Bundler.root, "sample_system_config.yml")
  end

  # returns valid config parsed as hash
  def valid_config
    CMT::Configuration.call(client: valid_config_path)
  end

  # returns valid config parsed as hash
  def valid_config_hash
    CMT::Parse::YamlConfig.call(valid_config_path).value!
  end

  # returns path to valid test config (core.dev)
  def valid_config_path
    File.join(fixtures_base, "config_valid.yml")
  end

  # returns path to valid test config (core.dev)
  def invalid_config_path
    File.join(fixtures_base, "config_invalid.yml")
  end

  def setup_handler(rectype)
    setup_mapping
    mapper = CMT::Parse::RecordMapper.call(rectype)
    config = CMT::Parse::BatchConfig.call
    if mapper.success? && config.success?
      CMT::Build::DataHandler.call(mapper.value!, config.value!).value!
    end
  end

  def setup_mapping
    mapper_dir = File.join(Bundler.root.to_s, "spec", "support", "fixtures",
      "record_mappers")
    CMT.config.client.mapper_dir = mapper_dir
    CMT.config.client.profile = "anthro"
    CMT.config.client.profile_version = "9-0-0"
    CMT.config.client.batch_config_path = File.join(Bundler.root, "spec",
      "support", "fixtures", "client_batch_config.json")
  end

  def build_test_archive_csv(
    dir: "tmp", headers: CMT::Batch::Csv::Headers.all_headers, rowct: 1,
    row: nil
  )
    CMT.config.client.base_dir = File.join(Bundler.root, dir)
    rowdata = row || Array.new(headers.length, "x")
    CSV.open(CMT::ArchiveCsv.path, "w") do |csv|
      csv << headers
      rowct.times { csv << rowdata }
    end
  end
end
