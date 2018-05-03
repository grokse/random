#!/usr/bin/env ruby

require 'shellwords'

exit 0 if `pgrep i3` == ''

File.open('/tmp/polybar.log', 'a') do |file|
  file.write "**********************************\n"
  file.write "         Running polybar.rb       \n"
  file.write `date` + "\n"
  file.write `xrandr` + "\n"
  file.write "**********************************\n"
end

def get_monitors
  `xrandr`.split("\n").
    select { |line| line.match(/\A([^ ]+ connected)/) }.
    map { |line| line.match(/\A([^ ]+)/) }.map(&:to_s)
end

def stop_monitor(monitor)
  puts "stopping monitor #{monitor}"
  `xrandr --output #{monitor} --off`
end

`killall -TERM polybar`
# get_monitors.each { |monitor| stop_monitor(monitor) }.reject

sleep 0.25

monitors = get_monitors

monitors = monitors.reject { |m| m =~ /eDP/ } if monitors.length > 1
displayport_monitors = monitors.select { |m| m =~ /DP/ }.sort
hdmi_monitors = monitors.select { |m| m =~ /HDMI/ }.sort

ordered_monitors = displayport_monitors + hdmi_monitors + (monitors - displayport_monitors - hdmi_monitors)

command = %w[xrandr]

(get_monitors - ordered_monitors).each { |monitor| command += %W[--output #{monitor} --off] }

last_monitor = nil

ordered_monitors.each do |m|
  command += %W[--output #{m} --auto]
  if last_monitor
    command += %W[--right-of #{last_monitor}]
  else
    command += %w[--primary]
  end
  last_monitor = m
end

puts "running command: `#{Shellwords.join(command)}"
`#{Shellwords.join(command)}`

`feh --bg-fill ~/Pictures/wallpaper/pexels-photo.jpg`

monitors.each.with_index do |monitor, index|
  workspaces = (1..10).select do |workspace|
    (workspace - 1 - index) % monitors.length == 0
  end

  puts command = "i3-msg '[workspace=\"^(#{workspaces.join('|')})\"] move workspace to output #{monitor};'"
  `#{command}`
end

ARGV.each do |arg|
  ENV['PATH'] = ENV['PATH'].gsub(/\/home\/kurt[^:]+:/, '')

  threads = monitors.map do |monitor|
    Thread.new do
      ENV['MONITOR'] = monitor
      `polybar #{arg} > /dev/null 2>&1`
    end
  end
  threads.each(&:join)
end
