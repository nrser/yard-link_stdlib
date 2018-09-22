# frozen_string_literal: true
# encoding: UTF-8

##############################################################################
# 
# Handle creating and loading maps of the Ruby stdlib objects.
# 
##############################################################################


# Requirements
# ========================================================================

# Stdlib
# ----------------------------------------------------------------------------

require 'json'

# Project / Package
# ------------------------------------------------------------------------

# We need {YARD::LinkStdlib::ROOT} to find `//tmp`
require_relative './version'
require_relative './ruby_version'


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================


# Moudle (Static) Methods
# ----------------------------------------------------------------------------


def self.system! *args
  Kernel.system( *args ).tap { |success|
    unless success
      raise SystemCallError.new \
        %{ Code #{ $?.exitstatus } error executing #{ args.inspect } },
        $?.exitstatus
    end
  }
end


# Get the path to the `//tmp` directory, creating it if it don't exist.
# 
# @return [Pathname]
# 
def self.tmp_dir &block
  path = ROOT.
    join( 'tmp' ).
    tap { |path| FileUtils.mkdir_p path unless path.exist? }

  if block
    Dir.chdir path, &block
  else
    path
  end
end


module Repo
  
  # Constants
  # --------------------------------------------------------------------------

  # Repo URL to clone Rub from.
  # 
  # @return [String]
  # 
  DEFAULT_URL = 'https://github.com/ruby/ruby.git'

  def self.url
    @url || DEFAULT_URL
  end


  def self.url= url
    @ruby_repo_url = url
  end


  def self.dir &block
    path = LinkStdlib.tmp_dir.join 'ruby'

    if block
      Dir.chdir path, &block
    else
      path
    end
  end


  def self.clone
    if dir.exist?
      false
    else
      LinkStdlib.tmp_dir do
        LinkStdlib.system! 'git', 'clone', url, dir.basename.to_s
      end

      true
    end
  end


  def self.checkout version
    unless version.is_a?( Gem::Version )
      version = Gem::Version.new( version.to_s )
    end

    clone
    LinkStdlib.system! \
      'git',
      'checkout',
      "v#{ version.segments.join( '_' ) }",
      chdir: dir.to_s
  end

end # module Repo


module Map
  def self.cache key, &load
    @cache ||= {}

    unless @cache.key? key
      @cache[key] = load.call
    end

    @cache[key]
  end


  def self.path version
    LinkStdlib::ROOT.join 'maps', "#{ version }.json.data"
  end


  def self.make version
    path = self.path version

    return false if path.exist?

    Repo.checkout version

    LinkStdlib.system! \
      LinkStdlib::ROOT.join( 'bin', 'make_map.rb' ).to_s,
      path( version ).to_s,
      # I *think* this option is not used for anything but is required 
      '--op', LinkStdlib.tmp_dir.join( 'not_used' ).to_s
    
    true
  end


  def self.load version
    JSON.load path( version ).read
  end


  def self.get version = LinkStdlib.ruby_version, make: true
    cache version do
      make( version ) if make
      load version
    end
  end
end # module Map


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
