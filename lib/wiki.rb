require 'wikipedia'

class Wiki
  class << self

    def search(text)
      Wikipedia.Configure {domain "#{I18n.locale}.wikipedia.org"}
      return Wikipedia.find(text)
    end
  end
end