# frozen_string_literal: true

require "bundler/setup"
require_relative "../lib/collectionspace_migration_tools"
require "benchmark"
require "debug"

Benchmark.bm do |x|
  x.report("a") { 50.times { CMT::RecordTypes.authorities_a } }
  x.report("b") { 50.times { CMT::RecordTypes.authorities_b } }
  x.report("c") { 50.times { CMT::RecordTypes.authorities_c } }
end

__END__

       user     system      total        real
a  0.557572   0.508855   1.066427 (  1.216051)
b  0.979739   0.636749   1.616488 (  1.710962)
c  0.251844   0.196984   0.448828 (  0.478095)

Going with c because it is much faster than a.
If a procedure with a hyphen in its mapper name ever happens, then c breaks, though.

b was a fair amount faster than a when repeated a small number of times.

    def authorities_a
      mappable.map{ |str| CMT::Entity::Authority.from_str(str) }
        .reject{ |auth| auth.status.failure? }
    end

    def authorities_b
      mappable.map{ |str| CMT::Parse::RecordMapper.new(str).call }
        .reject{ |mapper| mapper.failure? }
        .select{ |mapper| mapper.value!.authority? }
        .map{ |mapper| CMT::Entity::Authority.from_str(mapper.value!.name) }
    end

    def authorities_c
      mappable.select{ |rectype| rectype['-'] }
      .map{ |rectype| CMT::Entity::Authority.from_str(rectype) }
    end

