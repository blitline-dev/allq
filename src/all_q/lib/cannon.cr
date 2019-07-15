class Cannon
  def self.encode(io : IO, string : String)
    begin
      io.puts(string)
      io.flush
    rescue ex
      puts "Failed to serialize in custome Cannon encode"
      puts string.to_s
    end
  end

  def self.encode(io : IO, job : Job)
    begin
      job_hash = JobFactory.to_hash(job)
      io.puts(job_hash.to_json)
      io.flush
    rescue ex
      puts "Failed to serialize in custome Cannon encode"
      puts job.to_s
    end
  end

  def self.encode(io : IO, dj : AllQ::Tube::DelayedJob | AllQ::ReservedCache::ReservedJob | AllQ::ParentCache::ParentJob)
    begin
      io.puts(dj.to_json)
      io.flush
    rescue ex
      puts "Failed to serialize in custome Cannon encode"
      puts dj.to_s
    end
  end

  def self.decode_to_reserved_job(filename : String)
    begin
      txt = File.read(filename)
      job = AllQ::ReservedCache::ReservedJob.from_json(txt)
      return job
    rescue ex
      puts "Failed to decode_to_reserved_job(#{filename}) in custom Cannon decode: #{ex.message}"
      puts filename.to_s
      puts txt if txt
      File.delete(filename) if File.exists?(filename)
    end
    return nil
  end

  def self.decode_to_delayed_job(filename : String)
    begin
      txt = File.read(filename)
      job = AllQ::Tube::DelayedJob.from_json(txt)
      return job
    rescue ex
      puts "Failed to decode_to_delayed_job(#{filename}) in custom Cannon decode #{ex.message}"
      puts filename.to_s
      puts txt if txt
      File.delete(filename) if File.exists?(filename)
    end
    return nil
  end

  def self.decode_to_parent_job(filename : String)
    begin
      txt = File.read(filename)
      job = AllQ::ParentCache::ParentJob.from_json(txt)
      return job
    rescue ex
      puts "Failed to decode_to_parent_job(#{filename}) in custom Cannon decode #{ex.message}"
      puts filename.to_s
      puts txt if txt
      File.delete(filename) if File.exists?(filename)
    end
    return nil
  end

  def self.decode(filename : String) : JSON::Any
    begin
      txt = File.read(filename)
      return JSON.parse(txt)
    rescue ex
      puts "Failed to decode(#{filename}) in custom Cannon decode #{ex.message}"
      puts filename.to_s
      File.delete(filename) if File.exists?(filename)

      return JSON.parse("{}")
    end
  end

  def self.decode_to_job?(filename : String) : Job | Nil
    json_hash = decode(filename)

    if json_hash.size == 0
      return nil
    else
      begin
        job = JobFactory.build_job_factory_from_hash(json_hash).get_job
        return job
      rescue ex
        puts json_hash.to_s if json_hash
        puts "Failed to decode_to_job(#{filename}) in custom Cannon decode #{ex.message}"
        puts filename.to_s
        File.delete(filename) if File.exists?(filename)
      end
    end
    return nil
  end
end
