# frozen_string_literal: true
# encoding: UTF-8


# Requirements
# ========================================================================

# Stdlib
# ----------------------------------------------------------------------------

# Encode object maps in JSON... it's just super easy for everything, and
# gzip should take care of any size concerns.
require 'json'

# Good ol' mkdir_p...
require 'fileutils'

# Store the JSON-encoded maps compressed
require 'zlib'


# Project / Package
# ------------------------------------------------------------------------

# We need {YARD::LinkStdlib::ROOT} to find `//tmp`
require_relative './version'

# Need to be able to {RubySource.ensure} we have source code we need
require_relative './ruby_source'


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================


class ObjectMap

  @@data_dir = LinkStdlib::ROOT.join( 'maps' ).tap { |path|
    FileUtils.mkdir_p( path ) unless path.exist?
  }

  @@current = nil

  
  # Class Methods
  # ========================================================================

  def self.data_dir= path
    expanded = Pathname.new( path ).expand_path

    unless expanded.directory?
      raise ArgumentError,
        "Custom ObjectMap.data_dir must expand to an existing directory," +
        "try creating it first? Received #{ path.inspect }, expanded to " +
        expanded.to_s.inspect
    end

    @@data_dir = expanded
  end


  def self.data_dir
    @@data_dir
  end


  def self.current
    version = RubyVersion.get

    if @@current.nil? || @@current.version != version
      @@current = new( version ).make
    end

    @@current
  end


  # def self.cache key, &load
  #   @cache ||= {}

  #   unless @cache.key? key
  #     @cache[key] = load.call
  #   end

  #   @cache[key]
  # end


  # def self.get version = LinkStdlib::RubyVersion.get, make: true
  #   cache version do
  #     make( version ) if make
  #     load version
  #   end
  # end


  # Ruby version.
  # 
  # @return [Gem::Version]
  #     
  attr_reader :version


  def initialize version
    @version = Gem::Version.new version
  end


  def filename
    @filename ||= "#{ version }.json.gz"
  end


  def path
    @path ||= self.class.data_dir.join filename
  end


  # Is the object map present for this {#version}?
  # 
  # @return [Boolean]
  # 
  def present?
    path.exist?
  end


  def source
    @source ||= RubySource.new version
  end


  def make force: false
    # Bail unless forced or the map is not present
    return self unless force || !present?

    # Make sure we have the source files in place
    source.ensure

    # Invoke the build script
    LinkStdlib.system! \
      LinkStdlib::ROOT.join( 'bin', 'make_map.rb' ).to_s,
      source.src_path.to_s,
      path.to_s
    
    self
  end


  def data reload: false
    if reload || @data.nil?
      @data = Zlib::GzipReader.open path do |gz|
        JSON.load gz.read
      end
    end

    @data
  end


end # class ObjectMap


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
