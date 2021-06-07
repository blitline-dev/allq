require "./spec_helper"

describe AllQ do
  # -------------------------
  # Simplest Parent-Child Relationship
  # -------------------------
  it "Simple parent child" do
    cache_store = AllQ::CacheStore.new
    body_1 = Random::Secure.urlsafe_base64
    parent_body_1 = Random::Secure.urlsafe_base64
    tube = cache_store.tubes[TEST_TUBE_NAME]

    # Insert Parent Job
    parent_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, parent_body_1, nil)
    result = AllQ::SetParentJobHandler.new(cache_store).process(JSON.parse(parent_json_params))

    # Insert Child Job
    child_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, body_1, {parent_id: result.job_id})
    result = AllQ::PutHandler.new(cache_store).process(JSON.parse(child_json_params))

    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)

    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)
    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(0)

    if job
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end
    cache_store.parents.size.should eq(0)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)
  end

  # -------------------------
  # Compound parents are parents WITH parents, workflow-like functionality
  # -------------------------
  it "Compund parent child" do
    cache_store = AllQ::CacheStore.new
    tube = cache_store.tubes[TEST_TUBE_NAME]
    parent_body_2 = Random::Secure.urlsafe_base64
    parent_body_1 = Random::Secure.urlsafe_base64
    body_1 = Random::Secure.urlsafe_base64

    parent_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, parent_body_2, nil)
    top_parent_result = AllQ::SetParentJobHandler.new(cache_store).process(JSON.parse(parent_json_params))

    parent_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, parent_body_1, {parent_id: top_parent_result.job_id})
    mid_parent_result = AllQ::SetParentJobHandler.new(cache_store).process(JSON.parse(parent_json_params))

    child_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, body_1, {parent_id: mid_parent_result.job_id})
    result = AllQ::PutHandler.new(cache_store).process(JSON.parse(child_json_params))

    # Should be 2 parents, 1 ready
    cache_store.parents.size.should eq(2)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)

    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)

    # Should be 2 parents, 1 reserved, 0 ready
    cache_store.parents.size.should eq(2)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(0)

    # Finish job
    if job
      job["body"].should eq(body_1)
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end

    # Should now be 1 parent 1 ready
    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)

    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)
    # Finish job
    if job
      job["body"].should eq(parent_body_1)
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end
    # Should be 0 parent 1 readt

    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)
    if job
      job["body"].should eq(parent_body_2)
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(0)
  end

  # -------------------------
  # Parent Child with different tube names
  # -------------------------
  it "Multi tube parent child" do
    alt_tube = "some_other_tube"

    cache_store = AllQ::CacheStore.new
    body_1 = Random::Secure.urlsafe_base64
    parent_body_1 = Random::Secure.urlsafe_base64
    tube = cache_store.tubes[TEST_TUBE_NAME]

    parent_json_params = JobSpec.build_json_params(alt_tube, parent_body_1, nil)
    result = AllQ::SetParentJobHandler.new(cache_store).process(JSON.parse(parent_json_params))

    child_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, body_1, {parent_id: result.job_id})
    result = AllQ::PutHandler.new(cache_store).process(JSON.parse(child_json_params))

    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)

    job = JobSpec.get_via_handler(cache_store, TEST_TUBE_NAME)
    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(0)

    if job
      JobSpec.delete_via_handler(cache_store, job["job_id"])
    else
      raise "Must have job"
    end
    cache_store.parents.size.should eq(0)
    cache_store.tubes[alt_tube].size.should eq(1)
  end

  # -------------------------
  # Parent with unknown child count
  # -------------------------
  it "Multiple Child with unknown count" do
    cache_store = AllQ::CacheStore.new
    body_1 = Random::Secure.urlsafe_base64
    parent_body_1 = Random::Secure.urlsafe_base64
    tube = cache_store.tubes[TEST_TUBE_NAME]

    # Build parent
    data = { # No limit
      timeout: 3600,
      body:    parent_body_1,
      tube:    TEST_TUBE_NAME,
      ttl:     360,
    }

    # Insert Parent Job (with no limit)
    parent_json_params = data.to_json
    result = AllQ::SetParentJobHandler.new(cache_store).process(JSON.parse(parent_json_params))
    parent_id = result.job_id

    # Insert Child job
    child_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, body_1, {parent_id: parent_id})
    result = AllQ::PutHandler.new(cache_store).process(JSON.parse(child_json_params))

    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)

    # Get child job, parent job should not auto-enqueue
    JobSpec.get_job_and_delete(cache_store, TEST_TUBE_NAME)

    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(0)

    # Add another child job
    child_json_params = JobSpec.build_json_params(TEST_TUBE_NAME, body_1, {parent_id: parent_id})
    result = AllQ::PutHandler.new(cache_store).process(JSON.parse(child_json_params))

    # Set parent children_started!
    data = {job_id: parent_id}
    AllQ::SetChildrenStartedHandler.new(cache_store).process(JSON.parse(data.to_json))

    cache_store.parents.size.should eq(1)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)
    JobSpec.get_job_and_delete(cache_store, TEST_TUBE_NAME)

    cache_store.parents.size.should eq(0)
    cache_store.tubes[TEST_TUBE_NAME].size.should eq(1)
  end
end
