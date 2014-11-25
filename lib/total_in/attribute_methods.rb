module AttributeMethods
  def self.included base
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module ClassMethods
    def attribute name
      register_attribute name
      define_attribute_reader name
      define_attribute_writer name
    end

    def register_attribute name
      self.attribute_names.push name
    end

    def attribute_names
      @attribute_names ||= []
    end

    def define_attribute_reader name
      define_method name do
        read_attribute name
      end
    end

    def define_attribute_writer name
      define_method "#{name}=" do |value|
        write_attribute name, value
      end
    end
  end

  module InstanceMethods
    def initialize attrs = {}
      self.assign_attributes attrs
    end

    def assign_attributes attrs
      attrs.each do |name, value|
        write_attribute name, value
      end
    end

    def attributes
      @attributes ||= {}
    end

    def read_attribute name
      attributes[name]
    end

    def write_attribute name, value
      attributes[name] = value if attribute_names.include?(name)
    end

    def attribute_names
      self.class.attribute_names
    end
  end
end
