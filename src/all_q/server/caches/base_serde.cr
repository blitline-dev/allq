class BaseSerDe(T)
  getter :base_dir

  SERIALIZE = (ENV["SERIALIZE"]?.to_s == "true")

  def initialize
    @base_dir = EnvConstants::SERIALIZER_DIR
  end

  def build_ready(job : Job)
    "#{@base_dir}/ready/#{job.tube}/#{job.id}"
  end

  def build_parent(job : Job)
    "#{@base_dir}/parents/#{job.id}"
  end

  def build_reserved(job : Job)
    "#{@base_dir}/reserved/#{job.id}"
  end

  def build_buried(job : Job)
    "#{@base_dir}/buried/#{job.id}"
  end

  def build_delayed(job : Job)
    "#{@base_dir}/delayed/#{job.tube}/#{job.id}"
  end

  def build_ready_folder(tube)
    "#{@base_dir}/ready/#{tube}/"
  end

  def build_delayed_folder(tube)
    "#{@base_dir}/delayed/#{tube}/"
  end

  def build_reserved_folder
    "#{@base_dir}/reserved/"
  end

  def build_buried_folder
    "#{@base_dir}/buried/"
  end

  def build_parents_folder
    "#{@base_dir}/parents/"
  end

  def build_throttle_filepath(tube)
    "#{@base_dir}/throttles/#{tube}"
  end

  # abstract def remove(job : Job)
  # end

  # abstract def serialize(job_struct : T)
  # end

  # abstract def load(cache : Hash(String, T))
  # end

end
