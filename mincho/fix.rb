#! /usr/bin/env ruby

WIDTH=90
HEIGHT=50

module Direction
  N = 0
  NE = 1
  E = 2
  SE = 3
  S = 4
  SW = 5
  W = 6
  NW = 7
end

class Point
  def initialize(x, y, attr=0)
    @x = toNumerical(x)
    @y = toNumerical(y)
    @attr = attr
  end

  def to_s
    "#{@x} #{@y} (#{@attr})"
  end

  def ==(obj)
    @x == obj.x && @y == obj.y && @attr == obj.attr
  end

  def delta(point)
    return [@x - point.x, @y - point.y]
  end

  def move(delta_x, delta_y)
    @x += delta_x
    @y += delta_y
    return self
  end

  def newX(x)
    return Point.new(x, @y, @attr)
  end
  def newY(y)
    return Point.new(@x, y, @attr)
  end

  attr_reader :x, :y, :attr
  attr_writer :x, :y

  private
  def toNumerical(i)
    if i =~ /\./ then
      return i.to_f
    else
      return i.to_i
    end
  end
end

class Element
  include Direction

  def match(direction)
    return ((direction == NE && @start_point.x < @end_point.x &&
             @end_point.y > @start_point.y) ||
            (direction == SE && @start_point.x < @end_point.x &&
             @end_point.y < @start_point.y) ||
            (direction == NW && @start_point.y < @end_point.y &&
             @end_point.x < @start_point.x) ||
            (direction == SW && @start_point.y > @end_point.y &&
             @end_point.x < @start_point.x))
  end

  def move(delta_x, delta_y)
    @start_point.move(delta_x, delta_y)
    @end_point.move(delta_x, delta_y)
  end

  def multiply(numerator, denominator)
    @start_point.x = @start_point.x * numerator / denominator
    @start_point.y = @start_point.y * numerator / denominator
    @end_point.x = @end_point.x * numerator / denominator
    @end_point.y = @end_point.y * numerator / denominator
  end

  attr_writer :start_point, :end_point
end

class Line < Element
  def initialize(start_point, end_point)
    @start_point = start_point
    @end_point = end_point
  end

  def to_s
    "#{@start_point} - #{@end_point}"
  end

  def sfd
    "#{@end_point.x} #{@end_point.y} l #{@end_point.attr}"
  end

  def svg
    "L #{@end_point.x} #{800 - @end_point.y}"
  end

  def length
    if @start_point.x == @end_point.x
      return (@start_point.y - @end_point.y).abs
    elsif @start_point.y == @end_point.y
      return (@start_point.x - @end_point.x).abs
    else
      return Math.sqrt((@start_point.x - @end_point.x) * (@start_point.x - @end_point.x) + (@start_point.y - @end_point.y) * (@start_point.y - @end_point.y))
    end
  end

  def match(direction)
    return ((direction == N && @start_point.x == @end_point.x &&
             @end_point.y > @start_point.y) ||
            (direction == S && @start_point.x == @end_point.x &&
             @end_point.y < @start_point.y) ||
            (direction == E && @start_point.y == @end_point.y &&
             @end_point.x > @start_point.x) ||
            (direction == W && @start_point.y == @end_point.y &&
             @end_point.x < @start_point.x) ||
            super(direction))
  end

  attr_reader :start_point, :end_point
end

class Curve < Element
  def initialize(start_point, control_1, control_2, end_point)
    @start_point = start_point
    @control_1 = control_1
    @control_2 = control_2
    @end_point = end_point
  end

  def Curve.create(start_point, x1, y1, x2, y2, x3, y3, attr)
    Curve.new(start_point, Point.new(x1, y1), Point.new(x2, y2),
              Point.new(x3, y3, attr))
  end

  def to_s
    "#{@start_point} - #{@end_point} (#{@control_1}, #{@control_2})"
  end

  def sfd
    "#{control_1.x} #{control_1.y} #{control_2.x} #{control_2.y} #{@end_point.x} #{@end_point.y} c #{@end_point.attr}"
  end

  def svg
    "C #{control_1.x} #{800 - control_1.y} #{control_2.x} #{800 - control_2.y} #{@end_point.x} #{800 - @end_point.y}"
  end  

  def move(delta_x, delta_y)
    super(delta_x, delta_y)
    @control_1.move(delta_x, delta_y)
    @control_2.move(delta_x, delta_y)
  end

  def multiply(numerator, denominator)
    super(numerator, denominator)
    @control_1.x = @control_1.x * numerator / denominator
    @control_1.y = @control_1.y * numerator / denominator
    @control_2.x = @control_2.x * numerator / denominator
    @control_2.y = @control_2.y * numerator / denominator
  end

  attr_reader :start_point, :end_point, :control_1, :control_2
