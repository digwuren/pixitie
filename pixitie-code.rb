#! /usr/bin/ruby

# vim: sw=2 tw=70

require 'getoptlong'
require 'set'
require 'stringio'
require 'base64'
require 'zlib'

module Pixitie

  IDENT = 'Pixitie 1.0.0'

#### Help output

  USAGE = <<'EOU'
Usage: pixitie [-f FONT] INPUT-FILE
       pixitie -x RESOURCE ...
       pixitie -S FONT ...
Typesets the given plain text file in PostScript using the given pixel
font.

  -f, --font=FONT-NAME    font to use [EpsonFX80]
  -s, --size=SIZE         font scaling size [10]
  -m, --margin=MARGIN     margin [15mm]
  -L, --min-line-spacing  minimum line space [12bp]
  -o, --output=FILENAME   save output to this file [standard output]
  -R, --resources=DIR     directory for resource (font data, charset,
                          etc.) overrides
  -S, --showcase          showcase these fonts
  -x, --extract           extract the specified builtin resources into
                          the current directory as standalone files
      --obey-form-feed    break page at the FF (U+000C, ^L) char
      --list-builtins     list the builtin resources
      --list-fonts        list available fonts
  -h, --help              brief usage summary
      --version           display version identifier

EOU

#### Error handling

  class Resource_Not_Found < Exception
    def initialize resname
      super "#{resname}: resource not found"
      return
    end
  end

  class Duplicate_Encoding < Exception
    def initialize unicode
      super sprintf("duplicate encoding for U+%04X", unicode)
      return
    end
  end

  class Duplicate_Decoding < Exception
    def initialize native_charcode
      super sprintf("duplicate decoding for $%02X", native_charcode)
      return
    end
  end

  class Duplicate_Glyph < Exception
    def initialize charcode
      super sprintf("duplicate glyph data for $%02X", charcode)
      return
    end
  end

