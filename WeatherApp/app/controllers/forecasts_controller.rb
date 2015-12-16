class ForecastsController < ApplicationController
  
  before_action :authenticate_user!, :except => [:index]

    
    def index
        @forecast = Forecast.new
        
        if user_signed_in?
            @forecasts = Forecast.where(user_id: current_user.id)
        end    
        
        # Define city and state
        
        if params[:city]
            @city = params[:city]
            @state = params[:state]
        elsif user_signed_in? && Forecast.where(user_id: current_user.id).exists?
            @city = Forecast.where(user_id: current_user.id).first["city_name"]
            @state = Forecast.where(user_id: current_user.id).first["state_code"]
        
        else
            @city = "San Francisco"
            @state = "CA"
        end
        
        # Get weather from API
        
        request = Typhoeus::Request.new(
			    URI.encode("http://api.wunderground.com/api/#{ENV["wunderground_api_key"]}/forecast/q/#{@state}/#{@city.gsub(" ", "_")}.json"), method: :get)
	    request.run
	    weather_json = JSON.parse(request.response.body)
		@weather = weather_json["forecast"]["simpleforecast"]["forecastday"]
		
	    # Get internal logic file
	    
	    require 'json'
        file = File.read("#{Rails.root}/public/data.json")
        logic = JSON.parse(file)
        
        # Create array of days with hash of weather and clothing values
        
        @forecast_hash = []
        
        @weather.each do |day|
           
           forecast = {
                "weekday" => day["date"]["weekday"],
                "high_temp"=> day["high"]["fahrenheit"],
                "low_temp"=> day["low"]["fahrenheit"],
                "conditions"=> day["conditions"],
                "rain" => day["pop"]
                }
           
           @high_temp = day["high"]["fahrenheit"].to_i
           
           logic["ranges"].each do |h| 
                if h["max_temp"] >= @high_temp && h["min_temp"] <= @high_temp
                    @outfit = h["outfits"].sample
                end    
            end
            
            clothing = []
            image_urls = []
            
            @outfit.each do |item|
                @item = item
                
                request = Typhoeus::Request.new(
		            URI.encode("http://api.shopstyle.com/api/v2/products?pid=#{ENV["shopstyle_api_key"]}&fts=womens+#{@item.gsub(" ", "+")}&offset=#{rand(14)}&limit=15"), method: :get)
		        request.run
	            fashion_json = JSON.parse(request.response.body)
	            
	            clothing << item
	        	image_urls << fashion_json["products"][0]["image"]["sizes"]["IPhone"]["url"]    
            end
            
            forecast["clothes"] = clothing
            forecast["image_url"] = image_urls
            
            @forecast_hash << forecast
            
        end    
      
    end
    
    
    def create
        
        new_forecast = Forecast.create(forecast_params)
        
        redirect_to "/"
        
    end  
    
    def destroy
       Forecast.find(params[:id]).destroy
       redirect_to "/"
    end    
    
private 

    def forecast_params
        params.require(:forecast).permit(:city_name, :state_code, :user_id).merge(user_id: current_user.id)
    end    
    
end
