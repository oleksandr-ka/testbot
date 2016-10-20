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
          proccess_text(response['text'], response['quickreplies'], request['context'])
        },
        searchTrain: -> (response) {
          result = {
            'searchFail' => 'fail',
            'process_action' => 'search_train'
          }
          session = get_session(response['session_id'])
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
          session = get_session(response['session_id'])
          p '!!!!!!!!!!!!!!!SESSION!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          p session
          p '!!!!!!!!!!!!!!!SESSION!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          result = {'process_action' => 'check_location'}
          station_from = nil
          station_to = nil
          from_entities = response['entities'].try(:[], 'from')
          to_entities = response['entities'].try(:[], 'to')
          date = response['entities'].try(:[], 'date')
          if !from_entities.nil?
            from_entities_value = from_entities[0]['value'].strip.mb_chars.downcase.to_s
            # st = TicketsApi.get('rail/station', {name: from_entities[0]['value']}, true).try(:[], 'stations')
            stations = get_stations(response['session_id'], 'from', from_entities_value)
            if stations.size > 1
              result['many_stations'] = 'many'
              result['stations_from'] = stations
            else
              station_from = stations[0][:name]
              # session[:to] = station_to
              # session[:to_code] = stations[0][:code]
            end
            # if stations.to_a.size > 0
            #   station_from = st[0]['name']
            #   session[:from] = station_from
            #   session[:from_code] = st[0]['code']
            # end
          elsif session[:from]
            station_from = session[:from]
          end
          if !to_entities.nil?
            to_entities_value = to_entities[0]['value'].strip.mb_chars.downcase.to_s
            # st = TicketsApi.get('rail/station', {name: to_entities_value}, true).try(:[], 'stations')
            # p '========ST TO============='
            # p st
            # p '========ST TO============='
            stations = get_stations(response['session_id'], 'to', to_entities_value)
            if stations.size > 0
              # stations = []
              # st.to_a.each do |one_st|
              #   stations << {name: one_st['name'], code: one_st['code']}
              #   if one_st['name'].strip.downcase == to_entities_value
              #     stations = [{name: one_st['name'], code: one_st['code']}]
              #     break
              #   end
              # end
              if stations.size > 1
                result['many_stations'] = 'many'
                result['stations_to'] = stations
              else
                station_to = stations[0][:name]
                # session[:to] = station_to
                # session[:to_code] = stations[0][:code]
              end
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
                # session[:date] = parsed_date
                update_session(response['session_id'], {date: parsed_date})
              end
            end
            date_value = get_session(response['session_id'])[:date]
            if date_value.nil?
              result['missingDate'] = 'missing'
            else
              result['from'] = station_from
              result['to'] = station_to
              result['date'] = date_value.strftime('%d-%m-%Y')
            end
          end
          # update_session(response['session_id'], session)
          # Rails.cache.write(response['session_id'], session)
          return result
        },
        clear_session: -> (response) {
          clear_session(response['session_id'])
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

  def get_stations(session_id, direction, text)
    station_response = TicketsApi.get('rail/station', {name: text}, true).try(:[], 'stations')
    p '========ST TO============='
    p station_response
    p '========ST TO============='
    stations = []
    if station_response.to_a.size > 0
      station_response.to_a.each do |one_st|
        stations << {name: one_st['name'], code: one_st['code']}
        if one_st['name'].strip.mb_chars.downcase.to_s == text
          stations = [{name: one_st['name'], code: one_st['code']}]
          break
        end
      end
      if stations.size == 1
        update_session(session_id, {"#{direction}": stations[0][:name], "#{direction}_code": stations[0][:code]})
      end
    end
    return stations
  end

  def get_session(session_id)
    return Rails.cache.read(session_id) || {}
  end

  def update_session(session_id, data)
    Rails.cache.write(session_id, get_session(session_id).merge(data))
  end

  def clear_session(session_id)
    Rails.cache.delete(session_id)
  end

  def proccess_text(text, quickreplies, context_data)
    raise Exception 'Not implemented'
  end

  def run_actions(session_id, text)
    # session_context = {}
    p '===============CONTEXT======================='
    p (get_session(session_id)[:context] || {})
    session_context = client.run_actions(session_id, text, (get_session(session_id)[:context] || {}))
    update_session(session_id, {context: session_context})
    p session_context
    p '===============CONTEXT======================='
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