#### Resource loader

  class << RES = Object::new
    attr_accessor :dir

    RES.dir = nil

    def [] name
      if @dir then
        begin
          return IO::read(File::join(@dir, name))
        rescue Errno::ENOENT
        end
      end
      if BUILTIN.has_key? name then
        return BUILTIN[name]
      else
        raise Resource_Not_Found::new(name)
      end
    end

    def have? name
      return (BUILTIN.has_key?(name) or
          (@dir and File::exists?(File::join(@dir, name))))
    end

    # Return a list of available resources, including non-builtin
    # ones.
    def list
      names = Set::new(BUILTIN.keys)
      if RES.dir then
        Dir::entries(RES.dir).each do |name|
          if File::file? File::join(RES.dir, name) then
            names.add name
          end
        end
      end
      return names.to_a.sort
    end

    def sortkey name
      name, suffixen = name.split '.', 2
      return suffixen, name
    end

    # Output a human-readable list of builtin resources and their
    # sizes.
    #
    # While intuitively, this might fit better into BUILTIN, we
    # shouldn't place it there because BUILTIN is not a part of the
    # resource loader's public interface.
    def show_builtin_list
      BUILTIN.keys.sort{|a, b| sortkey(a) <=> sortkey(b)}.each do |n|
        printf "%7i %s\n", BUILTIN[n].length, n
      end
      return
    end

    # Dictionary for the builtin resources.  Populated as the module
    # is first loaded; no public methods.
    class << BUILTIN = {}
      DECODERS = {
        '.hex' => proc do |data, name|
          parse_i8hex data, name
        end,
        '.base64' => proc do |data, name|
          Base64::decode64 data
        end,
        '.gz' => proc do |data, name|
          Zlib::GzipReader::new(StringIO::new(data)).read
        end,
      }.freeze

      def add name, data
        name.freeze; data.freeze

        # Store the resource itself
        if self.has_key? name then
          raise "#{name}: duplicate builtin resource"
        end
        self[name] = data

        # Is the resource decodeable?
        if name =~ /\.([^.]+)$/i then
          decoder = DECODERS[$&]
          # This may recurse a bit.
          add $`, decoder.call(data, name) if decoder
        end

        return
      end

      def parse_data_fork content
        data_parts = content.split(/^\/([^\/]+)\/$/m, -1)

        unless !data_parts.empty? and data_parts[0].rstrip.empty? then
          raise "DATA parse error"
        end

        i = 1
        while i + 1 < data_parts.length do
          add data_parts[i], data_parts[i + 1].strip + "\n"
          i += 2
        end

        return
      end

      # Parse an 8-bit Intel HEX style text file into the binary it
      # represents.  Each record must occupy a separate and complete
      # line, the records must be in strictly ascending order with no
      # holes or overlap, and the start address must be 0x0000.
      #
      # hex_file_name is only used for error reporting.
      def self::parse_i8hex hex_data, hex_file_name
        bin_data = []   # collects the result
        endedp = false  # did we pass the terminal record?
        lineno = 1      # for error reporting
        fail = proc do |msg|
          raise "#{hex_file_name}:#{lineno}: #{msg}"
        end
        hex_data.each_line do |line|
          line.chomp!
          unless line =~ /^:([\da-f][\da-f])+$/i then
            fail.call "invalid record"
          end
          record = [line[1 .. -1]].pack('H*').unpack 'C*'

          # Is the length field correct?
          unless record.length == 4 + record[0] + 1 then
            fail.call "record length mismatch"
          end

          # Is the checksum correct?
          sum = 0
          record.each do |b|
            sum += b
          end
          unless sum & 0xFF == 0 then
            fail.call "record checksum mismatch"
          end

          # Handle the record
          case record[3]
          when 0 then # data record
            if endedp then
              fail.call "data after terminal record"
            end
            declared_record_length = (record[1] << 8) | record[2]
            unless bin_data.length == declared_record_length then
              fail.call "wrong address"
            end
            bin_data += record[4 .. -2]
          when 1 then # terminal record
            if endedp then
              fail.call "multiple terminal records"
            end
            endedp = true
          else
            fail.call "invalid record type"
          end

          # Proceed to the next record
          lineno += 1
        end

        unless endedp then
          unless bin_data.length == (record[1] << 8) | record[2] then
            fail.call "terminal record missing"
          end
        end

        return bin_data.pack 'C*'
      end

      # load the builtin resources
      content = if $0 == __FILE__ then DATA.read
      else IO::read(__FILE__).split(/^__END__$/, 2)[1] || ''
      end

      BUILTIN.parse_data_fork content
      
      freeze
    end
  end

#### PostScript-style string escaping

  class ::String
    # Quotes this string in PostScript-style using leading backslash
    # for backslash and parens and the octal notation for
    # nonprintables.  Returns the quoted string.  Does not add
    # surrounding parentheses.
    def ps_escape
      result = ''
      unpack 'U*' do |b|
        if (0x20 .. 0x7E).include? b then
          result << '\\' if "\\()".include? b.chr
          result << b.chr
        else
          result << sprintf('\\%03o', b)
        end
      end
      return result
    end
  end

#### Bit twiddling

  class ::Integer
    def bit_count
      unless self >= 0 then
        raise "No well-defined finite bit count for negative integers"
      end
      s = self
      result = 0
      until s.zero? do
        result += 1
        s >>= 1
      end
      return result
    end
  end

#### Character sets

  # The basic bidirectional deterministically multimapping character
  # set data structure.
  class Charset

    ## Constructors

    def initialize
      super()
      @encoding = {} # unicode-value => native-charcode
      @decoding = {} # native-charcode => unicode-value
      @natives = Set::new
      return
    end

    def Charset::load resname
      charset = Charset::new
      charset.parse resname, [], 3
      charset.freeze
      return charset
    end

    ## Query API

    # Return the native charcode or |nil| if this Unicode value can
    # not be encoded in this charset.
    def encode unicode
      return @encoding[unicode]
    end

    # Return the Unicode value or |nil| if this native character can
    # not be encoded in Unicode.
    def decode native_charcode
      return @decoding[native_charcode]
    end

    # Iterate over native charcodes for which mapping entries --
    # either encoding or decoding -- exist in this charset.
    def each_native_charcode &thunk
      @natives.each &thunk
      return
    end

    # Given a native charcode, return the Unicode values that encode
    # into this charcode, *except* the primary decoding, in an Array.
    def auxiliary_unicodes native_charcode
      canonical_unicode = @decoding[native_charcode]
      result = []
      @encoding.each_pair do |u, c|
        if c == native_charcode and u != canonical_unicode then
          result.push u
        end
      end
      result.sort!
      return result
    end

    ## Other utilities

    GLYPH_NAMES = Object.new
    class << GLYPH_NAMES
      def [] unicode
        unless @data then
          @data = {}
          RES['glyphlist.txt'].each_line do |line|
            line.rstrip!
            next if line.empty? or line =~ /^#/
            name, code = line.split /;/
            next unless code.length == 4
            code = code.hex
            @data[code] = name unless @data[code]
          end
        end
        return @data[unicode]
      end
    end

    # Construct and return a suitable PostScript charname for the
    # given native charcode.  If this code resolves into a Unicode
    # value and back, this will be a standard Unicode-based name for
    # the character, thus allowing PDF-to-text conversion tools to do
    # a reasonable work without having to OCR the glyphs.  Otherwise,
    # the character will be considered to not have a _canonical_
    # Unicode value, and the generated charname will be based on the
    # native charcode, and structured so as to not have a special
    # meaning for PDF tools.
    def ps_charname nc
      if decode(nc) and encode(decode(nc)) == nc then
        return GLYPH_NAMES[decode nc] || ('uni%04X' % decode(nc))
      else
        return 'chr%02X' % nc
      end
    end

    ## Build API

    # Set a Unicode's primary encoding in this charset.  It's a
    # checked error (see Duplicate_Encoding) to set an encoding for a
    # Unicode for which an encoding has already been defined.
    def set_encoding uc, nc
      if @encoding.has_key? uc then
        raise Duplicate_Encoding::new(uc)
      end
      @encoding[uc] = nc
      @natives.add nc
      return
    end

    # Set a native charcode's primary decoding (into a Unicode value)
    # in this charset.  It is a checked error (see Duplicate_Encoding)
    # to set a decoding for a native charcode for which a decoding has
    # already been defined.
    def set_decoding nc, uc
      if @decoding.has_key? nc then
        raise Duplicate_Decoding::new(nc)
      end
      @decoding[nc] = uc
      @natives.add nc
      return
    end

    def freeze
      @encoding.freeze
      @decoding.freeze
      @natives.freeze
      return super
    end

    ## Parser

    # Load charset data from the specified resource into the current
    # font's charset object, skipping exceptions, a list of charcodes
    # to not load, and avoiding excessive nesting.
    def parse resname, exceptions = [], nesting_countdown = 3
      RES[resname].each_line do |line|
        line.strip!
        line.gsub! /\s*#.*$/, ''
        next if line.empty?
        keyword, args = line.split /\s+/, 2
        if keyword == 'code' then
          if args =~ /^([\da-f]+)\s+=\s+U\+([\da-f]{4,5})$/i then
            native_charcode = $1.hex
            unicode = $2.hex
            unless exceptions.include? native_charcode then
              set_encoding unicode, native_charcode
              set_decoding native_charcode, unicode
            end
          elsif args =~ /^([\da-f]+)\s*\.\.\s*([\da-f]+)\s+=\s+/i then
            natives = $1.hex .. $2.hex
            unicodes = parse_unicode_list $'
            unless natives.first <= natives.last then
              raise "Native charcode range endpoints misordered"
            end
            unicodes = unicodes.to_a
            unless natives.last - natives.first + 1 ==
                unicodes.length then
              raise "Range length mismatch"
            end
            natives.zip(unicodes).each do |native_charcode, unicode|
              unless exceptions.include? native_charcode then
                set_encoding unicode, native_charcode
                set_decoding native_charcode, unicode
              end
            end
          elsif args =~ /^([\da-f]+)\s+<-\s+U\+([\da-f]{4,5})$/i then
            native_charcode = $1.hex
            unicode = $2.hex
            unless exceptions.include? native_charcode then
              set_encoding unicode, native_charcode
            end
          elsif args =~ /^([\da-f]+)\s+->\s+U\+([\da-f]{4,5})$/i then
            native_charcode = $1.hex
            unicode = $2.hex
            unless exceptions.include? native_charcode then
              set_decoding native_charcode, unicode
            end
          else
            raise "Argument parse error at line #{line.inspect}"
          end
        elsif keyword == 'include' then
          if args =~ /^([\w.-]+)(?:\s+except\s*(.*))?$/i then
            resname, newexc = $1, $2
            newexc ||= ''
            parsed_newexc = []
            newexc.split(/\s*,\s*/).each do |c|
              case c
              when /^[\da-f]+$/i then
                parsed_newexc.push c.hex
              when /^([\da-f]+)\s*\.\.\s*([\da-f]+)$/i then
                ($1.hex .. $2.hex).each do |c|
                  parsed_newexc.push c
                end
              else
                raise "Invalid hex value or range #{c.inspect}"
              end
            end
            if nesting_countdown > 0 then
              parse resname, exceptions + parsed_newexc,
                  nesting_countdown - 1
            else
              raise "Inclusion nesting too deep"
            end
          else
            raise "Argument parse error at line #{line.inspect}"
          end
        else
          raise "Invalid charset data line #{line.inspect}"
        end
      end
      return
    end

    private

    # Parse a string containing either a a two-dotted Unicode range or
    # a comma-separated list of Unicode values.  Return the values in
    # a Range or an Array.
    def parse_unicode_list s
      case s
      when /\AU\+([\da-f]{4,5})\s*\.\.\s*U\+([\da-f]{4,5})\Z/i then
        unicodes = $1.hex .. $2.hex
        unless unicodes.first <= unicodes.last then
          raise "Unicode range endpoints misordered"
        end
        return unicodes
      when /\AU\+([\da-f]{4,5})\s*(,\s*U\+([\da-f]{4,5}))*\Z/i then
        items = s.split(/\s*,\s*/).map do |i|
          i =~ /U\+([\da-f]{4,5})/i
          $1.hex
        end
      else
        raise "Unparseable unicode list #{s.inspect}"
      end
    end
  end

#### Font configuration

  # Represents the configuration of a specific font or its variant.
  class Font_Config
    # Glyph drawing type.  Known values: :rectangular_dots and
    # :circular_dots.  As a basic rule of thumb, fonts that were
    # intended for display on CRT screen or a dot matrix printer
    # should use circular dots; fonts that were intended for a LCD
    # screen should use rectangular dots.  But sometimes, it is a
    # good idea to do both kinds of fonts from the same pixels.
    attr_accessor :drawing_type

    # For rectangular dots, width of the blank strips between
    # neighbouring pixels, given in pixel grid's vertical units.
    # This blank space is constant no matter the aspect ratio;
    # however.  If the pixel grid is compressed, this blank space
    # might not apply between nominal neighbours.
    attr_accessor :interpixel_blank

    # For circular dots, radius of the dot, given in pixel grid's
    # vertical units.
    attr_accessor :dot_radius

    # Ratio of the pixel grid's horizontal and vertical unit.  Most
    # of the time, it's 1, but some eccentric fonts prefer other
    # aspect ratios.
    attr_accessor :aspect_ratio

    # The pixel grid can be compressed or stretched horizontally
    # without affecting dimensions of the pixels.  This factor
    # controls this behaviour.  A factor of 1 means that the pixel
    # grid obeys @aspect_ratio exactly; a factor of 0.5 means double
    # density.  The latter matches behaviour of many dot matrix
    # printers when in draft mode.
    attr_accessor :horcompr

    # The pixel grid can be compressed or stretched vertically
    # without affecting dimensions of the pixels.  This factor
    # controls this behaviour.
    attr_accessor :vertcompr

    # List of proc:s to transform the column list
    attr_reader :manipulations

    # Note that we're instantiating PLAIN as Font_Config before
    # defining Font_Config#initialize, so it won't be called.
    (PLAIN = Font_Config::new).instance_eval do
      @drawing_type = :rectangular_dots
      @interpixel_blank = 0.1
      @dot_radius = 0.45
      @aspect_ratio = 1
      @horcompr = 1.0
      @vertcompr = 1.0
      @manipulations = []
      freeze
    end

    def initialize prototype = PLAIN
      super()
      @drawing_type = prototype.drawing_type
      @interpixel_blank = prototype.interpixel_blank
      @dot_radius = prototype.dot_radius
      @aspect_ratio = prototype.aspect_ratio
      @horcompr = prototype.horcompr
      @vertcompr = prototype.vertcompr
      @manipulations = prototype.manipulations.dup
          # the duplicate will not be frozen
      return
    end

    def freeze
      @manipulations.freeze
      return super
    end

    # Parse the given |line| as a font configuration item and modify
    # the configuration accordingly.  Return whether the parsing was
    # successful; if not, the configuration object will not be
    # changed.
    def parse line
      keyword, args = line.split /\s+/, 2
      return false if keyword.nil?
      args ||= ''

      cls = Font_Config_Item::KEYWORDS[keyword]
      if cls then
        cls::apply keyword, args, self
        return true
      else
        return false
      end
    end

    # Parse an integer, a fixed-point number, or a common fraction
    # (using either a slash or a colon) into a Ruby floating point
    # number.
    def Font_Config::parse_number s
      s = s.strip
      if s =~ /\A([+-]?)\s*(\d+)\Z/i then
        return s.gsub(/\s+/, '').to_i
      elsif s =~ /\A([+-]?)\s*(\d+(\.\d+)?)\Z/i then
        return s.gsub(/\s+/, '').to_f
      elsif s =~ /\A([+-]?)\s*(\d+)\s*[:\/]\s*(\d+)\Z/i then
        denominator = $3.to_f
        if denominator.zero? then
          raise "Zero denominator in #{s.inspect}"
        end
        return ($1 != '-' ? +1 : -1) * $2.to_f / denominator
      else
        raise "Unparseable number #{s.inspect}"
      end
    end
  end

## Font configuration items

  class Font_Config_Item
    # Applies a configuration item embodied by this class and
    # specified by these |args| to the given |config|.  Note that
    # |keywords| is used only for error reporting.
    def self::apply keyword, args, config
      raise 'Abstract method called'
    end

    class Aspect_Ratio < Font_Config_Item
      def self::apply keyword, args, config
          ratio = Font_Config::parse_number args
          raise "Zero aspect ratio in #{args.inspect}" if ratio.zero?
          config.aspect_ratio = ratio
          return
      end
    end

    # Note that if the horizontal-compression directive is used
    # multiple times, the factors end up multiplied.
    class Horizontal_Compression < Font_Config_Item
      def self::apply keyword, args, config
        config.horcompr *= Font_Config::parse_number args
        return
      end
    end

    # Note that if the vertical-compression directive is used multiple
    # times, the factors end up multiplied.
    class Vertical_Compression < Font_Config_Item
      def self::apply keyword, args, config
        config.vertcompr *= Font_Config::parse_number args
        return
      end
    end

    class Circular_Dots < Font_Config_Item
      def self::apply keyword, args, config
        unless args.empty? then
          raise "#{keyword} takes no arguments"
        end
        config.drawing_type = :circular_dots
        return
      end
    end

    class Rectangular_Dots < Font_Config_Item
      def self::apply keyword, args, config
        unless args.empty? then
          raise "#{keyword} takes no arguments"
        end
        config.drawing_type = :rectangular_dots
        return
      end
    end
  end

## Pixel font manipulations

  # A 'manipulation' reifies a simple algorithmic transformation of
  # the font.  Early printers used such for deriving the bold, wide,
  # etc. variants from the base version.  Early video terminals'
  # reverse video and underscoring can also be represented in this
  # way.
  class Manipulation < Font_Config_Item
    # Alter the cell size specification.
    #
    # The default method is a null alteration.
    def process_size_constraints width, height
      return width, height
    end

    # Alter the font's baseline delta.
    #
    # The default method is a null alteration.
    def process_baseline_delta baseline_delta
      return baseline_delta
    end

    # Alter the font's column data.  Does not affect the passed column
    # Array; rather, return an Array with column data in the altered
    # font.
    #
    # The default method is a null alteration.
    def process_columns columns
        return columns
    end

    def self::apply keyword, args, config
      config.manipulations.push self::parse(keyword, args).freeze
      return
    end

    class Hex_Parametric_Manipulation < Manipulation
      def self::parse name, args
        unless args =~ /^[\da-f]+$/i then
          raise "#{name} requires a hex number as an argument"
        end
        return self::new(args.hex)
      end
    end

    # Shift the pixels fitting the given mask leftwards by one column.
    # Leave the remaining pixels in place.
    class Shift_Left_By_Mask < Hex_Parametric_Manipulation
      def initialize mask
        super()
        @mask = mask
        return
      end

      def process_columns columns
        glyph = Pixel_Glyph::new columns
        (0 .. glyph.length - 2).each do |i|
          glyph[i] = (glyph[i] & ~@mask) |
              (glyph[i + 1] & @mask)
        end
        glyph[-1] &= ~@mask
        glyph.freeze
        return glyph
      end
    end

    # Shift the pixels fitting the given mask rightwards by one
    # column.  Leave the remaining pixels in place.
    class Shift_Right_By_Mask < Hex_Parametric_Manipulation
      def initialize mask
        super()
        @mask = mask
        return
      end

      def process_columns columns
        glyph = Pixel_Glyph::new columns
        (1 .. glyph.length - 1).to_a.reverse_each do |i|
          glyph[i] = (glyph[i] & ~@mask) |
              (glyph[i - 1] & @mask)
        end
        glyph[0] &= ~@mask
        glyph.freeze
        return glyph
      end
    end

    class Pad < Hex_Parametric_Manipulation
      def initialize amount
        super()
        @amount = amount
        return
      end

      def process_size_constraints width, height
        return width && width + @amount, height
      end

      def process_columns columns
        return Pixel_Glyph::new(columns + [0] * @amount)
      end
    end

    class Parameterless_Manipulation < Manipulation
      def self::parse name, args
        unless args.empty? then
          raise "#{name} requires no argument"
        end
        return self::new
      end
    end

    # A feature from Roelof Koning's Prop-Print, a set of enhanced
    # terminal routines for ZX Spectrum: each set pixel is moved one
    # place to the left and one to place to the right simulatenously,
    # and the results are ORed together.
    class Propprint_Shadow < Parameterless_Manipulation
      def process_columns columns
        glyph = []
        (0 ... columns.length).each do |i|
          col = 0
          if i > 0 then
            col |= columns[i - 1]
          end
          if i < columns.length - 1 then
            col |= columns[i + 1]
          end
          glyph.push col
        end
        glyph.freeze
        return glyph
      end
    end

    # For each set dot in each glyph, make a duplicate one column
    # right from it.  (With the exception of the rightmost column of a
    # glyph.)
    class OR_Pixels_Rightwards < Parameterless_Manipulation
      def process_columns columns
        glyph = Pixel_Glyph::new columns
        (1 ... glyph.length).to_a.reverse_each do |i|
          glyph[i] |= glyph[i - 1]
        end
        glyph.freeze
        return glyph
      end
    end

    # For each set dot in each glyph, make a duplicate one row up from
    # it.
    #
    # Note that the nominal cell height will remain the same, which
    # means that use of this manipulation can lead to the resulting
    # pixel data not satisfying the cell height constraint.
    class OR_Pixels_Upwards < Parameterless_Manipulation
      def process_columns columns
        return Pixel_Glyph::new(columns.map{|c| c | (c << 1)}).freeze
      end
    end

    # Given a sequence of colon-separated simple operations, apply
    # these to the glyph columns from left to right in a loop.
    # Supported elementary operations:
    #   &nn -- AND the given hex number to the column
    #   &~nn -- AND NOT the given hex number to the column
    #   |nn -- OR the given hex number to the column
    #   ^nn -- XOR the given hex number to the column
    class Columns < Manipulation
      def self::parse name, args
        operations = (args || '').split /\s*:\s*/
        if operations.empty?
          raise "#{name} requires at least one column-manipulating " +
              "operation"
        end
        operations.each do |op|
          unless op =~ /^(\&(\s*\~)?|[|^])\s*[\da-f]+$/i then
            raise "#{name} can't parse operation #{op.inspect}"
          end
        end
        return self::new(*operations)
      end

      # Note that we'll expect the operations to be correct here.  An
      # undefined operation might get stored but will lead to a late
      # crash when an invocation attempt is made.
      def initialize *operations
        super()
        @operations = operations
        return
      end

      def process_columns columns
        glyph = Pixel_Glyph::new columns
        (0 ... glyph.length).each do |i|
          op = @operations[i % @operations.length]
          case op
          when /^\&\s*([\da-f]+)$/i then
            glyph[i] &= $1.hex
          when /^\&\s*\~\s*([\da-f]+)$/i then
            glyph[i] &= ~$1.hex
          when /^\|\s*([\da-f]+)$/i then
            glyph[i] |= $1.hex
          when /^\^\s*([\da-f]+)$/i then
            glyph[i] ^= $1.hex
          else
            raise "Assertion failed: invalid /columns operation " +
                "#{op.inspect} should have been caught earlier"
          end
        end
        glyph.freeze
        return glyph
      end
    end

    # Double all dot columns in all glyphs.  Some video terminals used
    # this for double-width text.
    class Simple_Double_Width < Parameterless_Manipulation
      def process_size_constraints width, height
        return width && width * 2, height
      end

      def process_columns columns
        glyph = Pixel_Glyph::new
        columns.each do |col|
          glyph.push col, col
        end
        glyph.freeze
        return glyph
      end
    end

    # Insert a blank column after each column.
    class Stretch_Wide < Parameterless_Manipulation
      def process_size_constraints width, height
        return width && width * 2, height
      end

      def process_columns columns
        glyph = Pixel_Glyph::new([0] * (columns.length * 2))
        columns.each_with_index do |col, i|
          glyph[i * 2] = col
        end
        glyph.freeze
        return glyph
      end
    end
  end

  class Font_Config_Item
    KEYWORDS = {
      'aspect-ratio' => Aspect_Ratio,
      'horizontal-compression' => Horizontal_Compression,
      'vertical-compression' => Vertical_Compression,
      'circular-dots' => Circular_Dots,
      'rectangular-dots' => Rectangular_Dots,

      # Manipulations
      '/shift-left-by-mask' => Manipulation::Shift_Left_By_Mask,
      '/shift-right-by-mask' => Manipulation::Shift_Right_By_Mask,
      '/propprint-shadow' => Manipulation::Propprint_Shadow,
      '/or-pixels-rightwards' => Manipulation::OR_Pixels_Rightwards,
      '/or-pixels-upwards' => Manipulation::OR_Pixels_Upwards,
      '/stretch-wide' => Manipulation::Stretch_Wide,
      '/simple-double-width' => Manipulation::Simple_Double_Width,
      '/columns' => Manipulation::Columns,
      '/pad' => Manipulation::Pad,
    }.freeze
  end

#### Font litters

  # A font litter is a font together with fonts derived from it via
  # predefined series of manipulations (see the |Manipulation| class).
  # Note that it is not quite a 'family'; it's common to define a
  # pixel font family in terms of two litters, one upright and one
  # slanted or italic.  The other variants are then automatically
  # generated from these base fonts.
  class Pixel_Font_Litter
    attr_accessor :name
    attr_reader :charset_filename
    attr_reader :charset
    attr_reader :plain_variant

    def initialize litter_name
      super()

      #### Initialise instance variables

      @name = litter_name
          # This is also the name of the baseline font.

      # native_charcode => [column, ...]
      @pixel_data = {}

      # Boolean, used during parsing to check for duplicate baseline
      # declaration
      @baseline_declared = false

      @charset_filename = nil
      @charset = nil

      # Font variant bits are numbered from 0 upwards
      @varbit_names = []
          # [variant-bit-index => variant-bit-name]
      @varbit_extra_decl = []
          # [variant-bit-index => [decl, ...]]

      # Bit combinations that can not be used together
      @varbit_exclusions = [] # [bit_pattern, ...]

      @plain_variant = Pixel_Font_Variant::new @name, self,
          Font_Config::new

      # Width of the unit cell, in pixels.  Possibly used for font
      # indexing.  Not defined for proportional fonts.
      #
      # Also functions as a cell size constraint.
      @plain_variant.cell_width = nil

      # Full height of the unit cell, in pixels.  Used for drawing
      # appropriate background.
      #
      # Also functions as a cell size constraint.
      @plain_variant.cell_height = nil

      # This many bottom pixel rows remain below the baseline.
      #
      # Having a defined baseline separate from the charcell bottom
      # enables easily typesetting pixel fonts together with common
      # PostScript fonts such as Times.
      @plain_variant.baseline_delta = 0

      #### Load the PXF file

      parse_pxf_resource @name + '.pxf'
      raise "#{@name}.pxf does not declare charset" unless @charset
      @plain_variant.config.freeze

      # Check that every decoding entry in the charset has a glyph.
      #
      # Note that it is not necessary for each glyph to have a
      # decoding entry, as a font may contain unique characters that
      # do not appear in Unicode.
      @charset.each_native_charcode do |c|
        unless @pixel_data.has_key? c then
          raise "Overbroad charset -- no glyph #{sprintf '$%02X', c}"
        end
      end

      # Since this is the plain variant, it is not allowed to contain
      # any manipulations.
      unless @plain_variant.config.manipulations.empty? then
        raise "Manipulated baseline font?"
      end

      @plain_variant.pixel_data = @pixel_data

      # If cell dimensions were defined, check that they accurately
      # match plain variant's post-manipulation pixel data
      @plain_variant.check_cell_size_constraints

      return
    end

    # Check whether the given variant bit pattern refers only to
    # defined variant bits and does not violate any exclusion
    # constraints.
    def variant_bit_pattern_valid? bits
      unless (0 ... 1 << @varbit_names.length).include? bits then
        return false
      end
      @varbit_exclusions.each do |exclusion|
        if (bits & exclusion) == exclusion then
          return false
        end
      end
      return true
    end

    # Given a variant bit pattern, construct and return the font
    # variant it describes.
    def get_variant_font bit_pattern
      unless variant_bit_pattern_valid? bit_pattern then
        raise 'Invalid font variant requested'
      end
      return @plain_variant if bit_pattern.zero?

      # The complete configuration of the non-plain variant font is
      # determined by starting from the main font's configuration and
      # applying the variant font's configuration items to it, in
      # order.
      variant_font_name = @name
      variant_font_config = Font_Config::new @plain_variant.config
      @varbit_names.each_with_index do |bit_name, bit_index|
        if bit_pattern[bit_index] == 1 then
          variant_font_name += '.' + bit_name
          @varbit_extra_decl[bit_index].each do |decl|
            unless variant_font_config.parse decl then
              raise "Unparseable configuration item #{decl.inspect}"
            end
          end
        end
      end

      # apply the manipulations
      pixel_data = {}
      @plain_variant.pixel_data.each_pair do |nc, glyph|
        variant_font_config.manipulations.each do |handler|
          glyph = handler.process_columns glyph
        end
        pixel_data[nc] = glyph
      end

      cell_width, cell_height =
          @plain_variant.cell_width, @plain_variant.cell_height
      baseline_delta = @plain_variant.baseline_delta
      variant_font_config.manipulations.each do |m|
        cell_width, cell_height =
            m.process_size_constraints cell_width, cell_height
        baseline_delta = m.process_baseline_delta baseline_delta
      end

      # assemble the font variant
      font_variant = Pixel_Font_Variant::new variant_font_name, self,
          variant_font_config, pixel_data
      font_variant.cell_width, font_variant.cell_height =
          cell_width, cell_height
      font_variant.baseline_delta = baseline_delta

      # check whether the cell size constraints of the font variant
      # are satisfied
      font_variant.check_cell_size_constraints

      # we're done
      return font_variant
    end

    # Return native charcodes of all glyphs contained in this font.
    # This is a (non-strict) superset of the native charcodes with
    # decoding entries in the associated Charset.
    def charcodes
      return @pixel_data.keys.sort
    end

    def has_char? charcode
      return @pixel_data.has_key?(charcode)
    end
  end

#### Font litter parser

  # As an Array, a Pixel_Glyph instance contains a list of columns,
  # each represented by an integer.
  class Pixel_Glyph < Array
    # Calculate logical OR over all the columns in this glyph.
    def splotch
      result = 0
      each do |column|
        result |= column
      end
      return result
    end

    # Determine and return the minimal bounding box necessary to fit
    # the glyph.  If all columns are empty, return a null bounding
    # box.  Consider baseline_delta properly.  Handle config.horcompr
    # and config.aspect_ratio.  Note that config.manipulations is
    # ignored -- it is assumed that the glyph data already reflects
    # the active manipulations.
    def bbox config, baseline_delta
      left = nil
      right = nil

      # scan for the left and right edge
      (0 ... self.length).each do |i|
        if self[i] != 0 then
          left = i if left.nil?
          right = i + 1
        end
      end

      # Does the glyph have any set pixels?
      s = splotch
      unless s.zero? then
        # It does, so let's scan for top and bottom edge.
        bottom = 0
        while s & 1 == 0 do
          bottom += 1
          s >>= 1
        end

        top = bottom + s.bit_count

        # Update the left and right edge to take the horizontal
        # compression factor into account.  Because horcompr does not
        # affect the width of individual dots, we'll count the
        # rightmost dot column at width 1, no matter the compression
        # factor.
        left = left * config.horcompr
        right = (right - 1) * config.horcompr + 1

        # Construct the preliminary bbox.
        result = Bounding_Box::new(left, bottom, right, top)

        # Lower the bbox according to baseline_delta.
        result = result.shift(0, -baseline_delta)

        # Stretch or shrink the bounding box horizontally according to
        # aspect_ratio.  Note that aspect_ratio must not be lower than
        # 1 when circular dots are used.
        # (FIXME: check it.)
        result = result.scale(config.aspect_ratio, 1)

        # Update the top and bottom edge to take the vertical
        # compression factor into account.
        result.bottom = result.bottom * config.vertcompr
        result.top = (result.top - 1) * config.vertcompr + 1

        # Convert each integer-in-float of this box' boundaries into
        # an actual integer.
        result = result.integerise_softly

        # We're done with this character's bbox.
        return result.freeze
      else
        # No, it's a blank char.
        return Bounding_Box::new(0, 0, 0, 0).freeze
      end
    end

    # Return a string containing a PostScript string literal or array
    # literal of this glyph's column data.
    def ps_columns
      if splotch < 0x100 then
        return "<#{map{|c| sprintf '%02x', c}.join ' '}>"
      else
        return "[#{map{|c| c.to_s}.join ' '}]"
      end
    end
  end

  class Pixel_Font_Litter
    # Given scanlines of a 8x8 glyph (with msb left) as integers in an
    # Array or bytes in a String, determine the glyph's columns and
    # return them in form of a Pixel_Glyph instance.
    def transpose_8x8_glyph lines
      glyph = Pixel_Glyph::new
      (0 .. 7).to_a.reverse_each do |x|
        column = 0
        (0 .. 7).each do |y|
          column <<= 1
          column |= (lines[y] >> x) & 1
        end
        glyph.push column
      end
      glyph.freeze
      return glyph
    end
    private :transpose_8x8_glyph

    def parse_charcode_clause s
      results = []
      s.strip.split(/\s*,\s*/).each do |part|
        if part =~ /\A([\da-f]+)\Z/i then
          results.push $1.hex
        elsif part =~ /\A([\da-f]+)\s*\.\.\s*([\da-f]+)\Z/i then
          first = $1.hex
          last = $2.hex
          raise 'Charcodes out of order' unless first < last
          results += (first .. last).to_a
        else
          raise "Unparseable charcode clause #{s.inspect}"
        end
      end
      return results
    end

    # Loads font from the given pxf file and includees.  Does not
    # complete the loading -- the caller will need to invoke any final
    # handlers explicitly when done.
    def parse_pxf_resource filename, nesting_countdown = 3
      # Note that having a keyword that could be interpreted as a
      # hex number would be problematic due to the inline font
      # column data notation.
      #
      # Note that the handlers access non-public slots in the
      # instance, so these slots need to be in scope.
      keyword_handlers = {}

      keyword_handlers['baseline'] = proc do |args|
        unless args =~ /^(\d+)$/i then
          raise "baseline requires an integer argument"
        end
        if @baseline_declared then
          raise "Duplicate baseline declaration"
        end
        @plain_variant.baseline_delta = $1.to_i
        @baseline_declared = true
      end

      keyword_handlers['cell-width'] = proc do |args|
        unless args =~ /^(\d+)$/i then
          raise "cell-width requires an integer argument"
        end
        if @plain_variant.cell_width then
          raise "Duplicate cell width declaration"
        end
        @plain_variant.cell_width = $1.to_i
      end

      keyword_handlers['cell-height'] = proc do |args|
        unless args =~ /^(\d+)$/i then
          raise "cell-height requires an integer argument"
        end
        if @plain_variant.cell_height then
          raise "Duplicate cell height declaration"
        end
        @plain_variant.cell_height = $1.to_i
      end

      keyword_handlers['include'] = proc do |args|
        unless args =~ /^([\w.-]+)$/i then
          raise "include requires a filename argument"
        end
        if nesting_countdown > 0 then
          parse_pxf_resource $1, nesting_countdown - 1
        else
          raise "Inclusion nesting too deep"
        end
      end

      keyword_handlers['charset'] = proc do |args|
        unless args =~ /^([\w.-]+)?$/i then
          raise "charset only permits a filename argument"
        end
        raise "Duplicate charset declaration" if @charset_filename
        filename, new_exceptions = $1
        @charset_filename = filename
        @charset = Charset::load filename
      end

      keyword_handlers['variant-bit'] = proc do |args|
        unless args =~ /^(\w+)\s+(.*)$/ then
          raise "variant-bit requires a name argument and a list " +
              "of font configuration items"
        end
        variant_bit_name = $1
        config_items = $2.split /\s*,\s*/

        if @varbit_names.include? variant_bit_name then
          raise "Duplicate variant bit name #{variant_bit_name}"
        end

        # In order to catch syntax errors early, we'll parse the
        # configuration items here, but we'll use a dummy
        # configuration.  We can't use an actual configuration until
        # we're generating the configuration for a specific
        # combination of the variant bits.
        dummy_config = Font_Config::new
        config_items.each do |decl|
          unless dummy_config.parse decl then
            raise "Unparseable configuration item #{decl.inspect}"
          end
        end

        @varbit_names.push variant_bit_name
        @varbit_extra_decl.push config_items
      end

      keyword_handlers['variant-bit-exclusion'] = proc do |args|
        unless args =~ /^(\w+(\s*,\s*\w+)*)$/ then
          raise "variant-bit-exclusion requires a list of " +
              "excluded variant bit names"
        end
        varbit_names = $1.split /\s*,\s*/
        @varbit_exclusions.push parse_varbit_names(varbit_names)
      end

      keyword_handlers['binary-8x8'] = proc do |args|
        # Extract optional filename clause, if any.
        resname = @name + '.8x8'
        args = args.sub(/^([\w-]+\.8x8)\b\s*/i) do
          resname = $1
          ''
        end

        # Extract optional columns clause, if any.
        colrange = 0 .. 7
        args = args.sub(/^columns\s+(\d)\s*\.\.\s*(\d)\b\s*/i) do
          first_column, last_column = $1.to_i, $2.to_i
          unless first_column <= last_column then
            raise 'Column numbers out of order'
          end
          if last_column >= 8 then
            raise 'Column number too large'
          end
          colrange = first_column .. last_column
          ''
        end

        # Extract optional charcodes clause, if any.
        charcodes = []
        args = args.sub(/^charcodes\s+([^\(\);]*)$/i) do
          charcodes = parse_charcode_clause $1
          ''
        end

        # That is all.
        unless args.empty? then
          raise "invalid binary-8x8 directive #{line.inspect}"
        end

        # Load the binary.  Each character is represented by eight
        # 8-bit scanlines, with top to bottom, with the msb being
        # left.  If |colrange| is given, the zeroth column is the
        # leftmost.
        charcodes = charcodes.to_a
        data = RES[resname].unpack 'C*'
        unless data.length == charcodes.length * 8 then
          raise "Invalid binary resource #{resname}"
        end
        charcodes.each_with_index do |charcode, i|
          if @pixel_data.has_key? charcode then
            raise Duplicate_Glyph::new(charcode)
          end
          rows = data[i * 8 ... (i + 1) * 8]
          cols = transpose_8x8_glyph rows
          @pixel_data[charcode] = Pixel_Glyph::new(cols[colrange])
        end
      end

      RES[filename].each_line do |line|
        line.strip!
        line.gsub! /\s*#.*$/, ''
        next if line.empty?
        keyword, args = line.split /\s+/, 2
        keyword.downcase!
        args ||= ''
        if keyword_handlers.has_key? keyword then
          keyword_handlers[keyword].call args
        elsif @plain_variant.config.parse line then
          # the parsing is done; nothing further to do with this line
        else
          words = line.split /\s+/
          words.each do |w|
            unless w =~ /^[\da-f]+$/i then
              raise "Invalid font data line #{line.inspect}"
            end
          end
          words = words.map{|w| w.hex}
          if @pixel_data.has_key? words[0] then
            raise Duplicate_Glyph::new(words[0])
          end
          @pixel_data[words[0]] = Pixel_Glyph::new words[1 .. -1]
        end
      end
      if @charset_filename.nil? then
        # load the implicit font-specific charset or raise an
        # exception if there isn't any
        @charset_filename = @name + '.cs'
        @charset = Pixitie::Charset::load @charset_filename
      end
      return
    end
    private :parse_pxf_resource

    # Iterate over all predefined font variants in this litter.
    def each_variant
      (0 ... 1 << @varbit_names.length).each do |bit_pattern|
        if variant_bit_pattern_valid? bit_pattern then
          yield get_variant_font(bit_pattern)
        end
      end
      return
    end

    # Given a list of variant bit names, return the matching
    # bit_pattern.  Raise an exception if some of the variant bit
    # names is unknown for this litter.  Count duplicate bit names
    # only once.  No checking whether the resulting bit pattern
    # violates any exclusion constraint.
    def parse_varbit_names bit_names
      bit_pattern = 0
      bit_names.each do |name|
        bit_index = @varbit_names.index(name)
        raise "Unknown variant bit name #{name}" if bit_index.nil?
        bit_pattern |= 1 << bit_index
      end
      return bit_pattern
    end
  end

  Pixel_Font_Variant = Struct::new(:name, :litter, :config,
      :pixel_data, :cell_width, :cell_height, :baseline_delta)

  class Pixel_Font_Variant
    # Check whether this font variant's pixel data satisfies the cell
    # width and height constraints, if either has been set.  Raise an
    # exception if that's not the case.
    def check_cell_size_constraints
      if cell_height or cell_width then
        mask = cell_height && -(1 << cell_height)
        pixel_data.each_pair do |native_charcode, columns|
          if cell_width and columns.length != cell_width then
            raise "cell-width declaration does not match pixel data"
          end
          if cell_height and not columns.all?{|c| c & mask == 0} then
            raise "cell-height declaration does not match pixel data"
          end
        end
        return
      end
    end

    # Calculate logical OR over all the columns of all the glyphs in
    # this font variant.
    def splotch
      result = 0
      pixel_data.values.each do |glyph|
        result |= glyph.splotch
      end
      return result
    end

    def max_column_bits
      return splotch.bit_count
    end

    # Determine the maximal number of columns used by any glyph in
    # this font variant.
    def max_column_count
      return pixel_data.values.map{|glyph| glyph.length}.max
    end

    # Given a full name of a pixel font, load it.
    def Pixel_Font_Variant::load full_name
      litter_name, *variant_bit_names = full_name.split('.', -1)
      litter = Pixitie::Pixel_Font_Litter::new(litter_name)
      pattern = litter.parse_varbit_names variant_bit_names
      unless litter.variant_bit_pattern_valid? pattern then
        raise 'Invalid combination of variant bits'
      end
      return litter.get_variant_font(pattern)
    end

    # Outputs the font as a PostScript Type 3 font definition.  Does
    # not generate any DSC entries.
    def construct_ps_t3_font port
      port.puts "0 dict begin"

      port.puts "/FontType 3 def"
      port.puts "/LanguageLevel 2 def"
      port.puts "/FontMatrix [0.1 0 0 0.1 0 0] def"
      port.puts "/FontBBox [#{font_bounding_box.to_postscript}] def"

      litter.construct_ps_t3_font_encoding_definition port

      # In fonts drawn dot-by-dot, we'll use this PostScript procedure
      # to actually draw the dot.  It will be given the dot's integral
      # co-ordinates as parameters, with y=0 being the dot row
      # immediately above the baseline.
      if config.drawing_type == :rectangular_dots then
        define_ps_dot_rectangularly port
      elsif config.drawing_type == :circular_dots then
        define_ps_dot_circularly port
      end

      # Let's determine if all columns in this font's glyphs fit into
      # signed tetra integers.
      all_font_columns_fit_in_signed_tetras = max_column_bits <= 31

      # Generate character-specific font data
      if all_font_columns_fit_in_signed_tetras then
        # In compact fonts, we can use the more memory-efficient
        # bitmap-based glyph construction mechanism, so we'll define
        # |CharMetrics| and |CharColumns|
        port.printf "/CharMetrics %i array def\n",
            litter.charcodes.max + 1
        port.printf "/CharColumns %i array def\n",
            litter.charcodes.max + 1
        litter.charcodes.each do |charcode|
          cm = calculate_character_metrics charcode
          port.print "CharMetrics #{sprintf '16#%02x', charcode} {"
          port.print "#{cm.width} 0 #{cm.bbox.to_postscript}"
          port.puts "} put"
          # If the font's height does not exceed 8 pixels,
          # |CharColumns| holds strings, otherwise it holds arrays.
          # Note that both are queried exactly the same way in
          # PostScript -- using |get|, which returns an integer.
          port.printf 'CharColumns 16#%02x ', charcode
          port.print pixel_data[charcode].ps_columns
          port.puts " put"
        end
      else
        # In non-compact fonts, we'll have to paint each point in
        # separately, so we'll define |CharProcs|
        port.puts "/CharProcs #{litter.charcodes.max + 1} array def"
        litter.charcodes.each do |charcode|
          cm = calculate_character_metrics charcode
          port.printf "CharProcs 16#%02x {\n", charcode
          port.printf "  %f 0 %s setcachedevice\n",
              cm.width, cm.bbox.to_postscript
          pixel_data[charcode].each_with_index do |bits, dx|
            unless bits.zero? then
              dy = -self.baseline_delta
              until bits.zero? do
                if bits & 1 != 0 then
                  port.puts "  #{dx} #{dy} //dot exec"
                end
                bits >>= 1
                dy += 1
              end
            end
          end
          port.puts "} put"
        end
      end

      port.puts "/BuildChar {" # ( font-dictionary charcode )
      # initialise the graphics context
      port.puts "  [] 0 setdash"
      port.puts "  2 setlinecap"
      port.puts "  0 setlinejoin"
      port.puts "  10 setmiterlimit"
      port.puts "  0.1 setlinewidth"
      # draw the character
      if all_font_columns_fit_in_signed_tetras then
        port.puts "  exch dup /CharMetrics get 2 index get exec"
        port.puts "    setcachedevice"
        port.puts "  /CharColumns get exch get"
        port.puts "  dup length 0 exch 1 exch 1 sub"
        # loop through columns, left to right
        port.puts "  {"
        # ( columns dx )
        port.puts "    #{-self.baseline_delta} 2 index 2 index get"
        # loop through pixels in this column, bottom to top
        port.puts "    {"
        # ( columns dx dy column )
        port.puts "      dup 0 eq {exit} if"
        port.puts "      dup 1 and 0 ne {"
        port.puts "        2 index 2 index //dot exec"
        port.puts "      } if"
        port.puts "      -1 bitshift exch 1 add exch"
        port.puts "    } loop"
        port.puts "    pop pop pop"
        port.puts "  } for"
        port.puts "  pop"
      else
        port.puts "  exch /CharProcs get exch get exec"
      end
      port.puts "} def"

      port.puts "currentdict end"
      port.puts "/#{self.name} exch definefont pop"
      return
    end

    # Calculate the bounding box and width of the specified character
    # and returns them in form of a Character_Metrics instance.  The
    # base unit is the pixel grid's vertical unit in a normal font,
    # which in PostScript fonts is 1bp.
    #
    # (Note that the PostScript fonts we generate are normally used at
    # size 10, so the dimensions actually used by our PostScript font
    # program are one tenth the size calculated here.  This scale-down
    # is implicit (that is, represented by the |FontMatrix|) in
    # PostScript code but explicit in metrics dumps.
    def calculate_character_metrics native_charcode
      glyph = pixel_data[native_charcode]
      width = glyph.length * config.aspect_ratio * config.horcompr
      bbox = glyph.bbox(config, baseline_delta)
      return Character_Metrics::new(width, bbox)
    end

    # Calculate the font's bounding box, as used by PostScript.  The
    # base unit is bp, as in |calculate_character_metrics|.
    def font_bounding_box
      font_bbox = Bounding_Box::new(0, 0, 0, 0)
      litter.charcodes.each do |native_charcode|
        cm = calculate_character_metrics native_charcode
        font_bbox = font_bbox.union cm.bbox
      end
      return font_bbox.freeze
    end

    private

    # Output PostScript code that defines |dot| to draw a rectangle
    # in accordance with this font variant's configuration.
    def define_ps_dot_rectangularly port
      port.puts "/dot {"
      port.puts "  newpath"
      if config.horcompr != 1 or config.aspect_ratio != 1 then
        port.puts "  exch"
        if config.horcompr != 1 then
          port.puts "  #{config.horcompr} mul"
        end
        if config.aspect_ratio != 1 then
          port.puts "  #{config.aspect_ratio} mul"
        end
        port.puts "  exch"
      end
      if config.vertcompr != 1 then
        port.puts "  #{config.vertcompr} mul"
      end
      port.puts "  moveto"
      port.puts "  #{config.interpixel_blank / 2.0} dup rmoveto"
      dot_width = config.aspect_ratio - config.interpixel_blank
      dot_height = 1 - config.interpixel_blank
      port.puts "  #{dot_width} 0 rlineto"
      port.puts "  0 #{dot_height} rlineto"
      port.puts "  #{- dot_width} 0 rlineto"
      port.puts "  closepath fill"
      port.puts "} def"
      return
    end

    # Outputs PostScript code that defines |dot| to draw a circle in
    # accordance with this font variant's configuration.
    def define_ps_dot_circularly port
      port.puts "/dot-radius #{config.dot_radius} def"
      port.puts "/dot {"
      port.puts "  newpath"
      if config.horcompr != 1 then
        port.puts "  exch #{config.horcompr} mul exch"
      end
      if config.vertcompr != 1 then
        port.puts "  #{config.vertcompr} mul"
      end
      # Determine the dot's centre.
      port.puts "  exch 0.5 add"
      if config.aspect_ratio != 1 then
        port.puts "  #{config.aspect_ratio} mul"
      end
      port.puts "  exch 0.5 add"
      # Draw the dot using |arc|.
      port.puts "  //dot-radius 0 360 arc"
      port.puts "  closepath fill"
      port.puts "} def"
      return
    end
  end # Pixel_Font_Variant

#### General PS utilities

  # Representation of bounding box
  Bounding_Box = Struct::new(:left, :bottom, :right, :top)

  class Bounding_Box
    # Return a bounding box with the same size and location as this
    # one, but with these co-ordinate values that are integers in
    # floating point form replaced with actual integers.
    def integerise_softly
      new_left = left.round == left ? left.round : left
      new_bottom = bottom.round == bottom ? bottom.round : bottom
      new_right = right.round == right ? right.round : right
      new_top = top.round == top ? top.round : top
      return Bounding_Box::new new_left, new_bottom,
          new_right, new_top
    end

    # Construct and return a new bounding box derived from shifting
    # all sides of this bounding box by the given vector.
    def shift dx, dy
      return Bounding_Box::new(left + dx, bottom + dy,
          right + dx, top + dy)
    end

    # Construct and return a new bounding box derived from multiplying
    # all co-ordinates of this bounding box by the given scale
    # factors.
    def scale xf, yf
      return Bounding_Box::new(left * xf, bottom * yf,
          right * xf, top * yf)
    end

    # Construct and return the smallest bounding box that contains
    # both this bounding box and the given other bounding box.  If
    # given |nil| instead, will just return this bounding box.
    def union that
      return self if that.nil? or that.empty?
      return that if self.empty?
      return Bounding_Box::new(
          [self.left, that.left].min, [self.bottom, that.bottom].min,
          [self.right, that.right].max, [self.top, that.top].max)
    end

    # Check if this bounding box has zero area.
    def empty?
      return left == right || bottom == top
    end

    # Return a string containing the bounding box dimensions in the
    # order used by PostScript separated by whitespace, ready for
    # embedding into PostScript code.
    def to_postscript
      return "#{left} #{bottom} #{right} #{top}"
    end
  end

#### The PXF->PS conversion

  Character_Metrics = Struct::new(:width, :bbox)

  class Pixel_Font_Litter
    def construct_ps_t3_font_encoding_definition port
      port.puts "/Encoding ["
      (0x00 .. charcodes.max).each do |i|
        if has_char? i then
          port.puts "  /#{charset.ps_charname i}"
        else
          port.puts "  /.notdef % #{sprintf '%02X', i}"
        end
      end
      port.puts "] def"
      return
    end
  end

#### The PSPrinter mechanism

  # Dimensions of a rectangle.  The base unit is bp, as usual in
  # PostScript.
  class Rectangle
    attr_reader :width
    attr_reader :height

    def initialize width, height
       super()
       @width, @height = width, height
       freeze
       return
    end

    def round
      return Rectangle::new(width.round, height.round)
    end
  end

  # Dimensions of a TeX-style box.  The base unit is bp.
  Box_Dimen = Struct::new(:width, :height, :depth)

  class Box_Dimen
    # Scale the given box dimensions by the given factor.
    def * factor
      return Box_Dimen::new(width * factor, height * factor,
          depth * factor)
    end

    # Given this and that Box_Dimen, return a Box_Dimen of the two
    # boxes placed next to each other on the same baseline.
    def + other
      return Box_Dimen::new(
          self.width + other.width,
          [self.height, other.height].max,
          [self.depth, other.depth].max)
    end
  end

#### Parsing the Adobe Glyph List

  $cached_adobe_glyph_list = nil

  # Return the Adobe Glyph List rows for characters that can be
  # represented with a single Unicode code point as {name =>
  # unicode_value}.  Ignores other characters.  (This is sufficient
  # for all of the 14 Adobe Core Fonts except Zapf Dingbats.)
  def Pixitie::get_adobe_glyph_list
    if $cached_adobe_glyph_list.nil? then
      result = {}
      lineno = 0
      fail = proc do |msg|
        raise "glyphlist.txt:#{lineno}: #{msg}"
      end
      RES['glyphlist.txt'].each_line do |line|
        line.strip!
        lineno += 1
        next if line.empty? or line[0] == ?#
        unless line =~ /^(\w+);([\da-f]{4})(\s+[\da-f]{4})*$/i then
          fail.call "parse error"
        end
        name, unicode, extra_unicode = $1, $2.hex, $3
        if result.has_key? name then
          fail.call "duplicate entry for #{name.inspect}"
        end
        next if extra_unicode
        result[name.freeze] = unicode
      end
      result.freeze
      $cached_adobe_glyph_list = result
    end
    return $cached_adobe_glyph_list
  end

  # A Font_Program instance encapsulates a font as seen from the
  # typesetter's side.  There are two implementations:
  # Pixel_Font_Program instances encapsulate font variants derived
  # from pxf files, and AFM_Font_Program instances encapsulate
  # external fonts for which Pixitie only has metrics data.  Most
  # importantly, this is useful for embedding pieces of text typeset
  # with the PostScript builtin fonts.
  class Font_Program
    attr_reader :postscript_code
    attr_reader :max_char_width
    attr_reader :charset

    def initialize
      super()
      @char_metrics = {} # native-charcode => Box_Dimen
      return
    end

    def get_char_dimen code
      return @char_metrics[code]
    end

    def min_charcode
      return @char_metrics.keys.min
    end

    def max_charcode
      return @char_metrics.keys.max
    end

    def has_char? code
      return @char_metrics.has_key?(code)
    end

    # Return the canonical name of the font.  This is mainly useful
    # because if this font is a variant pixel font, the variant flags
    # are ordered deterministically in the canonical name.
    def name
      raise 'Abstract method called'
    end
  end # Font_Program

  class Pixel_Font_Program < Pixitie::Font_Program
    attr_reader :name

    def initialize font_name
      super()

      ## Data acquisition

      pfv = Pixel_Font_Variant::load font_name
      @name = pfv.name

      # Construct the PostScript code
      sport = StringIO::new
      pfv.construct_ps_t3_font sport
      @postscript_code = sport.string.strip

      # Convert the metrics data
      pfv.litter.charcodes.each do |native_charcode|
        cm = pfv.calculate_character_metrics native_charcode
        # cm is a Character_Metrics -- a width and a bbox of a
        # character scaled by 10.  We're going to need a Box_Dimen
        # of an unscaled character instead.
        bd = Box_Dimen::new(cm.width * 0.1,
            cm.bbox.top * 0.1, -cm.bbox.bottom * 0.1)
        bd.freeze
        @char_metrics[native_charcode] = bd
      end

      # Bring over the charset
      @charset = pfv.litter.charset

      ## Determine the largest character width used in this font

      @max_char_width = 0
      @char_metrics.each_pair do |native_charcode, char_dimen|
        @max_char_width = [@max_char_width, char_dimen.width].max
      end

      return
    end

    # PXF fonts do not have unnumbered named characters.
    def get_char_name code
      return nil
    end
  end

  class AFM_Font_Program < Pixitie::Font_Program
    attr_reader :name

    # Instead of font_name, a Pixel_Font_Variant may be given.
    # Support for this is incomplete yet.
    def initialize font_name
      super()
      @name = name

      ## Data acquisition

      adobe_char_names = Pixitie::get_adobe_glyph_list
      @charset = Pixitie::Charset::new
      synthetic_charcode_counter = 0x10_0000
      @char_metrics = {}
      @charname = {}
      RES[font_name + '.afm'].each_line do |line|
        line.strip!
        case line.split.first
        when 'StartFontMetrics', 'Comment', 'FontName', 'FullName',
            'FamilyName', 'Weight', 'ItalicAngle', 'IsFixedPitch',
            'CharacterSet', 'FontBBox', 'UnderlinePosition',
            'UnderlineThickness', 'Version', 'Notice',
            'EncodingScheme', 'CapHeight', 'XHeight', 'Ascender',
            'Descender', 'StdHW', 'StdVW', 'StartCharMetrics',
            'EndCharMetrics', 'StartKernData', 'StartKernPairs',
            'KPX', 'EndKernPairs', 'EndKernData', 'EndFontMetrics'
            then
          # ignore
        when 'C' then
          field_res = [
            /C\s+([+-]?\d+)/,   # charcode
            /WX\s+([+-]?\d+)/,  # width
            /N\s+(\w+)/,        # charname
            /B\s+([+-]?\d+)\s+([+-]?\d+)\s+([+-]?\d+)\s+([+-]?\d+)/,
                # left, bottom, right, top
            /(?:L\s+\w+\s+\w+\s*;\s*)*/,
          ]
          unless line =~ /^#{field_res.join('\\s*;\\s*')}$/ then
            raise "Unparseable char metric data line #{line.inspect}"
          end
          charcode, width, name, left, bottom, right, top =
              $1.to_i, $2.to_i, $3, $4.to_i, $5.to_i, $6.to_i, $7.to_i
          if charcode == -1 then
            charcode = synthetic_charcode_counter
            synthetic_charcode_counter += 1
          end
          if @char_metrics.has_key? charcode then
            raise sprintf("Duplicate metric data line for char $%02X",
                charcode)
          end
          @char_metrics[charcode] =
              Box_Dimen::new(width, top, -bottom) * 0.001
          unicode = adobe_char_names[name]
          @charname[charcode] = name
          if unicode then
            @charset.set_encoding unicode, charcode
            @charset.set_decoding charcode, unicode
          end
        else
          raise "Unparseable AFM line #{line.inspect}"
        end
      end

      @postscript_code = '(extern)'

      if RES.have? font_name + '.cs' then
        @charset = Pixitie::Charset::load font_name + '.cs'
      end

      ## Determine the largest character width used in this font

      @max_char_width = 0
      @char_metrics.each_pair do |native_charcode, char_dimen|
        @max_char_width = [@max_char_width, char_dimen.width].max
      end

      return
    end

    def get_char_name code
      return @charname[code]
    end
  end

#### Lengths and paper sizes

  UNITS = {
    'bp' => 1,                 # PostScript point
    'in' => 72,                # international inch
    'cm' => 72 / 2.54,         # centimetre
    'mm' => 72 / 25.4,         # millimetre
    'um' => 72 / 25.4 / 1000,  # micrometre
  }
  UNITS.freeze
  LENGTH_RE = /\A(\d+(?:\.\d+)?)\s*(#{UNITS.keys.sort.join '|'})\Z/

  # Parses a length given as a string containing a number and a unit.
  # Returns the length, as expressed in PostScript points.
  def Pixitie::parse_length s
    unless s =~ LENGTH_RE then
      raise "Unparseable length #{s.inspect}"
    end
    return Float($1) * UNITS[$2]
  end

  def Pixitie::parse_rectangle spec
    if spec =~ /\*/ then
      width, height = $`.strip, $'.strip
      rect = Rectangle::new(parse_length(width), parse_length(height))
      return rect
    else
      raise "Invalid rectangle specification: #{spec.inspect}"
    end
  end

  PAPER_SIZES = {
    'A3' => parse_rectangle('297 mm * 420 mm'),
    'A4' => parse_rectangle('210 mm * 297 mm'),
    'A5' => parse_rectangle('148 mm * 210 mm'),
    'B5' => parse_rectangle('176 mm * 250 mm'),
    'Kindle' => parse_rectangle('3.6 in * 4.8 in'),
    'PA4' => parse_rectangle('210 mm * 280 mm'),
    'Letter' => parse_rectangle('8.5 in * 11 in'),
    'HalfLetter' => parse_rectangle('5.5 in * 8.5 in'),
    'Legal' => parse_rectangle('8.5 in * 14 in'),
    'CDCover' => parse_rectangle('12 cm * 12 cm'),
    'DVDCover' => parse_rectangle('129 mm * 184 mm'),
  }
  PAPER_SIZES.values.each{|v| v.freeze}
  PAPER_SIZES.freeze

