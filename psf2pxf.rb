#! /usr/bin/ruby

# Convert the glyph data in a (basic v1 format) PSF file as PXF and extract its
# (simple) Unicode mappings as CS.

require 'getoptlong'
require 'zlib'

begin
  $0 = 'psf2pxf.rb' # for error reporting
  $charset_output_filename = nil
  $extra_header = []
  $charset_extraction_suppressed = false
  GetoptLong::new(
    ['--header', '-h', GetoptLong::REQUIRED_ARGUMENT],
    ['--output-charset', GetoptLong::REQUIRED_ARGUMENT],
  ).each do |opt, arg|
    case opt
      when '--output-charset' then
        $charset_output_filename = arg
      when '--header' then
        $extra_header.push arg
        $charset_extraction_suppressed |= arg =~ /\^\s*charset\s+/
      else raise "Unknown option #{opt}"
    end
  end
  rescue GetoptLong::InvalidOption => e
    # the error message has already been output to stdout
    exit 1
end

raise 'argc mismatch' unless ARGV.length == 1

def open_possibly_gzipped filename, &thunk
  if filename =~ /\.gz\Z/ then
    return Zlib::GzipReader.open filename, &thunk
  else
    return open filename, 'rb', &thunk
  end
end

# We'll guess baseline by determining each glyph's distance from the bitmap's
# bottom and using whatever distance is most commonly used.  It tends to work
# for fonts intended for human scripts but and can produce rather silly
# outcomes in graphics-heavy fonts.  User caution is adviced.

class Baseline_Guesser
  def initialize
    @counts = [] # indexed by the prospective baseline
    return
  end

  def feed scanlines
    raise 'type mismatch' unless scanlines.is_a? Array and scanlines.all?{|l| l =~ /\A[01]*\Z/}
    # Note that scanlines is ordered top-to-bottom.
    @counts.push 0 while @counts.length < scanlines.length
    i = 0
    while i < scanlines.length do
      if scanlines[~i] =~ /1/ then
        @counts[i] += 1
        return
      end
      i += 1
    end
    # Must've been a blank glyph.  Let's not count it.
    return
  end

  def baseline
    max = 0
    baseline = 0
    @counts.each_with_index do |c, i|
      if c > max then
        max = c
        baseline = i
      end
    end
    return baseline
  end
end

$baseline_guesser = Baseline_Guesser.new
$glyph_data = [] # text rows, ready to be dumped to a PXF

class Charset_Emitter
  def initialize port
    super()
    @port = port
    @curstretch = nil
    @pending_aliases = []
    return
  end

  def emit nc, unicode, *extra_unicodes
    unless @curstretch and
        @curstretch[:last_native] + 1 == nc and
        @curstretch[:last_unicode] + 1 == unicode then
      flush
      @curstretch = {}
      @curstretch[:first_native] = nc
      @curstretch[:first_unicode] = unicode
    end
    @curstretch[:last_native] = nc
    @curstretch[:last_unicode] = unicode
    extra_unicodes.each do |xu|
      @pending_aliases.push "code %02X <- U+%04X" % [nc, xu]
    end
    if nc == 0x7E and unicode == 0x7E and @curstretch[:first_native] <= 0x20 then
      # Apparently, ascii.cs is a subset of this charset.  Let's make use of it.
      if @curstretch[:first_native] < 0x20 then
        @curstretch[:last_native] = @curstretch[:last_unicode] = 0x1F
        @port.puts format_curstretch
      end
      @curstretch = nil
      @port.puts "include ascii.cs"
      flush # just in case @pending_aliases is not empty
    end
  end

  def format_curstretch
    if @curstretch[:first_native] == @curstretch[:last_native] then
      return "code %02X = U+%04X" %
          [:first_native, :first_unicode].
              map{|k| @curstretch[k]}
    else
      return "code %02X .. %02X = U+%04X .. U+%04X" %
          [:first_native, :last_native, :first_unicode, :last_unicode].
              map{|k| @curstretch[k]}
    end
  end
  private :format_curstretch

  def flush
    if @curstretch then
      @port.puts format_curstretch
      @curstretch = nil
    end
    @port.puts @pending_aliases
    @pending_aliases = []
    return
  end
end

open_possibly_gzipped ARGV[0] do |port|
  data = port.read
  magic, mode, charsize = data.unpack('@0 S> C C')
  unless magic == 0x3604 then
    raise 'not a PSF v1 file'
  end
  if mode & 0x01 != 0 then
    char_count = 512
  else
    char_count = 256
  end
  if mode & 0x02 != 0 and $charset_output_filename.nil? and !$charset_extraction_suppressed then
    raise 'the font has PSF1_MODEHASTAB set but --output-charset was not used, nor was a charset header file specified'
  end
  if mode & 0x04 != 0 then
    raise 'PSF1_MODEHASSEQ is not supported'
  end
  i = 4
  (0 ... char_count).each do |charcode|
    rows = data.byteslice(i, charsize).unpack('C*').map{|row| [row].pack('C').unpack('B*').first}
    # The rows array now holds String:s of bits.
    raise "Broken data" unless rows.length == charsize
    i += charsize
    # pad the bitmap's bottom so that we could represent each column with full nibbles
    rows.push '0' * 8 while rows.length % 4 != 0
    odd_nybbles_per_column = rows.length % 8 != 0
    $baseline_guesser.feed rows
    pxf_line = "%02X" % charcode
    (0 ... 8).each do |i|
      column = rows.map{|row| row[i]}.join ''
      hex_column = [column].pack('B*').unpack('H*').first
      # Our column is padded to a four-bit alignment.  Unfortunately,
      # unpack('H*') will pad it to an eight-bit alignment.  We'll have to
      # discard the trailing zero when this happens.
      hex_column[-1] = '' if odd_nybbles_per_column
      pxf_line << " " << hex_column
    end
    $glyph_data.push pxf_line
  end

  puts "### !!! Generated by psf2pxf.rb from #{ARGV[0]}"
  puts
  unless $extra_header.empty? then
    puts "# Extra header data supplied manually"
    puts $extra_header
    puts "# End of extra header data"
    puts
  end
  puts "# The baseline was guessed by psf2pxf.rb."
  puts "baseline #{$baseline_guesser.baseline}"
  puts
  if $charset_output_filename then
    puts "# The charset was also extracted by psf2pxf.rb and written in this file."
    # Because Pixitie's resources live in a flat namespace, we'll discard the
    # directory prefix.
    puts "charset #{File.basename $charset_output_filename}"
    puts
  end
  puts $glyph_data

  if $charset_output_filename then
    open $charset_output_filename, 'w' do |csport|
      csport.puts "### !!! Generated by psf2pxf.rb from #{ARGV[0]}"
      csport.puts
      if mode & 0x02 != 0 then
        emitter = Charset_Emitter.new csport
        unicode_table = data.unpack("@#{i} S<*")
        (0 ... char_count).each do |charcode|
          term = unicode_table.index(0xFFFF)
          raise "Broken data" unless term
          char_data = unicode_table[0 ... term]
          unicode_table[0 .. term] = []
          # discard multi-codepoint entries
          char_data[(char_data.index(0xFFFE) || char_data.length) .. -1] = []
          emitter.emit charcode, *char_data unless char_data.empty?
        end
        emitter.flush
      end
    end
  end
end
