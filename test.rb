require 'async'
require 'pry'


task = Async do |task|
  puts 'scheduling a sleep'
  subtask = task.async do |subtask|
    subtask.sleep 6
    puts "done sleeping!"
  end
  subtask.wait
  puts 'sleeping is underway'

end

# puts task.wait
