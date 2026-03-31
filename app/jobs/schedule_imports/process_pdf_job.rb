module ScheduleImports
  class ProcessPdfJob < ApplicationJob
    queue_as :default

    def perform(schedule_import_id)
      schedule_import = ScheduleImport.find(schedule_import_id)

      schedule_import.update!(status: "processing", ai_status: "processing")

      ScheduleImports::ProcessPdf.call(schedule_import)
    end
  end
end
