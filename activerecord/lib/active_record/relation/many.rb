module ActiveRecord
  module Many
    module Static
      def self.embellish(relation)
        klass = relation.klass
        klass.class_eval(ar_inner_class_string(relation)) unless Kernel.const_defined?("#{klass.name}::Many")
        with_many_class = klass.const_get("Many")
        with_many_class.new(relation)
      end

      def self.ar_inner_class_string(relation)
        methods = {
          relation: [:where,:order,:to_sql],
          reflection: relation.has_many_reflections_names,
          scope: relation.klass.respond_to?('scopes_names') ? relation.klass.scopes_names : []
        }
        %(
          class Many < ActiveSupport::Many
    
            def initialize(enumerable)
              super
            end
    
            def map_method(kind, name, *args, &block)
              case kind
              when :relation
                ActiveRecord::Many::Static.embellish(@enumerable.send(name,*args, &block))
              when :reflection
                ActiveRecord::Many::Static.embellish(@enumerable.reverse_to(name))
              when :scope
                ActiveRecord::Many::Static.embellish(@enumerable.merge(@enumerable.klass.send(name, *args, &block)))
              end
            end
    
            #{
              methods.map{|key, methods|
                methods.map{|name|
                  %(
                    def #{name}(*args, &block)
                      self.map_method(:#{key}, '#{name}', *args, &block)
                    end
                  )
                }
              }.flatten.join(' ')
            }
          end
        )
      end
    end

    def with_many
      Many::Static.embellish(self.current_scope)
    end

    def reverse_to(name)
      reflection = self.klass._reflections[name]

      reflection_inverse_name = 
        reflection.send(:inverse_name) ||
        reflection.options[:as] ||
        self.klass.name.underscore.to_sym ||
        nil

      inverse_reflection = reflection.klass._reflect_on_association(reflection_inverse_name)
    
      if reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
        reverse_chain = reflection.chain.reverse
        reverse_chain.reduce(self){|relation, reflection|
          relation.reverse_to(
            reflection.name.to_s
          )
        }
      elsif inverse_reflection.polymorphic?
        result = 
          inverse_reflection
          .active_record
          .where(
            inverse_reflection.foreign_type => self.klass.to_s,
            inverse_reflection.foreign_key => self
          )
        reflection.scope.nil? ? result : result.merge(reflection.scope)
      else
        result = 
          reflection.klass
          .joins(inverse_reflection.name)
          .merge(self)
        reflection.scope.nil? ? result : result.merge(reflection.scope)
      end
    end

    def has_many_reflections_names
      self.klass._reflections.filter{|name, reflection|
        #reflection = reflection.chain.last if reflection.through_reflection?
        reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
      }.keys
    end
  end
end