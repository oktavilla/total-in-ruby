module TotalIn
  class Contexts
    def initialize containers = nil
      Array(containers).compact.each do |container|
        add container
      end
    end

    def result
      contexts.first
    end

    def current
      contexts.last
    end

    def add container
      contexts.push container
    end

    def move_up
      contexts.pop
    end

    def move_to container_class
      until current.is_a?(container_class)
        move_up
      end if contexts.any?
    end

    def move_to_or_add_to_parent container_class, parent_container_class
      return self if current.is_a?(container_class)

      until current.kind_of?(parent_container_class)
        move_up
      end

      entity = container_class.new

      setter_name = StringHelpers.underscore container_class.name.split("::").last
      current.public_send "#{setter_name}=", entity

      add entity

      self
    end

    private

    def contexts
      @contexts ||= []
    end
  end
end
