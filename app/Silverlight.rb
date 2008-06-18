include System::Windows
include System::Windows::Controls
include System::Windows::Media

include System
include System::Windows
include System::Windows::Controls
include System::Windows::Markup
include System::Windows::Media
include System::Windows::Media::Animation
include System::Windows::Media::Imaging

module Wpf
  module Builders
    def name_collector
      @___name_collector_ 
    end

    def [](name)
      name_collector[name]
    end

    def inject_names(obj)
      name_collector.each_pair { |k, v| obj.instance_variable_set("@#{k}".to_sym, v) }
    end

    def evaluate_properties(obj, args, &b) 
      obj.instance_variable_set(:@___name_collector_, name_collector)

      args.each_pair do |k, v| 
        if k == :name 
          name_collector[v] = obj
        end
        obj.send :"#{k.to_s}=", v
      end
      
      if obj.respond_to? :name
        name_collector[obj.name] = obj unless obj.name.nil?
      end

      obj
    end

    def add_object_to_name_collector(collection, obj, args = {}, &b)
      obj = evaluate_properties(obj, args, &b)
      obj.instance_eval(&b) unless b.nil?
      collection.add obj
      obj
    end

    def add_class_to_name_collector(collection, klass, args = {}, &b)
      obj = evaluate_properties(klass.new, args, &b)
      obj.instance_eval(&b) unless b.nil?
      collection.add obj
      obj
    end

    def assign_to_name_collector(property, klass, args = {}, &b) 
      obj = evaluate_properties(klass.new, args, &b)
      obj.instance_eval(&b) unless b.nil?
      self.send property, obj
      obj
    end
  end

  def self.build(klass, args = {}, &b)
    obj = klass.new
    obj.instance_variable_set(:@___name_collector_, {})

    args.each_pair do |k, v| 
      if k == :name 
        obj.name_collector[v] = obj 
      end
      obj.send :"#{k.to_s}=", v
    end

    obj.instance_eval(&b) if b != nil
    obj
  end
end

class SilverlightApplication
  def application
    Application.current
  end

  def self.use_xaml(options = {})
    options = {:type => UserControl, :name => "app"}.merge(options)
    Application.current.load_root_visual(options[:type].new, "#{options[:name]}.xaml")
  end
  
  def root
    application.root_visual
  end
  
  def method_missing(m)
    root.send(m)
  end
end

# TODO: implement caching?
class Brushes
  def self.black
    SolidColorBrush.new(Color.from_argb(0xff, 0x00, 0x00, 0x00))
  end

  def self.white
    SolidColorBrush.new(Color.from_argb(0xff, 0xff, 0xff, 0xff))
  end

  def self.green
    SolidColorBrush.new(Color.from_argb(0xff, 0x00, 0x80, 0x00))
  end
end

class DependencyObject
  def name=(value)
    self.set_value(FrameworkElement.NameProperty, value.to_clr_string)
  end
end

class UIElement
  alias_method :old_render_transform_origin=, :render_transform_origin=
  def render_transform_origin=(point)
    self.old_render_transform_origin = Point.new(point.first, point.last)
  end
end

class FrameworkElement
  def canvas_top=(value)
    Canvas.set_top(self, value)
  end

  def canvas_left=(value)
    Canvas.set_left(self, value)
  end

  alias_method :old_margin=, :margin=
  def margin=(value)
    self.old_margin = Thickness.new *value
  end

  def method_missing(m)
    find_name(m.to_s.to_clr_string)
  end
end

class Image
  alias_method :old_source=, :source=
  def source=(value)
    if value.is_a? BitmapImage
      self.old_source = value
    elsif value.is_a? String
      self.old_source = BitmapImage.new(Uri.new(value))
    elsif value.is_a? ClrString
      self.old_source = BitmapImage.new(Uri.new(value.to_s))
    else
      raise "Image.source must be a BitmapImage or a string type"
    end
  end
end

class DoubleKeyFrame
  alias_method :old_key_time=, :key_time=
  def key_time=(time_span)
    self.old_key_time = KeyTime.from_time_span(TimeSpan.parse(time_span))
  end
end

class SplineDoubleKeyFrame
  alias_method :old_key_spline=, :key_spline=
  def key_spline=(data)
    self.old_key_spline = KeySpline.new *data
  end
end

class Timeline
  include Wpf::Builders

  alias_method :old_begin_time=, :begin_time=
  def begin_time=(time_span)
    self.old_begin_time = TimeSpan.parse(time_span)
  end

  def add(klass, args = {}, &b)
    add_class_to_name_collector(key_frames, klass, args, &b)
  end

  def target_property=(property)
    Storyboard.set_target_property(self, property)
  end

  def target_name=(name)
    Storyboard.set_target_name(self, name)
  end
end

class TransformGroup
  include Wpf::Builders

  def add(klass, args = {}, &b)
    add_class_to_name_collector(children, klass, args, &b)
  end
end

class Storyboard
  include Wpf::Builders

  def add(klass, args = {}, &b)
    add_class_to_name_collector(children, klass, args, &b)
  end
end

class TextBlock
  alias_method :old_font_family=, :font_family=
  def font_family=(value)
    self.old_font_family = FontFamily.new(value)
  end
end

class Panel
  include Wpf::Builders

  def add(klass, args = {}, &b)
    add_class_to_name_collector(children, klass, args, &b)
  end

  def add_name(name, obj)
    name_collector[name] = obj
  end

  def add_obj(obj)
    add_object_to_name_collector(children, obj)
  end

  alias_method :old_background=, :background=
  def background=(color)
    self.old_background = case color
    when :black
      Brushes.black
    when :white
      Brushes.white
    when :green
      Brushes.green
    end
  end
end

class AnimationBase
  def random_name
    #"animation#{Random.new.next(1000000)}"
    @count ||= 0
    "animation#{@count}"
  end

  def obj
    @obj
  end
end

class BounceAnimation < AnimationBase
  def initialize(scale_transform_element)
    @name = random_name
    # NOTE that we don't need to name the storyboard element anymore! - can 
    # do away with name property too!
    @obj = Wpf.build(Storyboard, :target_name => scale_transform_element) do 
      add(DoubleAnimationUsingKeyFrames, :begin_time=>'00:00:00', :target_property => "ScaleX") do
        add SplineDoubleKeyFrame, :key_time => '00:00:00.0', :value => 0.200
        add SplineDoubleKeyFrame, :key_time => '00:00:00.2', :value => 0.935
        add SplineDoubleKeyFrame, :key_time => '00:00:00.3', :value => 0.852
        add SplineDoubleKeyFrame, :key_time => '00:00:00.4', :value => 0.935
      end
      add(DoubleAnimationUsingKeyFrames, :begin_time=>'00:00:00', :target_property => "ScaleY") do
        add SplineDoubleKeyFrame, :key_time => '00:00:00.0', :value => 0.200
        add SplineDoubleKeyFrame, :key_time => '00:00:00.2', :value => 0.935
        add SplineDoubleKeyFrame, :key_time => '00:00:00.3', :value => 0.852
        add SplineDoubleKeyFrame, :key_time => '00:00:00.4', :value => 0.935
      end
    end
  end

  # TODO: cannot attr_reader :name
  def name
    @name
  end
end

