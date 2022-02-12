# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/collectionspace_migration_tools'
require 'debug'
require 'fileutils'

TERMS_CREATED_FILE = 'tmp/created_persons.txt'
SERVICE_PATH = CMT.client.service(type: 'personauthorities', subtype: 'person')[:path]
REL_SVC_PATH = CMT.client.service(type: 'relations', subtype: nil)[:path]

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
  charset = %w{ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
               a b c d e f g h i j k l m n o p q r s t u v w x y z}
  charset << '.'
  charset << ' '
  term = (0...size).map{ charset.to_a[rand(charset.size)] }.join
  "#{term} BENCHMARK TEST"
end

def term_list
  Array.new(100).map{ |i| random_term(20) }
end

# @param terms [Array]
# @param path [String] 
def write(terms, path)
  File.open(path, 'w') do |file|
    terms.each{ |term| file << "#{term}\n" }
  end
end

def do_post(payload)
  CMT.client.post(SERVICE_PATH, payload)
rescue StandardError => err
  err.message
end

def do_find(term)
  CMT.client.find(type: 'personauthorities', subtype: 'person', value: term)
rescue StandardError => err
  err.message
end

def do_delete(term_uri)
  CMT.client.delete(term_uri)
rescue StandardError => err
  err.message
end

def get_term_data(term)
  result = do_find(term)
  return result if result.is_a?(String)
  return "Failed to find term" unless result.result.success?

  item = result.parsed['abstract_common_list']['list_item']
  Struct.new(:csid, :refname, :uri).new(item['csid'], item['refName'], item['uri'])
end

def put_term(payload, term)
  result = do_post(payload)
  return result if result.is_a?(String)
  return "Failed to create term" unless result.result.success?

  get_term_data(term)
end

def set_up
  terms = term_list
  write(terms, TERMS_CREATED_FILE)
  terms.each do |term|
    result = put_term(person_xml(term), term)
  end
  
  xml = terms.map{ |term| person_xml(term) }
  results = xml.map{ |payload| put_term(payload) }

  abort_setup(results) if results.any?(String)

  results
end

def abort_setup(term_data)
  cat = term_data.group_by(&:class)
  puts 'Cannot continue because person records for the following could not be created:'
  puts cat[String].map{ |str| "  #{str}" }
  puts 'Starting teardown...'
  tear_down(cat[Struct])
  exit
end

def delete_term(term_data)
  result = do_delete(term_data.uri)
  return result if result.is_a?(String)
  return "Failed to delete term" unless result.result.success?

  term_data
end

def tear_down(term_data)
  res = delete_term(term_data)
  if res.is_a?(String)
    puts %{Cannot delete "#{term}" because #{res}}
    next
  end

  puts %{ Deleted #{term} }

  FileUtils.rm(TERMS_CREATED_FILE)
end

def make_rel_xml(term_data, mthd)
  rels = []
  until(term_data.length < 2) do
    sbj = term_data.shift.send(mthd)
    obj = term_data.shift.send(mthd)
    if mthd == :refname
      rels << refname_xml(subject: sbj, object:obj)
    else
      rels << csid_xml(subject: sbj, object:obj)
    end
  end
  rels
end

refname_term_data = set_up
rel_xml = make_rel_xml(refname_term_data, :refname)
tear_down(refname_term_data)
