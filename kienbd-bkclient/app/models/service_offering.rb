class ServiceOffering < ActiveRecord::Base
  has_many :instance

  def self.sync
    service_offerings_response = ApplicationController.helpers.postRequest({ command: "listServiceOfferings" })
    service_offerings = service_offerings_response["listserviceofferingsresponse"]["serviceoffering"]
    @service_offerings = []
    ServiceOffering.destroy_all(['service_offering_id NOT IN (?)', service_offerings.map { |e| e["id"] } ])
    service_offerings.each do |e|
      service_offering = ServiceOffering.find_by service_offering_id: e["id"]
      if service_offering #only need to update
        service_offering.update_attributes!(cpunumber: e["cpunumber"].to_i, cpuspeed: e["cpuspeed"].to_i, memory: e["memory"].to_i, offerha: e["offerha"].to_bool )
        @service_offerings.push(service_offering)
      else #create new one
        service_offering = ServiceOffering.new(service_offering_id: e["id"] , cpunumber: e["cpunumber"].to_i, cpuspeed: e["cpuspeed"].to_i, memory: e["memory"].to_i, offerha: e["offerha"].to_bool, created_at: DateTime.iso8601(e["created"]) )
        if service_offering.save
          @service_offerings.push(service_offering)
        end
      end
    end
  end
end