end

class Spline
  include Direction

  def initialize
    @elements = Array.new
  end

  def add(element)
    @elements << element
  end

  def to_s
    if @elements.empty?
      return ""
    end

    start_point = @elements[0].start_point
    s = "#{start_point.x} #{start_point.y} m #{start_point.attr}\n"
    @elements.each { |x|
      s += " #{x.sfd}\n"
    }
    return s
  end

  def to_svg
    return "" if @elements.empty?

    start_point = @elements[0].start_point
    s = "<path d=\"M #{start_point.x} #{800 - start_point.y}"
    @elements.each {|x|
      s+= " #{x.svg}"
    }
    s += "\"/>\n"
  end

  def number_of_elements
    @elements.size
  end

  def at(i)
    @elements[i % @elements.size]
  end

  def each
    @elements.each {|x|
      yield(x)
    }
  end

  def pop
    @elements.pop
  end

  def push(x)
    @elements.push(x)
  end

  def match(directions)
    # N^2
    0.upto(@elements.size - 1) {|i|
      index = 0
      matched = true
      0.upto(@elements.size - 1) {|t|
        x = (t + i) % @elements.size
        # TODO continue matching if it matches previous one
        if (!@elements[x].match(directions[index])) then
          matched = false
          break
        else
          index += 1
        end
      }
      if matched then
        return i
      end
    }
    return false
  end

  def partial_match(directions)
    if number_of_elements < directions.length then
      return false
    end
    0.upto(@elements.size - 1) {|i|
      index = 0
      matched = true
      0.upto(directions.size - 1) {|t|
        x = (t + i) % @elements.size
        if (!@elements[x].match(directions[index])) then
          matched = false
          break
        else
          index += 1
        end
      }
      if matched then
        return i
      end
    }
    return false
  end

  def move(delta_x, delta_y)
    @elements.each {|e|
      e.move(delta_x, delta_y)
    }
  end

  def start
    return @elements[0]
  end
  
  def last
    return @elements[@elements.size - 1]
  end

  def fixVerticalAndHorizontalMain(spline, index, length, func)
    new_spline = Spline.new
    curve1 = arrayToSpline(Point.new(702, -139, 17),
                           [[674, -134, 650, -116, 645, -91, "c", 9]])
    curve2 = arrayToSpline(Point.new(735, -23, 17),
                           [[735, -44, 755, -58, 771, -59, "c", 9]])

    # keep the y coordinate of bottom line and x coordinate of the left
    # most vertical line
    curve1.move(spline.at(index + 1).end_point.x - curve1.start.end_point.x,
                spline.at(index).start_point.y - curve1.start.start_point.y)
    curve2.move(curve1.start.end_point.x + WIDTH - curve2.start.start_point.x,
                # WIDTH - 10 below is intentional
                curve1.at(0).start_point.y + (WIDTH - 10) - curve2.start.end_point.y)
    new_spline.add(Line.new(spline.at(index).start_point,
                            curve1.start.start_point))
    new_spline.add(curve1.start)
    func.call(new_spline)
    new_spline.add(Line.new(new_spline.last.end_point,
                            curve2.start.start_point))
    new_spline.add(curve2.start)
    tmp_point = spline.at(index + length - 1).end_point
    tmp_point.move(0, new_spline.last.end_point.y - tmp_point.y)
    new_spline.add(Line.new(new_spline.last.end_point, tmp_point))
    i = index + length
    current_spline = spline.at(i)
    while current_spline != spline.at(index)
      new_spline.add(current_spline)
      i += 1
      current_spline = spline.at(i)
    end
    return new_spline
  end


  def fixVerticalAndHorizontal()
    spline = self
    direction = [W, NW, N, E, S, SE, E]
    return nil if spline.number_of_elements < direction.length

    index = spline.partial_match(direction)
    return nil unless index

    func = lambda {|new_spline|
      new_spline.add(Line.new(new_spline.last.end_point,
                              Point.new(new_spline.last.end_point.x,
                                        spline.at(index + 2).end_point.y, 25)))
      new_spline.add(Line.new(new_spline.last.end_point,
                              Point.new(new_spline.last.end_point.x + WIDTH,
                                        new_spline.last.end_point.y, 25)))
    }
    return fixVerticalAndHorizontalMain(self, index, direction.length, func)
  end

  def horizontalVerticalRightShoulder()
    spline = arrayToSpline(Point.new(747, 540, 25),
                           [[763,553,769,578,789,573,"c",24],
                            [824,563,841,542,858,510,"c",24],
                            [865,497,845,492,837,480,"c",25]])
    spline.move(-spline.start.start_point.x, -spline.start.start_point.y)
    return spline
  end

  def fixHorizontalVerticalHorizontal()
    direction = [W, NW, N, W, N, E, NE, SE, SW, S, SE, E]
    index = partial_match(direction)
    return nil unless index

    func = lambda {|new_spline|
      left_most_x = self.at(index + 3).end_point.x
      bottom_y = self.at(index + 3).end_point.y
      shoulder = horizontalVerticalRightShoulder()
      shoulder.move(new_spline.last.end_point.x + WIDTH - shoulder.last.end_point.x,
                    bottom_y + HEIGHT - shoulder.start.start_point.y)
      new_spline.add(Line.new(new_spline.last.end_point,
                              Point.new(new_spline.last.end_point.x,
                                        bottom_y, 25)))
      new_spline.add(Line.new(new_spline.last.end_point,
                              Point.new(left_most_x,
                                        new_spline.last.end_point.y, 25)))
      new_spline.add(Line.new(new_spline.last.end_point,
                              Point.new(new_spline.last.end_point.x,
                                        new_spline.last.end_point.y + HEIGHT, 25)))
      new_spline.add(Line.new(new_spline.last.end_point,
                              shoulder.start.start_point))
      shoulder.each {|x|
        new_spline.add(x)
      }
    }
    return fixVerticalAndHorizontalMain(self, index, direction.length, func)
  end

  def fixVerticalWithHeadAndHorizontal()
    spline = self
    direction = [W, NW, N, SE, SW, S, SE, E]

    index = spline.partial_match(direction)
    return nil unless index

    new_spline = Spline.new

    curve1 = arrayToSpline(Point.new(702, -139, 17),
                           [[674, -134, 650, -116, 645, -91, "c", 9]])
    curve2 = arrayToSpline(Point.new(735, -23, 17),
                           [[735, -44, 755, -58, 771, -59, "c", 9]])

    # keep the y coordinate of bottom line and x coordinate of the left
    # most vertical line
    curve1.move(spline.at(index + 1).end_point.x - curve1.start.end_point.x,
                spline.at(index).start_point.y - curve1.start.start_point.y)
    curve2.move(curve1.start.end_point.x + WIDTH - curve2.start.start_point.x,
                # WIDTH - 10 below is intentional
                curve1.at(0).start_point.y + (WIDTH - 10) - curve2.start.end_point.y)
    head = verticalHead(Point.new(curve1.start.end_point.x,
                                  spline.at(index + 2).end_point.y))

    new_spline.add(Line.new(spline.at(index).start_point,
                            curve1.start.start_point))
    new_spline.add(curve1.start)
    new_spline.add(Line.new(new_spline.last.end_point,
                            head.start.start_point))
    head.each {|x|
      new_spline.add(x)
    }
    new_spline.add(Line.new(new_spline.last.end_point,
                            curve2.start.start_point))
    new_spline.add(curve2.start)
    tmp_point = spline.at(index + direction.length - 1).end_point
    tmp_point.move(0, new_spline.last.end_point.y - tmp_point.y)
    new_spline.add(Line.new(new_spline.last.end_point, tmp_point))
    i = index + direction.length
    current_spline = spline.at(i)
    while current_spline != spline.at(index)
      new_spline.add(current_spline)
      i += 1
      current_spline = spline.at(i)
    end
    return new_spline
  end

