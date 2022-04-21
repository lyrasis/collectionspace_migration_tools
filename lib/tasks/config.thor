# frozen_string_literal: true

require 'fileutils'

# tasks targeting Config
class Config < Thor
  
  desc 'show', 'print active config to screen'
  def show
    pp(CMT.config)
  end

  desc 'switch CONFIG_NAME_WITHOUT_EXTENSION', 'Copies specified .yml file from `repo_dir/config` to client_config.yml'
  def switch(name)
    CMT::Config::Switcher.call(name).either(
      ->(success){ puts "NOW USING CONFIG:"; pp(CMT.config) },
      ->(failure){ puts failure.to_s }
    )
  end
  
  desc 'redis_dbs', 'for each file in config dir, shows you the base_uri and redis db number'
  def redis_dbs
    vals = {}
    get_and_parse_configs.each do |path, config|
      if config.failure?
        puts "Cannot parse #{path}; skipping"
      else
        cfg = config.value!
        vals[File.basename(path, '.yml')] = cfg[:client][:redis_db_number]
      end
    end
    
    vals.sort_by{ |_key, val| val }
      .each{ |key, val| puts "#{val}\t#{key}" }
  end
  
  desc 'show', 'print active config to screen'
  def show
    pp(CMT.config)
  end

  desc 'switch CONFIG_NAME_WITHOUT_EXTENSION', 'Copies specified .yml file from `repo_dir/config` to client_config.yml'
  def switch(name)
    CMT::Config::Switcher.call(config_name: name).either(
      ->(success){
        puts "NOW USING CONFIG:"
        pp(CMT::Configuration.new)
      },
      ->(failure){
        puts failure.to_s
        puts "STILL USING CONFIG:"
        pp(CMT::Configuration.new)
      }
    )
  end

  no_commands do
    def config_dir
      File.join(Bundler.root, 'config')
    end
    
    def get_and_parse_configs
      Dir.new(config_dir)
        .children
        .select{ |file| File.extname(file) == '.yml' }
        .map{ |file| "#{config_dir}/#{file}" }
        .map{ |path| [path, CMT::Parse::YamlConfig.call(path)] }
        .to_h
    end
  end
end
