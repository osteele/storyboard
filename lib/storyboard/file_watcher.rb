# Watches files, and reloads them when they've changed
require 'watch_require'

class FileWatcher
  attr_accessor :last_mtimes

  def reload_changes
    mtimes = watched_files.map { |path| File.mtime(path) }.compact
    return if last_mtimes == mtimes
    self.last_mtimes = mtimes
    return reload_watched_requires :all => true, :verbose => true
  end
end
