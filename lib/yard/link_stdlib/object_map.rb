# frozen_string_literal: true
# encoding: UTF-8
# doctest: true


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

  # Mixins
  # ==========================================================================

  include Comparable

  
  # Class Variables
  # ==========================================================================

  @@data_dir = LinkStdlib::ROOT.join( 'maps' ).tap { |path|
    FileUtils.mkdir_p( path ) unless path.exist?
  }

  @@current = nil
  
  
  # A map of module names that we know *actually* point to another one.
  # 
  # This is basically here to support {YAML}, which internally points to 
  # {Psych} in a truly annoying fashion... seems to be a remnant from when 
  # `Syck` was around, but that appears to have been yanked out years ago 
  # around Ruby 2.0, and I can't think of seeing anyone use anything except 
  # {Psych} for about a decade.
  # 
  # However, it means that there is no entry in the object map for things like
  # {YAML.load}, which are pretty commonly used. This functionality allows
  # us to address that, by being aware that {YAML} points to {Psych} for 
  # practical purposes.
  # 
  # @return [Hash<String, String>]
  #
  @@module_aliases = {
    "YAML" => "Psych",
  }
  
  @@name_rewrites = {
    # The instance methods of the {JSON} module are encapsulated in a 
    # {Module#module_function} context, which adds them as module methods as
    # well, but RDoc doesn't seem to pick that up, so we just transform them
    # to make this bullshit work.
    # 
    # Creates mappings like:
    # 
    #     "JSON::load" => "JSON.html#method-i-load"
    #     "JSON::dump" => "JSON.html#method-i-dump"
    # 
    /\AJSON#(.*)\z/ => ->( match ) { "JSON::#{ match[ 1 ] }" },
  }

  
  # Singleton Methods
  # ========================================================================
  
  # Set the directory in which to load and store map data. Must exist.
  # 
  # @param [String | Pathname] path
  #   New data directory. Will be expanded.
  # 
  # @return [Pathname]
  # 
  # @raise [ArgumentError]
  #   If `path` is not a directory.
  # 
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

  
  # The directory in which to load and store object map data.
  # 
  # @example
  #   YARD::LinkStdlib::ObjectMap.data_dir
  #   #=> Pathname.new "#{ LinkStdlib::ROOT }/maps"
  # 
  # @return [Pathname]
  # 
  def self.data_dir
    @@data_dir
  end

  
  # Get the {ObjectMap} for {RubyVersion.get}.
  # 
  # @return [ObjectMap]
  # 
  def self.current
    version = RubyVersion.get

    if @@current.nil? || @@current.version != version
      @@current = new( version ).make
    end

    @@current
  end

  
  # Get all the object maps present.
  # 
  # @return [Array<ObjectMap>]
  # 
  def self.all
    data_dir.entries.
      select  { |filename| filename.to_s =~ /\Aruby\-(\d+\.)+json\.gz\z/ }.
      map     { |filename|
        new File.basename( filename.to_s, '.json.gz' ).sub( /\Aruby\-/, '' )
      }.
      sort
  end # .all
  
  
  # Add a Ruby version (download and build map data, see {#make}).
  # 
  # @param [String | Gem::Version] ruby_version
  #   Version to add.
  # 
  # @param [Boolean] force
  #   Pass `true` to re-build map when already present (see {#make}).
  # 
  # @return [ObjectMap]
  #   Added map.
  # 
  def self.add ruby_version, force: false
    new( ruby_version ).make force: force
  end
  
  
  def self.remove ruby_version, remove_source: true, force: false
    raise "TODO"
  end


  # Ruby version.
  # 
  # @return [Gem::Version]
  #     
  attr_reader :version
  
  
  # Construction
  # ==========================================================================
  
  # Instantiate an {ObjectMap} for a Ruby version.
  # 
  # This just initialized the interface - the source may need to be downloaded
  # and the map generated (see {#make}) to use it for anything.
  # 
  # @param [String | Gem::Version] version
  #   Ruby version.
  # 
  def initialize version
    @version = Gem::Version.new version
  end
  
  
  # Instance Methods
  # ==========================================================================

  
  # The name for this {ObjectMap}'s data file.
  # 
  # @example
  #   YARD::LinkStdlib::ObjectMap.new( '2.3.7' ).filename
  #   #=> "ruby-2.3.7.json.gz"
  # 
  # @return [String]
  # 
  def filename
    @filename ||= "ruby-#{ version }.json.gz"
  end

  
  # Absolute path to this {ObjectMap}'s data file.
  # 
  # @return [Pathname]
  # 
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

  
  # The {RubySource} interface for this {ObjectMap}.
  # 
  # @return [RubySource]
  # 
  def source
    @source ||= RubySource.new version
  end

  
  # Build the map data file (if needed or forced).
  # 
  # @param [Boolean] force
  #   Set to true to re-build even if the map data file is present.
  # 
  # @return [ObjectMap] self
  # 
  def make force: false
    # Bail unless forced or the map is not present
    if force
      log.info "FORCE making object map for Ruby #{ version }..."
    elsif !present?
      log.info "Making object map for Ruby #{ version }..."
    else
      log.info "Object map for Ruby #{ version } is present."
      return self
    end

    # Make sure we have the source files in place
    source.ensure

    # Invoke the build script
    LinkStdlib.system! \
      LinkStdlib::ROOT.join( 'bin', 'make_map.rb' ).to_s,
      source.src_path.to_s,
      path.to_s
    
    log.info "Made object map for Ruby #{ version }."

    self
  end


  def data reload: false
    if reload || @data.nil?
      @name_rewrites = nil
      @data = Zlib::GzipReader.open path do |gz|
        JSON.load gz.read
      end
    end

    @data
  end
  
  
  # Names of the objects in {#data} (equivalent to `self.data.keys`).
  # 
  # @param [Boolean] reload
  #   When `true`, reload the {#data} from disk first.
  # 
  # @return [Array<String>]
  # 
  def names reload: false
    data( reload: reload ).keys
  end
  
  
  def name_rewrites reload: false
    data( reload: true ) if reload
    
    @name_rewrites ||= \
      data.each_with_object( {} ) do |(name, rel_path), name_rewrites|
        @@name_rewrites.each do |regexp, transformer|
          if (match = regexp.match( name ))
            name_rewrites[ transformer.call match ] = rel_path
          end
        end
      end
  end
  
  
  # Get the relative path for the URL of an online stdlib document given the
  # code object's name.
  #
  # @example
  #   YARD::LinkStdlib::ObjectMap.current.resolve 'String'
  #   #=> [ 'String', 'String.html' ]
  # 
  # @example De-Aliasing
  #   YARD::LinkStdlib::ObjectMap.current.resolve 'YAML.load'
  #   #=> [ 'Psych::load', 'Psych.html#method-c-load' ]
  # 
  # @param [String] name
  # 
  # @return [nil]
  #   The (normalized) `name` was not found in the {ObjectMap}.
  # 
  # @return [Array[(String, String?)>]
  #   The normalized name (which may be totally different than the `name`
  #   argument due to de-aliasing) followed by the relative URL path to it's
  #   doc.
  # 
  def resolve name
    name = LinkStdlib.normalize_name name
    rel_path = data[ name ]
    
    if rel_path.nil?
      split = name.split '::'
      
      if (de_aliased_module_name = @@module_aliases[ split.first ])
        de_aliased_name = \
          [ de_aliased_module_name, *split[ 1..-1 ] ].join( '::' )
        
        if (de_aliased_module_name = data[ de_aliased_name ])
          return [ de_aliased_name, de_aliased_module_name ]
        end
      end
      
      if (rewritten_rel_path = name_rewrites[ name ])
        log.debug "Found re-written relative path: " +
                  "#{ name } -> #{ rewritten_rel_path.inspect }"
        
        return [ name, rewritten_rel_path ]
      end # if rewritten_rel_path
    end # if rel_path.nil?
    
    # NOTE `rel_path` may be `nil`, indicating we didn't find shit
    [ name, rel_path ]
  end # .resolve
  
  
  # Get the doc URL for a name.
  # 
  # @example Using defaults
  #   YARD::LinkStdlib::ObjectMap.current.url_for 'String'
  #   #=> 'https://docs.ruby-lang.org/en/2.3.0/String.html'
  # 
  # @example Manually override components
  #   YARD::LinkStdlib::ObjectMap.current.url_for 'String',
  #     https: false,
  #     domain: 'example.com',
  #     lang: 'ja'
  #   #=> 'http://example.com/ja/2.3.0/String.html'
  # 
  # @param [String] name
  #   Name of the code  object.
  # 
  # @param [Hash<Symbol, Object>] url_options
  #   Passed to {LinkStdlib.build_url}.
  # 
  # @return [nil]
  #   The (normalized) `name` was not found in the {ObjectMap}.
  # 
  # @return [String]
  #   The fully-formed URL to the online doc.
  # 
  def url_for name, **url_options
    name, rel_path = resolve name
    
    if rel_path
      LinkStdlib.build_url \
        rel_path,
        **url_options,
        version: RubyVersion.minor( version )
    end
  end # .url_for
  
  
  # Language Integration Instance Methods
  # --------------------------------------------------------------------------

  # Compare {ObjectMap} instances by their {#version} (used to sort them).
  # 
  # @return [Fixnum]
  #   `0` is equal, negatives and positives denote order.
  # 
  def <=> other
    version <=> other.version
  end


end # class ObjectMap


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
