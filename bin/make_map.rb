#!/usr/bin/env ruby

##############################################################################
# Make a {YARD::LinkStdlib::ObjectMap} Data File
# ============================================================================
#
# Running this script is what creates the `//maps/ruby-M.m.p.json.gz` data files
# index object names to their relative URL path in the generated documentation,
# which is in turn how the plugin generates document URLs.
#
# Coming back now (2019.03.09) I don't remember a ton of how ro why things got
# this way (comment your code, kids!). From the commit history, I can see that
# this script came over from initial work somewhere in `nrser/nrser.rb`.
#
# I think I remember this needing to run in a separate child process (versus
# just in the main `yard` one), but I don't recall why.
#
# It might have just been to try to emulate `rdoc` as much as possible, and
# might no longer be needed given present knowledge and understanding, but I
# think I'm just going to leave it for now, because it does work, and to fuck
# with it I would probably want some sort of testing set up to check I'm not
# breaking things, and that's a whole 'nother thing...
#
##############################################################################

require 'pathname'
require 'fileutils'
require 'zlib'

require 'rdoc/rdoc'

GEM_ROOT = Pathname.new( __dir__ ).join( '..' ).expand_path

class RDoc::RDoc
  
  # Pretty much a copy of `RDoc::RDoc#document`, just with the `#generate` step
  # commented-out.
  def almost_document options = ARGV
    self.store = RDoc::Store.new

    if RDoc::Options === options then
      @options = options
      @options.finish
    else
      @options = load_options
      @options.parse options
    end
    
    # We want **all** of the names available, so force the highest visibility
    # level.
    @options.visibility = :nodoc

    if @options.pipe then
      handle_pipe
      exit
    end

    unless @options.coverage_report then
      @last_modified = setup_output_dir @options.op_dir, @options.force_update
    end

    @store.encoding = @options.encoding
    @store.dry_run  = @options.dry_run
    @store.main     = @options.main_page
    @store.title    = @options.title
    @store.path     = @options.op_dir

    @start_time = Time.now

    @store.load_cache

    file_info = parse_files @options.files

    @options.default_title = "RDoc Documentation"

    @store.complete @options.visibility

    @stats.coverage_level = @options.coverage_report

    gen_klass = @options.generator

    @generator = gen_klass.new @store, @options
    
    # What we *don't* do:
    # generate
    
    nil
  end # #almost_document
  
end # class RDoc::RDoc


def main args
  src = Pathname.new( args.shift ).expand_path
  dest = Pathname.new( args.shift ).expand_path
  
  puts "src: #{ src }"
  puts "dest: #{ dest }"

  # RDoc needs this output dir arg in `ARGV` or it will bail out with an error
  # due to `//doc` existing, even though we don't ever actually write to any of
  # it.
  unless args.include? '--op'
    args << '--op'
    args << '/tmp/not_actually_used'
  end

  Dir.chdir src

  rd = RDoc::RDoc.new

  rd.almost_document args

  map = {}

  rd.store.all_classes_and_modules.each do |mod|
    # if mod.full_name == 'Gem::Specification'
    #   require 'pry'
    #   Pry.config.should_load_rc = false
    #   binding.pry
    # end
    
    [
      mod,
      mod.constants,
      mod.class_attributes,
      mod.class_method_list,
      mod.instance_attributes,
      mod.instance_method_list,
    ].flatten.each { |entry|
      map[ entry.full_name ] = entry.path
    }
    
  end

  FileUtils.mkdir_p( dest.dirname ) unless dest.dirname.exist?

  Zlib::GzipWriter.open dest do |gz|
    gz.write JSON.pretty_generate( map )
  end
end

# Kickoff!
main( ARGV ) if __FILE__ == $0
