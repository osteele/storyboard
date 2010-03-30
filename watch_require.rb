# Extend Kernel with a new function reload_watched_requires that
# reloads all functions that are require'd after this file is
# loaded.

module Kernel
  # TODO initialize this with the mtimes of all currently loaded
  # modules, so that we can reload them too
  REQUIRE_LOAD_TIMES = {}

  alias_method :require_without_watch, :require unless
    Kernel::method_defined?(:require_without_watch)

  def require(*args)
    previously_loaded = $".clone
    value = require_without_watch(*args)
    ($" - previously_loaded).each do |path|
      path = $:.first { |dir| File.exists?(File.join(dir, 'singleton.rb')) } unless path =~ /^\//
      puts "Watching #{path}" if false
      # FIXME race condition if the file was modified between
      # require_without_watch and now
      REQUIRE_LOAD_TIMES[path] = File.mtime(path)
    end
    return value
  end

  def reload_watched_requires()
    REQUIRE_LOAD_TIMES.each do |path, mtime|
      new_mtime = File.mtime(path)
      return unless new_mtime
      return if mtime == new_mtime
      puts "reload #{path} (#{new_mtime} <-> #{mtime})" if false
      load path
      REQUIRE_LOAD_TIMES[path] = new_mtime
    end
  end
end
