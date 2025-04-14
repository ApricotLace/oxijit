#!/usr/bin/env ruby

require_relative './lockfile'

class Refs
  def initialize(pathname)
    @pathname = pathname
  end

  def update_head(oid)
    lockfile = Lockfile.new(head_path)

    lockfile.hold_for_update

    lockfile.write(oid)
    lockfile.write("\n")
    lockfile.commit
  end

  def read_head
    puts head_path
    return unless File.exist?(head_path)

    File.read(head_path).strip
  end

  private

  def head_path
    @pathname.join('HEAD')
  end
end
