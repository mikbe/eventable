require 'thread'
Thread.abort_on_exception = true

class Foo
  attr_accessor :bar

  def baz
    @bar ||= rand(10000000000)
  end
end

f = Foo.new
baz1 = -1
baz2 = -1
count = 0
last_one = ""
while baz1 == baz2
  last_one = "f.bar: #{f.bar}; baz1: #{baz1}; baz2: #{baz2}"
  f.bar = nil
  wait_til = Time.now + 0.01
  Thread.new {sleep (wait_til - Time.now); baz1 = f.baz }
  Thread.new {sleep (wait_til - Time.now); baz2 = f.baz }
  sleep 0.02
  count += 1
  if count == 100
    puts "working: #{last_one}"
    count = 0
  end
end
puts
puts "Thread collision"
puts "previous: #{last_one}" # Just to prove it's not remembering value from last iteration but is a real collision
puts "current:  f.bar: #{f.bar}; baz1: #{baz1}; baz2: #{baz2}"

