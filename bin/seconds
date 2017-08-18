#!/usr/bin/env ruby
# seconds, a CLI for interval conversion by Brett Terpstra 2017
# Free for use by anyone, anywhere, at any time
# http://brettterpstra.com/2017/08/18/seconds-cli-for-quick-time-interval-calculation/
#
## convert days, hours, and minutes to seconds
# Arguments are numbers followed by a timespan
# (w = week day = d, hours = h, minutes = m, seconds = s)
# e.g. 2 days and 3 hours = "2d3h"
# unrecognized characters don't matter, so also "2 days, and 3 hours"
# $ seconds 2 days, and 3 hours
# => 183600
## convert seconds to days, hours, and minutes
# $ seconds 183600
# => 2 days, 3 hours

require 'bigdecimal'

def help(do_exit=false)
  app = File.basename(__FILE__)
  usage = ["#{app}: convert days, hours, and minutes to seconds"]
  usage.push("Usage: #{app} [Xw[Xd[Xh[Xm]]]] | [seconds]")
  usage.push("Examples:")
  usage.push("#{app} 5d2h3m => 439380")
  usage.push("#{app} 4d => 345600")
  usage.push("Or convert seconds to time units: #{app} 1125093 => 13 days, 31 minutes, 33 seconds")
  $stdout.puts(usage.join("\n"))
  if do_exit
    code = do_exit.to_i rescue 0
    Process.exit code
  end
end

class String
  def plural
    num, unit = self.split(/ /)
    if num.to_i > 1
      return self + 's'
    else
      return self
    end
  end
end


def from_seconds(seconds)
  t = BigDecimal.new(seconds)
  mm, ss = t.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)
  output = []

  output.push("#{dd.to_i} day".plural) if dd > 0
  output.push("#{hh.to_i} hour".plural) if hh > 0
  output.push("#{mm.to_i} minute".plural) if mm > 0
  output.push("#{ss.to_i} second".plural) if ss > 0
  output.join(", ")
  # "%d days, %d hours, %d minutes, %d seconds" % [dd, hh, mm, ss]
end

def to_seconds(input)
  secs = {
    'w' => 604800,
    'd' => 86400,
    'h' => 3600,
    'm' => 60,
    's' => 1
  }
  total = 0
  parts = input.gsub(/([wdhms])[a-z]+/,'\1').gsub(/[^wdhms\d]/,'').scan(/\d+\w/)
  parts.each do |p|
    num, qty = p.split(/(?=[wdhms])/)
    if secs.key? qty
      total += num.to_i * secs[qty]
    end
  end
  total
end

if STDIN.stat.size > 0
  if RUBY_VERSION.to_f > 1.9
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8
    input = STDIN.read.force_encoding('utf-8')
  else
    input = STDIN.read
  end
else
  if ARGV.length > 0
    if ARGV[0].strip.match(/^(-h|help|--help)$/)
      help(0)
    end
    input = ARGV.join('')
  else
    help(1)
  end
end

if input =~ /^\d+$/
  res = from_seconds(input)
else
  res = to_seconds(input)
end

$stdout.print(res)