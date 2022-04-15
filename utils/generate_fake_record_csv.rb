require 'bundler/inline'

gemfile do
  source "https://rubygems.org"
  gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
  gem 'pry'
end


require 'csv'
require 'faker'
require 'optparse'
require 'pry'
require 'singleton'


options = {}
OptionParser.new{ |opts|
  opts.on('-o', '--output OUTPUTPATH', 'Path to output CSV'){ |o|
    options[:output] = File.expand_path(o)
  }
  opts.on('-n', '--num INTEGER', 'number of record rows to generate'){ |n|
    options[:num] = n.to_i
  }
  opts.on('-s', '--suffix STRING', 'string to add to end of id values'){ |s|
    options[:suffix] = s
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

DELIM = '|'
SGDELIM = '^^'
NV = '%NULLVALUE%'

# usage: Multi.call(3) {Date.call}
class Multi
  def self.call(max, &meth)
    Array.new(rand(0..max+1)){ meth.call }
      .compact
      .uniq
      .join(DELIM)
  end
end

# mixin to select a value from values array
module Selectable
  def value
    values.sample
  end
end

# mixin to add %NULLVALUE% as a potential return value
module Nullable
  def call(nullable: true)
    nullable ? [value, value, value, value, NV].flatten.sample : value
  end
end

class Date
  class << self
    include Nullable
    def value
      Faker::Date.backward.strftime(formats.sample)
    end

    private
    def formats
      [
        '%Y', #2021
        '%D', #02/03/21
        '%F', #2021-02-03
        "%-m/%-d/%Y", #2/3/2021
        "%B %-d, %Y", #February 3, 2021 
        "%b %-d, %Y", #Feb 3, 2021 
        "%b %d %Y", #Feb 03 2021
      ]
    end
  end
end

class InventoryStatus
  class << self
    include Nullable
    include Selectable

    def values
      ["unknown", "accession status unclear", "accessioned", "deaccessioned", "destroyed", "destructive analysis", "discarded", "exchanged", "intended for transfer", "irregular museum number", "missing", "missing in inventory", "not cataloged", "not located", "not received", "number not used", "object mount", "on loan", "partially deaccessioned", "partially exchanged", "partially recataloged", "returned loan object", "sold", "stolen", "transferred"]
    end
  end
end

class Language
  class << self
    include Nullable
    include Selectable

    def values
      [
        "Arabic", "Armenian", "Chinese", "English", "French", "German", "Ancient Greek", "Hebrew", "Indonesian", "Italian",
        "Japanese", "Korean", "Latin", "Malaysian", "Middle English", "Old English", "Portuguese", "Romanian", "Russian",
        "Spanish", "Swahili", "Swedish", "Tagalog", "Yoruba"
      ]
    end
  end
end

class ResponsibleDepartment
  class << self
    include Nullable
    include Selectable

    def values
      %w[antiquities architecture-design decorative-arts ethnography herpetology media-performance-art paintings-sculpture paleobotany photographs prints-drawings]
    end
  end
end

class Role
  class << self
    include Nullable
    include Selectable

    def values
        [Faker::Cosmere.knight_radiant, Faker::Cosmere.allomancer, Faker::Cosmere.feruchemist]
    end
  end
end

class Organization
  class << self
    include Nullable
    include Selectable
    
    attr_reader :values

    def setup(num = 25)
      @values = Array.new(num){ Faker::Company.unique.name }
    end
  end
end

class Person
  class << self
    include Nullable
    include Selectable
    
    attr_reader :values

    def setup(num = 50)
      @values = Array.new(num){ Faker::Name.unique.name }
    end
  end
end

class NamedCollectionWork
  class << self
    include Nullable
    include Selectable
    
    attr_reader :values

    def setup(num = 50)
      @values = Array.new(num){ "#{Faker::Science.science} Collection" }
    end
  end
end

class PublishTo
  class << self
    def call(max = 1)
      postprocess(Array.new(rand(max + 1)){ value })
    end

    private

    def postprocess(arr)
      if arr.any?('All')
        'All'
      elsif arr.any?('None')
        'None'
      else
        arr.uniq.join(DELIM)
      end
    end
    
    def value
      ["All", "None", "CollectionSpace Public Browser", "Culture Object", "DPLA", "Omeka"].sample
    end
  end
end

module Groupable
  def headers
    template.keys
  end

  def multijoin(vals, delim = DELIM)
    vals.transpose.map{ |fieldvals| fieldvals.join(delim) }
  end
end

module Subgroupable
  include Groupable
  
  def call(groups: 2, max_subgroups: 3)
    return Array.new(headers.length, '') if groups == 0
    
    subgroups = rand(max_subgroups + 1)
    return Array.new(headers.length, '') if subgroups == 0

    vals = Array.new(groups){ per_group(subgroups) }
    groups == 1 ? vals.flatten : multijoin(vals, DELIM)
  end

  def per_group(subgroups)
    return Array.new(headers.length, '') if subgroups == 0
    
    vals = Array.new(subgroups){ template.values_at(*headers) }
    subgroups == 1 ? vals.flatten : multijoin(vals, SGDELIM)
  end
end

class DimensionSubGroup
  class << self
    include Subgroupable
    
    private

    def template
      {
        'dimension' => %w[area base circumference count depth diameter height length running-time target volume weight width].sample,
        'measuredbypersonlocal' => Person.call,
        'measurementunit' => %w[carats centimeters cubic-centimeters feet inches kilograms liters meters millimeters minutes ounces pixels pounds square-feet stories tons].sample,
        'value' => [
          Faker::Number.number(digits: rand(1..3)),
          Faker::Number.decimal(l_digits: rand(1..3), r_digits: rand(1..3))
        ].sample,
        'valuedate' => Date.call
      }
    end
  end
end

class MeasuredPartGroup
  class << self
    include Groupable
    
    def call(max_groups: 3, max_subgroups: 3)
      groups = rand(max_groups + 1)
      [
        group_data(groups),
        DimensionSubGroup.call(groups: groups, max_subgroups: max_subgroups)
      ].flatten
    end

    def header_row
      [template.keys, DimensionSubGroup.headers].flatten
    end

    private

    def group_data(num)
      return Array.new(headers.length, '') if num == 0
      
      vals = Array.new(num){ template.values_at(*headers) }
      num == 1 ? vals.flatten : multijoin(vals, DELIM)
    end
    
    def template
      {
        'dimensionsummary' => Faker::Lorem.sentence(word_count: 1, random_words_to_add: 7).delete_suffix('.'),
        'measuredpart' => %w[base frame framed image-size mount paper-size plate-size unframed].sample
      }
    end
  end
end

class TitleTranslationSubGroup
  class << self
    include Subgroupable
    
    private

    def template
      {
        'titletranslation' => Faker::Lorem.sentence(word_count: 2, random_words_to_add: 4),
        'titletranslationlanguage' => Language.call
      }
    end
  end
end

class TitleGroup
  class << self
    include Groupable
    
    def call(max_groups: 3, max_subgroups: 3)
      groups = rand(max_groups + 1)
      [
        group_data(groups),
        TitleTranslationSubGroup.call(groups: groups, max_subgroups: max_subgroups)
      ].flatten
    end

    def header_row
      [template.keys, TitleTranslationSubGroup.headers].flatten
    end

    private

    def group_data(num)
      return Array.new(headers.length, '') if num == 0
      
      vals = Array.new(num){ template.values_at(*headers) }
      num == 1 ? vals.flatten : multijoin(vals, DELIM)
    end
    
    def template
      {
        'title' => Faker::Lorem.sentence(word_count: 2, random_words_to_add: 4).delete_suffix('.'),
        'titlelanguage' => Language.call,
        'titletype' => ['assigned-by-artist', 'collection', 'generic', 'popular', 'series', 'trade', ''].sample
      }
    end
  end
end


class FieldGroupList
  class << self
    include Groupable
    
    def call(max_groups: 3)
      num = rand(max_groups + 1)

      return Array.new(headers.length, '') if num == 0
      
      vals = Array.new(num){ template.values_at(*headers) }
      num == 1 ? vals.flatten : multijoin(vals, DELIM)
    end
  end
end

class AnnotationList < FieldGroupList
  class << self
    private

    def template
      {
        'annotationType' => ["additional taxa", "deaccession", "holotype location", "image made", "nomenclature", "number collision", "population biology", "type", "Vegetation Type Map Project", ""].sample,
        'annotationNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
        'annotationDate' => Date.call,
        'annotationAuthor' => Person.call,
      }
    end
  end
end

class AssocOrganization < FieldGroupList
  class << self
    private

    def template
      {
        'assocOrganization' => Organization.call,
        'assocOrganizationType' => Role.call,
        'assocOrganizationNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2)
      }
    end
  end
end

class AssocPerson < FieldGroupList
  class << self
    private

    def template
      {
        'assocPerson' => Person.call,
        'assocPersonType' => Role.call,
        'assocPersonNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2)
      }
    end
  end
end

class AssocDate < FieldGroupList
  class << self
    private

    def template
      {
        'assocstructureddategroup' => Date.call,
        'assocDateType' => Role.call,
        'assocDateNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2)
      }
    end
  end
end

class ObjectProductionPerson < FieldGroupList
  class << self
    private

    def template
      {
        'objectProductionPerson' => Person.call,
        'objectProductionPersonRole' => Role.call
      }
    end
  end
end

class ObjectProductionOrganization < FieldGroupList
  class << self
    private

    def template
      {
        'objectProductionOrganization' => Organization.call,
        'objectProductionOrganizationRole' => Role.call
      }
    end
  end
end

class ObjectName < FieldGroupList
  class << self
    private

    def template
      {
        'objectname' => Faker::Lorem.sentence(word_count: 1, random_words_to_add: 2).delete_suffix('.'),
        'objectnamenote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2)
      }
    end
  end
end

class OtherNumberList < FieldGroupList
  class << self
    private

    def template
      {
        'numbervalue' => Faker::Number.number(digits: 10),
        'numbertype' => %w[lender obsolete previous serial unknown].sample
      }
    end
  end
end

class BaseRow
  def initialize(suffix)
    @suffix = suffix
    @orgs = Array.new(25){ Faker::Company.name }

  end

  def call
    updated = handle_id
    updated.values_at(*headers).flatten
  end

  def headers
    template.keys
  end

  def header_row
    headers.flatten
  end
  
  private

  attr_reader :suffix, :orgs, :persons
  
  def date
  end

  def handle_id
    if id == 'termdisplayname'
      idvals = template[id].split(DELIM)
      mainid = "#{prefix}#{idvals.shift}#{suffix}"
      edited = {id => [mainid, idvals].flatten.join(DELIM)}
    else
      edited = {id => "#{prefix}#{template[id]}#{suffix}"}
    end
    template.merge(edited)
  end  
end

class CSObject < BaseRow
  private
  def id
    'objectnumber'
  end

  def prefix
    "#{Time.now.year}."
  end
end

class ObjectLow < CSObject
  private

  def template
    {
      id => Faker::Number.unique.number(digits: 6),
      'title' => Faker::Book.title
    }
  end  
end

class ObjectHigh < CSObject
  private

#      'title' => Faker::Book.title
  def template
    {
      id => Faker::Number.unique.number(digits: 6),
      'numberOfObjects' => [Faker::Number.number(digits: rand(1..3)), ''].sample,
      OtherNumberList.headers => OtherNumberList.call,
      'responsibleDepartment' => Multi.call(2){ ResponsibleDepartment.call(nullable: false) },
      'collection' => ['library-collection', 'permanent-collection', 'study-collection', 'teaching-collection', ''].sample,
      'namedCollection' => Multi.call(3){ NamedCollectionWork.call(nullable: false) },
      'recordStatus' => ['approved', 'in-process', 'new', 'temporary', ''].sample,
      'publishTo' => PublishTo.call(3),
      'inventoryStatus' => Multi.call(2){InventoryStatus.call(nullable: false)},
      'briefDescription' => Multi.call(3){ Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2) },
      'distinguishingFeatures' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      'comment' => Multi.call(3){ Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2) },
      AnnotationList.headers => AnnotationList.call,
      TitleGroup.header_row => TitleGroup.call,
      ObjectName.headers => ObjectName.call,
      'copyNumber' => [Faker::Number.number(digits: 2), ''].sample,
      'objectStatus' => Multi.call(2){ ['copy', 'forgery', 'holotype', 'paralectotype', 'paratype', 'type', ''].sample },
      'sex' => ['female', 'male', ''].sample,
      'phase' => ['adult', 'imago', 'larva', 'nymph', 'pupa', ''].sample,
      'form' => Multi.call(2){ ['dry', 'pinned', 'thin-section', 'wet', ''].sample },
      'editionNumber' => [Faker::Number.number(digits: 2), ''].sample,
      MeasuredPartGroup.header_row => MeasuredPartGroup.call,
      'style' => Multi.call(3){ [Faker::Adjective.positive, Faker::Adjective.negative, nil].sample },
      'color' => Multi.call(3){ [Faker::Commerce.color, nil].sample },
      'physicalDescription' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      'contentDescription' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      'contentLanguage' => Multi.call(3){ Language.call(nullable: false) },
      'contentActivity' => Multi.call(2){ Faker::Hobby.activity },
      'contentConceptConceptMaterial' => Multi.call(2){ Faker::Commerce.material },
      'contentDateGroup' => Date.call,
      'contentPersonPersonLocal' => Multi.call(2){ Person.call },
      'contentOrganizationOrganizationLocal' => Multi.call(2){ Organization.call },
      'contentNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      'objectProductionDateGroup' => Multi.call(3){ Date.call},
      'objectProductionReason' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      ObjectProductionPerson.headers => ObjectProductionPerson.call,
      ObjectProductionOrganization.headers => ObjectProductionOrganization.call,
      'objectProductionNote' => Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2),
      AssocOrganization.headers => AssocOrganization.call,
      AssocPerson.headers => AssocPerson.call,
      AssocDate.headers => AssocDate.call,
      'objectHistoryNote' => [Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 2), ''].sample,
      'ownerPersonLocal' => Multi.call(2){ Person.call },
      'ownerOrganizationLocal' => Multi.call(2){ Organization.call },
      'ownershipDateGroup' => Multi.call(2){ Date.call },
      'ownershipAccess' => ['limited', 'open', 'restricted', ''].sample,
    }
  end  
