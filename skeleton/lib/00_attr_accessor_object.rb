class AttrAccessorObject
    def self.my_attr_accessor(*names)
        names.each do |name|
            variable_name = ("@" + name.to_s).to_sym
            self.define_method(name) do
                instance_variable_get(variable_name)
            end

            setter_method = (name.to_s + "=").to_sym
            self.define_method(setter_method) do |value|
                instance_variable_set(variable_name, value)
            end
        end
    end
end
