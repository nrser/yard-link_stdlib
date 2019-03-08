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

  # Mixins
  # ========================================================================

  include Comparable


  # Class Methods
  # ============================================================================
  
  
  def self.make_missing?
    unless instance_variable_defined? :@make_missing
      @make_missing = true
    end
    
    @make_missing
  end
  
  
  def self.make_missing= value
    @make_missing = !!value
  end
  
  
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


  def self.list
    LinkStdlib.tmp_dir.entries.
      select { |filename|
        filename.to_s =~ /\Aruby\-\d+\_\d+\_\d+\z/
      }.
      map { |filename|
        new filename.to_s.sub( /\Aruby\-/, '' ).gsub( '_', '.' )
      }.
      sort
  end


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


  def download force: false
    if force
      log.info "FORCING download of Ruby #{ version } tarball..."
    elsif tar_path.exist?
      log.info "Ruby #{ version } tarball present."
      return self
    else
      log.info "Downloading Ruby #{ version } tarball..."
    end

    response = LinkStdlib.http_get url
    tar_path.open( "wb" ) { |file| file.write response.body }

    self # For chaining
  end


  def extract force: false
    if force
      log.info "FORCING extraction of Ruby #{ version } source tarball..."
    elsif src_path.exist?
      log.info "Ruby #{ version } source present."
      return self
    else
      log.info "Extracting #{ tar_path } -> #{ src_path }..."
    end

    LinkStdlib.system! \
      'tar',  '-x',                           # extract
              '-f', tar_path.to_s,            # file
              '-C', LinkStdlib.tmp_dir.to_s   # directory (chdir)
    
    log.info "Source for Ruby #{ version } extracted to #{ src_path }."

    self # For chaining
  end


  def ensure
    if src_path.exist?
      # Nothing to do, source is already in place
      log.info "Source for Ruby #{ version } is present."
      return
    end
    
    unless self.class.make_missing?
      raise RuntimeError,
        "Object map for Ruby version #{ version } missing; " +
        "not configured to auto-make"
    end

    # Download unless the tar's already there
    download

    # And we must need to extract it since the src path wasn't there
    extract

    self # For chaining
  end


  def to_s
    %{#<YARD::LinkStdlib::RubySource "#{ version }">}
  end

  def inspect; to_s; end


  def <=> other
    version <=> other.version
  end

end # class RubySource


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
