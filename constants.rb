# define Constants
module Constants
  ARENA_X = 40.0         # Open Field Arena X size[cm]: default 40.0
  ARENA_Y = 40.0         # Open Field Arena Y size[cm]: default 40.0
  ROI_X = 120.0          # ROI X size[pixcels]: default 120.0
  ROI_Y = 120.0          # ROI Y size[pixcels]: default 120.0
  CENTER_AREA = 40.0     # Center region definition[%] (% of Rectangle area compare with arena whole area).: default 40.0
  BLOCK_ROWS = 5         # Arena division number for vertical axis.: default 5
  BLOCK_COLUMNS = 5      # Arena division number for horizontal axis.: default 5
  DURATION = 1200        # Duration of experiment[sec.]: default 1200
  FRAME_RATE = 2         # Frame rate[fps]: default 2
  MOTION_CRITERIA = 4.0  # If subject moves more than MOTION_CRITERIA, status is 'moved', else 'rested'.[cm/s]: default 4.0
end