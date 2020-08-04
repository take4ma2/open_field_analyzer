require 'csv'
require 'fileutils'
require './file_search'
require './open_field_analyzer/data'

module OpenFieldAnalyzer
  module Parameters
    ARENA_X = 40.0      # Open Field Arena X size[cm]
    ARENA_Y = 40.0      # Open Field Arena Y size[cm]
    ROI_X = 120.0       # ROI X size[pixcels]
    ROI_Y = 120.0       # ROI Y size[pixcels]
    CENTER_AREA = 40.0  # Center region definition[%] (% of Rectangle area compare with arena whole area).
    BLOCK_ROWS = 5      # Arena division number for vertical axis.
    BLOCK_COLUMNS = 5   # Arena division number for horizontal axis.
    DURATION = 1200     # Duration of experiment[sec.]
    FRAME_RATE = 2      # Frame rate[fps]
    MOTION_CRITERIA=4.0 # If subject moves more than MOTION_CRITERIA, status is 'moved', else 'rested'.[cm/s]
  end

  class Center
    include Parameters
    attr_reader :area
    attr_reader :length
    attr_reader :left
    attr_reader :right
    attr_reader :top
    attr_reader :bottom

    def initialize
      @area = ROI_X*ROI_Y*CENTER_AREA/100.0
      @length = Math.sqrt(@area)
      @left = ((ROI_X/2.0) - (@length/2.0))
      @right = (@left + @length)
      @bottom = ((ROI_Y/2.0) - (@length/2.0))
      @top = (@bottom + @length)
      @left = @left.round(2)
      @right = @right.round(2)
      @bottom = @bottom.round(2)
      @top = @top.round(2)
    end

    def self.constants
      [
        "  Arena height:          #{ARENA_X}(cm)",
        "  Arena width:           #{ARENA_Y}(cm)",
        "  ROI height:            #{ROI_X}(pixels)",
        "  ROI width:             #{ROI_Y}(pixels)",
        "  Center region:         #{CENTER_AREA}(%)",
        "  Block layout(rows):    #{BLOCK_ROWS}(-)",
        "  Block layout(columns): #{BLOCK_ROWS}(-)",
        "  Duration:              #{DURATION}(sec.)",
        "  Frame rate:            #{FRAME_RATE}(fps)",
        "  Motion criteria:       #{MOTION_CRITERIA}(cm/sec.)"
      ]
    end
  end

  class OpenFieldAnalyzer

    attr_reader :center
    attr_reader :file_dir
    attr_accessor :data
    attr_accessor :file_search

    def initialize(xy_data_dir)
      @center = Center.new
      @file_dir = xy_data_dir
      @file_search = FileSearch::FileUtil.set(@file_dir, /_XY\.txt$/, '_of.csv')
      unless @file_search.files.size > 0
        raise IOError.new "There is no xy data file in directory: #{@file_dir}."
      end

      @data = []
      parse
    end

    def result
      return false if @data.empty?
      CSV.open(@file_search.output_filename, 'w') do |csv|
        csv << @data[0].result_headers
        @data.sort { |a, b| a.subject_id <=> b.subject_id }.each { |datum| csv << datum.result_array }
      end
    end

    def debug
      Dir.mkdir('subjects') unless Dir.exist?('subjects')
      FileUtils.rm Dir.glob(File.join('subjects', '*.csv'))
      @data.each do |data|
        File.open(File.join('subjects', "#{data.subject_id}.csv"), 'w') do |f|
          f.puts data.result_each_frame
        end
      end

      File.open('analyze.info', 'w') do |f|
        f.puts "OpenFieldAnalyzer Ver. #{OpenFieldAnalyzer.VERSION}"
        f.puts "***        Parameters          ***"
        Center.constants.each { |c| f.puts c }
        f.puts ''
        f.puts "*** Centre region definitions. ***"
        f.puts "  Coordinates[pixel]: (#{@center.left},#{@center.bottom}), (#{@center.right},#{@center.bottom}), (#{@center.right}, #{@center.top}), (#{@center.left},#{@center.top})"
        f.puts "  Length:             #{@center.length.round(2)}[pixels]"
        f.puts "  Area:               #{@center.area.round(2)}[pixels^2]"
      end
    end

    def analyzed
      @data.size > 0
    end

    def self.VERSION
      #"1.0.0"
      "1.1.0(Incldes file search module and assigns output file name)"
    end
    private

    def parse
      @file_search.files.each_with_index { |file, i|
        puts "XY_DATA No.#{i}: #{file}"
        @data << Data.new(file, @center)
      }
    end

  end
end

target_dir = ARGV[0]
puts "Open Field Analyzer (v.#{OpenFieldAnalyzer::OpenFieldAnalyzer.VERSION})"
ofa = OpenFieldAnalyzer::OpenFieldAnalyzer.new target_dir
ofa.result
ofa.debug
