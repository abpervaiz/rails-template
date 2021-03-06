<%= class_app_name %>::Application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params].reject do |k|
      %w(controller action).include? k
    end

    { 'params' => params }
  end
end
