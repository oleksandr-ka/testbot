require "wit"
require "tickets_api"
require "nlp_date"

module NLP

  LOCALES = {
    uk: 'Українська',
    ru: 'Руский'
  }

  WIT_LOCALES = {
    uk: 'RYZZVM3TRHSIJW3IVMXXO3RR66QT3CFT',
    ru: 'FPHIJCQ2D6SC5DHKL3XK3HDQS77VFRVH'
  }

  def client(locale)
    @client ||= Wit.new(access_token: WIT_LOCALES[locale], actions: actions)
  end

  def actions
    {
      send: -> (request, response) {
        p '--------------WIT response--------------'
        p response
        p '--------------WIT request---------------'
        p request
        p '-----------------WIT-------------------'
        proccess_text(response['text'], response['quickreplies'], request['context'])
      },
      searchTrain: -> (response) {
        result = {
          'search_fail' => 'fail',
          'search_url' => 'https://gd.tickets.ua'
        }
        session = get_session(response['session_id'])
        search_result = TicketsApi.get('rail/search', {from: session[:from_code], to: session[:to_code], date: session[:date].to_date.strftime('%d-%m-%Y')})
        search_result_status_code = search_result.try(:[], 'result').try(:[], 'code')
        if !search_result_status_code.nil? && search_result_status_code.to_i == 0
          result = {
            'search_success' => 'success',
            'search_url' => "https://gd.tickets.ua/preloader/~#{session[:from_code]}~#{session[:to_code]}~#{session[:date].to_date.strftime("%d.%m.%Y")}~1~ukraine~~~~~/",
            'trains_count' => search_result['trains'].size,
            'trains_descriptions' => search_result['trains'].map{ |train| "#{train['number']}" }.join(", ")
          }
          clear_session(response['session_id'])
        elsif !search_result_status_code.nil?
          result["error#{search_result_status_code}"] = 'error'
        end
        result['process_action'] = 'search_train'
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
        location_entities = response['entities'].try(:[], 'location')
        date = response['entities'].try(:[], 'date')
        if !from_entities.nil?
          from_entities_value = from_entities[0]['value'].strip.mb_chars.downcase.to_s
          stations = get_stations(response['session_id'], 'from', from_entities_value)
          if stations.size > 1
            result['many_stations'] = 'many'
            result['stations_from'] = stations
          else
            station_from = stations[0][:name]
          end if stations.size > 0
        elsif session[:from]
          station_from = session[:from]
        end
        if !to_entities.nil?
          to_entities_value = to_entities[0]['value'].strip.mb_chars.downcase.to_s
          stations = get_stations(response['session_id'], 'to', to_entities_value)
          if stations.size > 1
            result['many_stations'] = 'many'
            result['stations_to'] = stations
          else
            station_to = stations[0][:name]
          end if stations.size > 0
        elsif session[:to]
          station_to = session[:to]
        end
        location_direction = false
        if !location_entities.nil?
          location_entities_value = location_entities[0]['value'].strip.mb_chars.downcase.to_s
          location_direction = station_from.nil? ? 'from' : 'to'
          stations = get_stations(response['session_id'], location_direction, location_entities_value)
          if stations.size > 1
            result['many_stations'] = 'many'
            result["stations_#{location_direction}"] = stations
          else
            eval("station_#{location_direction} = \"#{stations[0][:name]}\"")
          end if stations.size > 0
        end
        if !date.nil?
          parsed_date = NLPDate.parse("#{date[0]['value']}")
          if parsed_date
            update_session(response['session_id'], {date: parsed_date})
          end
        end

        if station_from.nil? || station_to.nil?
          if station_from.nil? && (!from_entities.nil? || location_direction == 'from')
            result['missing_from'] = 'missing'
            result['checked_location'] = (location_entities_value || from_entities)[0]['value']
          elsif station_to.nil? && (!to_entities.nil? || location_direction == 'to')
            result['missing_to'] = 'missing'
            result['checked_location'] = (location_entities_value || to_entities)[0]['value']
          else
            result['missing_to'] = 'missing' if station_to.nil?
            result['missing_from'] = 'missing' if station_from.nil?
          end
        else
          date_value = get_session(response['session_id'])[:date]
          if date_value.nil?
            result['missing_date'] = 'missing'
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
    p '===============STATIONS===================='
    p stations
    p '===============STATIONS===================='
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
    p '===============CONTEXT======================='
    p (get_session(session_id)[:context] || {})
    session_context = client(get_user_locale(session_id)).run_actions("#{session_id}-#{get_user_locale(session_id)}", text, (set_context ? (get_session(session_id)[:context] || {}) : {}))
    update_session(session_id, {context: session_context})
    p session_context
    p '===============CONTEXT======================='
  end

  def get_user(session_id)
    return (Rails.cache.read("user_#{session_id}") || {})
  end

  def set_user_data(session_id, data)
    Rails.cache.write("user_#{session_id}", get_user(session_id).merge(data))
  end

  def get_user_locale(session_id)
    user_locale = get_user(session_id)[:locale]
    if user_locale
      user_locale = WIT_LOCALES.keys.include?(user_locale) ? user_locale : WIT_LOCALES.keys.first
    else
      user_locale = WIT_LOCALES.keys.first
    end
    return user_locale
  end

  #
  # Interactive mode for testing
  #
  def interactive
    client.interactive
  end

end
