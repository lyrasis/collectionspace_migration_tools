# frozen_string_literal: true

require "bundler/setup"
require_relative "../lib/collectionspace_migration_tools"
require "benchmark"
require "debug"
require "fileutils"

SERVICE_PATH = CMT.client.service(type: "personauthorities",
  subtype: "person")[:path]
REL_SVC_PATH = CMT.client.service(type: "relations", subtype: nil)[:path]
NUM_RECS_IN_TEST = 200

TermData = Struct.new(:csid, :refname, :uri, :term)
RelData = Struct.new(:sbj, :obj)
RelBundle = Struct.new(:xml, :reldata, :post_result, :rel_uri)

def csid_xml(subject:, object:)
  <<~XML
    <?xml version="1.0" encoding="utf-8" standalone="yes"?>
    <document name="relations">
        <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation">
        <subjectCsid>#{subject}</subjectCsid>
            <relationshipType>hasBroader</relationshipType>
            <objectCsid>#{object}</objectCsid>
        </ns2:relations_common>
    </document>
  XML
end

def person_xml(term)
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <document name="persons">    
        <ns2:persons_common xmlns:ns2="http://collectionspace.org/services/person"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">        
            <personTermGroupList>
                <personTermGroup>
                <termDisplayName>#{term}</termDisplayName>
                </personTermGroup>
            </personTermGroupList>        
        </ns2:persons_common>    
    </document>
  XML
end

def refname_xml(subject:, object:)
  <<~XML
    <?xml version="1.0" encoding="utf-8" standalone="yes"?>
    <document name="relations">
        <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation">
        <subjectRefName>#{subject}</subjectRefName>
            <relationshipType>hasBroader</relationshipType>
            <objectRefName>#{object}</objectRefName>
        </ns2:relations_common>
    </document>
  XML
end

def random_term(size = 6)
  charset = %w[ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    a b c d e f g h i j k l m n o p q r s t u v w x y z]
  charset << "."
  charset << " "
  term = (0...size).map { charset.to_a[rand(charset.size)] }.join
  "#{term} BENCHMARK TEST"
end

def term_list
  Array.new(NUM_RECS_IN_TEST).map { |i| random_term(20) }
end

# @param terms [Array]
# @param path [String]
def write(terms, path)
  File.open(path, "w") do |file|
    terms.each { |term| file << "#{term}\n" }
  end
end

def do_post(payload, service_path)
  CMT.client.post(service_path, payload)
rescue => err
  err.message
end

def do_find(term)
  CMT.client.find(type: "personauthorities", subtype: "person", value: term)
rescue => err
  err.message
end

def do_delete(uri)
  CMT.client.delete(uri)
rescue => err
  err.message
end

def get_term_data(term)
  result = do_find(term)
  return result if result.is_a?(String)
  return "Failed to find term" unless result.result.success?

  item = result.parsed["abstract_common_list"]["list_item"]
  TermData.new(item["csid"], item["refName"], item["uri"], term)
end

def put_rel(rel_bundle)
  result = do_post(rel_bundle.xml, REL_SVC_PATH)
  rel_bundle.post_result = result
  rel_bundle
end

def put_term(payload, term)
  result = do_post(payload, SERVICE_PATH)
  return result if result.is_a?(String)
  return "Failed to create term" unless result.result.success?

  get_term_data(term)
end

def write_put_names(term_data, type)
  File.open(file_path(:put, :person, type), "w") do |outfile|
    term_data.each do |term_struct|
      term_struct.to_h.each { |key, val| outfile.write "#{key}|#{val}\n" }
      outfile.write("\n")
    end
  end
end

def file_path(action, rectype, reltype)
  "tmp/#{action}_#{rectype}_#{reltype}.txt"
end

def set_up(reltype)
  terms = term_list
  write(terms, file_path(:created, :person, reltype))

  puts "#{reltype}: Creating and loading #{NUM_RECS_IN_TEST} terms starting with #{terms.first}..."
  results = terms.map { |term| put_term(person_xml(term), term) }
  results_by_class = results.group_by(&:class)
  unless results_by_class[TermData].empty?
    write_put_names(results_by_class[TermData],
      reltype)
  end

  abort_setup(results_by_class, reltype) if results.any?(String)

  results
end

def abort_setup(term_data_by_class, reltype)
  puts "#{reltype}: Cannot continue because person records for the following could not be created:"
  puts term_data_by_class[String].map { |str| "  #{str}" }
  puts "#{reltype}: Starting teardown..."
  tear_down(term_data_by_class[TermData])
  exit
