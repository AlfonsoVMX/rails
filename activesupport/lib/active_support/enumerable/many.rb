module ActiveSupport
  class Many
    def initialize(enumerable=nil)
      @enumerable = enumerable.is_a?(Enumerable) ? enumerable : nil
    end
    
    def method_missing(method, *args, &block)
      map(method, *args, &block)
    end
  
    def values
      lazy? ? @enumerable.force : @enumerable
    end

    def force(*args,&block)
      lazy? ? @enumerable.force(*args,&block) : @enumerable
    end
  
    def map(method, *args, &block)
      
      return self if @enumerable.nil?

      if method.is_a?(Proc)
        b = method.call(@enumerable)
        b.is_a?(Many) ? b : self.class.new(b)
      elsif method.is_a?(Symbol)
        self.class.new @enumerable.lazy.flat_map{|element| element.respond_to?(method) ? element.send(method,*args, &block) : nil}
      elsif method.is_a?(Hash) && method[:f].is_a?(Proc)        
        self.class.new @enumerable.lazy.flat_map(&method[:f])
      else
        self.class.new
      end

    end

    private
      def lazy?
        @enumerable.class == Enumerator::Lazy
      end
  end
end
