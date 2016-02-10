# coding: utf-8

require "clockwork"
require "holiday_japan"
require "yaml"
require "open-uri"
require "pp"

class FHC
  def initialize
    config = YAML.load_file("config.yaml")
    @addr = config["fhc_addr"]
    @api_key = config["fhc_api_key"]
  end

  def get(query)
    open("http://#{@addr}/api/elec/action?webapi_apikey=#{@api_key}&#{query}").read
  end

  def aircon_heating
    # エアコン 暖房普通
    get("elec=%E3%82%A8%E3%82%A2%E3%82%B3%E3%83%B3&action=%E6%9A%96%E6%88%BF%E6%99%AE%E9%80%9A")
  end

  def aircon_cooling
    # エアコン 冷房普通
    get("elec=%E3%82%A8%E3%82%A2%E3%82%B3%E3%83%B3&action=%E5%86%B7%E6%88%BF%E6%99%AE%E9%80%9A")
  end

  def aircon_off
    # エアコン けす
    get("elec=%E3%82%A8%E3%82%A2%E3%82%B3%E3%83%B3&action=%E3%81%91%E3%81%99")
  end

  def kotatsu_on
    # こたつ つける
    get("elec=%E3%81%93%E3%81%9F%E3%81%A4&action=%E3%81%A4%E3%81%91%E3%82%8B")
  end

  def kotatsu_off
    # こたつ けす
    get("elec=%E3%81%93%E3%81%9F%E3%81%A4&action=%E3%81%91%E3%81%99")
  end

  def light_toggle
    # 照明 つける
    get("elec=%E7%85%A7%E6%98%8E&action=%E3%81%A4%E3%81%91%E3%82%8B")
  end
end

class Bot
  def initialize
    @fhc = FHC.new
  end

  def business_day?
    !(Time.now.saturday? || Time.now.sunday? || HolidayJapan.check(Time.now))
  end

  def wakeup
    return unless business_day?
    @fhc.aircon_heating
    @fhc.kotatsu_on
    @fhc.light_toggle
  end

  def go_out
    return unless business_day?
    @fhc.aircon_off
    @fhc.kotatsu_off
  end

  def before_come_home
    return unless business_day?
    @fhc.aircon_heating
  end
end

module Clockwork
  handler do |job|
    bot = Bot.new
    bot.send(job.to_sym)
  end

  every(1.day, "wakeup", :at => "08:30")
  every(1.day, "go_out", :at => "09:45")
  every(1.day, "before_come_home", :at => "18:45")
end
