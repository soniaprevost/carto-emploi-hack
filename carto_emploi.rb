require 'sinatra'
require 'json'
require 'active_support/all'
require 'active_record'
require 'sinatra/activerecord'
require './lib/pg_db_config_parse'

# ----------------- CONFIGURATION DATAS ----------------------
configure { set :server, :puma }
set :public_folder, 'public'

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'super secret'
end

#------------------------ config.time_zone = 'Europe/Paris'-----
Time.zone = "UTC"
ActiveRecord::Base.default_timezone = :utc


set :public_folder, 'frontend' #this is necessary to be able to access to static files
get '/' do
  redirect '/index.html' #The root of the project is /frontend so the absolute path to static files doesn't need /frontend in front
end

#----------------- /metiers : renvoie la liste des metiers
get '/metiers' do
  content_type :json, 'charset' => 'utf-8'
  class Job_list < ActiveRecord::Base
  end
  @metiers = Job_list.all().to_json
end

#--------------   /geosearch/LAT,LNG : renvoie les emplois aux alentours
get '/geosearch/:lat,:lng' do
  #geosearch/48.86833,2.66833?p=42&limit=42&text=developpeur LAGNY SUR MARNE
  #TESTER AVEC CES VALEURS POUR EVRY
  # @lat = 48.629828
  # @lng = 2.441782

  content_type :json, 'charset' => 'utf-8'

  @lat = params[:lat]
  @lng = params[:lng]
  job = params['text']
  @distance = params['d']
  page = params['p'].to_i
  limit_given = params['limit'].to_i
  @data_job = []
  bg_offers = 0
  lang = params[:lg]

  if @distance == nil || @distance == ""
    @distance = 50
  end

  #////////////////////////////// PAGINATION ///////////////////////
  #----------- Counting number of all offers in database -----------------------
  total_offers = CONN.exec("SELECT COUNT (id_key) FROM job_offers")
  @total = total_offers[0]["count"].to_i

  puts "---------------> number of offers in db #{@total}"

  if limit_given == 0 #afficher, 10, 20 ou 50 annonces, bouge suivant le nbre d'offers disponibles dans la BDD
    limit = 100 #afficher, 10, 20 ou 50 annonces, nombre fixe
    bg_offers = limit_given
    page = 0
    all_pages = (@total.to_f / limit).ceil
  else
    limit = limit_given
    all_pages = (@total.to_f / limit).ceil
    bg_offers = limit_given - limit
    if page >= 1 && page <= all_pages
      bg_offers = limit_given * (page - 1)
    end
  end
  #///////////////////////////// ENF OF PAGINATION ////////////////////////

  if job == nil || job == ""
    sql = ""
  else
    #sql = "AND to_tsvector('french', offer_description || ' ' || title) @@ plainto_tsquery('french', '#{job}')"
    sql = "AND title LIKE '%#{job}%'"
  end

    if lang == nil || lang == ""
    sql2 = ""
  else
    sql2 = "AND title LIKE '%#{lang}%'"
  end

  requete_sql = "SELECT *, distance FROM (SELECT *, ( 6371 * acos( cos( radians( #{@lat} ) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians(#{@lng}) ) + sin( radians(#{@lat}) ) * sin( radians( latitude ) ) ) ) AS distance FROM job_offers ) AS dt WHERE distance < #{@distance} #{sql} #{sql2} ORDER BY publication_date DESC LIMIT #{limit} OFFSET #{bg_offers} ;"
  result = CONN.exec(requete_sql)

  result.map do |data|
    puts "---- #{data["publication_date"]}  // //  #{data["region_adress"]} //  #{data["id_key"]} // #{data["offer_id"]} : #{data["title"]}"
    @data_job << data
  end

  @data_job.to_json

  # if @data_job == [] #an empty data is analysed by index.html
  #   [].to_json
  # else
  #   @data_job.to_json
  # end

end
