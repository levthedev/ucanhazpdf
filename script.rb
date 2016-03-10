require 'twitter'
require 'gmail'

class TweetParser
  attr_accessor :client, :doi, :email
  EMAIL_REGEX = /\S+@\S+/
  DOI_REGEX = /(10.(\d)+\/(\S)+)/

  def initialize
    @client = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = ENV["consumer_key"]
      config.consumer_secret     = ENV["consumer_secret"]
      config.access_token        = ENV["access_token"]
      config.access_token_secret = ENV["access_token_secret"]
    end
  end

  def check_for_DOI(tweet)
    doi = tweet.text.match(DOI_REGEX).to_s
    if doi.empty?
      expand_link(tweet)
    else
      check_for_email(tweet, doi)
    end
  end

  def expand_link(tweet)
    tweet.urls.map do |url|
      cleaned_doi = url.expanded_url.to_s.match(DOI_REGEX).to_s
      if !cleaned_doi.empty?
        check_for_email(tweet, cleaned_doi)
      end
    end
  end

  def check_for_email(tweet, doi)
    email = tweet.text.match(EMAIL_REGEX).to_s
    puts email
    puts doi
    unless email.empty?
      send_email(doi, email)
    end
  end

  def send_email(doi, email)
    link = "sci-hub.io/#{doi}"

    Gmail.connect!(ENV["gmail_username"], ENV["gmail_password"]) do |gmail|
      gmail.deliver do
        to "#{email}"
        subject "PDF you requested :)"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body "<p>Hi there! I am a bot made to help nice people like yourself find research papers. I included a link to an online version at the bottom of this email. The link might require you to enter a Captcha code, and if the paper appears blank, try refreshing the page a few times.</p><p>Please respond back to this if you didn't intend to get a research paper or if the article I sent you is broken/incorrect. Thanks!</p> Here is your link - #{link}"
        end
      end
    end
  end

  def filter
    @client.filter(track: "icanhazpdf") do |tweet|
      check_for_DOI tweet
    end
  end
end

x = TweetParser.new
x.filter
