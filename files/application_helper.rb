module ApplicationHelper
  def js_for_view
    manifest = "#{params[:controller]}-#{params[:action]}"

    all_js = Dir.glob("#{Rails.root}/app/assets/javascripts/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-)*)/] + ".js" }
    all_js.include?("#{manifest}.js") ? manifest : ""
  end
end
