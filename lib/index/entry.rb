# lib/entry.rb

class Index
  REGULAR_MODE = 0o100644
  EXECUTABLE_MODE = 0o100755
  MAX_PATH_SIZE = 0xfff
  ENTRY_FORMAT = 'N10H40nZ*'
  ENTRY_BLOCK = 8
  ENTRY_MIN_SIZE = 64

  ENTRY_FIELDS = %i[
    ctime ctime_nsec
    mtime mtime_nsec
    dev ino mode uid gid size
    oid flags path
  ]

  Entry = Struct.new(*ENTRY_FIELDS) do
    def self.create(pathname, oid, stat)
      path = pathname.to_s
      mode = stat.executable? ? EXECUTABLE_MODE : REGULAR_MODE
      flags = [path.bytesize, MAX_PATH_SIZE].min

      Entry.new(
        stat.ctime.to_i, stat.ctime.nsec,
        stat.mtime.to_i, stat.mtime.nsec,
        stat.dev, stat.ino, mode, stat.uid, stat.gid, stat.size,
        oid, flags, path
      )
    end

    def self.parse(data)
      Entry.new(*data.unpack(ENTRY_FORMAT))
    end

    def key
      path
    end

    def parent_directories
      Pathname.new(path).descend.to_a[0..-2]
    end

    def basename
      Pathname.new(path).basename
    end

    def to_s
      string = to_a.pack(ENTRY_FORMAT)
      string << "\0" until string.bytesize % ENTRY_BLOCK == 0
      string
    end
  end
end
