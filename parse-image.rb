#! /usr/bin/ruby -rubygems

require 'RMagick'
require 'getoptlong'

# Because our input is a planar image, we'll use a number of planar
# vectors.  Mostly, for configuration.
Planar_Vector = Struct::new(:x, :y)

#### Parsing subroutines

def parse_sign s
  case s
  when '+', '', nil then return +1
  when '-' then return -1
  else raise "#{s.inspect} is not a sign"
  end
end

class String
  def parse_number
    if self =~ /\A([+-]?)(\d+)\Z/ then # decimal
      return parse_sign($1) * $2.to_i
    elsif self =~ /\A([+-]?)(?:\$|0x|\&h)?([\da-f]+)\Z/i then # hex
      return parse_sign($1) * $2.hex
    else
      raise "#{self.inspect} is not a number"
    end
  end

  def parse_range
    first, last = self.split /\.\./, 2
    if first and last then
      return first.parse_number .. last.parse_number
    else
      raise "#{self.inspect} is not a range"
    end
  end
end

def Planar_Vector::parse arg
  unless arg =~ /^(\d+)\s*,\s*(\d+)$/ then
    raise "planar vector parse error near #{coord_spec.inspect}"
  end
  return Planar_Vector::new $1.parse_number, $2.parse_number
end

class Planar_Vector
  def + other
    raise 'Type mismatch' unless other.is_a? Planar_Vector
    return Planar_Vector::new(self.x + other.x, self.y + other.y)
  end
 
  # element-wise multiplication
  def * other
    raise 'Type mismatch' unless other.is_a? Planar_Vector
    return Planar_Vector::new(self.x * other.x, self.y * other.y)
  end
end

#### Miscellaneous subroutines

def Planar_Vector::fold index, width
  raise 'Type mismatch' unless index.is_a? Integer
  raise 'Type mismatch' unless width.is_a? Integer
  # NB: integer division
  return Planar_Vector::new(index % width, index / width)
end

#### Configuration

$origin = nil
$range = nil
$pad_bottom = 0
$pixel_step = nil
$vsparse = false
$pad_right = 0
$check_horizontal_neighbours = false
$skew = 0
$hsparse = false
$origin = nil
$cell_size = nil
$cell_step = nil

$header = []

GetoptLong::new(
  ['--origin', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
  ['--pad-bottom', GetoptLong::REQUIRED_ARGUMENT],
  ['--pixel-step', GetoptLong::REQUIRED_ARGUMENT],
  ['--header', '-h', GetoptLong::REQUIRED_ARGUMENT],
  ['--vsparse', GetoptLong::NO_ARGUMENT],
  ['--pad-right', GetoptLong::REQUIRED_ARGUMENT],
  ['--skew', GetoptLong::REQUIRED_ARGUMENT],
  ['--check-horizontal-neighbours', GetoptLong::NO_ARGUMENT],
  ['--hsparse', GetoptLong::NO_ARGUMENT],
  ['--cell-size', GetoptLong::REQUIRED_ARGUMENT],
  ['--cell-step', GetoptLong::REQUIRED_ARGUMENT]
).each do |opt, arg|
  case opt
  when '--origin' then $origin = Planar_Vector::parse arg
  when '--range' then $range = arg.parse_range
  when '--pad-bottom' then $pad_bottom = arg.parse_number
  when '--pixel-step' then $pixel_step = Planar_Vector::parse arg
  when '--header' then $header.push arg
  when '--vsparse' then $vsparse = true
  when '--pad-right' then $pad_right = arg.parse_number
  when '--skew' then $skew = arg.parse_number
  when '--check-horizontal-neighbours' then
    $check_horizontal_neighbours = true
  when '--hsparse' then $hsparse = true
  when '--cell-size' then $cell_size = Planar_Vector::parse arg
  when '--cell-step' then $cell_step = Planar_Vector::parse arg
  end
end

raise '--origin not given' unless $origin
raise '--range not given' unless $range
raise '--pixel-step not given' unless $pixel_step
raise '--cell-size not given' unless $cell_size

$nybbles ||= ($cell_size.y / ($vsparse ? 2 : 1) + 3) / 4
    # NB: integer division

#### Main work

image = Magick::Image::from_blob($stdin.read).first

$header.each do |l|
  puts l
end
puts

# Iterate over chars
$range.each do |charcode|
  printf "%02X", charcode
  charcoord = 
  # calculate the position of this char's top left dot centre
  char_origin = $origin + $cell_step *
      Planar_Vector::fold(charcode - $range.first + $skew, 16)
  (0 ... $cell_size.x).each do |dx|
    column = 0
    (0 ... $cell_size.y).each do |dy|
      p = char_origin + Planar_Vector::new(dx, dy) * $pixel_step
      mpix = image.pixel_color p.x, p.y
      dot = mpix.red + mpix.green + mpix.blue == 0
      if $check_horizontal_neighbours then
        lpix = image.pixel_color p.x - 1, p.y
        dot &= lpix.red + lpix.green + lpix.blue == 0
        rpix = image.pixel_color p.x + 1, p.y
        dot &= rpix.red + rpix.green + rpix.blue == 0
      end
      unless dy % 2 == 1 and $vsparse then
        column <<= 1
        column |= dot ? 1 : 0
      else
        if dot then
          raise sprintf("Vertical sparsity constraint violation " +
              "in char $%02X (dx=%i, dy=%i)", charcode, dx, dy)
        end
      end
    end
    column <<= $pad_bottom
    unless dx % 2 == 1 and $hsparse then
      printf " %0#{$nybbles}X", column
    else
      if column != 0 then
        raise sprintf("Vertical sparsity constraint violation " +
            "in char $%02X (dx=%i)", charcode, dx)
      end
    end
  end
  $pad_right.times do
    printf " %0#{$nybbles}X", 0
  end
  puts
end
