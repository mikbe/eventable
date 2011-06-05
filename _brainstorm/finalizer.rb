# how does the finalizer work?
# I need to unregister the object when the finalizer
# is called but will it be called if I'm holding a reference to it?

class Foo
  def self.finalize(object_id)
    proc {puts "finalize me: #{object_id}"}
  end

  def initialize
    ObjectSpace.define_finalizer( self, self.class.finalize(self.object_id))
  end

  def hello
    puts "hello: #{self.object_id}"
  end

end

@y = []
def external_finalizer(object_id)
  proc do 
    puts "external finalizer: #{object_id}"
    @y.delete(object_id)
  end
end

(0..4).each do |i|
  f = Foo.new
  ObjectSpace.define_finalizer(f, external_finalizer(f.object_id))
  GC.start
  @y << f.object_id
  puts "i: #{i}"
end

@y.each do |object_id|
  begin
    obj = ObjectSpace._id2ref(object_id)
    obj.hello
  rescue RangeError => e
    puts "das error: #{!!e.message.match(/is recycled object/)}"
  end
end

puts "all done : note the finalizers firing AFTER this..."



