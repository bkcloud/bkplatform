class VMDestroy
  include Sidekiq::Worker

  def perform(instance)
    puts "waiting for destroying #{instance["name"]}"
    job = ApplicationController.helpers.postRequest({command: "queryAsyncJobResult", jobid: instance["job_id"]})
    case true
    when job == nil, job["queryasyncjobresultresponse"]["jobstatus"] == 2
      Instance.find(instance["id"]).update_attributes!(
        state: "Error"
      )
      puts "#{instance["name"]} error"
    when job["queryasyncjobresultresponse"]["jobstatus"] == 0
      VMDestroy.perform_in(20.seconds, instance)
    when job["queryasyncjobresultresponse"]["jobstatus"] == 1
      Instance.find(instance["id"]).update_attributes!(
        state: "Destroyed"
      )
      puts "#{instance["name"]} destroyed"
    end
    # state = Instance.updateState(instance["id"]).downcase
    # if state == "destroying"
    # # Resque.enqueue_at(20.seconds.from_now, Jobs::VMStop, instance)
    # VMDestroy.perform_in(20.seconds, instance)
    # elsif state == "destroyed"
    # puts "#{instance["name"]} destroyed"
    # end
  end

end
