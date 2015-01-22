require 'twitter/direct_message'
require 'twitter/streaming/deleted_tweet'
require 'twitter/streaming/disconnect'
require 'twitter/streaming/event'
require 'twitter/streaming/friend_list'
require 'twitter/streaming/limit'
require 'twitter/streaming/scrub_geo'
require 'twitter/streaming/stall_warning'
require 'twitter/streaming/status_withheld'
require 'twitter/tweet'

module Twitter
  module Streaming
    class MessageParser
      def self.parse(data) # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
        if data[:id]
          Tweet.new(data)
        elsif data[:event]
          Event.new(data)
        elsif data[:direct_message]
          DirectMessage.new(data[:direct_message])
        elsif data[:friends]
          FriendList.new(data[:friends])
        elsif data[:delete] && data[:delete][:status]
          DeletedTweet.new(data[:delete][:status])
        elsif data[:warning]
          StallWarning.new(data[:warning])
        elsif data[:disconnect]
          Disconnect.new(data[:disconnect])
        elsif data[:scrub_geo]
          ScrubGeo.new(data[:scrub_geo])
        elsif data[:limit]
          Limit.new(data[:limit])
        elsif data[:status_withheld]
          StatusWithheld.new(data[:status_withheld])
        end
      end
    end
  end
end
