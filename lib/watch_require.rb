# Extend Kernel with a new function reload_watched_requires that
# reloads all functions that are require'd after this file is
# loaded.

module Kernel
  # TODO initialize this with the mtimes of all currently loaded
  # modules, so that we can reload them too
  REQUIRE_LOAD_TIMES = []

  alias_method :require_without_watch, :require unless
    Kernel::method_defined?(:require_without_watch)

  def require(*args)
    verbose = false
    previously_loaded = $".clone
    value = require_without_watch(*args)
    ($" - previously_loaded).each do |feature|
      path = feature
      path = $:.
        reject { |dir| dir =~ /^\w+:/ }.
        map { |dir| File.expand_path(File.join(dir, feature)) }.
        select { |p| File.exists?(p) }.
        first unless path =~ /^\//
      puts "Unable to find #{feature}" if verbose and not path
      next unless path
      next if REQUIRE_LOAD_TIMES.any? { |_, path0, _| path == path0 }
      puts "Watching #{feature}" if verbose
      # FIXME race condition if the file was modified between
      # require_without_watch and now
      REQUIRE_LOAD_TIMES << [feature, path, File.mtime(path)]
    end
    return value
  end

  ## Returns true iff any file was reloaded.
  ## Options:
  ##   :all:     reload all watched files if any file was reloaded
  ##   :verbose: print the paths of reloaded files
  def reload_watched_requires(options={})
    all = options[:all]
    verbose = options[:verbose]
    reloads = REQUIRE_LOAD_TIMES.select do |_, path, mtime|
      new_mtime = File.mtime(path)
      new_mtime and mtime != new_mtime
    end
    # if any file changed, load them all
    return unless reloads.any?
    reloads = REQUIRE_LOAD_TIMES if all
    # load them in the same order they were originally loaded
    reloads = reloads.sort_by { |feature, _, _| $".index(feature) }
    reloads.each do |entry|
      feature, path, _ = entry
      new_mtime = File.mtime(path)
      puts "Reloading #{feature}" if verbose
      load path
      entry[2] = new_mtime
    end
    return reloads.any?
  end

  def watched_require_mtime
    (REQUIRE_LOAD_TIMES.map { |_, path, _| File.mtime(path) }.compact).max
  end

  def watched_files
    REQUIRE_LOAD_TIMES.map { |_, path, _| path }
  end
end
