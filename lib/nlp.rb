require "wit"
require "tickets_api"
require "nlp_date"

module NLP

  def client
    @client ||= Wit.new(access_token: 'RYZZVM3TRHSIJW3IVMXXO3RR66QT3CFT', actions: actions)
  end

  def actions
    {
        send: -> (request, response) {
          p '--------------WIT response--------------'
          p response
          p '--------------WIT request---------------'
          p request
          p '-----------------WIT-------------------'
          p "sending... #{response['text']}"
          proccess_text(response['text'], response['quickreplies'])
        },
        searchTrain: -> (response) {
          result = {'searchFail' => 'fail'}
          session = Rails.cache.read(response['session_id']) || {}
          search_result = TicketsApi.get('rail/search', {from: session[:from_code], to: session[:to_code], date: session[:date]}).try(:[], 'result').try(:[], 'code')
          if !search_result.nil? && search_result.to_i == 0
            result = {
                'yes_no' => 'yes',
                'searchSuccess' => "https://gd.tickets.ua/preloader/~#{session[:from_code]}~#{session[:to_code]}~#{Date.parse(session[:date]).strftime('%d.%m.%Y')}~1~ukraine~~~~~/"
            }

          end
          return result
        },
        checkLocations: -> (response) {
          p '--------------response--------------'
          p response
          p '--------------response--------------'
          session = Rails.cache.read(response['session_id']) || {}
          p '!!!!!!!!!!!!!!!SESSION!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          p session
          p '!!!!!!!!!!!!!!!SESSION!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          result = {}
          station_from = nil
          station_to = nil
          from_entities = response['entities'].try(:[], 'from')
          to_entities = response['entities'].try(:[], 'to')
          date = response['entities'].try(:[], 'date')
          if !from_entities.nil?
            st = TicketsApi.get('rail/station', {name: from_entities[0]['value']}, true).try(:[], 'stations')
            if st.to_a.size > 0
              station_from = st[0]['name']
              session[:from] = station_from
              session[:from_code] = st[0]['code']
            end
          elsif session[:from]
            station_from = session[:from]
          end
          if !to_entities.nil?
            st = TicketsApi.get('rail/station', {name: to_entities[0]['value']}, true).try(:[], 'stations')
            p '========ST TO============='
            p st
            p '========ST TO============='
            if st.to_a.size > 0
              station_to = st[0]['name']
              session[:to] = station_to
              session[:to_code] = st[0]['code']
            end
          elsif session[:to]
            station_to = session[:to]
          end
          if station_from.nil? && station_to.nil?
            result['missingFrom'] = 'missing'
          elsif station_from.nil? || station_to.nil?
            result['missingTo'] = 'missing' if station_to.nil?
            result['missingFrom'] = 'missing' if station_from.nil?
          else
            if !date.nil?
              parsed_date = NLPDate.parse("#{date[0]['value']}")
              p '===============DATE================'
              p parsed_date
              p "#{date[0]['value']}"
              p '===============DATE================'
              if parsed_date
                session[:date] = parsed_date
              end
            end
            if session[:date].nil?
              result['missingDate'] = 'missing'
            else
              result['from'] = station_from
              result['to'] = station_to
              result['date'] = session[:date].strftime('%d-%m-%Y')
            end
          end
          Rails.cache.write(response['session_id'], session)
          return result
        },
        clear_session: -> (response) {
          session = Rails.cache.read(response['session_id']) || {}
          Rails.cache.delete(response['session_id']) unless session.blank?
          return {}
        },
        get_hello: -> (response) {
          p '==========HELLO RESPONSE=============='
          p response
          p '==========HELLO RESPONSE=============='
          return {:test => 'test'}
        }
    }
  end

  def proccess_text(text, quickreplies)
    raise Exception 'Not implemented'
  end

  def run_actions(session_id, text)
    @session_context ||= {}
    @session_context = client.run_actions(session_id, text, @session_context)
    p '!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    p @session_context
    p '!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  end

  def interactive
    client.interactive
  end

  def search_trains
    url = URI.parse("http://127.0.0.1:3001/rail/search.json")
    http = Net::HTTP.new(url.host, url.port)
    response = http.get("#{url.path}?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&from=#{@search_session_data[:from_code]}&to=#{@search_session_data[:to_code]}&date=#{@search_session_data[:date]}")
    result_code = JSON.parse(response.body).try(:[], 'response').try(:[], 'result').try(:[], 'code')
#    p '!!!!!!!!!!!!!!!!!!!!!!!!!'
#    p "?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&from=#{@search_session_data[:from_code]}&to=#{@search_session_data[:to_code]}&date=#{@search_session_data[:date]}"
#    p result_code
#    p JSON.parse(response.body)
#    p '!!!!!!!!!!!!!!!!!!!!!!!!!'
    result_code.to_i unless result_code.nil?
  end

  # end
end
