# Filling in the gaps with the Adapter


# Three ways to adapt

1. Subclass implementing desired methods.
2. Monkey patch.
3. Modify a single instance.

# Subclass

~~~
@@@ruby

  class MyClass
    attr_reader :fou
  end

  class MyClassAdapter < MyClass
    def foo
      @fou
    end
  end
~~~



# Monkey patch 🙈

~~~
@@@ruby

  class MyClass
    attr_reader :fou
  end

  # Monkey patch
  class MyClass
    def foo
      @fou
    end
  end
~~~


# Beat it into submission

I first saw this technique in - of all things - some code Bosco wrote.
I was terribly impressed, but I haven't seen it elsewhere in the wild.

### Modifying a single instance

~~~
@@@ruby

  bto = BritishTextObject('hello', 50.8, :blue)

  class << bto
    def text
      string
    end
  end
~~~

# Questions?


# More?


# Adapter in the wild


![If it looks like a duck, quacks like a duck...](./duck_typing.jpg)

# Even more?

# No more!
