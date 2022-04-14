require 'bundler/inline'

gemfile do
  gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
  gem 'pry'
end


require 'csv'
require 'faker'
require 'optparse'
require 'pry'


options = {}
OptionParser.new{ |opts|
  opts.on('-o', '--output OUTPUTPATH', 'Path to output CSV'){ |o|
    options[:output] = File.expand_path(o)
  }
  opts.on('-n', '--num INTEGER', 'number of record rows to generate'){ |n|
    options[:num] = n.to_i
  }
  opts.on('-s', '--suffix STRING', 'string to add to end of id values'){ |s|
    options[:suffix] = s.strip
  }
  opts.on('-t', '--type STRING', 'record type to create'){ |t|
    options[:type] = t
  }
  opts.on('-c', '--complexity STRING', 'complexity of records to create: low, high'){ |c|
    options[:complexity] = c
  }

  opts.on('-h', '--help', 'Prints this help'){
    puts opts
    exit
  }
}.parse!

class BaseRow
  def initialize(suffix)
    @suffix = suffix
  end

  def call
    if suffix
      data = row
      id = "#{data.shift}#{suffix}"
      [id, data].flatten
    else
      row
    end
  end

  def header_row
    headers
  end
  
  private

  attr_reader :suffix
  
  def date
    formats = [
      '%Y', #2021
      '%D', #02/03/21
      '%F', #2021-02-03
      "%-m/%-d/%Y", #2/3/2021
      "%B %-d, %Y", #February 3, 2021 
      "%b %-d, %Y", #Feb 3, 2021 
      "%b %d %Y", #Feb 03 2021
    ]
    Faker::Date.backward.strftime(formats.sample)
  end

  def language
    opts = %w[English French German Spanish]
    opts.random
  end

  def role
    roles = [Faker::Cosmere.knight_radiant, Faker::Cosmere.allomancer, Faker::Cosmere.feruchemist]
    roles.sample
  end
  
end

class ObjectLow < BaseRow
  private

  def headers
    %w[objectnumber title]
  end
  
  def row
    [
      Faker::Code.unique.isbn, #objectnumber
      Faker::Book.title #title
    ]
  end  
end

class PersonLow < BaseRow
  private

  def headers
    %w[termdisplayname]
  end

  def row
    [
      Faker::Name.name
    ]
  end  
end

class MediaHigh < BaseRow
  private
  
  def headers
    %w[identificationnumber title mediafileuri contributororganizationlocal creatorpersonlocal language publisherorganizationlocal copyrightstatement coverage dategroup relation source subject rightsholderpersonlocal description alttext
      ]
  end

  def row
    [
      Faker::Code.unique.isbn, #objectnumber
      Faker::Book.title, #title
      Faker::Placeholdit.image(format: 'jpg'), #mediafileuri
      Faker::Company.name, #contributororganizationlocal
      Faker::Name.name, #creatorpersonlocal
      language,
      Faker::Book.publisher, #publisherorganizationlocal
      Faker::Lorem.sentence, #copyrightstatement
      date, #dategroup
      role, #relation
      Faker::Commerce.department, #source
      Faker::Name, #rightsholderpersonlocal
      Faker::Commerce.product_name #alttext
    ]
  end  
end




class Creator
  def initialize(type:, complexity:, suffix:, path:, num:)
    @suffix = suffix
    @klass = Object.const_get("#{type.capitalize}#{complexity.capitalize}").new(suffix)
    @path = path
    @num = num
  end

  def call
    CSV.open(path, 'w') do |csv|
      csv << klass.header_row
      num.times{ csv << klass.call }
    end
  end

  private

  attr_reader :klass, :suffix, :path, :num
end

creator = Creator.new(
  type: options[:type],
  complexity: options[:complexity],
  suffix: options[:suffix],
  path: options[:output],
  num: options[:num]
)
creator.call

