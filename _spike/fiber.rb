Fiber.new do
  Fiber.yield @z = rand(10000)
end.resume
class Foo
  attr_accessor :bar

  def baz
    Fiber{
      Fiber.yield @bar ||= rand(10000000000)
    }.resume
  end
end

f = Foo.new
puts f.baz
puts @z
puts "done"
