#!/usr/local/bin/ruby -w

require 'rubygems'
require 'json'
require 'date'
require 'optparse'
require 'swearjar'
require 'set'

def parse_opts
$options = {}
OptionParser.new do | opts |
  opts.banner = "\nGroupMe-Superalatives.\n"

  opts.on("-f", "--filename filename", "File of JSON to analyze") do | filename |
    $options[:filename] = filename
  end

  opts.on("-h", "--help", "Displays help") do
    puts opts
    exit
  end
end.parse!
end

# Filters out messages that do not fall in the given date range
def filter_messages(json, start_date, end_date)
  return json if start_date.nil? && end_date.nil?
  to_ret = Array.new
  json.each do | message |
    message_date =  Date.strptime(message["created_at"].to_s, '%s')
    if message_date >= start_date && message_date <= end_date
      to_ret << message
    end
  end
  return to_ret
end

def get_user_ids(messages)
  user_ids = Set.new
  messages.each do | message |
    next if message["user_id"] == "system" || message["user_id"] == "calendar"
    user_ids.add(message["user_id"])
  end
  return user_ids
end

def validate_input(options)
  raise OptionParser::MissingArgument if options[:filename].nil?
  abort "File does not exist" if !File.exist?(options[:filename])
end

def get_user_info(messages)
  users = Hash.new
  user_ids = get_user_ids(messages)
  user_ids.each do | user_id |
    users[user_id] = Hash.new
    users[user_id]["total_likes_given"] = 0
    users[user_id]["total_likes_received"] = 0
    users[user_id]["total_messages_sent"] = 0
    users[user_id]["common_name"] = ""
  end

  messages.each do | message |
    next if message["user_id"] == "system" || message["user_id"] == "calendar"
    user_id = message["user_id"]
    user_hash = users[user_id]
    user_hash["total_messages_sent"] += 1
    user_hash["common_name"] = message["name"]
    message["favorited_by"].each do | favoritor |
      users[favoritor]["total_likes_given"] += 1
    users[user_id]["total_likes_received"] += 1
    end

  end
  return users
end

if __FILE__==$0
  parse_opts
  validate_input($options)
  text = File.read($options[:filename])
  json = JSON.parse(text)
  filtered = filter_messages(json, nil, nil)
  users = get_user_info(filtered)

  users.each do | key, user |
    received = user["total_likes_received"]
    sent = user["total_messages_sent"] * 1.0
    ratio = received/sent * 1.0
    puts "Analysis of user \"#{user["common_name"]}\""
    puts "Total messages sent: #{user["total_messages_sent"]}"
    puts "Total likes given: #{user["total_likes_given"]}"
    puts "Total likes received: #{user["total_likes_received"]}"
    puts "Ratio of likes received to messages sent: #{ratio}"
    puts "===========================================\n\n\n"
  end
end
