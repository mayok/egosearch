require 'twitter'
require 'net/http'
require 'json'
require 'uri'
require 'yaml'

class Search
  
  FILENAME = "./.egosearch"

  def initialize
    @config = YAML.load_file("./config.yml")

    @client = Twitter::REST::Client.new do |c|
      c.consumer_key        = @config["twitter"]["consumer_key"]
      c.consumer_secret     = @config["twitter"]["consumer_secret"]
      c.access_token        = @config["twitter"]["access_token"]
      c.access_token_secret = @config["twitter"]["access_token_secret"]
    end
  end

  def get_tweet
    @client.search(@config["twitter"]["search_word"], lang: "ja", locale: "ja", result_type: "recent").first
  end

  def check(id)
    if File.exist?(FILENAME) then
      File.open(FILENAME, "r") do |f|
        f.read.split('\n')[0]
      end
    else
      save(0)
    end
  end

  def save(id)
    File.open(FILENAME, "w") do |f|
      f.write(id)
    end
  end

  def format(tweet)
    # テキストの整形
    data = {
      "text" => "http://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
    }
    data.to_json
  end

  def post(text)
    # slack にポストする
    # http://twitter.com/#{screen_name}/status/#{id}
    request_url = @config["slack"]["webhook_url"]
    uri = URI.parse(request_url)
    Net::HTTP.post_form(uri, {"payload" => text})
  end

  def run
    tweet = get_tweet
    if tweet.id.to_s == check(tweet.id) then exit
    else 
      save(tweet.id)
      post(format(tweet))
    end
  end

end

ego = Search.new
ego.run