end

def arrayToSpline(start_point, points)
  prev_point = start_point
  spline = Spline.new
  points.each {|x|
    if x.length == 4 then
      cur_point = Point.new(x[0], x[1], x[3])
      spline.add(Line.new(prev_point.clone, cur_point))
      prev_point = cur_point
    else
      cur_point = Point.new(x[4], x[5], x[7])
      spline.add(Curve.new(prev_point.clone,
                           Point.new(x[0], x[1]),
                           Point.new(x[2], x[3]),
                           cur_point))
      prev_point = cur_point
    end
  }
  return spline
end

def fixHorizontalLine(spline)
  include Direction
  return nil unless spline.number_of_elements == 6

  index = spline.match([E, NE, SE, SW, W, N])
  return nil unless index

  curve =  spline.at(index - 2).length > 500 ?
  arrayToSpline(Point.new(774, 375, 17),
                [[803,403,812,435,837,444,"c",1],
                 [863,440,905,387,936,354,"c",1],
                 [944,336,927,325,909,325,"c",9]]) :
    arrayToSpline(Point.new(766, 685, 25),
                  [[766, 685, 788, 716, 812, 725, "c", 1],
                   [831, 718, 855, 690, 874, 664, "c", 1],
                   [882, 646, 866, 635, 848, 635, "c", 9]])
