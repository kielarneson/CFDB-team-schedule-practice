require "net/http"
require "json"
require "uri"

class EventsController < ApplicationController
  def index
    # Getting schedule infomation for a specific team using Seat Geek API
    response = HTTP.get("https://api.seatgeek.com/2/events?q=#{params[:team]}&client_id=MzA3NTE0OHwxNjMxOTEyOTc1LjMzNDA4NA&client_secret=#{Rails.application.credentials.seat_geek_api_key}")
    events = JSON.parse(response.body)

    # Mapping each game on a team's schedule
    games = events["events"].map { |game| game }

    # Defining variables to be used in the loop
    # This is where we will store all of our information
    info = []
    # Week count
    week = 3

    # Looping through each game
    games.each do |game|
      home_team = game["performers"][0]["name"]
      away_team = game["performers"][1]["name"]

      # Function to get the right team name construction for use with CFDB API
      # Currently only works 100% of the time with SEC teams
      def cfdb_team_key(team)
        if team.split(" ")[1] == "Miss" || team.split(" ")[1] == "State" || team.split(" ")[1] == "Carolina" || team.split(" ")[1] == "A&M"
          team_name = "#{team.split(" ")[0]} #{team.split(" ")[1]}"
        else
          team_name = "#{team.split(" ")[0]}"
        end
        return team_name
      end

      # Home team name
      home_team = cfdb_team_key(home_team)
      # Away team name
      away_team = cfdb_team_key(away_team)

      # CFDB active_players request
      def active_players(team)
        uri = URI.parse("https://api.collegefootballdata.com/roster?team=#{team}&year=2021")
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["Authorization"] = "Bearer "
        req_options = {
          use_ssl: uri.scheme == "https",
        }
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        active_players = JSON.parse(response.body)

        # Getting real player names and sorting them alphabetically
        return active_players.select { |player| player["first_name"] != nil }.map { |player| "#{player["last_name"]}, #{player["first_name"]}" }.sort
      end

      # Getting home team active_players
      home_team_active_players = active_players(home_team)
      # Getting away team active_players
      away_team_active_players = active_players(away_team)

      # Getting weather date from weather API
      response = HTTP.get("https://api.openweathermap.org/data/2.5/weather?q=#{game["venue"]["city"]}&units=imperial&appid=#{Rails.application.credentials.weather_api_key}")
      weather = JSON.parse(response.body)

      # Storing information for each game
      info << { "week_#{week}": {
        game: game["title"],
        venue: game["venue"]["name"],
        city: game["venue"]["city"],
        temperature: weather["main"]["feels_like"],
        home_team_players: home_team_active_players,
        away_team_players: away_team_active_players,
      } }

      # Indexing the week count
      week += 1
    end
    # Displaying information
    render json: info
  end
end
