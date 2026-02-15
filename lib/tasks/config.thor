# frozen_string_literal: true

require "fileutils"

# tasks targeting Config
class Config < Thor
  desc "all", "shows names of all configs in `repo_dir/config`"
  def all
    CMT::Config::Lister.call(type: :basename).either(
      ->(success) {
        success.each { |cfg| puts cfg }
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "redis_dbs",
    "for each file in config dir, shows you the base_uri and redis db number"
  def redis_dbs
    vals = {}
    fails = 0
    get_and_parse_configs.each do |path, config|
      if config.failure?
        puts "Cannot parse #{path}; skipping"
        fails += 1
      else
        cfg = config.value!
        vals[File.basename(path, ".yml")] = cfg[:client][:redis_db_number]
      end
    end

    vals.compact.sort_by { |_key, val| val }
      .each { |key, val| puts "#{val}\t#{key}" }

    (fails == 0) ? exit(0) : exit(1)
  end

  desc "show", "print name of active config to screen"
  method_option :verbose,
    aliases: "-v",
    desc: "Print full active config to screen",
    type: :boolean,
    default: false
  def show
    mode = options[:verbose] ? :prod : :check
    config = CMT::Configuration.call(mode: mode)
    if config.client.nil?
      puts "No client config found. Try doing:\n"\
        "  thor config switch {yourconfigname}. "
      exit(1)
    end

    if options[:verbose]
      pp(config)
    else
      puts config.current_client
    end
    exit(0)
  end

  desc "switch CONFIG_NAME_WITHOUT_EXTENSION",
    "Validates the specified client config, and if valid, resets the current "\
    "config value stored in `config_name_file` (see system config)"
  def switch(name)
    CMT::Config::Switcher.call(client: name).either(
      ->(success) {
        puts "NOW USING CONFIG:"
        pp(success)
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  no_commands do
    def config_dir = CMT.config.system.client_config_dir

    def get_and_parse_configs
      Dir.new(config_dir)
        .children
        .select { |file| File.extname(file) == ".yml" }
        .map { |file| "#{config_dir}/#{file}" }
        .map { |path| [path, CMT::Parse::YamlConfig.call(path)] }
        .to_h
    end
  end
end
