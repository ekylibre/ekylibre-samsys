autoload :Samsys, 'samsys'

Samsys::SamsysIntegration.on_check_success do
  SamsysFetchUpdateCreateJob.perform_later
end

Samsys::SamsysIntegration.run every: :day do
  SamsysFetchUpdateCreateJob.perform_now
end
