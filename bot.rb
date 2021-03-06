require 'slack-ruby-client'
require 'logging'

logger = Logging.logger(STDOUT)
logger.level = :debug

EMOJI = %w(:nail_care: :speech_balloon: :boom: :eyes: :floppy_disk: :e-mail: :sexynam: :sparkling_heart: :dancers: :haircut: :saxophone: :pray: :yoda: :clubs: :soon: :circus_tent: :eggplant: :snowman: :rip: :cool: :repeat: :smoking: :moneybag:)
REGEX = Regexp.new("([a-zA-Z]{2,6}-[0-9]{1,4})+")
REJECT = Regexp.new("TONE") # skin tone

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  if not config.token
    logger.fatal('Missing ENV[SLACK_TOKEN]! Exiting program')
    exit
  end
end

client = Slack::RealTime::Client.new

# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

# listen for channel_joined event - https://api.slack.com/events/channel_joined
client.on :channel_joined do |data|
  if joiner_is_bot?(client, data)
    # client.message channel: data['channel']['id'], text: "Thanks for the invite! I don\'t do much yet, but #{help}"
    logger.debug("#{client.self['name']} joined channel #{data['channel']['id']}")
  else
    # logger.debug("Someone far less important than #{client.self['name']} joined #{data['channel']['id']}")
  end
end

# listen for message event - https://api.slack.com/events/message
client.on :message do |data|

  # when 'hi', 'bot hi' then
  #   client.typing channel: data['channel']
  #   client.message channel: data['channel'], text: "Hello <@#{data['user']}>."
  #   logger.debug("<@#{data['user']}> said hi")

  #   if direct_message?(data)
  #     client.message channel: data['channel'], text: "It\'s nice to talk to you directly."
  #     logger.debug("And it was a direct message")
  #   end

  # when 'attachment', 'bot attachment' then
  #   # attachment messages require using web_client
  #   client.web_client.chat_postMessage(post_message_payload(data))
  #   logger.debug("Attachment message posted")

  # when 'bot help', 'help' then
  #   client.message channel: data['channel'], text: help
  #   logger.debug("A call for help")

  # when /^bot/ then
  #   client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, I don\'t understand. \n#{help}"
  #   logger.debug("Unknown command")


  if data['text'] =~ bot_mentioned(client)
    client.message channel: data['channel'], text: EMOJI.sample
    logger.debug("Bot mentioned in channel #{data['channel']}")
  end

  if data['text'] && ((matches = data['text'].scan(REGEX)).length > 0) then
    if data['text'] !~ /https:\/\//
      matches.flatten.map(&:upcase).uniq.each do |match|
        if match !~ REJECT
          client.message channel: data['channel'], text: "https://vicedev.atlassian.net/browse/#{match}"
          logger.debug("Bot linked issue #{match} in #{data['channel']}")
        end
      end
    end
  end

end

# def direct_message?(data)
#   # direct message channles start with a 'D'
#   data['channel'][0] == 'D'
# end

def bot_mentioned(client)
  # match on any instances of `<@bot_id>` in the message
  /\<\@#{client.self['id']}\>+/
end

def joiner_is_bot?(client, data)
 /^\<\@#{client.self['id']}\>/.match data['channel']['latest']['text']
end

def help
  # %Q(I will respond to the following messages: \n
  #     `bot hi` for a simple message.\n
  #     `bot attachment` to see a Slack attachment message.\n
  #     `@<your bot\'s name>` to demonstrate detecting a mention.\n
  #     `bot help` to see this again.)
end

# def post_message_payload(data)
#   main_msg = 'Beep Beep Boop is a ridiculously simple hosting platform for your Slackbots.'
#   {
#     channel: data['channel'],
#       as_user: true,
#       attachments: [
#         {
#           fallback: main_msg,
#           pretext: 'We bring bots to life. :sunglasses: :thumbsup:',
#           title: 'Host, deploy and share your bot in seconds.',
#           image_url: 'https://storage.googleapis.com/beepboophq/_assets/bot-1.22f6fb.png',
#           title_link: 'https://beepboophq.com/',
#           text: main_msg,
#           color: '#7CD197'
#         }
#       ]
#   }
# end

client.start!
