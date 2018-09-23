# frozen_string_literal: true
# encoding: UTF-8


# Requirements
# ========================================================================

# Stdlib
# ----------------------------------------------------------------------------

require 'net/http'
require 'uri'


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================

# Light utility object around a Ruby {Gem::Version} used to download and 
# extract it's source code to the {LinkStdlib.tmp_dir}.
# 
class RubySource

  # Class Methods
  # ============================================================================

  # Ensure the version's source is downloaded and extracted.
  # 
  # @example
  #   YARD::LinkStdlib::RubySource.ensure '2.5.1'
  # 
  # @param [Gem::Version || #to_s] version
  #   The Ruby version you need present.
  # 
  # @return [RubySource]
  #   The utility object instance.
  # 
  def self.ensure version
    new( version ).ensure
  end # .ensure


  # Ruby version.
  # 
  # @return [Gem::Version]
  #     
  attr_reader :version

  
  # Construction
  # ========================================================================

  # Make a new instance for a version.
  # 
  # @param [Gem::Version || #to_s] version
  #   The Ruby version to work with.
  # 
  def initialize version
    @version = Gem::Version.new version
  end

  
  # Instance Methods
  # ========================================================================

  def ruby_style_version
    @ruby_style_version ||= version.to_s.gsub '.', '_'
  end


  def url
    @url ||=
      "https://github.com/ruby/ruby/archive/v#{ ruby_style_version }.tar.gz"
  end


  def tar_filename
    @tar_filename ||= "ruby-#{ ruby_style_version }.tar.gz"
  end


  def tar_path
    @tar_path ||= LinkStdlib.tmp_dir.join tar_filename
  end


  def src_path
    @src_path ||= LinkStdlib.tmp_dir.join "ruby-#{ ruby_style_version }"
  end


  def download
    response = LinkStdlib.http_get url
    tar_path.open( "wb" ) { |file| file.write response.body }

    self # For chaining
  end


  def extract
    LinkStdlib.system! \
      'tar',  '-x',                           # extract
              '-f', tar_path.to_s,            # file
              '-C', LinkStdlib.tmp_dir.to_s   # directory (chdir)
    
    self # For chaining
  end


  def ensure
    return if src_path.exist? # Nothing to do, source is already in place

    # Download unless the tar's already there
    download unless tar_path.exist?

    # And we must need to extract it since the src path wasn't there
    extract

    self # For chaining
  end

end # class RubySource


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
