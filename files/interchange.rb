module Interchange
  # provides a straightforward way to make ruby variables available on the
  # client.
  #
  # js side handled by lib/assets/javascripts/interchange.coffee (you probably
  # want to load this before all of your own js)
  #
  # rails side handled by '<%= interchange_data %>' in application layout
  #
  # access variables via Interchange.key => value
  # set variabels by calling: interchange(key: value)

  class KeyAlreadyExists < StandardError; end
  class KeyMustBeSymbol < StandardError; end

  extend ActiveSupport::Concern
  include ERB::Util

  included do
    before_filter :init_interchange

    helper_method :interchange_data
  end

  def interchange(data)
    data.keys.each do |key|
      raise KeyMustBeSymbol, key if key.class != Symbol
      raise KeyAlreadyExists, key if @interchange_data.has_key?(key)
    end

    @interchange_data = @interchange_data.merge(data)
  end

  def interchange_data
    data = Oj.dump(@interchange_data, mode: :compat)

    "<div id=\"interchange\" data-data=\"#{h data}\" style=\"display: none\"></div>".html_safe
  end

  def init_interchange
    @interchange_data = {}
  end
end