end

class Authority < BaseRow
  def id
    'termdisplayname'
  end

  def prefix
    ''
  end
end

class PersonLow < Authority
  private

  def template
    {
      id => Multi.call(3){ Faker::Name.unique.name }
    }
  end  
end

class MediaHigh < BaseRow
  private
  
  def id
    'identificationnumber'
  end

  def prefix
    'MR'
  end
  
  def template
    {
      'identificationnumber' => Faker::Code.unique.isbn,
      'title' => Faker::Book.title,
      'publishto' => PublishTo.call(3),
      'mimetype' => Faker::File.mime_type,
      'mediafileuri' => Faker::Placeholdit.image(format: 'jpg'),
      'contributororganizationlocal' => org,
      'creatorpersonlocal' => Person.call,
      'language' => Multi.call(3){ Language.call },
      'publisherorganizationlocal' => Organization.call,
      'copyrightstatement' => Faker::Lorem.sentence,
      'dategroup' => Date.call,
      'relation' => Multi.call(3){ role },
      'source' => Faker::Commerce.department,
      'rightsholderpersonlocal' => Person.call,
      'alttext' => Faker::Commerce.product_name,
      MeasuredPartGroup.header_row => MeasuredPartGroup.call
    }
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

Person.setup(30)
Organization.setup(25)
NamedCollectionWork.setup(30)

creator = Creator.new(
  type: options[:type],
  complexity: options[:complexity],
  suffix: options[:suffix],
  path: options[:output],
  num: options[:num]
)
creator.call

