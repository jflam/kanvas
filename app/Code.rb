require 'debug'
require 'canvas'
require 'silverlight'
require 'patch'
require 'drawing'

include System::Windows
include System::Windows::Controls
include System::Windows::Media
include System::Windows::Shapes
include System::Windows::Browser

canvas = CanvasAdapter.initialize_from_xaml 'scene.xaml'
ctx = canvas.getContext '2d'

def arcs(ctx)
  (0..3).each do |i|
    ctx.beginPath()
    ctx.moveTo(75 + i * 50, 0)
    ctx.lineTo(75 + i * 50, 200)
    ctx.stroke
    ctx.beginPath
    ctx.moveTo(0, 25 + i * 50)
    ctx.lineTo(400, 25 + i * 50)
    ctx.stroke
  end

  (0..3).each do |i|
    (1..4).each do |j|
      ctx.beginPath
      x              = 25+j*50               # x coordinate
      y              = 25+i*50               # y coordinate
      radius         = 20                    # Arc radius
      startAngle     = 0                     # Starting point on circle
      endAngle       = Math::PI*j/2          # End point on circle
      anticlockwise  = i % 2==0 ? false : true # clockwise or anticlockwise

      ctx.arc(x,y,radius,startAngle,endAngle, anticlockwise)

      if i > 1
        ctx.fill
      else
        ctx.stroke
      end 
    end
  end
end

def test(ctx)
  ctx.beginPath()
  ctx.arc(75,75,50,0,Math::PI*2,true) # Outer circle
  ctx.moveTo(110,75)
  ctx.arc(75,75,35,0,Math::PI,false)  # Mouth (clockwise)
  ctx.moveTo(65,65)
  ctx.arc(60,65,5,0,Math::PI*2,true)  # Left eye
  ctx.moveTo(95,65)
  ctx.arc(90,65,5,0,Math::PI*2, true)  # Right eye
  ctx.stroke()
end

def roundedRect(ctx,x,y,width,height,radius) 
  ctx.beginPath()
  ctx.moveTo(x,y+radius)
  ctx.lineTo(x,y+height-radius)
  ctx.quadraticCurveTo(x,y+height,x+radius,y+height)
  ctx.lineTo(x+width-radius,y+height)
  ctx.quadraticCurveTo(x+width,y+height,x+width,y+height-radius)
  ctx.lineTo(x+width,y+radius)
  ctx.quadraticCurveTo(x+width,y,x+width-radius,y)
  ctx.lineTo(x+radius,y)
  ctx.quadraticCurveTo(x,y,x,y+radius)
  ctx.stroke()
end

# Draw crazy picture
def tutorial8(ctx)
  roundedRect(ctx,12,12,150,150,15);
  roundedRect(ctx,19,19,150,150,9);
  roundedRect(ctx,53,53,49,33,10);
  roundedRect(ctx,53,119,49,16,6);
  roundedRect(ctx,135,53,49,33,10);
  roundedRect(ctx,135,119,25,49,10);

  # Character 1
  ctx.beginPath();
  ctx.arc(37,37,13,Math::PI/7,-Math::PI/7,false);
  ctx.lineTo(34,37);
  ctx.fill();

  # blocks
  (0..7).each { |i| ctx.fillRect(51+i*16,35,4,4) }
  (0..5).each { |i| ctx.fillRect(115,51+i*16,4,4) }
  (0..7).each { |i| ctx.fillRect(51+i*16,99,4,4) }

  # character 2
  ctx.beginPath();
  ctx.moveTo(83,116);
  ctx.lineTo(83,102);
  ctx.bezierCurveTo(83,94,89,88,97,88);
  ctx.bezierCurveTo(105,88,111,94,111,102);
  ctx.lineTo(111,116);
  ctx.lineTo(106.333,111.333);
  ctx.lineTo(101.666,116);
  ctx.lineTo(97,111.333);
  ctx.lineTo(92.333,116);
  ctx.lineTo(87.666,111.333);
  ctx.lineTo(83,116);
  ctx.fill();
  ctx.fillStyle = "rgb(255,255,255)";
  ctx.beginPath();
  ctx.moveTo(91,96);
  ctx.bezierCurveTo(88,96,87,99,87,101);
  ctx.bezierCurveTo(87,103,88,106,91,106);
  ctx.bezierCurveTo(94,106,95,103,95,101);
  ctx.bezierCurveTo(95,99,94,96,91,96);
  ctx.moveTo(103,96);
  ctx.bezierCurveTo(100,96,99,99,99,101);
  ctx.bezierCurveTo(99,103,100,106,103,106);
  ctx.bezierCurveTo(106,106,107,103,107,101);
  ctx.bezierCurveTo(107,99,106,96,103,96);
  ctx.fill();
  ctx.fillStyle = "rgb(0,0,0)";
  ctx.beginPath();
  ctx.arc(101,102,2,0,Math::PI*2,true);
  ctx.fill();
  ctx.beginPath();
  ctx.arc(89,102,2,0,Math::PI*2,true);
  ctx.fill();
