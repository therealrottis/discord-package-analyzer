class Array
  def to_table
    output = ""
    height = self.size()
    width = self[0].size()
    widths = []
    width.times do |x|
      widths << 0
      height.times do |y|
        if widths[x] < self[y][x].to_s.size()
          widths[x] = self[y][x].to_s.size()
        end
      end
    end

    self.each do |arr|
      arr.each_with_index do |element, idx|
        to_print = element.to_s
        if (to_print.size() < widths[idx])
          to_print += (" " * (widths[idx] - to_print.size()))
        end
        output += (to_print + ";")
      end
      output[-1] = "\n"
    end
    output
  end
end

require "json"
require "date_core"

TIMEZONE = Time.now.utc_offset/60/60

file = File.read("messages.json")

file_json = JSON.parse(file)

messages_per_month = []
12.times do
  messages_per_month << 0
end

messages_per_day = []
365.times do
  messages_per_day << 0
end

messages_per_hour = []
24.times do
  messages_per_hour << 0
end

messages_per_year = {}


file_json.each do |message|
  timestamp = DateTime.parse(message["Timestamp"])

  messages_per_month[(timestamp.month()+11)%12] += 1
  messages_per_day[(timestamp.yday()+364)%365] += 1
  messages_per_hour[(timestamp.hour()+23+TIMEZONE)%24] += 1
  
  messages_per_year[timestamp.year()] = 1 + (messages_per_year[timestamp.year()] || 0)
end


begin_year = 99999999
end_year = 0
messages_per_year.each do |k, v|
  if k < begin_year
    begin_year = k
  end
  if k > end_year
    end_year = k
  end
end

years = []
(begin_year..end_year).each do |year|
  years << (messages_per_year[year] || 0)
end


puts("Total messages: #{file_json.length()}")
puts()
puts("Messages by year:")
puts(
  [(begin_year..end_year).to_a,
  messages_per_year.map { |k, v| v }].to_table
)
puts()
puts("Messages per day of year:")
puts(
  [(1..365).to_a,
  messages_per_day].to_table
)
puts()
puts("Messages by month:")
puts(
  [(1..12).to_a,
  messages_per_month].to_table
)
puts()
puts("Messages per time of day:")
puts(
  [(1..24).to_a,
  messages_per_hour].to_table
)

