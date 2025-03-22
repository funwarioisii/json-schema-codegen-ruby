User = Data.define(:name, :age, :email, :is_active) do
  def initialize(name:, age:, email:, is_active: nil)
    raise TypeError, "name must be a String" unless name.is_a?(String)
    raise TypeError, "age must be an Integer" unless age.is_a?(Integer)
    raise ArgumentError, "age must be greater than or equal to 0" if age < 0
    raise TypeError, "email must be a String" unless email.is_a?(String)
    unless is_active.nil?
          raise TypeError, "is_active must be a Boolean" unless [true, false].include?(is_active)
    end
    super(name: name, age: age, email: email, is_active: is_active)
  end
end