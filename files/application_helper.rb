module ApplicationHelper
  def all_js
    if Rails.env.production?
      <%= app_name %>::Application::ALL_JS
    else
      <%= app_name %>::Application.all_js
    end
  end

  def controller_name
    params[:controller].gsub(/\//, '~')
  end

  def js_for_action
    file = "#{controller_name}-#{params[:action]}"

    @action_js ||= all_js[file] ? file : nil
  end

  def js_for_controller
    file = controller_name

    @controller_js ||= all_js[file] ? file : nil
  end
end