# old shape
#     arrayToSpline(Point.new(336, 408, 25),
#                   [[336,408,359,444,384,453,"c",1],
#                    [410,449,398,420,429,387,"c",1],
#                    [437,369,420,358,402,358,"c",9]])


  delta = [spline.at(index + 2 % spline.number_of_elements).end_point.x -
           curve.at(1).end_point.x,
           spline.at(index).start_point.y - curve.at(0).start_point.y]

  curve.each {|c|
    c.move(delta[0], delta[1])
  }
  new_spline = Spline.new
  new_spline.add(Line.new(spline.at(index).start_point,
                          Point.new(curve.at(0).start_point.x,
                                    spline.at(index).start_point.y, 25)))
  curve.each {|c|
    new_spline.add(c)
  }
  last_element = new_spline.at(new_spline.number_of_elements - 1)
  new_spline.add(Line.new(last_element.end_point,
                          Point.new(spline.at(index).start_point.x ,
                                    last_element.end_point.y, 25)))

  last_element = new_spline.at(new_spline.number_of_elements - 1)
  new_spline.add(Line.new(last_element.end_point,
                          spline.at(index).start_point))

  return new_spline
end

def fixHorizontalLine2(spline)
  include Direction
  direction = [W, N, E]
  return nil if spline.number_of_elements < direction.length

  index = spline.partial_match(direction)
  return nil unless index

  return nil unless spline.at(index).length > spline.at(index + 1).length

  new_spline = Spline.new

  start_y = spline.at(index + 1).end_point.y - HEIGHT

  start_point = spline.at(index).start_point.newY(start_y)
  new_spline.add(Line.new(start_point,
                          spline.at(index).end_point.newY(start_y)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at(index + 1).end_point.newY(start_y + HEIGHT)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at(index + 2).end_point.newY(start_y + HEIGHT)))

  start_index = (index + direction.length) % spline.number_of_elements
  while true
    break if start_index == index
    start_point = new_spline.last.end_point
    end_point = (index == ((start_index + 1) % spline.number_of_elements)) ? new_spline.at(0).start_point : spline.at(start_index).end_point
    element = spline.at(start_index).clone
    element.start_point = start_point
    element.end_point = end_point
    new_spline.add(element)
    start_index = (start_index + 1) % spline.number_of_elements
  end

  return new_spline
end

def verticalHead(start_point)
  spline1 = arrayToSpline(Point.new(120, 651, 25),
                          [[120,651,199,635,231,600,"c",24],
                           [245,585,218,571,210,552,"c",25]])
  delta = start_point.delta(spline1.at(0).start_point)
  spline1.move(delta[0], delta[1])
  return spline1
end

def verticalBottom(right_x, bottom_y)
  spline2 = arrayToSpline(Point.new(534, 45, 2),
                          [[534, 24, 543, -60, 537, -93, "c", 0],
                           [529, -135, 494, -147, 474, -147, "c", 0],
                           [454, -147, 436, -140, 435, -118, "c", 0],
                           [434, -98, 444, -6, 444, 30, "c", 2,]])
  spline2.move(right_x - spline2.at(0).start_point.x,
               bottom_y - spline2.at(1).end_point.y)
  return spline2
