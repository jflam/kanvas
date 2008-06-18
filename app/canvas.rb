require 'System.Net'

include System
include System::Net
include System::Windows::Media
include System::Windows::Media::Imaging

# Adapter for HTML 5 <canvas/> element

class CanvasAdapter
  def initialize(canvas)
    @canvas = canvas
    @context = CanvasContext.new(canvas)
  end

  # We only support 2d context right now
  def getContext(contextId)
    raise ArgumentError.new 'only 2d context supported' unless contextId.downcase == '2d'
    @context
  end

  def self.initialize_from_xaml(name)
    CanvasAdapter.new(Application.current.load_root_visual(Canvas.new, name))
  end
end

class ColorContext
  private
  def self.rgb(r, g, b)
    Color.from_argb(255, r, g, b)
  end

  def self.rgba(r, g, b, a)
    a = 0 if a < 0
    a = 1 if a > 1
    Color.from_argb((a * 255).to_int, r, g, b)
  end

  def self.hex_to_int(digit)
    if digit >= ?0 && digit <= ?9
      digit - ?0
    elsif digit >= ?A && digit <= ?F
      digit - (?A - 10)
    else
      raise ArgumentError.new "invalid hex digit: #{digit}"
    end
  end

  def self.hexbyte_to_int(byte)
    hex_to_int(byte[0]) * 16 + hex_to_int(byte[1])
  end

  def self.css_color3(color)
    css_color6 "#{color[0..0]}#{color[0..0]}#{color[1..1]}#{color[1..1]}#{color[2..2]}#{color[2..2]}"
  end

  def self.css_color6(color)
    r = hexbyte_to_int color[0..1]
    g = hexbyte_to_int color[2..3]
    b = hexbyte_to_int color[4..5]
    rgb r, g, b
  end

  public
  def self.eval(color)
    if color.length == 4 && color[0] == ?#
      css_color3 color[1..3].upcase
    elsif color.length == 7 && color[0] == ?#
      css_color6 color[1..6].upcase
    else
      class_eval color
    end
  end
end

class CanvasGradient
  attr_reader :brush

  def initialize(brush)
    @brush = brush
  end

  def addColorStop(offset, color)
    stop = GradientStop.new
    stop.offset = offset
    stop.color = ColorContext.eval(color)
    brush.gradient_stops.add stop
  end
end

# The strokeStyle attribute represents the color or style to use for the lines around shapes, and
# the fillStyle attribute represents the color or style to use inside the shapes.
# Both attributes can be either strings, CanvasGradients, or CanvasPatterns. On setting, strings
# must be parsed as CSS <color> values and the color assigned, and CanvasGradient and
# CanvasPattern objects must be assigned themselves. [CSS3COLOR] If the value is a string but is
# not a valid color, or is neither a string, a CanvasGradient, nor a CanvasPattern, then it must be
# ignored, and the attribute must retain its previous value

class StyleContext
  attr_reader :result

  private
  # TODO: method_missing impl with color names

  def rgb(r, g, b)
    SolidColorBrush.new(Color.from_argb(255, r, g, b))
  end

  def rgba(r, g, b, a)
    a = 0 if a < 0
    a = 1 if a > 1
    SolidColorBrush.new(Color.from_argb((a * 255).to_int, r, g, b))
  end

  def eval(arg)
    instance_eval arg
  end

  public
  def self.create(arg)
    StyleContext.new.eval(arg)
  end
end

class XImage
  def self.load(uri)
    image = BitmapImage.new
    client = WebClient.new
    client.open_read_completed do |sender, args|
      image.set_source args.result
      yield image if block_given?
    end
    client.open_read_async Uri.new(uri)
  end
end

