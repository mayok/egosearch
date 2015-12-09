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

  def get_tweets
    @config["twitter"]["search_word"].map { |word|
      @client.search(word, lang: "ja", result_type: "recent").first
    }
  end

  def check(id)
    if File.exist?(FILENAME) then
      File.open(FILENAME, "r") do |f|
        f.read.split("\n").include?(id.to_s)
      end
    else
      save(0)
      false
    end
  end

  def save(id)
    File.open(FILENAME, "a") do |f|
      f.write(id.to_s + "\n")
    end
  end

  # テキストの整形
  def format(tweet)
    { "text" => "http://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}" }.to_json
  end

  # slack にポストする
  # http://twitter.com/#{screen_name}/status/#{id}
  def post(text)
    request_url = @config["slack"]["webhook_url"]
    uri = URI.parse(request_url)
    Net::HTTP.post_form(uri, {"payload" => text})
  end

  def run
    tweets = get_tweets
    tweets.each do |tweet|
      if check(tweet.id) then exit
      else
        save(tweet.id)
        post(format(tweet))
      end
    end
  end

end

ego = Search.new
ego.run
