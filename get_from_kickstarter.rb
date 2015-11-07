require "bundler/setup"
require "typhoeus"
require "redis"

class Cache
  def initialize
    url = ENV["REDISTOGO_URL"]
    @redis = url.nil? ? Redis.new : Redis.new(url: url)
  end

  def get(request)
    response_body = @redis.get url_id(request.base_url)
    if response_body && JSON.parse(response_body)["error"].nil?
      Typhoeus::Response.new(return_code: :ok, code: 200, body: response_body)
    else
      nil
    end
  end

  def set(request, response)
     @redis.set url_id(request.base_url), response.body
  rescue Exception => e
    # probably because of redis memory limit
    puts "Couldn't cache #{request.base_url}"
  end

  def url_id(url)
    uri = URI.parse url
    uri.path + "?" + uri.query
  end
end

module KickstartRequestBuilder
  extend self

  PER_PAGE = 40 # maximum
  PATH ||= "https://www.kickstarter.com/discover/advanced"
  OPTIONS = {
    all_by_popularity: {
      state: "live",
      woe_id: 0,
      sort: "popularity",
      per_page: PER_PAGE
    }
  }

  def build(*args, &block)
    uri = build_url(*args)
    req = Typhoeus::Request.new(uri, method: :get, headers: { "Accept" => "application/json" })
    req.on_complete do |response|
      if response.success?
        json = JSON.parse(response.body)
        if json["error"].nil?
          puts "[OK-#{response.cached?}] #{uri}"
          block.call(json)
        else
          puts "[JSON-ERROR-#{response.cached?}] #{uri}"
        end
      else
        puts "[FAIL-#{response.cached?}] #{uri}"
      end
    end
    req
  end

private

  def build_url(type, page: )
    options = OPTIONS[type].merge(page: page)
    PATH + "?" + to_query(options)
  end

  def to_query(options)
    options.to_a.sort_by(&:first).map{|pair| pair.join("=")}.join("&")
  end
end

module KickstartConsumer
  extend self

  def each_page(type, &block)
    KickstartRequestBuilder.build(:all_by_popularity, page: 1) do |json|
      block.call(json)
      pages = (json["total_hits"] / KickstartRequestBuilder::PER_PAGE.to_f).ceil
      reqs = (2..pages).to_a.map do |page|
        KickstartRequestBuilder.build(:all_by_popularity, page: page) do |json|
          block.call(json)
        end
      end
      hydra = Typhoeus::Hydra.new(max_concurrency: 200)
      reqs.each{|req| hydra.queue(req)}
      hydra.run
    end.run
  end
end

Typhoeus::Config.cache ||= Cache.new

KickstartConsumer.each_page :all_by_popularity do |json|
  p json
end