#### Print jobs

  class Print_Job
    attr_reader :margin
    attr_reader :page_body_size
    attr_reader :typesetter

    def initialize page_size_name = 'A4',
        margin = Pixitie::parse_length('15 mm')
      super()
      @margin = margin

      if page_size_name =~ /\*/ then
        @page_size = parse_rectangle page_size_name
        @page_size_name = page_size_name.gsub ' ', ''
      else
        @page_size = PAPER_SIZES[page_size_name]
        if @page_size.nil? then
          raise "Unknown paper size #{page_size_name.inspect}"
        end
        @page_size_name = page_size_name
      end
      @page_size = @page_size.round
      @page_body_size = Rectangle::new(@page_size.width - @margin * 2,
          @page_size.height - @margin * 2)

      @pages = [] # [[page-name, postscript-code], ...]
      @font_load_order = []
      @font_programs = {}

      @typesetter = Typesetter::new(self)

      return
    end

    # Retrieve a Font_Program instance corresponding to the given
    # name, which may contain flags as needed.
    def get_font_metadata font_name
      if font_name.empty? then
        raise "invalid font name #{font_name.inspect}"
      end

      # FIXME: Currently, if the same font is asked twice but with
      # different flag ordering, we load it twice.  It would be
      # slightly more efficient to canonicalise the flag order before
      # cache lookup.
      if @font_programs.has_key? font_name then
        return @font_programs[font_name]
      else
        if RES.have? font_name.split('.', -1).first + '.pxf' then
          # It's a pixel font.
          font_metadata = Pixitie::Pixel_Font_Program::new(font_name)
        elsif RES.have? font_name + '.afm' then
          font_metadata = Pixitie::AFM_Font_Program::new(font_name)
        else
          raise "#{font_name}: no .pxf or .afm font resource found"
        end
        @font_load_order.push font_metadata
        @font_programs[font_metadata.name] = font_metadata
        if font_name != font_metadata.name then
          @font_programs[font_name] = font_metadata
        end
        return font_metadata
      end
    end

    # Add a completed page to the print job.  The |postscript_code|
    # will have to take care of all aspects of page construction,
    # including the initial setup of fonts and colours, but not invoke
    # |showpage|.
    def add_page page_name, postscript_code
      @pages.push [page_name, postscript_code]
      return
    end

    # Dump the whole print job, as PostScript, into the given port.
    def dump_to_port port
      port.puts '%!PS-Adobe-3.0'
      port.puts "%%Pages: #{@pages.length}"
      port.puts "%%PageOrder: Ascend"
      port.puts "%%DocumentPaperSizes: #{@page_size_name}"
      port.printf "%%%%DocumentMedia: %s %i %i 0 () ()\n",
          @page_size_name, @page_size.width, @page_size.height
      port.puts "%%BeginDefaults"
      port.puts "%%PageMedia: #{@page_size_name}"
      port.puts "%%EndDefaults"
      port.puts "%%Orientation: Portrait"
      @font_load_order.each_with_index do |font_program, i|
        if i == 0 then
          port.print '%%DocumentSuppliedResources: '
        else
          port.print '%+ '
        end
        port.puts "font #{font_program.name}"
      end
      port.puts "%%EndComments"
      port.puts
      unless @font_load_order.empty? then
        port.puts "%%BeginProlog"
        @font_load_order.each_with_index do |font_program, i|
          port.puts unless i == 0
          port.puts "%%BeginResource: font #{font_program.name}"
          port.puts font_program.postscript_code
          port.puts "%%EndResource"
        end
        port.puts "%%EndProlog"
        port.puts
      end
      port.puts "%%BeginSetup"
      port.puts "%%PaperSize: #{@page_size_name}"
      port.puts "%%BeginFeature: *PageSize #{@page_size_name}"
      port.printf "<< /PageSize [%i %i] >> setpagedevice\n",
          @page_size.width, @page_size.height
      port.puts "%%EndFeature"
      port.puts "%%EndSetup"
      port.puts
      @pages.each_with_index do |(page_name, postscript_code), i|
        port.puts "%%Page: (#{page_name.ps_escape}) #{i + 1}"
        port.puts postscript_code.rstrip
        port.puts "showpage"
        port.puts
      end
      port.puts "%%Trailer"
      port.puts "%%EOF"
      return
    end

    # Dumps the whole print job, as PostScript, into the given file.
    def dump_to_file filename
      open filename, 'w' do |port|
        dump_to_port port
      end
      return
    end
  end

