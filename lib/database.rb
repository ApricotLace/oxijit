#!/usr/bin/env ruby

require 'digest/sha1'
require 'zlib'
require 'strscan'
require_relative './database/blob'
require_relative './database/tree'
require_relative './database/commit'
require_relative './database/author'
require_relative './database/entry'

class Database

  def initialize(pathname)
    @pathname = pathname
    @objects = {}
  end

  def load(oid)
    @objects[oid] ||= read_object(oid)
  end

  def store(object)
    content = serialize_object(object)
    object.oid = hash_content(content)
    write_object(object.oid, content)
  end

  def hash_object(object)
    hash_content(serialize_object(object))
  end

  private

  TYPES = { 
    "blob" => Blob,
    "tree" => Tree,
    "commit" => Commit
  }

  def read_object(oid)
    data = Zlib::Inflate.inflate(File.read(object_path(oid)))
    scanner = StringScanner.new(data)

    type = scanner.scan_until(/ /).strip
    _size = scanner.scan_until(/\0/)[0..-2]

    object = TYPES[type].parse(scanner)
    object.oid = oid

    object
  end

  def serialize_object(object)
    string = object.to_s.force_encoding(Encoding::ASCII_8BIT)
    "#{ object.type } #{ string.bytesize }\0#{ string }"
  end

  def hash_content(string)
    Digest::SHA1.hexdigest(string)
  end

  def write_object(oid, content)
    object_path = object_path(oid)
    return if File.exist?(object_path)

    dirname = object_path.dirname
    temp_path = dirname.join(generate_temp_name)
    begin
      flags = File::RDWR | File::CREAT | File::EXCL
      file = File.open(temp_path, flags)
    rescue Errno::ENOENT
      Dir.mkdir(dirname)
      file = File.open(temp_path, flags)
    end
    compressed = Zlib::Deflate.deflate(content, Zlib::BEST_SPEED)

    file.write(compressed)
    file.close
    File.rename(temp_path, object_path)
  end

  def generate_temp_name
    "tmp_obj_#{(1..6).map { TEMP_CHARS.sample }.join('')}"
  end

  def object_path(oid)
    @pathname.join(oid[0..1], oid[2..])
  end

  TEMP_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
end
