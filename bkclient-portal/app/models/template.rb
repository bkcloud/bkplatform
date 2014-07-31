class Template < ActiveRecord::Base
  has_many :instance

  def self.sync
    templates_response = ApplicationController.helpers.postRequest({ command: "listTemplates", templatefilter: "featured" })
    templates = templates_response["listtemplatesresponse"]["template"]
    templates = templates.class.to_s != "Array" ? [templates] : templates
    @templates = []
    Template.destroy_all(['template_id NOT IN (?)', templates.map { |e| e["id"] } ])
    templates.each do |e|
      template = Template.find_by template_id: e["id"]
      if template #only need to update
        template.update_attributes!(name: e["name"], ostypename: e["ostypename"], details: e["details"])
        @templates.push(template)
      else #create new one
        template = Template.new(template_id: e["id"] , name: e["name"], ostypename: e["ostypename"], details: e["details"], created_at: DateTime.iso8601(e["created"]) )
        if template.save
          @templates.push(template)
        end
      end
    end
  end

end
