class EventsController < ApplicationController
  def index
    response = HTTP.get("https://api.seatgeek.com/2/events?q=#{params[:team]}&client_id=MzA3NTE0OHwxNjMxOTEyOTc1LjMzNDA4NA&client_secret=#{Rails.application.credentials.seat_geek_api_key}")
    events = JSON.parse(response.body)

    games = events["events"].map { |game| game }
    cities = events["events"].map { |city| city["venue"]["city"] }

    info = []
    games.each do |game|
      response = HTTP.get("https://api.openweathermap.org/data/2.5/weather?q=#{game["venue"]["city"]}&units=imperial&appid=#{Rails.application.credentials.weather_api_key}")
      weather = JSON.parse(response.body)
      info << { game: game["title"], city_name: game["venue"]["city"], temperature: weather["main"]["feels_like"] }
    end
    render json: info
  end
end