end

# Paints a picture on the screen
def tutorial9(ctx)
  XImage.load('http://localhost:2060/images/sunset.jpg') do |img|
    ctx.drawImage(img,100,100)
    ctx.beginPath()
    ctx.moveTo(30,96)
    ctx.lineTo(70,66)
    ctx.lineTo(103,76)
    ctx.lineTo(170,15)
    ctx.stroke()
  end
end

# Draw nice mosaic of colors to test fillStyle
def tutorial10(ctx)
  (0..6).each do |i|
    (0..6).each do |j|
      ctx.fillStyle = "rgb(#{(255-42.5*i).to_int}, #{(255-42.5*j).to_int},0)"
      ctx.fillRect(j*25,i*25,25,25)
    end
  end
end

# Draw nice mosaic of circles to test strokeStyle
def tutorial11(ctx)
  (0..6).each do |i|
    (0..6).each do |j|
      ctx.strokeStyle = "rgb(0,#{(255-42.5*i).to_int},#{(255-42.5*j).to_int})"
      ctx.beginPath()
      ctx.arc(12.5+j*25,12.5+i*25,10,0,Math::PI*2,true)
      ctx.stroke()
    end
  end
end

# Draw using globalAlpha transparency changes
def tutorial12(ctx)
  ctx.fillStyle = '#FD0';
  ctx.fillRect(0,0,75,75)
  ctx.fillStyle = '#6C0'
  ctx.fillRect(75,0,75,75)
  ctx.fillStyle = '#09F'
  ctx.fillRect(0,75,75,75)
  ctx.fillStyle = '#F30'
  ctx.fillRect(75,75,75,75)
  ctx.fillStyle = '#FFF';

  # set transparency value
  ctx.globalAlpha = 0.2;

  # Draw semi transparent circles
  (0..7).each do |i|
    ctx.beginPath
    ctx.arc(75,75,10+10*i,0,Math::PI*2,true)
    ctx.fill
  end
end

def tutorial13(ctx)
  ctx.fillStyle = 'rgb(255,221,0)'
  ctx.fillRect(0,0,150,37.5)
  ctx.fillStyle = 'rgb(102,204,0)'
  ctx.fillRect(0,37.5,150,37.5)
  ctx.fillStyle = 'rgb(0,153,255)'
  ctx.fillRect(0,75,150,37.5)
  ctx.fillStyle = 'rgb(255,51,0)'
  ctx.fillRect(0,112.5,150,37.5)

  # Draw semi transparent rectangles
  (0..9).each do |i|
    ctx.fillStyle = "rgba(255,255,255,#{(i + 1)/10.0})"
    (0..3).each do |j|
      ctx.fillRect(5+i*14,5+j*37.5,14,27.5)
    end
  end 
end

# lineWidth
def tutorial14(ctx)
  (0..9).each do |i|
    ctx.lineWidth = 1+i
    ctx.beginPath
    ctx.moveTo(5+i*14,5)
    ctx.lineTo(5+i*14,140)
    ctx.stroke
  end
end

# linearGradient
def tutorial15(ctx)
  lingrad = ctx.createLinearGradient(0,0,0,150)
  lingrad.addColorStop(0, '#00ABEB')
  lingrad.addColorStop(0.5, '#fff')
  lingrad.addColorStop(0.5, '#26C000')
  lingrad.addColorStop(1, '#fff')

  lingrad2 = ctx.createLinearGradient(0,50,0,95)
  lingrad2.addColorStop(0.5, '#000')
  lingrad2.addColorStop(1, 'rgba(0,0,0,0)')

  # assign gradients to fill and stroke styles
  ctx.fillStyle = lingrad
  ctx.strokeStyle = lingrad2
  
  # draw shapes
  ctx.fillRect(10,10,130,130)
  ctx.strokeRect(50,50,50,50)
end
#tutorial15(ctx)

#=begin
$d = HtmlPage.document
$d.run.onclick do |s,e|
  code = $d.code.get_property("innerText".to_clr_string)
  $logger.clear
  ctx.clear
  begin
    instance_eval code.to_s
  rescue Exception => e
    $logger.log e.message
  end
end
#=end
