class Api::Decorator < Draper::Decorator
  delegate_all

  def as_json(*)
    super(object.class.try(:json_options)).
      reject do |k,v|
        blacklisted_attrs.include?(k) || k.end_with?('_count')
      end.
      merge(associations_as_json)
  end

  def associations_as_json
    {}.tap do |json|
      model = Api::Model.new(object.class.name.underscore)
      associations = [
        model.has_many_associations,
        model.has_and_belongs_to_many_associations
      ].flatten

      associations.each do |association|
        next if expanded_association?(association) || excluded_association?(association)
        json[association.param] = object.send(association.name).pluck(association.primary_key)
      end
    end
  end

  private

  def blacklisted_attrs
    %w(user_id created_at updated_at)
  end

  def expanded_association?(association)
    return false unless object.class.respond_to?(:json_options)

    includes = Array.wrap(object.class.json_options[:include])
    includes.include?(association.name.to_sym)
  end

  def excluded_association?(association)
    return false unless object.class.respond_to?(:json_options)

    excludes = Array.wrap(object.class.json_options[:except])
    excludes.include?(association.name.to_sym)
  end
end
