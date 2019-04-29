#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"
require "open-uri"
require "date"
require "sinatra"

URL = "https://www.lumpofsugar.co.jp/"

html = open(URL) do |f|
  f.read
end

# header
body = <<EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

  <title>新着情報 | Lump of Sugar</title>
  <link href="https://www.lumpofsugar.co.jp"/>
   <updated>__updated__</updated>
   <author>
     <name>Lump of Sugar</name>
   </author>
   <id>tag:www.lumpofsugar.co.jp,#{DateTime.now.strftime('%Y-%m-%d')}:atom</id>
EOF

res = Nokogiri::HTML.parse(html, nil, "utf-8")
res.xpath('//div[@class="left_information"]/ul/li[@class="lamp"]').each_with_index do |obj, i|
  body += "<entry>"
  # title
  body += "<title>#{obj.xpath( \
    "/html/body/div[4]/div[2]/div[3]/div/div[1]/div[1]/ul/li[#{i + 1}]/a[1]/div[2]/p[2]" \
    ).text().gsub(/\r\n|\r|\n|\s|\t/, "")}</title>"

  # link
  link =  obj.xpath("/html/body/div[4]/div[2]/div[3]/div/div[1]/div[1]/ul/li[#{i + 1}]/a[1]/@href").text()
  if link.include?("http")
    # http がある: 絶対リンク
    # => 何もしない
  else
    # http が無い: 相対リンク
    # => htttps:// をつける
    link = "https://www.lumpofsugar.co.jp/" + link
  end
  body += "<link rel='alternate' type='text/html' href='#{link}' />"

  # updated
  updated = DateTime.parse(obj.xpath( "/html/body/div[4]/div[2]/div[3]/div/div[1]/div[1]/ul/li[#{i + 1}]/a[1]/div[2]/p[1]" ).text() + " 00:00 JST")
  updated_prev = DateTime.parse(obj.xpath( "/html/body/div[4]/div[2]/div[3]/div/div[1]/div[1]/ul/li[#{i + 2}]/a[1]/div[2]/p[1]" ).text() + " 00:00 JST")

  if updated == updated_prev
      updated += Rational(1, 24 * 60)
  end

  body.gsub!(/__updated__/, updated.iso8601) if i == 0
  body += "<updated>#{updated.iso8601}</updated>"

  # id
  body += "<id>tag:www.lumpofsugar.co.jp,#{updated.strftime("%Y-%m-%d")}:info_#{i}</id>"

  body += "<summary>[no content]</summary>"
  body += "</entry>"
end


# footer
body += "</feed>"

# sinatra response
get '/' do
  content_type 'application/atom+xml', :charset => 'utf-8'
  body
end
