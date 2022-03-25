# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/collectionspace_migration_tools'
require 'benchmark'
require 'debug'

processor = CMT::Csv::BatchProcessorPreparer.new(csv_path: '/Users/kristina/data/CSWS/cs/collectionobject.csv', rectype: 'collectionobject', action: 'create').call.value!

Benchmark.bm do |x|
  x.report('processes'){ 15.times{ processor.process_processes } }
  x.report('threads'){ 15.times{ processor.process_threads } }
end

__END__

       user     system      total        real
processesParallel method: in_processes
       1.016772   0.598342  23.558290 ( 17.482548)
threadsParallel method: in_threads
       15.211764   2.084226  17.295990 ( 32.356538)
