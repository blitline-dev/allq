class BaseSerDe(T)
  SERIALIZE = (ENV["SERIALIZE"]?.to_s == "true")

  def initialize
    @base_dir = ENV["SERIALIZER_DIR"]? || "/tmp/"
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

  # abstract def remove(job : Job)
  # end

  # abstract def serialize(job_struct : T)
  # end

  # abstract def load(cache : Hash(String, T))
  # end

end
