class DiskOffering < ActiveRecord::Base
  has_many :instance

  def self.sync
    disk_offerings_response = ApplicationController.helpers.postRequest({ command: "listDiskOfferings" })
    disk_offerings = disk_offerings_response["listdiskofferingsresponse"]["diskoffering"]
    @disk_offerings = []
    DiskOffering.destroy_all(['disk_offering_id NOT IN (?)', disk_offerings.map { |e| e["id"] } ])
    disk_offerings.each do |e|
      disk_offering = DiskOffering.find_by disk_offering_id: e["id"]
      if disk_offering #only need to update
        disk_offering.update_attributes!(disksize: e["disksize"], storagetype: e["storage"])
        @disk_offerings.push(disk_offering)
      else #create new one
        disk_offering = DiskOffering.new(disk_offering_id: e["id"] , disksize: e["disksize"], storagetype: e["storagetype"], created_at: DateTime.iso8601(e["created"]) )
        if disk_offering.save
          @disk_offerings.push(disk_offering)
        end
      end
    end
  end
end