#### Typesetter

  class Typesetter
    attr_accessor :min_line_spacing

    Typeset_State = Struct::new(:font_program, :font_size, :colour)

    def initialize print_job
      super()
      @print_job = print_job
      @page_body_size = print_job.page_body_size
      @page_start_state = Typeset_State::new(nil, 10, '0 setgray')
      @line_start_state = Typeset_State::new(nil, 10, '0 setgray')
      @curstate = Typeset_State::new(nil, 10, '0 setgray')
      @curpage_ps = []

      @curline_dimen = Box_Dimen::new(0, 0, 0)
      @curline_ps = []
      @curpageno = 1

      @min_line_spacing = 12
      @last_line_dimen = nil # there was no last_line yet
      @curpage_height = 0
          # from top of the page until last baseline

      @curstr = nil

      return
    end

    def _switch_colour new_colour
      _flush_current_string
      unless @curstate.colour == new_colour then
        @curline_ps.push new_colour
        @curstate.colour = new_colour
      end
      return
    end
    private :_switch_colour

    def switch_grey intensity
      _switch_colour "#{intensity} setgray"
      return
    end

    def switch_rgb red, green, blue
      _switch_colour "#{red} #{green} #{blue} setrgbcolor"
      return
    end

    def switch_cmyk cyan, magenta, yellow, black
      _switch_colour "#{cyan} #{magenta} #{yellow} #{black} " +
          "setrgbcolor"
      return
    end

    def switch_font name, size = @curstate.font_size
      raise 'Type mismatch' unless size.is_a? Fixnum

      # Get the new font program
      new_font_program = @print_job.get_font_metadata(name)
      # Note that new_font_program.name is canonicalised whereas the
      # name we got from our caller may not be.

      unless @curstate.font_program and
          @curstate.font_program.name == new_font_program.name and
          @curstate.font_size == size then
        _flush_current_string
        @curline_ps.push sprintf("/%s %i selectfont",
            new_font_program.name, size)
        @curstate.font_program = new_font_program
        @curstate.font_size = size
      end
      return
    end

    # Typeset a character given by its code in the font's native
    # charset.
    def typeset_native_char code
      raise 'Type mismatch' unless code.is_a? Fixnum
      raise 'No current font' if @curstate.font_program.nil?
      char_dimen = @curstate.font_program.get_char_dimen(code)
      if char_dimen.nil? then
        raise sprintf("No char $%X in font %s",
            code, @curstate.font_program.name)
      end
      char_dimen *= @curstate.font_size
      if @curline_dimen.width + char_dimen.width >
          @page_body_size.width then
        newline
        # Now, the current line should be empty.
      end
      if (0x00 .. 0xFF).include? code then
        @curstr ||= ''
        @curstr << [code].pack('U*')
      else
        _flush_current_string
        char_name = @curstate.font_program.get_char_name(code)
        if char_name.nil? then
          raise sprintf("Character $%02X has no name in font %s",
              code, @curstate.font_program.name)
        end
        @curline_ps.push "/#{char_name} glyphshow"
      end
      @curline_dimen += char_dimen
      return
    end

    # Given a native charcode and a width, typeset the char padded on
    # both left and right to center it within the given width.
    def typeset_fixed_width_centered_native_char code, width
      raise 'Type mismatch' unless code.is_a? Fixnum
      raise 'No current font' if @curstate.font_program.nil?
      char_dimen = @curstate.font_program.get_char_dimen(code)
      if char_dimen.nil? then
        raise sprintf("No char $%X in font %s",
            code, @curstate.font_program.name)
      end
      char_dimen *= @curstate.font_size
      padding = (width - char_dimen.width) / 2.0
      if @curline_dimen.width + width >
          @page_body_size.width then
        newline
        # Now, the current line should be empty.
      end
      _move_right padding
      typeset_native_char code
      _move_right padding
      return
    end

    def typeset_fixed_width_centered_chars chars, width
      chars.each_byte do |code|
        typeset_fixed_width_centered_native_char code, width
      end
      return
    end

    # Does not handle charwrap or wordwrap.  Currently only for
    # internal use.
    def _move_right amount
      if amount != 0 then
        _flush_current_string
        @curline_ps.push "#{amount} 0 rmoveto"
        @curline_dimen.width += amount
      end
      return
    end

    # Typeset a string given in the font's native encoding, one char
    # per byte.
    def typeset_native_string s
      s.each_byte do |b|
        typeset_native_char b
      end
      return
    end

    # Typeset a character given by its Unicode value.  Error if the
    # currently selected font does not contain a glyph for this
    # Unicode character.
    def typeset_unicode_char unicode
      raise 'Type mismatch' unless unicode.is_a? Fixnum
      raise 'No current font' if @curstate.font_program.nil?
      charcode = @curstate.font_program.charset.encode(unicode)
      if charcode.nil? then
        raise "Font #{@curstate.font_program.name} does not have " +
            "char #{sprintf 'U+%04X', unicode}"
      end
      typeset_native_char charcode
      return
    end

    # Typeset a string given in Latin-1.
    def typeset_latin1 s
      s.each_byte do |c|
        typeset_unicode_char c
      end
      return
    end

    # Typeset a string given in UTF-8.
    def typeset_utf8 s
      s.unpack('U*').each do |c|
        typeset_unicode_char c
      end
      return
    end

    def form_feed
      newline unless @curline_ps.empty?
      _flush_current_page
      return
    end

    def _flush_current_string
      if @curstr then
        @curline_ps.push "(#{@curstr.ps_escape}) show"
        @curstr = nil
      end
      return
    end
    private :_flush_current_string

    # Add content of the current line to the current page (changing
    # page before if it won't fit), then empty the current line in
    # anticipation of typesetting another line.
    def newline
      _flush_current_string
      if @last_line_dimen then
        linespace = [@last_line_dimen.depth + @curline_dimen.height,
            @min_line_spacing].max
        if @curpage_height + linespace + @curline_dimen.depth >
            @print_job.page_body_size.height then
          _flush_current_page
          linespace = nil
        end
      end
      if linespace then
        @curpage_ps.push sprintf("%f %f rmoveto",
            - @last_line_dimen.width, - linespace)
        @curpage_height += linespace
      else
        @curpage_ps.push sprintf("%f %f moveto",
            @print_job.margin,
            @print_job.margin + @print_job.page_body_size.height -
                @curline_dimen.height)
        # A new page starts.
        if @page_start_state.font_program then
          @curpage_ps.push sprintf("/%s %i selectfont",
              @page_start_state.font_program.name,
              @page_start_state.font_size)
        end
        @curpage_ps.push @page_start_state.colour
        @curpage_height = @curline_dimen.height
      end
      @curpage_ps.push *@curline_ps
      @curline_ps = []
      @last_line_dimen = @curline_dimen
      @curline_dimen = Box_Dimen::new(0, 0, 0)
      @line_start_state = @curstate.dup
      return
    end

    # Append content of the current page to the print job, then empty
    # the current page.  The current line will not be affected.
    def _flush_current_page
      @print_job.add_page @curpageno.to_s, @curpage_ps.join("\n")
      @curpage_ps = []
      @page_start_state = @line_start_state.dup
      @last_line_dimen = nil
      @curpageno += 1
      @curpage_height = 0
    end
    private :_flush_current_page
  end

