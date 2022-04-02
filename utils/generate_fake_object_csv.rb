require 'bundler/inline'

require 'csv'
require 'optparse'
require 'debug'

options = {}
OptionParser.new{ |opts|
  opts.banner = 'Usage: ruby profile_xml.rb -i ~/projects/mods -d "|"'

  opts.on('-o', '--output OUTPUTPATH', 'Path to output CSV'){ |o|
    options[:output] = File.expand_path(o)
  }
  opts.on('-n', '--num INTEGER', 'number of record rows to generate'){ |n|
    options[:num] = n.to_i
  }
  opts.on('-h', '--help', 'Prints this help'){
    puts opts
    exit
  }
}.parse!

def random_value(min: 6, max: 6)
  size = rand(min...max+1)
  chars = %q{ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
               a b c d e f g h i j k l m n o p q r s t u v w x y z
               0 1 2 3 4 5 6 7 8 9 . - : /}
    .gsub(/\n +/, ' ')
    .split(' ')
  spaces = '. . . . . . . . . . . . . . . '
    .split('.')
  charset = [chars, spaces].flatten

  (0...size).map{ charset.to_a[rand(charset.size)] }.join
end

# options[:num].times do
#   puts random_value(min: 15, max: 50)
# end

CSV.open(options[:output], 'w') do |csv|
  csv << %w{objectnumber title}
  options[:num].times do
    csv << [random_value(min: 6, max: 10), random_value(min: 12, max: 50)]
  end
end
