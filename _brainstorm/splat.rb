def foo(a,b,c)
  puts
  puts "foo"
  puts "a:#{a}; b: #{b}; c: #{c};"
end

def foo_explicit_block(a, b, c, &block)
  puts
  puts "foo_with_block"
  puts "a:#{a}; b: #{b}; c: #{c};"
  puts block.inspect
end

def foo_implied_block(a,b,c)
  puts
  puts "foo_implied_block"
  puts "a:#{a}; b: #{b}; c: #{c};"
  yield [a,b,c]
end

def bar(*args, &block)
  foo(*args, &block)
  foo_explicit_block(*args, &block)
  foo_implied_block(*args, &block)
end

bar(1,2,3) {|x| puts x}
