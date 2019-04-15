module AllQ
  class FileWrapper
    def self.rm(path)
      begin
        FileUtils.rm(path) if File.exists?(path)
      rescue ex
        puts "Error in file wrapper rm with #{path}"
      end
    end

    def self.mv(src, dest)
      begin
        FileUtils.mv(src, dest) if File.exists?(src)
      rescue ex
        puts "Error in file wrapper mv with #{src} #{dest}"
      end
    end
  end
end
