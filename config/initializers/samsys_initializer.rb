Samsys::SamsysIntegration.on_check_success do
  SamsysFetchUpdateCreateJob.perform_later
end

Samsys::SamsysIntegration.run every: :hour do
  if Integration.find_by(nature: "samsys").present?
    SamsysFetchUpdateCreateJob.perform_now
  end
end
