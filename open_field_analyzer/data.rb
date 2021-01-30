require 'csv'
module OpenFieldAnalyzer
  class Datum
    attr_accessor :xp, :yp  # Pixel XY座標系(x, y)[unit: pixels]
    attr_reader :xm, :ym  # XY座標系(x, y)[unit: cm]
    attr_reader :max_xp, :max_yp  # Pixel座標系最大値(o = (0, 0))
    attr_reader :max_xm, :max_ym  # XY座標系最大値(o = (0, 0))
    attr_accessor :center
    attr_reader :frame, :duration # Frame No と Frame の実験開始からの経過時間[sec]
    attr_accessor :distance # 1 frame 前からの移動距離[cm]
    
    def initialize(frame, x, y, center)
      @xp = x
      @yp = y
      @center = center
      @max_xp = Center::ROI_X
      @max_yp = Center::ROI_Y
      @max_xm = Center::ARENA_X
      @max_ym = Center::ARENA_Y
      @frame = frame
      @duration = frame.to_f / Center::FRAME_RATE.to_f 
      @distance = 0.0
      if valid?
        set_xy
      end
    end

    def set_coodinates(xp, yp)
      @xp = xp
      @yp = yp
      set_xy
    end

    def valid?
      !@xp.nil? && !@yp.nil?
    end

    # Datumの座標から(xp, yp)までの距離を求める[unit: cm]
    def moved(datum)
      @distance = Math.sqrt(((@xp - datum.xp)*cf_x)**2.0 + ((@yp - datum.yp)*cf_y)**2.0)
    end

    # resting の判定
    def resting?
      return false if @frame == 1
      @distance <= Center::MOTION_CRITERIA / Center::FRAME_RATE.to_f
    end

    # 中心領域判定
    def center?
      @center.bottom <= @yp && @center.top >= @yp && @center.left <= @xp && @center.right >= @xp
    end

    # 辺縁領域判定
    def peripheral?
      !center?
    end
    
    def output
      {
        slice_no: @frame,
        pixel_x: @xp,
        pixel_y: @yp,
        x: @xm,
        y: @ym,
        distance: @distance,
        min_center_x: @center.left,
        max_center_x: @center.right,
        min_center_y: @center.bottom,
        max_center_y: @center.top,
        is_resting: resting?,
        is_center: center?,
        is_peripheral: peripheral?
      }
    end
    
    private
    
    # XY座標系の導出
    def set_xy
      @xm = @xp * cf_x
      @ym = @yp * cf_y
    end
    
    # X方向換算係数[cm/pixel]
    def cf_x
      @max_xm / @max_xp
    end
    
    # Y方向換算係数[cm/pixel]
    def cf_y
      @max_ym / @max_yp 
    end

  end

  class Data
    attr_reader :xy_data_file
    attr_reader :data
    attr_reader :center
    attr_reader :frames
    attr_reader :subject_id

    def initialize(xy_data_file, center)
      @xy_data_file = xy_data_file
      @center = center
      @data = []
      @frames = 0
      parse
    end

    # フレームデータの取得
    def frame(number)
      nil if number > @data.size
      @data.select{ |d| d.frame == number }[0]
    end

    # 中心領域への移動潜時[sec]
    def latency_to_center_entry
      start_frame = to_frame(0)
      end_frame = to_frame(Center::DURATION)
      frame = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.center? }.sort{ |a, b| a.frame <=> b.frame }
      return Center::DURATION.to_f if frame.empty?
      frame.first.frame / Center::FRAME_RATE.to_f
    end
    
    # 中心領域への進入回数(辺縁->中心に位置が変わった回数)
    def number_of_center_entry
      count=0
      @data.each_with_index do |datum, i|
        if i == 0
          count += 1 if datum.center?
        else
          count += 1 if datum.center? && frame(i).peripheral?
        end
      end
      count
    end

    # 移動距離[cm]
    def total_move(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frames = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
      sum = frames.inject(0) { |sum, frame| sum + frame.distance }
      return 0.0 if sum.nil?
      sum
    end

    # 中心領域移動距離[cm]
    def total_move_in_center(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frames = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.center? }
      sum = frames.inject(0) { |sum, frame| sum + frame.distance }
      return 0.0 if sum.nil?
      sum
    end
    
    # 辺縁領域移動距離[cm]
    def total_move_in_peripheral(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frames = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.peripheral? }
      sum = frames.inject(0) { |sum, frame| sum + frame.distance }
      return 0.0 if sum.nil?
      sum
    end
    
    # performance time[sec]
    def performance_time(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }.size
      frame_rest/Center::FRAME_RATE.to_f
    end

    # 中心領域performance time[sec]
    def performance_time_in_center(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_center_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.center? }.size
      frame_center_rest/Center::FRAME_RATE.to_f
    end
    
    # 辺縁領域performance time[sec]
    def performance_time_in_peripheral(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_center_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.peripheral? }.size
      frame_center_rest/Center::FRAME_RATE.to_f
    end
    
    # resting time[sec]
    def resting_time(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.resting? }.size
      frame_rest/Center::FRAME_RATE.to_f
    end

    # 中心領域resting time[sec]
    def resting_time_in_center(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_center_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.center? }
        .select{ |datum| datum.resting? }.size
      frame_center_rest/Center::FRAME_RATE.to_f
    end
    
    # 辺縁領域resting time[sec]
    def resting_time_in_peripheral(start_time, end_time)
      start_frame = to_frame(start_time)
      end_frame = to_frame(end_time)-1
      frame_center_rest = @data.select{ |datum| datum.frame >= start_frame && datum.frame <= end_frame }
        .select{ |datum| datum.peripheral? }
        .select{ |datum| datum.resting? }.size
      frame_center_rest/Center::FRAME_RATE.to_f
    end
    
    # 解析結果出力用ヘッダデータ
    def result_headers
      [
        'Animal', 'Distance travelled 5',
        'Distance travelled 10', 'Distance travelled 15',
        'Distance travelled 20', 'Whole arena resting time',
        'Whole arena permanence time', 'Whole arena average speed',
        'Periphery distance travelled', 'Periphery resting time',
        'Periphery permanence time', 'Periphery average speed',
        'Center distance travelled', 'Center resting time',
        'Center permanence time', 'Center average speed',
        'Latency to center entry', 'Number of center entries',
        'Distance travelled - total', 'Percentage center time'
      ]
    end

    # カラム順序定義
    def result_columns
      [
        :subject_id,
        :distance_traveled_5, :distance_traveled_10,
        :distance_traveled_15,:distance_traveled_20,
        :whole_arena_resting_time, :whole_arena_performance_time,
        :whole_area_average_speed, :periphery_distance_traveled,
        :periphery_resting_time, :periphery_performance_time,
        :periphery_average_speed, :centre_distance_traveled,
        :centre_resting_time, :centre_performance_time,
        :centre_average_speed, :latency_to_center_entry,
        :number_of_center_entry, :distance_traveled_total,
        :percentage_center_time
      ]
    end

    def result_array
      ary = []
      rst = result
      result_columns.each { |col| ary << rst[col] }
      ary
    end

    def result
      allmove = total_move(0, Center::DURATION)
      move_in_center = total_move_in_center(0, Center::DURATION)
      move_in_peripheral = total_move_in_peripheral(0, Center::DURATION)
      perform_all = performance_time(0, Center::DURATION)
      perform_in_center = performance_time_in_center(0, Center::DURATION)
      perform_in_peripheral = performance_time_in_peripheral(0, Center::DURATION)
      distance_traveled_5 = Center::DURATION >= 300 ? total_move(0, 300) : total_move(0, Center::DURATION)
      distance_traveled_10 = if Center::DURATION < 300
                               0.0
                             elsif Center::DURATION >= 300 && Center::DURATION <= 600
                               total_move(300, Center::DURATION)
                             else
                               total_move(300, 600)
                             end
      distance_traveled_15 = if Center::DURATION < 600
                               0.0
                             elsif Center::DURATION >= 600 && Center::DURATION <= 900
                               total_move(600, Center::DURATION)
                             else
                               total_move(600, 900)
                             end
      distance_traveled_20 = if Center::DURATION < 900
                               0.0
                             elsif Center::DURATION >= 900 && Center::DURATION <= 1200
                               total_move(900, Center::DURATION)
                             else
                               total_move(900, 1200)
                             end
      {
        subject_id: @subject_id,
        distance_traveled_5: distance_traveled_5,
        distance_traveled_10: distance_traveled_10,
        distance_traveled_15: distance_traveled_15,
        distance_traveled_20: distance_traveled_20,
        whole_arena_resting_time: resting_time(0, Center::DURATION),
        whole_arena_performance_time: perform_all,
        whole_area_average_speed: allmove/Center::DURATION.to_f,
        periphery_distance_traveled: move_in_peripheral,
        periphery_resting_time: resting_time_in_peripheral(0, Center::DURATION),
        periphery_performance_time: perform_in_peripheral,
        periphery_average_speed: move_in_peripheral/perform_in_peripheral,
        centre_distance_traveled: move_in_center,
        centre_resting_time: resting_time_in_center(0, Center::DURATION),
        centre_performance_time: perform_in_center,
        centre_average_speed: move_in_center/perform_in_center,
        latency_to_center_entry: latency_to_center_entry,
        number_of_center_entry: number_of_center_entry,
        distance_traveled_total: allmove,
        percentage_center_time: (perform_in_center/perform_all)*100.0
      }
    end

    def result_each_frame
      header = ['Slice No.','X(pixel)','Y(pixel)',
                'X(cm)','Y(cm)','move from previos frame(cm)',
                'Center left(pixels)', 'Center Right(pixels)',
                'Center bottom(pixels)', 'Center top(pixels)',
                'Resting?', 'in center?', 'in periphery?']
      columns = [
        :slice_no, :pixel_x, :pixel_y,
        :x, :y, :distance,
        :min_center_x, :max_center_x,
        :min_center_y, :max_center_y,
        :is_resting, :is_center, :is_peripheral
      ]
      s = CSV.generate do |csv|
        csv << header
        @data.each do |datum|
          row = []
          output = datum.output
          columns.each { |key| row << output[key] }
          csv << row
        end
      end
      s
    end
    
    private

    def to_frame(time)
      time*Center::FRAME_RATE+1
    end

    def parse
      f = File.readlines(@xy_data_file)
      start_data = false
      f.each do |line|
        unless line.index("Animal ID").nil?
          @subject_id = line.strip.split("\t")[1]
          next
        end
        unless line.index("Slice\tX\tY").nil?
          start_data = true
          next
        end
        next unless start_data
        next if line.strip.size < 1  # 空行は無視
        @frames += 1
        cols = line.split("\t")
        if !cols[1].empty? && !cols[2].empty?
          @data << Datum.new(cols[0].to_i, cols[1].to_f, cols[2].to_f, @center)
        else
          @data << Datum.new(cols[0].to_i, nil, nil, @center)
        end
      end
      check_coordinates
      Array(2..@data.size).each do |i|
        frame(i).moved(frame(i-1))
      end
    end

    # 座標データが欠落していないかのチェック
    def check_coordinates
      @data.each_with_index do |datum, index|
        unless datum.valid?
          if index==0
            # 以降のフレームナンバーでvalidなデータを探す
            d = @data.select{ |d| d.frame > index+1 && d.valid? }[0]
            @data[index].set_coordinates(d.xp, d.yp)
            next
          end
          if index == @data.size-1
            d = @data.select{ |d| d.frame < index+1 && d.valid? }[-1]
            @data[index].set_coordinates(d.xp, d.yp)
            next
          end
          datum_pre = @data.select{ |d| d.frame < index+1 && d.valid? }[-1]
          datum_post = @data.select{ |d| d.frame > index+1 && d.valid? }[0]
          interpolation(datum_pre, datum_post, index+1)
        end
      end
    end

    # 抜けているデータがあった場合は内挿
    def interpolution(datum_pre, datum_post, frame_number)
      xp = (datum_post.xp-datum_pre.xp)/(datum_post.frame-datum_pre.frame)*(@data[frame_number].frame-datum_pre.frame)+datum_pre.xp
      yp = (datum_post.yp-datum_pre.yp)/(datum_post.frame-datum_pre.frame)*(@data[frame_number].frame-datum_pre.frame)+datum_pre.yp
      @data[frame_number].set_coordinate xp, yp
    end
  end
end
