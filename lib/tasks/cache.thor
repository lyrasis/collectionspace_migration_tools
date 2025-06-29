# frozen_string_literal: true

require "thor"

# tasks targeting one RefCache at a time
class Cache < Thor
  desc "clear CACHETYPE", "remove all keys from given cache (csid, refname)"
  def clear(cachetype)
    check_cachetype(cachetype)
    cache = get_cache(cachetype)
    puts "Keys before clearing: #{cache.size}"
    cache.flush
    puts "Keys after clearing: #{cache.size}"
    exit(0)
  end

  desc "size CACHETYPE", "print size of given cache (csid, refname)"
  def size(cachetype)
    check_cachetype(cachetype)
    puts get_cache(cachetype).size
    exit(0)
  end

  # @todo refactor these to Cache module methods
  no_commands do
    def get_cache(type)
      cache_method = :"#{type}_cache"
      CMT.method(cache_method).call
    end

    def check_cachetype(cachetype)
      return if %w[csid refname].any?(cachetype)

      puts "cachetype must be csid or refname"
      exit(1)
    end
  end
end
