require "wit"
require "tickets_api"

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
          proccess_text(response['text'])
        },
        searchTrain: -> (response) {
          result = {'searchFail' => 'fail'}
          if search_trains == 0
            result = {
                'yes_no' => 'yes',
                'searchSuccess' => "https://gd.tickets.ua.local2/preloader/~#{@search_session_data[:from_code]}~#{@search_session_data[:to_code]}~#{Date.parse(@search_session_data[:date]).strftime('%d.%m.%Y')}~1~ukraine~~~~~/"
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
            st = TicketsApi.get('rail/station', {name: from_entities[0]['value']}, true).try(:[], 'stations')
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
            parsed_date = (Date.parse("#{date}") rescue nil)
            if parsed_date
              result['from'] = station_from
              result['to'] = station_to
              result['date'] = parsed_date.strftime('%d-%m-%Y')
              session[:date] = result['date']
            else
              result['missingDate'] = 'missing'
            end
          end
          Rails.cache.write(response['session_id'], session)
          return result
        }
    }
  end

  def proccess_text(text)
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
