require "x"
require "mime/types" # requires mime-types gem

x_credentials = {
  api_key: "INSERT YOUR X API KEY HERE",
  api_key_secret: "INSERT YOUR X API KEY SECRET HERE",
  access_token: "INSERT YOUR X ACCESS TOKEN HERE",
  access_token_secret: "INSERT YOUR X ACCESS TOKEN SECRET HERE"
}

upload_client = X::Client.new(base_url: "https://upload.twitter.com/1.1/", **x_credentials)

file_path = "path/to/your/media.jpg"
file_name = File.basename(file_path)
media_type = MIME::Types.type_for(file_path).first.content_type
media_category = "tweet_image" # other options include: tweet_video, tweet_gif, dm_image, dm_video, dm_gif, subtitles

boundary = "AaB03x"
upload_body = "--#{boundary}\r\n" \
              "Content-Disposition: form-data; name=\"media\"; filename=\"#{file_name}\"\r\n" \
              "Content-Type: #{media_type}\r\n\r\n" \
              "#{File.read(file_path)}\r\n" \
              "--#{boundary}--\r\n"

upload_client.content_type = "multipart/form-data, boundary=#{boundary}"
media = upload_client.post("media/upload.json?media_category=#{media_category}", upload_body)

tweet_client = X::Client.new(**x_credentials)

tweet_body = {text: "Posting media from @gem!", media: {media_ids: [media["media_id_string"]]}}

tweet = tweet_client.post("tweets", tweet_body.to_json)

puts tweet["data"]["id"]