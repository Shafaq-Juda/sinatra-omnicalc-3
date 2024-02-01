require "sinatra"
require "sinatra/reloader"
require "better_errors"
require "http"
require "sinatra/cookies"

# Need this configuration for better_errors
use(BetterErrors::Middleware)
BetterErrors.application_root = __dir__
BetterErrors::Middleware.allow_ip!('0.0.0.0/0.0.0.0')


get("/") do
    erb(:homepage)
end

get("/umbrella") do
    erb(:umbrella_form)
end

get("/message") do
    erb(:message)
end

get("/chat") do
    erb(:chat)
end

post("/process_umbrella") do
    @user_location = params.fetch("user_loc")
    if_user_location_with_spaces = @user_location.gsub(" ", "+")
    gmaps_key = ENV.fetch("GMAPS_KEY")

    gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?
    address=#{if_user_location_with_spaces}&key=#{gmaps_key}"

    @raw_response = HTTP.get(gmaps_url).to_s
    @parsed_response = JSON.parse(@raw_response)

    # Now to fetch out lat and long we need to dig in the hashes and arrays
    results_array = parsed_response.fetch("results")

    first_result_hash = results_array.at(0)

    geometry_hash = first_result_hash.fetch("geometry")

    location_hash = geometry_hash.fetch("location")

    # Finally we got lat and long
    @latitude = location_hash.fetch("lat")
    @longitude = location_hash.fetch("lng")

    cookies["last_location"] = @user_location # I can also use cookies.store("last_location", "@user_location")
    cookies["last_latitude"] =  @latitude
    cookies["last_longitude"] = @longitude

    # To find current temp and summary we need to fetch from this hash (hash of weather api) its like hash in a hash
   # "currently": {"time": 1706770320, "summary": "Clear", "icon": "clear-night", "nearestStormDistance": 0, "nearestStormBearing": 0, "precipIntensity": 0.0, "precipProbability": 0.0, "precipIntensityError": 0.0, "precipType": "none", "temperature": 33.98, "apparentTemperature": 27.51, "dewPoint": 32.97, "humidity": 0.9, "pressure": 993.5, "windSpeed": 7.53, "windGust": 14.94, "windBearing": 230, "cloudCover": 0.08, "uvIndex": 0.0, "visibility": 8.64, "ozone": 351.49},
    # We will need to fetch currently then temperature then summary

    weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
    weather_url = "https://api.pirateweather.net/forecast/#{weather_key}/#{@latitude},#{@longitude}"


    erb(:umbrella_results)
end

# This is incomplete till now
