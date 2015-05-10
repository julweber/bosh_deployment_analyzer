#
# analyze_deployment.rb
#
# Prints out deployment analytics
#

require 'yaml'
require 'pp'

def print_releases(releases)
  puts "----- Releases -----"
  releases.each do |r|
    puts "- #{r["name"]} -> #{r["version"]}"
  end
  puts ""
end

def print_summary(deployment)
  puts "---- Deployment ----"
  puts "  Name: #{deployment["name"]}"
  puts "  Bosh-Director: #{deployment["director_uuid"]}"
  puts "  Total Permanent VMs: #{get_total_permanent_vms(deployment)}"
  puts "  Total Errand VMs: #{get_total_errand_vms(deployment)}"
  puts "  Total Jobs: #{get_total_jobs(deployment)}"
  puts ""
end

def print_update_settings(deployment)
  puts "---- Update Settings ----"
  pp deployment["update"]
  puts ""
end

def get_total_permanent_vms(deployment)
  deployment["jobs"].inject(0) do |t, job|
    if job["resource_pool"].include?("errand")
      t
    else
      t + job["instances"]
    end
  end
end

def get_total_errand_vms(deployment)
  deployment["jobs"].inject(0) do |t, job|
    if job["resource_pool"].include?("errand")
      t + job["instances"]
    else
      t
    end
  end
end

def get_total_jobs(deployment)
  return deployment["jobs"].count
end

def print_jobs(jobs)
  puts "----- Jobs -----"
  jobs_to_install = []

  other_jobs = []

  jobs.each do |j|
    if j["instances"] > 0
      jobs_to_install << j
    else
      other_jobs << j
    end
  end

  jobs_to_install.sort! { |x,y| x["name"] <=> y["name"] }
  other_jobs.sort! { |x,y| x["name"] <=> y["name"] }

  puts "---- Installed ----"
  jobs_to_install.each do |j|
    print_job j
  end
  puts ""
  puts "---- Not Installed ----"
  other_jobs.each do |j|
    print_job j
  end
  puts ""
  puts ""
end

def print_job(j)
  puts "- Name: #{j["name"]}"
  puts "  Instances: #{j["instances"]}"
  puts "  Resource pool: #{j["resource_pool"]}"
  print_templates j
  puts ""
end

def print_pools(pools)
  puts "----- Resource pools -----"
  active_pools = []

  inactive_pools = []

  pools.each do |pool|
    if pool["size"] && pool["size"] > 0
      active_pools << pool
    else
      inactive_pools << pool
    end
  end

  puts ""
  puts "-- Active Pools --"
  active_pools.each do |pool|
    print_pool pool
  end
  puts ""
  puts "-- Inactive Pools --"
  inactive_pools.each do |pool|
    print_pool pool
  end

  puts ""
end

def print_pool(pool)
  puts "- Name: #{pool["name"]}"
  puts "  Size: #{pool["size"]}"
  puts "  Stemcell: #{pool["stemcell"]}"
  puts ""
end

def print_properties(properties)
  puts "----- Properties -----"
  puts ""
end

def print_templates(job)
  puts "  Templates:"
  unless job["templates"].nil?
    templates = job["templates"]
    templates.each do |t|
      puts "    - #{t.inspect}"
    end
  end

  unless job["template"].nil?
    if job["template"].is_a?(Array)
      job["template"].each do |tem|
        puts "    - #{tem}"
      end
    else
      puts "    - #{job["template"]}"
    end
  end
  puts ""
end

def print_used_templates(deployment)
  puts "---- Used Templates ----"
  templates = []

  deployment["jobs"].each do |j|
    unless j["templates"].nil?
      j["templates"].each do |tem|
        templates << { name: tem["name"], release: tem["release"] }
      end
    end

    unless j["template"].nil?
      if j["template"].is_a?(Array)
        j["template"].each do |tem|
          templates << { name: tem, release: j["release"] }
        end
      else
        templates << { name: j["template"], release: j["release"] }
      end
    end
  end

  templates.uniq!.sort! { |x,y| x[:name] <=> y[:name] }
  templates.each do |tem|
    puts "- #{tem}"
  end
  puts ""
end

def main
  yml_file = ARGV[0]

  puts "Input File: #{yml_file}"

  dep = YAML.load_file(yml_file)

  releases = dep["releases"]
  jobs = dep["jobs"]
  pools = dep["resource_pools"]
  properties = dep["properties"]

  print_summary dep
  print_update_settings dep
  print_releases releases
  print_used_templates dep
  print_pools pools
  print_jobs jobs
  print_properties properties
end

main
