# Semantics Game Scraper Test
# Test runs the game scraper
# test.rb
# 
# Gannon McGibbon
# Date Created: 31/10/2013
# Last Updated: 11/11/2013

require './semantics_game_scraper'

scraper = GameScraper.new

# prints out a list of PS3 games
# list = scraper.get_wiki_games_list "http://en.wikipedia.org/wiki/List_of_PlayStation_3_games"
# list.each {|item| puts item}

puts "Games"
22.times {print "="}
puts

# sample single query
params  = {"cat_id"   => 11932, 
	       "name"     => "Halo 3: ODST", 
	       "platform" => "Xbox 360"}

results = scraper.get_game params
labels  = ["Title","Genre","Price","Developer","Rating","Reseller Site", "Image Source"]
results.each_index do |i|
  puts "#{labels[i]}: #{results[i]}"
end

22.times {print "-"}
puts

# multiple queries
names     = ["Batman: Arkham City","Final Fantasy XIII","Forza Motorsport 4","Uncharted 2",  "Batman: Arkham Asylum","Resistance 2"]
platforms = ["Xbox 360",           "Playstation 3",     "Xbox 360",          "Playstation 3","Xbox 360",             "Playstation 3"]
labels    = ["Title","Genre","Price","Developer","Rating","Reseller Site", "Image Source"]
params    = {"cat_id" => 11932, "name" => "", "platform" => ""}

names.each_index do |i|
	params["name"] = names[i]
	params["platform"] = platforms[i]

	results= scraper.get_game params

	results.each_index do |i|
  	puts "#{labels[i]}: #{results[i]}"
	end

	22.times {print "-"}
	puts
end

puts "*** Image Source is an educated guess and may not always be accurate! ***"

22.times {print "-"}
puts