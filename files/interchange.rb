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
  include ActionView::Helpers::TagHelper

  included do
    before_action :init_interchange

    helper_method :interchange_data
  end

  def interchange(data)
    data.keys.each do |key|
      raise KeyMustBeSymbol, key if key.class != Symbol
      raise KeyAlreadyExists, key if @interchange_data.key?(key)
    end

    @interchange_data = @interchange_data.merge(data)
  end

  def interchange_data
    data = Oj.dump(@interchange_data, mode: :compat)

    content_tag(
      :div,
      '',
      id: 'interchange',
      style: 'display: none',
      'data-data' => data
    )
  end

  def init_interchange
    @interchange_data = {}
  end
end