end

def fixVerticalLine1(spline)
  include Direction
  direction = [SE, SW, S, SW, NW, N]
  return nil if spline.number_of_elements < direction.length

  index = spline.match(direction)
  return nil unless index

  spline1 = verticalHead(spline.at(index).start_point)

  spline2 = verticalBottom(spline1.last.end_point.x,
                           spline.at((index + 3) % spline.number_of_elements).end_point.y)

  new_spline = Spline.new
  spline1.each {|s|
    new_spline.add(s)
  }
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline2.at(0).start_point))
  spline2.each {|s|
    new_spline.add(s)
  }
  new_spline.add(Line.new(new_spline.last.end_point,
                          new_spline.at(0).start_point))

  return new_spline
end

def fixVerticalLine2(spline)
  include Direction
  direction = [N, SE, SW, S]
  return nil if spline.number_of_elements < direction.length

  index = spline.partial_match(direction)
  return nil unless index

  spline1 = verticalHead(spline.at(index).end_point)

  new_spline = Spline.new
  new_spline.add(Line.new(spline.at(index).start_point.newX(spline1.at(0).start_point.x),
                          spline1.at(0).start_point))

  spline1.each {|x|
    new_spline.add(x)
  }

  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at((index + direction.length - 1) % spline.number_of_elements).end_point.newX(new_spline.last.end_point.x)))

  start_index = (index + direction.length) % spline.number_of_elements
  while true
    break if start_index == index
    start_point = new_spline.last.end_point
    end_point = (index == ((start_index + 1) % spline.number_of_elements)) ? new_spline.at(0).start_point : spline.at(start_index).end_point
    element = spline.at(start_index).clone
    element.start_point = start_point
    element.end_point = end_point
    new_spline.add(element)
    start_index = (start_index + 1) % spline.number_of_elements
  end

  return new_spline
end

def fixVerticalLine3(spline)
  include Direction
  direction = [S, SW, NW, N]
  return nil if spline.number_of_elements < direction.length

  index = spline.partial_match(direction)
  return nil unless index

  spline1 = verticalBottom(spline.at(index).end_point.x,
                           spline.at((index + 1) % spline.number_of_elements).end_point.y)

  new_spline = Spline.new

  new_spline.add(Line.new(spline.at(index).start_point.newX(spline1.at(0).start_point.x),
                          spline1.at(0).start_point))
  spline1.each {|x|
    new_spline.add(x)
  }

  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at((index + direction.length - 1) % spline.number_of_elements).end_point.newX(new_spline.at(2).end_point.x)))

  start_index = (index + direction.length) % spline.number_of_elements
  while true
    break if start_index == index
    start_point = new_spline.last.end_point
    end_point = (index == ((start_index + 1) % spline.number_of_elements)) ? new_spline.at(0).start_point : spline.at(start_index).end_point
    element = spline.at(start_index).clone
    element.start_point = start_point
    element.end_point = end_point
    new_spline.add(element)
    start_index = (start_index + 1) % spline.number_of_elements
  end

  return new_spline
end

def fixVerticalLine4(spline)
  include Direction
  direction = [N, E, S]
  return nil if spline.number_of_elements < direction.length

  index = spline.partial_match(direction)
  return nil unless index

  return nil unless spline.at(index).length > spline.at(index + 1).length

  new_spline = Spline.new

  start_x = spline.at(index + 1).end_point.x - WIDTH

  start_point = spline.at(index).start_point.newX(start_x)
  new_spline.add(Line.new(start_point,
                          spline.at(index).end_point.newX(start_x)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at(index + 1).end_point.newX(start_x + WIDTH)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at(index + 2).end_point.newX(start_x + WIDTH)))

  start_index = (index + direction.length) % spline.number_of_elements
  while true
    break if start_index == index
    start_point = new_spline.last.end_point
    end_point = (index == ((start_index + 1) % spline.number_of_elements)) ? new_spline.at(0).start_point : spline.at(start_index).end_point
    element = spline.at(start_index).clone
    element.start_point = start_point
    element.end_point = end_point
    new_spline.add(element)
    start_index = (start_index + 1) % spline.number_of_elements
  end

  return new_spline
