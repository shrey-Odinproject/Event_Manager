require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

# template_letter = File.read('form_letter.html')

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    # legislators =
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
    # legislators = legislators.officials
    # legislator_names = legislators.map(&:name)
    # legislator_names.join(", ")
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_numbers(ph_num)
  ph_num = ph_num.tr('^0-9', '')
  if ph_num.length == 11 && ph_num[0] == 1
    ph_num[1..11]
  elsif ph_num.length == 10
    ph_num
  else
    'bad number'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output') # make folder if not already made
  filename = "output/thanks_#{id}.html" # name file accordingly for each row and save inside output folder we created
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

def regdate_to_time(reg_date)
  Time.strptime(reg_date, '%m/%d/%y %k:%M') # parse our custom given str to time obj
end

def regdate_to_date(reg_date)
  Date.strptime(reg_date, '%m/%d/%y %k:%M')
end

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

$peak_hour = []
$peak_day = []
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  home_phone = clean_phone_numbers(row[:homephone])
  id = row[0]
  time = regdate_to_time(row[:regdate])
  date = regdate_to_date(row[:regdate])
  $peak_hour.push(time.hour)
  $peak_day.push(date.wday)
  puts "#{name}  #{zipcode} ->  #{home_phone} legislators: #{legislators}"

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
freq_hour = $peak_hour.each_with_object(Hash.new(0)) do |v, h|
  h[v] += 1
end

puts " #{$peak_hour.max_by { |v| freq_hour[v] }}:00 is the most common hour"

freq_day = $peak_day.each_with_object(Hash.new(0)) do |v, h|
  h[v] += 1
end

cal = { 0 => 'sunday', 1 => 'monday', 2 => 'tuesday', 3 => 'wednesday', 4 => 'thursday', 5 => 'friday',
        6 => 'saturday' }
puts " #{cal[$peak_day.max_by { |v| freq_day[v] }]} is the most common weekday"
