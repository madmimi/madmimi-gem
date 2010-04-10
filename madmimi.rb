require 'net/http'

resp = href = "";
begin
  http = Net::HTTP.new("madmimi.com", 80)
  http.start do |http|
    req = Net::HTTP::Get.new("/audience_lists/lists.xml?username=nicholas@madmimi.com&api_key=f745b56de62ab9b46f613173a10806fb")
    response = http.request(req)
    resp = response.body
  end
  puts resp
rescue SocketError
  raise "Host " + host + " nicht erreichbar"
end