end

def createHook()
  return arrayToSpline(Point.new(747, 540, 25),
                       [[763,553,769,578,789,573,"c",24],
                        [824,563,841,542,858,510,"c",24],
                        [865,497,845,492,837,480,"c",25]])
end

def fixHorizontalAndVertical(spline)
  include Direction
  direction = [E, NE, SE, SW, S, SW, NW, N, W, N]
  return nil if spline.number_of_elements < direction.length

  index = spline.match(direction)
  return nil unless index

  spline1 = createHook()
  spline1.move(spline.at((index + 3)).end_point.x - spline1.last.end_point.x,
               spline.at(index).start_point.y - spline1.at(0).start_point.y)

  spline2 = verticalBottom(spline1.last.end_point.x, 
                           spline.at((index + 5)).end_point.y)

  new_spline = Spline.new
  new_spline.add(Line.new(spline.at(index).start_point,
                          spline1.at(0).start_point))
  spline1.each {|s|
    new_spline.add(s)
  }
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline2.at(0).start_point))
  spline2.each {|s|
    new_spline.add(s)
  }
  new_spline.add(Line.new(new_spline.last.end_point,
                          Point.new(new_spline.last.end_point.x,
                                    new_spline.at(0).start_point.y - HEIGHT,
                                    HEIGHT / 2)))

  new_spline.add(Line.new(new_spline.last.end_point,
                          Point.new(new_spline.at(0).start_point.x,
                                    new_spline.last.end_point.y, HEIGHT / 2)))

  new_spline.add(Line.new(new_spline.last.end_point,
                          new_spline.at(0).start_point))

  return new_spline
end

def fixHorizontalAndVertical1(spline)
  include Direction
  direction = [N, W, N, E, NE, SE, SW, S]
  return nil if spline.number_of_elements < direction.length

  index = spline.partial_match(direction)
  return nil unless index

  spline1 = arrayToSpline(Point.new(747, 540, 25),
                          [[763,553,769,578,789,573,"c",24],
                           [824,563,841,542,858,510,"c",24],
                           [865,497,845,492,837,480,"c",25]])
  spline1.move(spline.at((index + 5) % spline.number_of_elements).end_point.x - spline1.at(1).end_point.x,
               spline.at((index + 4) % spline.number_of_elements).end_point.y - spline1.at(0).end_point.y)

  new_spline = Spline.new
  start_point = spline.at(index).start_point.newX(spline1.at(2).end_point.x - WIDTH)
  new_spline.add(Line.new(start_point,
                          Point.new(start_point.x,
                                    spline1.at(0).start_point.y - HEIGHT, 25)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          new_spline.last.end_point.newX(spline.at((index + 1) % spline.number_of_elements).end_point.x)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          new_spline.last.end_point.clone.move(0, HEIGHT)))
  new_spline.add(Line.new(new_spline.last.end_point,
                          spline1.at(0).start_point))
  spline1.each {|s|
    new_spline.add(s)
  }

  new_spline.add(Line.new(new_spline.last.end_point,
                          spline.at((index + direction.length - 1) % spline.number_of_elements).end_point.newX(new_spline.last.end_point.x)))

  start_index = (index + direction.length) % spline.number_of_elements
  while true
    break if start_index == index
    start_point = new_spline.last.end_point
    end_point = (index == ((start_index + 1) % spline.number_of_elements)) ? new_spline.at(0).start_point : spline.at(start_index).end_point
    element = spline.at(start_index).clone
    element.start_point = start_point
    element.end_point = end_point
    new_spline.add(element)
    start_index = (start_index + 1) % spline.number_of_elements
  end

  return new_spline
end

