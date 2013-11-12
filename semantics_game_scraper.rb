# Semantics Game Scraper
# Queries and scrapes information about video games
# semantics_game_scraper.rb
# 
# Gannon McGibbon
# Date Created: 31/10/2013
# Last Updated: 11/11/2013

require 'rubygems'
require 'mechanize'
require 'semantics3'
require 'money'

# API documentation here: https://www.semantics3.com/docs/
# Get keys here: https://www.semantics3.com/
API_KEY    = ""
API_SECRET = ""

# Add pan to String class
class String

  # downcase, strip, and remove special characters
  def pan
    self.downcase.strip.gsub(/[^0-9A-Za-z]/, "")
  end

end

# Finds information on games 
class GameScraper

  # add an exchange rate, initalize semantics products and mechanize agent
  def initialize
    Money.add_rate("USD", "CAD", 1.04)
  	@sem_prod_query = Semantics3::Products.new(API_KEY,API_SECRET)
    @agent = Mechanize.new
    @agent.user_agent_alias = "Linux Mozilla" #spoof header
  end

  # Obtain a list of games with a wikipedia uri
  # 
  # PS3 Games:      "http://en.wikipedia.org/wiki/List_of_PlayStation_3_games"
  # XBOX 360 Games: "http://en.wikipedia.org/wiki/List_of_Xbox_360_games"
  # Wii U Games:    "http://en.wikipedia.org/wiki/List_of_Wii_U_games"
  def get_wiki_games_list wiki_uri
  	list    = []
    page    = nav_to wiki_uri
    table   = page
      .search("table.wikitable:first-of-type, table.sortable:first-of-type")
      # find first sortable wikitable table 
    elements = table.children # obtain table's trs

    elements.each do |elem|
      title   = elem.search("i") # find the i tag of the tr

      # if a title ws found in the i tag, capture it
      if title !=""
        title = title.text
      # if not, extract it from the a tag in the i tag
      else
        title = title.search("a").text
      end

      # push title to list and remove any square bracket text
      list.push title.sub(/\[{1}[0-9].*\]{1}/,"")
    end
    list
  end

  # Queries a game using a hash of queries (see test.rb for an example)
  def get_game query_hash
    # get a result set from query game
    response  = query_game query_hash
    # obtain a game info array using the result set, name, and platform
    game_info = parse_game response, query_hash["name"], query_hash["platform"]
    # push the returned box art url to the end of game info
    game_info << get_box_art_uri(query_hash["name"], game_info.last)

    game_info
  end

  protected

  # Query a game using a hash of queries
  def query_game query_hash
  	queries_arr   = query_hash.to_a # convert query hash to an array

    # add query parameters to query object
  	query_hash.each do |vals|
  		@sem_prod_query.products_field vals.first, vals.last
  	end

    # obtain hashed response from query object
		products_hash = @sem_prod_query.get_products
  end

  # Parses a result set into name, genre, price, rating, developer, and reseller url
  def parse_game result_set, game_name, game_platform

  	name         = ""
  	genre        = ""
  	price        = ""
  	rating       = ""
  	developer    = ""
  	reseller_url = ""

    # iterate through each result in set
  	result_set["results"].each do |rset|

      # puts rset # display each result hash as it is processed

			begin
        # if panned name and platform in result match passed values
				if rset["name"].pan.include?(game_name.pan) && 
          rset["platform"].downcase.strip.include?(game_platform.downcase.strip)

          # store each value for result
					name         = rset["name"]
					price        = Money.new(rset["price"].sub(".",""),"USD").exchange_to("CAD")
					genre        = rset["genre"]
					developer    = rset["features"]["Developer"]
					rating       = rset["features"]["ESRB Rating"]
          reseller_url = rset["sitedetails"].each.reduce(Hash.new, :merge)["url"]
					
          # has result provided all the needed values?
					break unless name.empty? or price.to_s.empty? or genre.empty? or rating.empty?
				end
			rescue #=> err
				# a problem reading hashes
        # puts err.inspect
			end
		end

		[name,genre,price,developer,rating,reseller_url]
  end

  # Returns a box art url using a reseller url 
  def get_box_art_uri name, uri
    selected_url = ""

    # continue only if url is not empty
    if not uri.empty?
      
      page = nav_to uri

      # capture image elements
      img_elems = page.images.uniq {|img| img.src}

      #iterate through each image url
      img_elems.each_index do |i|
        
        # if url contains the word product
        if img_elems[i].src.to_s.pan.include?("product")
          # if the image has a .jpg extension
          if (img_elems[i].src.to_s[(img_elems[i].src.to_s.length() -8)..-1].include?(".jpg"))
            # select this url as box art url
            selected_url = img_elems[i].src unless #frys product fix
                                       (img_elems[i].src.to_s.include?(".big.") and 
                                       img_elems[i].src.to_s.include?("frys.com"))
            # if image element alt or title attribs contain game name ignoring numbers
            if img_elems[i].alt.to_s.pan.sub(/[0-9]/,"").include?(name.pan.sub(/[0-9]/,"")) or 
              img_elems[i].title.to_s.pan.sub(/[0-9]/,"").include?(name.pan.sub(/[0-9]/,""))
              break
            end
          end
        end
      end
    end
    selected_url
  end

  # Navigates mechanize agent to a passed uri
  def nav_to uri
    begin
      page = @agent.get uri
    rescue Mechanize::ResponseReadError => e
      page = e.force_parse
    end
  end

end


