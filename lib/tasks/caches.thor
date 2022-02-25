# frozen_string_literal: true

require 'thor'

# tasks targeting both RefCaches
class Caches < Thor
  desc 'clear', 'remove all keys from both caches'
  def clear
    types.each do |type|
      cache = get_cache(type)
      puts "#{type.upcase}: Keys before clearing: #{cache.size}"
      cache.flush
      puts "#{type.upcase}: Keys after clearing: #{cache.size}"
    end
  end

  desc 'size', 'print size of both caches'
  def size
    types.each do |type|
      puts "#{type.upcase}: #{get_cache(type).size}"
    end
  end

  private

  def get_cache(type)
    cache_method = "#{type}_cache".to_sym
    CMT.send(cache_method)
  end
  
  def types
    %w[csid refname]
  end
end

