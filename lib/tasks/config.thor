# frozen_string_literal: true

require 'thor'

# tasks targeting Config
class Config < Thor
  
  desc 'show', 'print active config to screen'
  def show
    pp(CMT.config)
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
