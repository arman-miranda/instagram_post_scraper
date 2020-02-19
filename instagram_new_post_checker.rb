require 'nokogiri'
require 'open-uri'
require 'irb'
require 'json'

def instagram_has_new_post?(link)
  url = open(link, open_timeout: 15)
  page = Nokogiri::HTML(url, nil, 'UTF-8')
  scripts = page.search('script')
  raw_shared_data = scripts.find do |script|
    script.children.first&.text&.match(/window._sharedData/)
  end
  shared_data = parse_json_data_from(raw_shared_data.content)
  recent_post = check_latest_post_id_with(shared_data)
  last_post = previous_latest_post

  if recent_post.to_i == last_post.to_i
    p 'Latest post has not been updated'
  else
    p "Latest post has been updated to #{recent_post.to_i} from #{last_post.to_i}"
    update_latest_post_with(recent_post)
  end
end

def check_latest_post_id_with(shared_data)
  shared_data['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges'][0]['node']['id']
end

# Remove the window._sharedData = from the start of the string
# also removes the ';' from the end of the raw_data
def extract_and_clean_relevant_data_from(raw_data)
  raw_data.gsub(/^\S*\s=\s|;$/, '')
end

def parse_json_data_from(raw_data)
  sanitized_data = extract_and_clean_relevant_data_from(raw_data)
  JSON.parse(sanitized_data)
end

def previous_latest_post
  File.new('saved_new_post', 'w') unless File.exists?('saved_new_post')
  File.open('saved_new_post', 'r') { |file| file.read }
end

def update_latest_post_with(recent_post)
  File.open('saved_new_post', 'w+') { |file| file.write(recent_post) }
end

# Use this for testing purposes: https://www.instagram.com/barackobama
if ARGV.length < 1
  puts "Add the link to the instagram profile"
  exit
end

instagram_has_new_post?(ARGV[0])
