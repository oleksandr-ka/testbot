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
          search_result = TicketsApi.get('rail/search', {from: session[:from_code], to: session[:to_code], date: session[:date].to_date.strftime('%d-%m-%Y')})
          search_result_status_code = search_result.try(:[], 'result').try(:[], 'code')
          if !search_result_status_code.nil? && search_result_status_code.to_i == 0
            result = {
              'yes_no' => 'yes',
              'searchSuccess' => "https://gd.tickets.ua/preloader/~#{session[:from_code]}~#{session[:to_code]}~#{session[:date].to_date.strftime('%d.%m.%Y')}~1~ukraine~~~~~/",
              'trains_count' => search_result['trains'].size,
              'trains_descriptions' => search_result['trains'].map{ |train| "#{train['number']}" }.join("\n")
            }
            clear_session(response['session_id'])
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
            stations = get_stations(response['session_id'], 'from', from_entities_value)
            if stations.size > 1
              result['many_stations'] = 'many'
              result['stations_from'] = stations
            else
              station_from = stations[0][:name]
            end
          elsif session[:from]
            station_from = session[:from]
          end
          if !to_entities.nil?
            to_entities_value = to_entities[0]['value'].strip.mb_chars.downcase.to_s
            stations = get_stations(response['session_id'], 'to', to_entities_value)
            if stations.size > 0
              if stations.size > 1
                result['many_stations'] = 'many'
                result['stations_to'] = stations
              else
                station_to = stations[0][:name]
              end
            end
          elsif session[:to]
            station_to = session[:to]
          end
          if !date.nil?
            parsed_date = NLPDate.parse("#{date[0]['value']}")
            if parsed_date
              update_session(response['session_id'], {date: parsed_date})
            end
          end
          if station_from.nil? && station_to.nil?
            result['missingFrom'] = 'missing'
          elsif station_from.nil? || station_to.nil?
            result['missingTo'] = 'missing' if station_to.nil?
            result['missingFrom'] = 'missing' if station_from.nil?
          else
            date_value = get_session(response['session_id'])[:date]
            if date_value.nil?
              result['missingDate'] = 'missing'
            else
              result['from'] = station_from
              result['to'] = station_to
              result['date'] = date_value.strftime('%d-%m-%Y')
            end
          end
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
        stations << {name: one_st['name'], code: one_st['code'], railroad: one_st['railroad']}
        if one_st['name'].strip.mb_chars.downcase.to_s == text
          stations = [{name: one_st['name'], code: one_st['code'], railroad: one_st['railroad']}]
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
    raise 'Not implemented'
  end

  def run_actions(session_id, text, set_context = false)
    # session_context = {}
    p '===============CONTEXT======================='
    p (get_session(session_id)[:context] || {})
    session_context = client.run_actions(session_id, text, (set_context ? (get_session(session_id)[:context] || {}) : {}))
    update_session(session_id, {context: session_context})
    p session_context
    p '===============CONTEXT======================='
  end

  #
  # Interactive mode for testing
  #
  def interactive
    client.interactive
  end

end