class CanvasContext
  attr_reader :fillStyle, :strokeStyle, :lineCap, :lineJoin, :miterLimit, :canvas
  attr_accessor :globalAlpha, :lineWidth

  TransparentBlack = SolidColorBrush.new(Color.from_argb(0, 0, 0, 0))

  private
  def add_child(node)
    @canvas.children.add node
  end

  def make_rect(x, y, width, height)
    r = Rectangle.new
    r.canvas_top = y
    r.canvas_left = x
    r.width = width
    r.height = height
    r
  end

  public
  def initialize(canvas)
    @path = nil
    @lineWidth = 1
    @lineCap = "butt"
    @lineJoin = "miter"
    @miterLimit = 10
    @canvas = canvas

    @globalAlpha = 1.0
    @strokeStyle = SolidColorBrush.new(Colors.Black)
    @fillStyle = SolidColorBrush.new(Colors.Black)

    # Transform styles
    @scale = nil
    @rotate = nil
    @translate = nil
  end

  # Styles
  def fillStyle=(style)
    @fillStyle = style.is_a?(String) ? SolidColorBrush.new(ColorContext.eval(style)) : style.brush
  end

  def strokeStyle=(style)
    @strokeStyle = style.is_a?(String) ? SolidColorBrush.new(ColorContext.eval(style)) : style.brush
  end

  # Canvas transform APIs
  def scale(x, y)
    scale = ScaleTransform.new
    scale.scale_x = x
    scale.scale_y = y
    @scale = scale
  end

  def rotate(angle)
    rotate = RotateTransform.new
    rotate.angle = angle
    @rotate = rotate
  end

  def translate(x, y)
    translate = TranslateTransform.new
    translate.x = x
    translate.y = y
    @translate = translate
  end

  # Colors and Styles
  def createLinearGradient(x0, y0, x1, y1)
    # Normalize the vector to range 0->1.0
    dx = x1 - x0
    dy = y1 - y0
    factor = dx > dy ? dx : dy

    brush = LinearGradientBrush.new
    brush.start_point = Point.new(0, 0)
    brush.end_point = Point.new(dx / factor, dy / factor)
    brush.gradient_stops = GradientStopCollection.new
    CanvasGradient.new(brush)
  end

  def createRadialGradient(x0, y0, r0, x1, y1, r1)

  end

  # rect API
  def fillRect(x, y, width, height)
    r = make_rect x, y, width, height
    r.fill = fillStyle
    add_child r
  end

  # TODO: fix this code to correctly 'clear' pixels - hack right now
  # have to find the rectangle that we need to clear pixels from and clear the
  # pixels
  def clearRect(x, y, width, height)
    r = make_rect x, y, width, height
    r.fill = SolidColorBrush.new(Colors.White)
    r.stroke = SolidColorBrush.new(Colors.White)
    add_child r
  end

  def strokeRect(x, y, width, height)
    r = make_rect x, y, width, height
    r.fill = SolidColorBrush.new(Colors.White)
    r.stroke = strokeStyle
    add_child r
  end

  # path API
  def construct_path
    path = Path.new
    pg = PathGeometry.new
    pg.figures = PathFigureCollection.new
    path.data = pg
    path
  end

  def beginPath
    @path = construct_path
    @subpath = nil
  end

  def closePath
    unless @subpath.nil?
      @subpath.is_closed = true
    end
  end

  def moveTo(x, y)
    pf = PathFigure.new
    pf.start_point = Point.new(x, y)
    pf.segments = PathSegmentCollection.new
    @path.data.figures.add pf
    @subpath = pf
  end

  def lineTo(x, y)
    unless @subpath.nil?
      ls = LineSegment.new
      ls.point = Point.new(x, y)
      @subpath.segments.add ls
    end
  end

  def quadraticCurveTo(cpx, cpy, x, y)
    unless @subpath.nil?
      qb = QuadraticBezierSegment.new
      qb.point1 = Point.new(cpx, cpy)
      qb.point2 = Point.new(x, y)
      @subpath.segments.add qb
    end
  end

  def bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
    unless @subpath.nil?
      bs = BezierSegment.new
      bs.point1 = Point.new(cp1x, cp1y)
      bs.point2 = Point.new(cp2x, cp2y)
      bs.point3 = Point.new(x, y)
      @subpath.segments.add bs
    end
  end

  def arcTo(x1, y1, x2, y2, radius)
    unless @subpath.nil?
      raise NotImplementedError.new
    end
  end

  def calc_point(radius, angle, x, y)
    if angle <= Math::PI / 2
      theta = angle
    elsif angle <= Math::PI
      theta = Math::PI - angle
    elsif angle <= (Math::PI * 3 / 2)
      theta = Math::PI + angle
    else
      theta = 2 * Math::PI - angle
    end  

    dx = Math::cos(theta) * radius
    dy = Math::sin(theta) * radius
  
    if angle <= Math::PI / 2
      return x + dx, y + dy
    elsif angle <= Math::PI
      return x - dx, y + dy
    elsif angle <= (Math::PI * 3 / 2)
      return x - dx, y - dy
    else
      return x + dx, y - dy
    end  
  end

  def drawArc(x1, y1, x2, y2, radius, large_arc, direction)
    # Add a straight line from last point in subpath 
    # to start point in path (if we have a subpath already)
    if @subpath.nil?
      moveTo(x1, y1)
    else
      lineTo(x1, y1)
    end

    as = ArcSegment.new
    as.point = Point.new(x2, y2)
    as.size = Size.new(radius, radius)
    as.sweep_direction = direction
    as.is_large_arc = large_arc
    @subpath.segments.add as
  end

  # Circles must be special cased 
  def drawCircle(x, y, radius)
    x1, y1 = calc_point(radius, Math::PI * 2 - 0.0001, x, y)
    # TODO: is there a better way of expressing this?
    x2, y2 = calc_point(radius, 0, x, y)
    drawArc(x1, y1, x2, y2, radius, true, SweepDirection.Counterclockwise)
  end

  # Note that startAngle and endAngle are in radians
  def arc(x, y, radius, startAngle, endAngle, anticlockwise)
    drawCircle(x, y, radius) if startAngle == 0 && endAngle == Math::PI * 2

    arc = endAngle - startAngle

    # Calculate the start point of the path
    x1, y1 = calc_point(radius, startAngle, x, y)
    x2, y2 = calc_point(radius, endAngle, x, y)

    direction = anticlockwise ? SweepDirection.Counterclockwise : SweepDirection.Clockwise
    if anticlockwise
      large_arc = arc >= Math::PI ? false : true
    else
      large_arc = arc >= Math::PI ? true : false
    end

    drawArc(x1, y1, x2, y2, radius, large_arc, direction)
  end

  def rect(x, y, w, h)
    pf = PathFigure.new
    pf.start_point = Point.new(x, y)
    pf.segments = PathSegmentCollection.new
    @subpath = pf

    lineTo(x + w, y)
    lineTo(x + w, y + h)
    lineTo(x, y + h)

    pf.is_closed = true

    @path.data.figures.add pf

    pf = PathFigure.new
    pf.start_point = Point.new(x, y)

    @subpath = pf
  end

  def isPointInPath(x, y)
    raise NotImplementedError.new
  end

  def stroke
    @path.stroke = @strokeStyle
    @path.stroke_thickness = @lineWidth
    add_child @path
  end

  def fill
    a = (globalAlpha * 255).to_int
    color = Color.from_argb(a, fillStyle.color.r, fillStyle.color.g, fillStyle.color.b)
    brush = SolidColorBrush.new(color)
    @path.fill = brush #@fillStyle
    add_child @path
  end

  def clip
    # TODO: fix this egregious hack
    @path.clip = @path.data
    @path.data = nil
    add_child @path
  end

  # text API
  attr_accessor :font, :textAlign, :textBaseline

  def fillText(text, x, y, maxWidth = 0)

  end

  def strokeText(text, x, y, maxWidth = 0)

  end

  def measureText(text)

  end

  # image API
  def drawImage(image, dx, dy)
    brush = ImageBrush.new
    brush.image_source = image

    # draw a rectangle with the fill brush as the image brush?
    rect = Rectangle.new
    rect.width = dx
    rect.height = dy
    rect.fill = brush

    add_child rect
  end  

  # hack
  def clear
    @canvas.children.clear
  end
end
