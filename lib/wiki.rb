require 'wikipedia'

class Wiki
  class << self

    def search(text)
      Wikipedia.Configure {domain "#{I18n.locale}.wikipedia.org"}
      return Wikipedia.find(prepare_query(text))
    end

    # private

    def prepare_query(text)
      query = []
      %w(capitalize downcase upcase).each do |m|
        query << text.split(/[\s,-]/).map(&:mb_chars).map(&m.to_sym).map(&:to_s)
      end
      prepared_query = []
      if text.split(/[\s,-]/).size > 1
        query.each do |texts|
          prepared_query << texts.join(' ')
          prepared_query << texts.join('-')
        end
      else
        prepared_query = query.flatten
      end

      return prepared_query.join('|')
    end
  end
end