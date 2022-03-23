require 'json'
require 'date'

User = Struct.new(:id, :name, :events)
Event = Struct.new(:user_id, :start_time, :end_time)

NoNamesError = Class.new(StandardError)
InvalidNumberError = Class.new(StandardError)

class CalculateAvailability
    attr_reader :all_users, :all_events, :search_names, :work_start, :work_end

    def initialize(search_names, work_start, work_end)
        @all_users = parse_users
        @all_events = parse_events
        @search_names = search_names
        @work_start = work_start
        @work_end = work_end
    end

    def perform
        puts "Availability"
        puts "-----------------------"

        days = [Time.utc(2021, 07, 05), Time.utc(2021, 07, 06), Time.utc(2021, 07, 07)]
        current_range = nil
        days.each do |day|
            day_start = Time.utc(day.year, day.month, day.day, work_start.hour)
            day_end = Time.utc(day.year, day.month, day.day, work_end.hour)
            working_times = [day_start]
            while working_times[-1] < day_end
                new_time = working_times[-1] + (15 * 60)
                working_times.push(new_time)
            end

            working_times.each_with_index do |start_time, index|
                break if start_time == working_times[-1]

                time_block = (start_time..working_times[index + 1])
                if time_available?(time_block)
                    if current_range.nil?
                        current_range = time_block
                        next
                    end

                    if time_block.begin == current_range.end
                        current_range = Range.new(current_range.begin, time_block.end)
                        next
                    end

                    print_time(current_range)
                    current_range = time_block
                end
            end

            print_time(current_range)
            current_range = nil
            puts "\n"
        end
    end

    private

    def parse_users
        user_array = JSON.parse(File.read("./users.json"))
        user_map = {}
        user_array.each do |user|
            user_struct = User.new(user["id"], user["name"], [])
            user_map[user["id"]] = user_struct
        end

        user_map
    end

    def parse_events
        event_array = JSON.parse(File.read("./events.json"))
        event_array.each do |event|
            start_time = DateTime.parse(event["start_time"]).to_time
            end_time = DateTime.parse(event["end_time"]).to_time
            event_struct = Event.new(event["user_id"], start_time, end_time)
            user = all_users[event["user_id"]]
            user.events.push(event_struct) # in prod I would do an upsert to prevent duplications
        end
    end

    def time_available?(time_block)
        search_users = all_users.values.select { |user| search_names.include?(user.name) }
        available_users = []

        search_users.each do |user|
            is_unavailable = user.events.any? do |event|
                event_range = (event.start_time.to_i..event.end_time.to_i)
                event_range.cover?((time_block.begin.to_i..time_block.end.to_i))
            end

            available_users.push(user.name) unless is_unavailable
        end

        available_users.sort == search_names.sort
    end

    def print_time(time_range)
        day = time_range.begin.strftime("%F")
        begin_time = time_range.begin.strftime("%H:%M")
        end_time = time_range.end.strftime("%H:%M")

        puts "#{day} #{begin_time} - #{end_time}"
    end
end

def find_time_argument(input_arr, flag)
    time_idx = input_arr.index {|el| el =~ flag }
    time = nil
    if time_idx
        time_digit = 0
        if input_arr[time_idx] =~ /\=\d+/
            time_digit = input_arr[time_idx].split('=')[1].to_i
        else
            time_digit = input_arr[time_idx + 1].to_i
        end

        raise InvalidNumberError, "#{flag.source} flag must be a digit from 0-24" if time_digit < 0 || time_digit > 24
        time = Time.utc(2022, 03, 19, time_digit)
    end

    time
end

input_arr = ARGV
names = input_arr.shift&.split(',')
raise NoNamesError, "Please supply the names of users you'd like to search (i.e Maggie,Joe,Jordan)" if names.nil?

start_time = find_time_argument(input_arr, /--start/) || Time.utc(2022, 03, 19, 13)
end_time = find_time_argument(input_arr, /--end/) || Time.utc(2022, 03, 19, 21)

CalculateAvailability.new(names, start_time, end_time).perform
