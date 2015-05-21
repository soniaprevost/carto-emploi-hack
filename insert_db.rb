require 'pg'
require_relative 'body_parser'
require 'geocoder'

def doc
 @newdoc = ::BodyParser.new
end

puts "new object #{doc}"

url = "https://candidat.pole-emploi.fr/candidat/rechercheoffres/detail/027FLJF"
offer_id = "02''7FL,JF"


#-------------- GETTING DATA FROM PARSING ---------------------
adress = doc.search_region(url)
puts "-------------------------------- adresse : #{adress} "
title = doc.search_title(url)
puts "---------------------------------#{title}"
contrat_type = doc.search_employment_type(url).chop
puts "----------------------#{contrat_type}"
code_rome = doc.search_code_rome(url) #enlever le /n
puts "--------------#{code_rome}"
publication_date = doc.search_publication_date(url)
puts "----------------- #{publication_date}"
offer_description = doc.search_description_offer(url)[0, 8]
offer_description.gsub!(/'/, "''")
puts "------------------- #{offer_description}"
company_description = doc.search_company_description(url)
company_description.gsub!(/'/, "''")
puts "-------------------- #{company_description}"
#--------------END  ------------------

#-------------- GETTING LATITUDE & LONGITUDE ---------------------
d = Geocoder.search(adress)
puts d
ll = d[0].data["geometry"]["location"]
puts "#{adress}\t#{ll['lat']}\t#{ll['lng']}"

latitude = ll['lat']
puts "------------------ #{latitude}"
longitude = ll['lng']




#-------------- INSERT DATAS TO DATABASE---------------------
#----- WATCH OUT URL MUST BE VALID : NO URL, NO DATAS -------


conn = PGconn.connect(:hostaddr=>"127.0.0.1", :port=>5432, :dbname=>"pejoboffers", :user=>"jobadmin", :password=>'Som3ThinG')

conn.exec("INSERT INTO joboffers (region_adress, offer_id, title, contrat_type, code_rome, publication_date, offer_description, url, company_description, latitude, longitude) VALUES ('#{adress}', '#{offer_id}', '#{title}', '#{contrat_type}', '#{code_rome}', '#{publication_date}', '#{offer_description}', '#{url}', '#{company_description}', '#{latitude}', '#{longitude}');")

conn.close



#______________________________________
# conn.exec( "SELECT * FROM joboffers" ) do |result|
#   puts "     region_adress | "
#   puts result
# result.each do |row|
#     puts " %7d | %-16s | %s " %
#       row.values_at('region_adress')
#   end
# end

#------------------- CONNECTING DATA BASE

#query_result  = conn.exec('SELECT * FROM joboffers')

#------------------- INSERT VALUE TO DATA BASE
