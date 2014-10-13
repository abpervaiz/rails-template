module ApplicationHelper
  def js_for_action
    file = "#{params[:controller]}-#{params[:action]}"

    all_js = Dir.glob("#{Rails.root}/app/assets/javascripts/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-)*)/] }
    all_js.include?(file) ? file : ""
  end

  def js_for_controller
    file = params[:controller]

    all_js = Dir.glob("#{Rails.root}/app/assets/javascripts/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-)*)/] }
    all_js.include?(file) ? file : ""
  end
end
