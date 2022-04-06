require 'bundler/inline'

require 'csv'
require 'optparse'
require 'debug'

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

case options[:type]
when 'object'
  CSV.open(options[:output], 'w') do |csv|
    csv << %w{objectnumber title}
    options[:num].times do
      objnum = "#{random_value(min: 6, max: 10)} #{options[:suffix]}"
      csv << [objnum, random_value(min: 12, max: 50)]
    end
  end
when 'authority'
  CSV.open(options[:output], 'w') do |csv|
    csv << %w{termdisplayname}
    options[:num].times do
      term = "#{random_value(min: 6, max: 10)} #{options[:suffix]}"
      csv << [term]
    end
  end
when 'media'
  uris = [
    'https://boston-media.s3.us-west-2.amazonaws.com/pc070256.jpg',
    'https://boston-media.s3.us-west-2.amazonaws.com/r2011.1.jpg',
    'https://boston-media.s3.us-west-2.amazonaws.com/r2011.10-1.jpg',
    'https://boston-media.s3.us-west-2.amazonaws.com/r2011.10-2.jpg',
    'https://boston-media.s3.us-west-2.amazonaws.com/r2011.10-3.jpg',
    ]
  CSV.open(options[:output], 'w') do |csv|
    csv << %w{identificationnumber title mediafileuri}
    options[:num].times do
      id = "#{random_value(min: 6, max: 10)} #{options[:suffix]}"
      title = "#{random_value(min: 12, max: 50)} #{options[:suffix]}"
      csv << [id, title, uris.sample]
    end
  end
end
