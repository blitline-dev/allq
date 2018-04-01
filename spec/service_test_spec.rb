require 'functions'
require 'spec_helper'

def stats_count(f, r = 0, rs = 0, b = 0, d = 0, p = 0)
  out = f.stats
  expect(out['tube-1']['ready']).to eq(r.to_s)
  expect(out['tube-1']['reserved']).to eq(rs.to_s)
  expect(out['tube-1']['buried']).to eq(b.to_s)
  expect(out['tube-1']['delayed']).to eq(d.to_s)
  expect(out['tube-1']['parents']).to eq(p.to_s)
end

describe 'Put/Get' do
  it 'put-get-done works' do
    f = Functions.new
    f.put
    out = f.get
    expect(out['job']['id'].size > 0).to be_truthy
    expect(out['job']['body'].size > 0).to be_truthy
    f.done(out['job']['id'])
    stats_count(f)
  end

  it 'put-get-count works' do
    f = Functions.new
    f.put
    f.put
    stats_count(f, 2, 0, 0)
    f1 = f.get
    stats_count(f, 1, 1, 0)
    f2 = f.get
    stats_count(f, 0, 2, 0)
    f.done(f1['job']['id'])
    f.done(f2['job']['id'])
    stats_count(f)
  end

  # it 'handles delay properly' do
  #   f = Functions.new
  #   merge_data = {
  #     delay: 2
  #   }
  #   f.put(nil, merge_data)
  #   stats_count(f, 0, 0, 0, 1)
  #   sleep(5)
  #   stats_count(f, 1, 0, 0, 0)
  #   job_id = f.get_return_id
  #   f.done(job_id)
  #   stats_count(f, 0, 0, 0, 0)
  # end

  # it 'handles ttl properly' do
  #   f = Functions.new
  #   merge_data = {
  #     ttl: 1
  #   }
  #   f.put(nil, merge_data)
  #   stats_count(f, 1, 0, 0, 0)
  #   f.get_return_id
  #   stats_count(f, 0, 1, 0, 0)
  #   sleep(7)
  #   stats_count(f, 1, 0, 0, 0)
  #   job_id = f.get_return_id
  #   f.done(job_id)
  #   stats_count(f, 0, 0, 0, 0)
  # end

  it 'handles parent jobs properly' do
    f = Functions.new
    limit = 3
    job_id = f.create_parent_job_return_id(limit, nil)

    stats_count(f, 0, 0, 0, 0, 1)
    merge_data = {
      parent_id: job_id
    }
    1.upto(limit) do
      f.put(nil, merge_data)
    end
    stats_count(f, limit, 0, 0, 0, 1)
    1.upto(limit) do
      f.get_set_done
    end
    stats_count(f, 1, 0, 0, 0, 0)
    parent_id = f.get_return_id
    expect(parent_id).to eq(job_id)
  end

  # it 'handles multiple waits' do
  #   f = Functions.new
  #   limit = 3
  #   master_id = f.create_parent_job_return_id(2, nil)
  #   merge_data = {
  #     parent_id: job_id,
  #     noop: true,
  #     limit: limit
  #   }
  #   waiter_1 = f.create_parent_job_merge(merge_data)
  #   waiter_2 = f.create_parent_job_merge(merge_data)

  #   merge_data = {
  #     parent_id: waiter_1
  #   }

  #   1.upto(limit) do
  #     f.put(nil, merge_data)
  #   end

  #   merge_data = {
  #     parent_id: waiter_2
  #   }

  #   1.upto(limit) do
  #     f.put(nil, merge_data)
  #   end

  #   stats_count(f, 6, 0, 0, 0, 3)
  #   f.get_set_done
  #   f.get_set_done
  #   f.get_set_done
  #   f.get_set_done
  #   f.get_set_done
  #   stats_count(f, 1, 0, 0, 0, 3)
  #   f.get_set_done
  #   stats_count(f, 1, 0, 0, 0, 0)
  #   # -- Cleanup
  #   f.get_set_done

  # end




end
