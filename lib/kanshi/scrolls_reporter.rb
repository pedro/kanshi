require 'scrolls'

class Kanshi::ScrollsReporter

  def initialize
    @last_value = {}
  end

  ABSOLUTE = [:size, :numbackends, :locks_waiting, :total_open_xact_time, :xact_waiting, :xact_idle]

  def report(name, url, data)
    data = calculate_hit_rate(record_and_diff(name, data))
    if data
      Scrolls.context(:app => name, :measure => true) do
        data.each do |k, v|
          Scrolls.log(:at => k, :last => v)
        end
      end
    end
  end

private

  def record_and_diff(name, data)
    diff = nil
    if @last_value[name]
      diff = Hash.new
      data.keys.each do |key|
        if ABSOLUTE.include?(key)
          diff[key] = data[key]
        else
          diff[key] = data[key] - @last_value[name][key]
        end
      end
    end
    @last_value[name] = data
    diff
  end

  def calculate_hit_rate(data)
    return nil unless data
    hit = data[:blks_hit] || 0
    read = data[:blks_read] || 0
    if hit + read > 0
      data[:blks_hit_ratio] = 100.0 * hit / (hit + read)
    end
    hit = data[:heap_blks_hit] || 0
    read = data[:heap_blks_read] || 0
    if hit > 0
      data[:heap_hit_ratio] = 100.0 * (hit - read) / hit
    end
    data
  end

end
