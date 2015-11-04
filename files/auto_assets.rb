module <%= class_app_name %>
  module AutoAssets
    extend self

    def init
      all_js # prime @javascripts ivar in production
    end

    def all
      (top_level_js + top_level_css).select { |f| !f.match(/application\.(css|js)/) }
    end

    def js(raw_controller_name, raw_action_name)
      controller_name = transform_controller_name(raw_controller_name)

      [
        'application',
        js_for_controller(controller_name),
        js_for_action(controller_name, raw_action_name)
      ].compact
    end

    private

    def js_for_action(controller_name, action_name)
      file = "#{controller_name}-#{action_name}"

      all_js[file] ? file : nil
    end

    def js_for_controller(controller_name)
      file = controller_name

      all_js[file] ? file : nil
    end

    # to handle controllers in folders transform slashes to tildes
    # admin/dashboard_controller => admin~dashboard_controller
    def transform_controller_name(name)
      name.gsub(/\//, '~')
    end

    def all_js
      if Rails.env.production?
        @javascripts ||= list_all_js
      else
        list_all_js
      end
    end

    def top_level_js
      Dir.glob("#{Rails.root}/app/assets/javascripts/*").select do |f|
        !File.directory?(f)
      end.map { |f| File.basename(f)[/((\w|-|~)*)/] + ".js" }
    end

    def top_level_css
      Dir.glob("#{Rails.root}/app/assets/stylesheets/*").select do |f|
        !File.directory?(f)
      end.map { |f| File.basename(f)[/((\w|-|~)*)/] + ".css" }
    end

    def list_all_js
      file_list = Dir.glob("#{Rails.root}/app/assets/javascripts/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-|~)*)/] }
      file_list.map { |file| [file, true] }.to_h
    end

    init
  end
end
