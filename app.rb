require "sinatra"
require 'json'

require 'hexapdf'

get "/" do
	return "welcome to pdfshield"
end

post '/redact' do
  push = JSON.parse(request.body.read)
  return push.inspect

  class ShowTextProcessor < HexaPDF::Content::Processor

    def initialize(page, to_hide_arr)
      super()
      @canvas = page.canvas(type: :overlay)
      @to_hide_arr = to_hide_arr
      @boxeslist = []
    end

    def show_text(str)
      boxes = decode_text_with_positioning(str)
      boxes.each do |box|
          @boxeslist << box
      end
    end

    def blackout_text()
      @to_hide_arr.each do |hide_item|
        @boxeslist.each_with_index do |box, index|
          #puts sum_string(index, hide_item.length)
          if hide_item == sum_string(index, hide_item.length)
            blackout_array(index, hide_item.length)
          end
        end
      end
    end

    def blackout_array(start_ind, end_ind)
      sum = ""
      i = start_ind
      while i < start_ind+end_ind  do
        box = @boxeslist[i]
        @canvas.fill_color(255, 255, 255)
        x, y = *box.lower_left
        tx, ty = *box.upper_right
        @canvas.rectangle(x, y, tx - x, ty - y).fill
        i +=1
      end
    end

    def sum_string(start_ind, end_ind)
      sum = ""
      i = start_ind
      while i < start_ind+end_ind  do
        begin
          sum += @boxeslist[i].string
        rescue NoMethodError 
          print ""
        end
        i +=1
      end
      return sum
    end 

    alias :show_text_with_positioning :show_text

  end


  file_name = params[:filepath]
  strings_to_black = params[:words]

  doc = HexaPDF::Document.open(file_name)
  puts "Blacken strings [#{strings_to_black}], inside [#{file_name}]."
  doc.pages.each.with_index do |page, index|
    processor = ShowTextProcessor.new(page, strings_to_black)
    page.process_contents(processor)
    processor.blackout_text()
  end

  new_file_name = "#{file_name.split('.').first}_updated.pdf"
  doc.write(new_file_name, optimize: true)

  puts "Writing updated file [#{new_file_name}]."
end
