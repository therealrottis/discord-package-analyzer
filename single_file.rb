class String
  def lstrip_char(char)
    new_str = ""
    still_stripping = true
    self.chars.each do |c|
      if still_stripping
        if c == char
          next
        end
        still_stripping = false
      end
      new_str += c
    end
    new_str
  end
end

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

MONTHS_DAY_LENGTHS = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
# returns month (1..12) from yday
def g_month(day_of_year)
  month = 0
  while day_of_year > 0
    day_of_year -= MONTHS_DAY_LENGTHS[month]
    month += 1
  end
  month
end

# returns day of month (1..31) from yday
def g_day(day_of_year)
  month = 0
  while day_of_year > 0
    day_of_year -= MONTHS_DAY_LENGTHS[month]
    month += 1
  end
  day_of_year + MONTHS_DAY_LENGTHS[month-1]
end

require "json"
require "date_core"

MOST_FREQ_MSG_LEN_COUNT = 10
TIMEZONE = Time.now.utc_offset/60/60 # still works with non-1h timezones, integer division

file = File.read("messages.json")

file_json = JSON.parse(file)

messages_per_month = []
12.times do
  messages_per_month << 0
end

messages_per_day = []
366.times do
  messages_per_day << 0
end

messages_per_hour = []
24.times do
  messages_per_hour << 0
end

messages_per_year = Hash.new(0) # default value 0

message_lengths = []

file_json.each do |message|
  # 
  # {"ID": int, "Timestamp": "2024-11-17 11:59:46", "Contents": "abcdef", "Attachments": ""},
  #
  timestamp = DateTime.parse(message["Timestamp"]) + TIMEZONE / 24.0
  contents = message["Contents"]

  messages_per_month[(timestamp.month()+11)%12] += 1
  # LEAP DAY TAKES INDEX 60
  # ALL OTHER DAYS ARE OFFSET ONE TO THE RIGHT :)
  messages_per_day[(
    (Date.leap?(timestamp.year) ?
      ((timestamp.yday() > 60) ? 0 : 364)
      : 0
    ) + timestamp.yday()+365)%366
  ] += 1
  messages_per_hour[(timestamp.hour()+23+TIMEZONE)%24] += 1

  # ignore messages including only attachments in msglen calculations
  if contents.length() > 0
    message_lengths << contents.length()
  end

  messages_per_year[timestamp.year()] += 1
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
  years << messages_per_year[year]
end

message_lengths.sort!
average_message_length = message_lengths.sum / message_lengths.size
median_message_length = message_lengths[message_lengths.size / 2]

message_length_occurences = Hash.new(0)
message_lengths.each do |msg_len|
  message_length_occurences[msg_len] += 1
end

most_frequent_message_lengths = []
most_frequent_message_length_occurences = []

MOST_FREQ_MSG_LEN_COUNT.times do
  most_frequent_message_lengths << 0
  most_frequent_message_length_occurences << 0
end

message_length_occurences.each do |msglen, occurences|
  idx = 0
  while idx < MOST_FREQ_MSG_LEN_COUNT && most_frequent_message_length_occurences[idx] > occurences
    idx += 1
  end
  if idx == MOST_FREQ_MSG_LEN_COUNT
    next
  end

  most_frequent_message_lengths.insert(idx, msglen)
  most_frequent_message_length_occurences.insert(idx, occurences)

  most_frequent_message_lengths = most_frequent_message_lengths[0...MOST_FREQ_MSG_LEN_COUNT]
  most_frequent_message_length_occurences = most_frequent_message_length_occurences[0...MOST_FREQ_MSG_LEN_COUNT]
end



puts("Total messages: #{file_json.length()}")
puts()
puts("Message length averages:")
puts("Average: #{average_message_length.round(2)}")
puts("Median: #{median_message_length}")
puts("Most sent message lengths:")
puts(
  [most_frequent_message_lengths,
  most_frequent_message_length_occurences].to_table
)
puts()
puts("Messages by year:")
puts(
  [(begin_year..end_year).to_a,
  messages_per_year.map { |k, v| v }].to_table
)
puts()
puts("Messages per day of year:")
puts(
  [(1..366).map { |day_of_year| Date.new(2024, g_month(day_of_year), g_day(day_of_year)).to_s.split("-")[1..2].reverse!.map { |s| s.lstrip_char("0") }.join(".") }.to_a,
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

