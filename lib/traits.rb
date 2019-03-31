module Traitable
  def +(another_trait)
    ComposedTrait.new(as_trait, another_trait.as_trait)
  end

  def -(methods_to_remove)
    PartialTrait.new(as_trait, methods_to_remove)
  end

  def &(alias_dictionary)
    AliasedTrait.new(as_trait, alias_dictionary)
  end

  def as_trait
    raise 'subclass responsibility'
  end
end

class BaseTrait
  include Traitable

  def as_trait
    self
  end

  def use_in(klass)
    verify_no_conflicts_for!(klass)

    methods.each do |method_name, method|
      klass.define_method(method_name, method)
    end
  end

  def methods
    raise 'subclass responsibility'
  end

  private

  def verify_no_conflicts_for!(klass)
    existing_methods = methods.keys.select { |method_name| klass.method_defined?(method_name) }
    raise IncludedTraitConflict.new(klass, self, existing_methods) unless existing_methods.empty?
  end
end

class Trait < BaseTrait
  def initialize(method_container = nil, &block)
    @method_container = method_container.nil? ? Module.new(&block) : method_container
  end

  def methods
    @method_container.instance_methods.map do |method_name|
      [method_name, @method_container.instance_method(method_name)]
    end.to_h
  end
end

class ComposedTrait < BaseTrait
  def initialize(*traits)
    @traits = traits
    verify_no_conflicts!
  end

  def methods
    @traits.map(&:methods).inject({}, &:merge)
  end

  private

  def verify_no_conflicts!
    repeated_methods = @traits.map(&:methods).map(&:keys).reduce(:&)
    raise ComposedTraitConflict.new(@traits, repeated_methods) unless repeated_methods.empty?
  end
end

class PartialTrait < BaseTrait
  def initialize(parent_trait, methods_to_remove)
    @parent_trait = parent_trait
    @methods_to_remove = methods_to_remove.is_a?(Array) ? methods_to_remove : [methods_to_remove]
  end

  def methods
    @parent_trait.methods.delete_if { |method_name, _| @methods_to_remove.include?(method_name) }
  end
end

class AliasedTrait < BaseTrait
  def initialize(parent_trait, alias_dictionary)
    @parent_trait = parent_trait
    @alias_dictionary = alias_dictionary
  end

  def methods
    @alias_dictionary.reduce(@parent_trait.methods) do |result, alias_and_original|
      alias_name, method_name = alias_and_original
      result[alias_name] = result[method_name]
      result
    end
  end
end

TraitConflict = Class.new(StandardError)

IncludedTraitConflict = Class.new(TraitConflict) do
  def initialize(klass, trait, methods)
    super "The class #{klass} does not properly resolve a method conflict while including the trait #{trait}. " +
              "The method(s) #{methods.join(', ')} were already defined."
  end
end

ComposedTraitConflict = Class.new(TraitConflict) do
  def initialize(traits, repeated_methods)
    super "The trait combination between #{traits.join(' and ')} does not properly resolve a method conflict. " +
              "The method(s) #{repeated_methods.join(', ')} are defined multiple times."
  end
end

class Module
  include Traitable
  def as_trait
    Trait.new(self)
  end
end

class Class
  def use(trait)
    trait.as_trait.use_in(self)
  end
end

