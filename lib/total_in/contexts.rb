module TotalIn
  class Contexts
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
      end
    end

    private

    def contexts
      @contexts ||= []
    end
  end
end