end

def delete_term(term_data)
  result = do_delete(term_data.uri)
  return result if result.is_a?(String)
  return "Failed to delete term" unless result.result.success?

  term_data
end

def tear_down_terms(term_data, type)
  puts "#{type}: Tearing down terms..."
  term_data.each do |term_struct|
    res = delete_term(term_struct)
    if res.is_a?(String)
      puts %(#{type}: Cannot delete "#{term_struct.term}" because #{res})
      next
    end

    #    puts %{ #{type}: Deleted #{term_struct.term} }
  end

  FileUtils.rm(file_path(:created, :person, type))
  FileUtils.rm(file_path(:put, :person, type))
end

def rel_xml(reldata, mthd)
  sbj = reldata.sbj.send(mthd)
  obj = reldata.obj.send(mthd)
  if mthd == :refname
    refname_xml(subject: sbj, object: obj)
  else
    csid_xml(subject: sbj, object: obj)
  end
end

def make_rel_xml(term_data, mthd)
  puts "#{mthd}: Creating #{NUM_RECS_IN_TEST / 2} relations XML payloads..."
  rels = []
  until term_data.empty?
    reldata = RelData.new(term_data.shift, term_data.shift)
    xml = rel_xml(reldata, mthd)
    rels << RelBundle.new(xml, reldata)
  end

  File.open(file_path(:created, :rel, mthd), "w") do |outfile|
    rels.each do |rel|
      outfile.write("#{rel.reldata.sbj.term} > #{rel.reldata.obj.term}\n")
      outfile.write("#{rel.reldata.sbj.uri} > #{rel.reldata.obj.uri}\n")
      outfile.write("#{rel.reldata.sbj.csid} > #{rel.reldata.obj.csid}\n")
    end
  end

  rels
end

def rel_uri(relbundle)
  result = CMT.client.find_relation(subject_csid: relbundle.reldata.sbj.csid,
    object_csid: relbundle.reldata.obj.csid)
  return result if result.is_a?(String)
  return "Failed to find relation" unless result.result.success?

  result.parsed["relations_common_list"]["relation_list_item"]["uri"]
end

def do_delete_rel(rel)
  uri = rel_uri(rel)
  return "Could not find relation" unless uri.start_with?("/relations/")

  result = do_delete(uri)
  return result if result.is_a?(String)
  return "Failed to delete term" unless result.result.success?

  rel
end

def delete_rel(rel, type)
  rel_str = "#{rel.reldata.sbj.term} > #{rel.reldata.obj.term}"
  result = do_delete_rel(rel)
  return "#{rel_str}: #{result}" if result.is_a?(String)

  #  puts "#{type}: Deleted #{rel_str}"
  rel
end

def tear_down_rels(data, type)
  puts "#{type}: Tearing down relations..."
  did_not_post = data.select do |relbundle|
    relbundle.post_result.is_a?(String) || !relbundle.post_result.result.success?
  end
  puts "#{type}: WARNING: SOME RELS DID NOT POST" unless did_not_post.empty?

  deletes = data.map { |rel| delete_rel(rel, type) }
  delete_failures = deletes.select { |result| result.is_a?(String) }

  if delete_failures.empty?
    FileUtils.rm(file_path(:created, :rel, type))
  else
    puts "Relation delete failures:"
    delete_failures.each { |f| puts "  #{f}" }
  end
end

# [
# ].each do |rel_csid|
#   do_delete("/relations/#{rel_csid}")
# end

# [
# ].each{ |term|
#   puts "deleting #{term}"
#   delete_term(get_term_data(term))
# }

# Refname first, CSID second
ref_first_term_data = set_up(:refname)
ref_first_rel_xml = make_rel_xml(ref_first_term_data.dup, :refname)

csid_second_term_data = set_up(:csid)
csid_second_rel_xml = make_rel_xml(csid_second_term_data.dup, :csid)

puts "Transferring (and benchmarking) transfer of #{NUM_RECS_IN_TEST / 2} relations and receipt of response\n\n"
Benchmark.bm do |x|
  puts "Running refname first, csid second, #{NUM_RECS_IN_TEST / 2} records each"
  x.report("refname rel creation") do
    ref_first_rel_xml.map do |rel|
      put_rel(rel)
    end
  end
  x.report("csid rel creation") do
    csid_second_rel_xml.map do |rel|
      put_rel(rel)
    end
  end
end
puts "\n\n"

tear_down_rels(ref_first_rel_xml, :refname)
tear_down_terms(ref_first_term_data, :refname)

tear_down_rels(csid_second_rel_xml, :csid)
tear_down_terms(csid_second_term_data, :csid)

# CSID first, Refname second
puts "\nStarting run with CSID first, Refname second\n"
csid_first_term_data = set_up(:csid)
csid_first_rel_xml = make_rel_xml(csid_first_term_data.dup, :csid)

ref_second_term_data = set_up(:refname)
ref_second_rel_xml = make_rel_xml(ref_second_term_data.dup, :refname)

puts "Transferring (and benchmarking) transfer of #{NUM_RECS_IN_TEST / 2} relations and receipt of response\n\n"
Benchmark.bm do |x|
  puts "Running csid first, refname second, #{NUM_RECS_IN_TEST / 2} records each"
  x.report("csid rel creation") do
    csid_first_rel_xml.map do |rel|
      put_rel(rel)
    end
  end
  x.report("refname rel creation") do
    ref_second_rel_xml.map do |rel|
      put_rel(rel)
    end
  end
end
puts "\n\n"

tear_down_rels(csid_first_rel_xml, :csid)
tear_down_terms(csid_first_term_data, :csid)

tear_down_rels(ref_second_rel_xml, :refname)
tear_down_terms(ref_second_term_data, :refname)

__END__

refname: Creating and loading 100 terms starting with wNjGVgjrvMFwcpuvajwe BENCHMARK TEST...
refname: Creating 50 relations XML payloads...
csid: Creating and 100 loading terms starting with mmCEZYpcTeLo.qzdMfzA BENCHMARK TEST...
csid: Creating 50 relations XML payloads...
Transferring (and benchmarking) transfer of 50 relations and receipt of response

       user     system      total        real
Running refname first, csid second, 50 records each
refname rel creation  0.187575   0.037203   0.224778 ( 26.915908)
csid rel creation  0.185499   0.035924   0.221423 ( 26.739460)


refname: Tearing down relations...
refname: Tearing down terms...
csid: Tearing down relations...
csid: Tearing down terms...

Starting run with CSID first, Refname second
csid: Creating and 100 loading terms starting with egLGTukyqqnXAMT ygdJ BENCHMARK TEST...
csid: Creating 50 relations XML payloads...
refname: Creating and loading 100 terms starting with XxVSOWL waPjsqWpXyQw BENCHMARK TEST...
refname: Creating 50 relations XML payloads...
Transferring (and benchmarking) transfer of 50 relations and receipt of response

       user     system      total        real
Running csid first, refname second, 50 records each
csid rel creation  0.185836   0.036172   0.222008 ( 26.514017)
refname rel creation  0.183944   0.036299   0.220243 ( 26.486293)


csid: Tearing down relations...
csid: Tearing down terms...
refname: Tearing down relations...
refname: Tearing down terms...

--------------------------------------------------------------------------------

refname: Creating and loading 200 terms starting with BtSMJGktSrDUdEjDWbAM BENCHMARK TEST...
refname: Creating 100 relations XML payloads...
csid: Creating and loading 200 terms starting with sTqlqTBbVAOEJpxkvWkQ BENCHMARK TEST...
csid: Creating 100 relations XML payloads...
Transferring (and benchmarking) transfer of 100 relations and receipt of response

       user     system      total        real
Running refname first, csid second, 100 records each
refname rel creation  0.352469   0.068445   0.420914 ( 53.357641)
csid rel creation  0.357175   0.067506   0.424681 ( 52.778184)


refname: Tearing down relations...
refname: Tearing down terms...
csid: Tearing down relations...
csid: Tearing down terms...

Starting run with CSID first, Refname second
csid: Creating and loading 200 terms starting with HcuUAUPaKoJNWGDeoPlk BENCHMARK TEST...
csid: Creating 100 relations XML payloads...
refname: Creating and loading 200 terms starting with ANrJEgXZvqlfPQAUGugn BENCHMARK TEST...
refname: Creating 100 relations XML payloads...
Transferring (and benchmarking) transfer of 100 relations and receipt of response

       user     system      total        real
Running csid first, refname second, 100 records each
csid rel creation  0.347619   0.067349   0.414968 ( 54.111061)
refname rel creation  0.342433   0.063451   0.405884 ( 53.965949)


csid: Tearing down relations...
csid: Tearing down terms...
refname: Tearing down relations...
refname: Tearing down terms...
