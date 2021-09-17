class EventsController < ApplicationController
  def index
    response = HTTP.get("https://api.seatgeek.com/2/events?q=#{params[:team]}&client_id=MzA3NTE0OHwxNjMxODkzNDk1LjM1ODYyMjg&client_secret=c938cb14d832601d646e7d02bd49c483fc4446a53a689eb3ecdc50036142f918")
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
