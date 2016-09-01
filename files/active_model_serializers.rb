if Rails.env.production?
  ActiveModelSerializers.logger = nil
end
