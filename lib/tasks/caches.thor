# frozen_string_literal: true

require "thor"

# tasks targeting both Refcaches
class Caches < Thor
  include CMT::CliHelpers

  desc "clear", "remove all keys from both caches"
  def clear
    report_result(CMT::Caches::Clearer.call)
  end

  desc "size", "print size of both caches"
  def size
    CMT::Caches.types.each do |type|
      puts "#{type.upcase}: #{CMT::Caches.get_cache(type).size}"
    end
    exit(0)
  end
end
