#! /usr/bin/ruby

MAX_RECORD_SIZE = 24

address = 0
loop do
  raw_bytes = $stdin.read MAX_RECORD_SIZE
  break unless raw_bytes
  record = [raw_bytes.length, address, 0].pack 'CnC'
  record << raw_bytes
  checksum = 0
  record.each_byte do |b|
    checksum += b
  end
  checksum = (-checksum) & 0xFF
  printf ":%s%02X\n", record.unpack('H*').first.upcase, checksum
  address += raw_bytes.length
  raise "Too much data" if address >= 0x10000
end
puts ":00000001FF"