#### Main entry

  def Pixitie::main
    begin
      $0 = 'pixitie' # For error messages

      $fontname = 'EpsonFX80'
      $font_size = 10
      $output_filename = nil
      $page_size_name = 'A4'
      $margin = parse_length '15 mm'
      $min_line_spacing = nil
      $obey_form_feed = false
      mode = method :main_vprinter

      GetoptLong::new(
        ['--font', '-f', GetoptLong::REQUIRED_ARGUMENT],
        ['--size', '-s', GetoptLong::REQUIRED_ARGUMENT],
        ['--paper', '-p', GetoptLong::REQUIRED_ARGUMENT],
        ['--margin', '-m', GetoptLong::REQUIRED_ARGUMENT],
        ['--min-line-spacing', '-L', GetoptLong::REQUIRED_ARGUMENT],
        ['--showcase', '-S', GetoptLong::NO_ARGUMENT],
        ['--output', '-o', GetoptLong::REQUIRED_ARGUMENT],
        ['--resources', '-R', GetoptLong::REQUIRED_ARGUMENT],
        ['--extract', '-x', GetoptLong::NO_ARGUMENT],
        ['--obey-form-feed', GetoptLong::NO_ARGUMENT],
        ['--list-builtins', GetoptLong::NO_ARGUMENT],
        ['--list-fonts', GetoptLong::NO_ARGUMENT],
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--version', GetoptLong::NO_ARGUMENT]
      ).each do |opt, arg|
        case opt
        when '--font' then $fontname = arg
        when '--size' then $font_size = arg.to_i
        when '--paper' then $page_size_name = arg
        when '--margin' then $margin = parse_length arg
        when '--min-line-spacing' then
          $min_line_spacing = parse_length arg
        when '--showcase' then mode = method :main_showcase
        when '--output' then $output_filename = arg
        when '--resources' then RES.dir = arg
        when '--extract' then mode = method :main_extract_builtins
        when '--obey-form-feed' then $obey_form_feed = true
        when '--list-builtins' then mode = method :main_list_builtins
        when '--list-fonts' then mode = method :main_list_fonts
        when '--help' then print USAGE; exit
        when '--version' then puts IDENT; exit
        else raise "Unknown option #{opt}"
        end
      end

      mode.call
    rescue SystemExit => e
      raise e
    rescue GetoptLong::InvalidOption => e
      # the error message has already been output to stdout
      exit 1
    rescue Exception => e
      $stderr.print "#$0: #{e}\n"
      exit 1
    end
  end

  def Pixitie::main_extract_builtins
    RES.dir = nil
    raise "no resources to --extract specified" if ARGV.empty?
    ARGV.each do |resname|
      data = RES[resname]
      open resname, File::WRONLY | File::CREAT | File::EXCL do |port|
        port.write data
      end
      puts resname
    end
    return
  end

  def Pixitie::main_list_builtins
    RES.show_builtin_list
    return
  end

  def Pixitie::main_list_fonts
    litter_count = 0
    variant_count = 0
    RES.list.each do |name|
      next unless name =~ /\.pxf\Z/i
      litter = Pixel_Font_Litter::new $`
      litter_count += 1
      puts litter.name
      litter.each_variant do |variant|
        variant_count += 1
        puts "    #{variant.name}"
      end
    end
    printf "Total of %i litter(s) with %i variant(s).\n",
        litter_count, variant_count
    puts
    return
  end

  def Pixitie::main_vprinter
    if ARGV.empty? then
      print USAGE; exit
    end

    $input_file_names = ARGV

    # Set up the virtual printer
    $job = Print_Job::new($page_size_name, $margin)
    $ts = $job.typesetter
    $ts.min_line_spacing = $min_line_spacing if $min_line_spacing
    $ts.switch_font $fontname, $font_size

    # Feed input to the virtual printer
    $input_file_names.each do |filename|
      open_input = proc do |filename, &thunk|
        if filename != '-' then
          open filename, 'r', &thunk
        else
          thunk.call $stdin
        end
      end

      open_input.call filename do |port|
        port.each_line do |line|
          line.chomp!
          line.unpack('U*').each do |c|
            if c == 0x000C and $obey_form_feed then
              $ts.form_feed
            else
              $ts.typeset_unicode_char c
            end
          end
          $ts.newline
        end
      end
    end

    $ts.form_feed

    # Output virtual printer's content
    if $output_filename and $output_filename != '-' then
      open $output_filename, 'w' do |port|
        $job.dump_to_port port
      end
    else
      $job.dump_to_port $stdout
    end

    return
  end

  def Pixitie::main_showcase
    # Set up the virtual printer
    $job = Print_Job::new($page_size_name, $margin)
    $ts = $job.typesetter
    $ts.min_line_spacing = $min_line_spacing if $min_line_spacing

    narrative_font = $job.get_font_metadata($fontname || 'EpsonFX80')

    if ARGV.empty? then
      print USAGE; exit
    end

    unicode_char_names = {}
    RES['abridged-unicode.txt'].each_line do |line|
      line.chomp!
      unicode, char_name = line.split ';', 2
      unicode = unicode.hex
      raise 'Invalid resource' if unicode_char_names.has_key? unicode
      unicode_char_names[unicode] = char_name
    end

    ARGV.each do |object_font_name|
      object_font = $job.get_font_metadata object_font_name
      $ts.switch_font narrative_font.name, $font_size
      $ts.typeset_latin1 object_font_name
      $ts.newline
      $ts.newline

      # We'll start with a basic character chart.
      pad_width = [narrative_font, object_font].map do |f|
        f.max_char_width
      end.max * $font_size
      $ts.switch_font narrative_font.name, $font_size
      3.times do
        $ts._move_right pad_width
      end
      (0 .. 15).each do |col|
        $ts.typeset_fixed_width_centered_chars sprintf(' %X', col),
            pad_width
      end
      $ts.newline
      row_range = object_font.min_charcode >> 4 ..
          object_font.max_charcode >> 4
      row_range.each do |row|
        row_needed = false
        (0 .. 15).each do |col|
          code = (row << 4) | col
          if object_font.has_char? code then
            row_needed = true
            break
          end
        end

        if row_needed then
          $ts.switch_font narrative_font.name, $font_size
          $ts.typeset_fixed_width_centered_chars sprintf('%2X ', row),
              pad_width
          $ts.switch_font object_font.name, $font_size
          (0 .. 15).each do |col|
            $ts._move_right pad_width
            code = (row << 4) | col
            if object_font.has_char? code then
              $ts.typeset_fixed_width_centered_native_char code,
                  pad_width
            else
              $ts._move_right pad_width
            end
          end
          $ts.newline
        end
      end
      $ts.newline

      # Is this font based on ASCII?
      pure_ascii_characters = []
      ascii_charset = Charset::load('ascii.cs')
      ascii_charset.each_native_charcode do |nc|
        if object_font.charset.auxiliary_unicodes(nc).empty? and
            object_font.charset.decode(nc) ==
                ascii_charset.decode(nc) then
          pure_ascii_characters.push nc
        end
      end

      if pure_ascii_characters.length >= 32 then
        base_charset_name = 'ASCII'
        pure_characters = pure_ascii_characters
      else
        base_charset_name = nil
        pure_characters = []
      end

      # Next, we'll list the individual characters in the font.
      charcode_range =
          object_font.min_charcode ..  object_font.max_charcode
      charcode_range.each do |nc|
        next unless object_font.has_char? nc
        next if pure_characters.include? nc
        $ts.switch_font narrative_font.name, $font_size
        $ts.typeset_latin1 sprintf('$%02X ', nc)
        $ts.switch_font object_font.name, $font_size
        $ts.typeset_native_char nc
        $ts.switch_font narrative_font.name, $font_size
        $ts.typeset_latin1 ' '
        unicode = object_font.charset.decode nc
        if unicode then
          $ts.typeset_latin1 sprintf('U+%04X ', unicode)
          if object_font.charset.encode(unicode) != nc then
            $ts.typeset_latin1 '(duplicate) '
          end
          char_name = unicode_char_names[unicode] ||
              'unknown Unicode char'
          $ts.typeset_latin1 char_name
        else
          $ts.typeset_latin1 '(not in Unicode)'
        end
        $ts.newline
      end
      unless pure_characters.empty? then
        $ts.newline
        $ts.switch_font narrative_font.name, $font_size
        $ts.typeset_latin1 sprintf "%i chars, not shown above, have",
            pure_characters.length
        $ts.newline
        $ts.typeset_latin1 "pure #{base_charset_name} meaning with no"
        $ts.newline
        $ts.typeset_latin1 "aux entries and are not listed in detail."
        $ts.newline
      end
#      unless object_font.name.include? ?. then
#        $ts.newline
#        litter = Pixel_Font_Litter::new(object_font.name)
#        litter.each_variant do |variant|
#          $ts.switch_font variant.name, $font_size
#          $ts.typeset_latin1 variant.name
#          $ts.newline
#        end
#      end
      $ts.form_feed
    end

    # Output virtual printer's content
    if $output_filename and $output_filename != '-' then
      open $output_filename, 'w' do |port|
        $job.dump_to_port port
      end
    else
      $job.dump_to_port $stdout
    end

    return
  end
end

Pixitie::main if $0 == __FILE__

#### The builtin resources
__END__
