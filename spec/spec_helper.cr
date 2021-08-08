require "spec"
require "zeromq"
require "base64"
require "socket"

require "../src/all_q/server/cache_store"
require "../src/all_q/server/job"
require "../src/all_q/server/redirect_handler"
require "../src/all_q/server/request_handler"
require "../src/all_q/server/throttle"
require "../src/all_q/server/handlers/*"
require "../src/all_q/lib/*"
require "../src/all_q/server/caches/*"

TEST_TUBE_NAME    = "test"
FQ_TEST_TUBE_NAME = "fq-test"

Spec.before_each do
  cache_store = AllQ::CacheStore.new
  tubes = cache_store.tubes.all
  tubes.each do |tube|
    tube.clear
  end
  cache_store.reserved.clear_all
  cache_store.buried.clear_all
  cache_store.parents.clear_all
  GuageStats.instance.delay_between_calc = 1
end

class JobSpec
  def self.delete_via_handler(cache_store, job_id)
    val = {
      job_id: job_id,
    }.to_json
    AllQ::DeleteHandler.new(cache_store).process(JSON.parse(val))
  end

  def self.get_job_and_delete(cache_store, tube)
    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)
    if job
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end
    job
  end

  def self.get_via_handler(cache_store, tube)
    params = build_get_params(tube)
    job_wrapper = AllQ::GetHandler.new(cache_store).process(JSON.parse(params))
    if job_wrapper
      if job_wrapper.is_a?(HandlerResponse)
        return job_wrapper.job
      else
        return job_wrapper.jobs[0]
      end
    end
  end

  def self.build_job(tube, body : String | Nil)
    val = {
      tube: tube,
      body: body || (0...8).map { (65 + rand(26)).chr }.join,
    }.to_json

    job = JobFactory.build_job_factory_from_hash(JSON.parse(val)).get_job
    job.id = Random::Secure.urlsafe_base64(16)
    return job
  end

  def self.build_json_params(tube, body, hash_merge)
    data = {
      timeout: 3600,
      limit:   1,
      body:    body,
      tube:    tube,
      ttl:     3600,
    }
    if hash_merge
      data = data.merge(hash_merge)
    end
    data.to_json
  end

  def self.build_get_params(tube, count = 1)
    data = {
      tube:  tube,
      count: count,
    }
    data.to_json
  end

  def self.build_alot_of_jobs(cache_store, count = 10_000)
    1.upto(count) do
      tube = cache_store.tubes[TEST_TUBE_NAME]
      job = JobSpec.build_job(TEST_TUBE_NAME, nil)
      tube.put(job)
    end
  end

  def self.build_jobs_for_each_state(cache_store)
    tube = cache_store.tubes[TEST_TUBE_NAME]
    job = JobSpec.build_job(TEST_TUBE_NAME, nil)
    job2 = JobSpec.build_job(TEST_TUBE_NAME, nil)
    job3 = JobSpec.build_job(TEST_TUBE_NAME, nil)
    job4 = JobSpec.build_job(TEST_TUBE_NAME, nil)

    # Load a job into ready, delayed, and reserved
    tube.put(job)
    tube.put(job2, 5, 3600)
    tube.put(job3)
    tube.put(job4)
    reserved_job = tube.get
    job_to_bury = tube.get

    # This is normally done by GetHandler, we need to manually do it in this test
    if reserved_job && job_to_bury
      cache_store.reserved.set_job_reserved(reserved_job)
      cache_store.reserved.set_job_reserved(job_to_bury)
      cache_store.reserved.bury(job_to_bury.id)
    else
      raise "Failed catastrophically on creating job"
    end

    tube.size.should eq(1)
    tube.delayed_size.should eq(1)
    cache_store.reserved.get_job_ids.size.should eq(1)
  end
end

class FileChecker
  def self.get_ready(tube)
    serde = BaseSerDe(Job).new
    path = serde.base_dir.to_s + "/ready/#{tube}"
    Dir.entries(path).select { |f| !File.directory? f }
  end

  def self.get_delayed(tube)
    serde = BaseSerDe(Job).new
    path = serde.base_dir.to_s + "/delayed/#{tube}"
    Dir.entries(path).select { |f| !File.directory? f }
  end

  def self.get_reserved
    serde = BaseSerDe(Job).new
    path = serde.base_dir.to_s + "/reserved/"
    Dir.entries(path).select { |f| !File.directory? f }
  end

  def self.get_buried
    serde = BaseSerDe(Job).new
    path = serde.base_dir.to_s + "/buried/"
    Dir.entries(path).select { |f| !File.directory? f }
  end
end