def fixSpline(spline)
  include Direction
  direction = [E, S, W, N]
  return nil if spline.number_of_elements < direction.length

  index = spline.match(direction)
  return nil unless index

  if spline.at(0).start_point.x == spline.at(0).end_point.x
    new_spline = Spline.new
    1.upto(3) {|i|
      new_spline.add(spline.at(i))
    }
    new_spline.add(spline.at(0))
    spline = new_spline
  end
  is_box = true
  is_horizontal = true

  spline.each {|s|
    is_box &= is_horizontal ? s.start_point.y == s.end_point.y : s.start_point.x == s.start_point.x
    is_horizontal = !is_horizontal
  }

  if is_box
    width = spline.at(0).length
    height = spline.at(1).length
    if (width > height)
      if height != HEIGHT then
        original_smaller = [spline.at(1).start_point.y, spline.at(1).end_point.y].min
        original_bigger = [spline.at(1).start_point.y, spline.at(1).end_point.y].max
        middle = (spline.at(1).start_point.y + spline.at(1).end_point.y) / 2
        smaller = middle - HEIGHT / 2
        bigger = middle + HEIGHT / 2
        new_spline = Spline.new
        spline.each {|s|
          new_spline.add(Line.new(Point.new(s.start_point.x,
                                            s.start_point.y == original_smaller ? smaller : bigger,
                                            s.start_point.attr),
                                  Point.new(s.end_point.x,
                                            s.end_point.y == original_smaller ? smaller : bigger,
                                            s.end_point.attr)))
        }
        return new_spline
      end
    else
      if width != WIDTH then
        original_smaller = [spline.at(0).start_point.x, spline.at(0).end_point.x].min
        original_bigger = [spline.at(0).start_point.x, spline.at(0).end_point.x].max
        middle = (spline.at(1).start_point.x + spline.at(1).end_point.x) / 2
        smaller = middle - WIDTH / 2
        bigger = middle + WIDTH / 2
        new_spline = Spline.new
        spline.each {|s|
          new_spline.add(Line.new(Point.new(s.start_point.x == original_smaller ? smaller : bigger,
                                            s.start_point.y, s.start_point.attr),
                                  Point.new(s.end_point.x == original_smaller ? smaller : bigger,
                                            s.end_point.y, s.end_point.attr)))
        }
        return new_spline
      end
    end
  end
  return spline
end


def parse(wrapper)
  header = ""
  splines = Array.new
  in_spline_data = false
  base_point = nil
  points = Array.new
  while l = wrapper.next
    l.chomp!
    if l == "Fore" then
      in_spline_data = true
    elsif l == "EndSplineSet"
      in_spline_data = false
      break
    elsif in_spline_data
      if l[0..0] != " " then
        x, y, m, attr = l.split
        splines << arrayToSpline(base_point, points) if base_point
        base_point = Point.new(x, y, attr)
        points = Array.new
      else
        data = l.split
        points << data
      end
    else
      header += l + "\n"
    end
  end
  splines << arrayToSpline(base_point, points) if points.length > 0
  return [header, splines]
end

class FileWrapper
  def initialize(file)
    @file = File.open(file)
  end

  def finish
    @file.close
  end

  def next
    @file.gets
  end
end

class StringWrapper
  def initialize(str)
    @index = 0
    @strings = str.split(/\n/)
  end

  def finish
  end

  def next
    if @index >= @strings.length
      return nil
    else
      str = @strings[@index]
      @index += 1
      return str
    end
  end
end

def fix(wrapper)
  header, splines = parse(wrapper)
  ret = header
  ret += "Fore\n"
  splines.each {|x|
    new_spline = fixSpline(x)
    new_spline = fixHorizontalLine(x) unless new_spline
    new_spline = fixVerticalLine1(x) unless new_spline
    new_spline = x.fixHorizontalVerticalHorizontal unless new_spline
    new_spline = fixHorizontalAndVertical(x) unless new_spline
    new_spline = fixHorizontalAndVertical1(x) unless new_spline
    new_spline = fixHorizontalLine2(x) unless new_spline
    new_spline = x.fixVerticalAndHorizontal unless new_spline
    new_spline = x.fixVerticalWithHeadAndHorizontal unless new_spline
    new_spline = fixVerticalLine2(x) unless new_spline
    new_spline = fixVerticalLine3(x) unless new_spline
    new_spline = fixVerticalLine4(x) unless new_spline
    ret += (new_spline ? new_spline : x).to_s
  }
  ret += "EndSplineSet\n"
  ret += "EndChar\n"
  wrapper.finish
  return ret
end

if $0 == __FILE__
  puts fix(FileWrapper.new(ARGV[0]))
end
