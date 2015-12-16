module AwesomeDelete
  module DeleteExtension
    def delete_collection ids, all_associations_name = []
      #检查是否有destroy callback -> where(id: ids).destroy_all 或 delete_all

      #找 has_many(排除through) 并且 dependent destroy, foreign_key, class_name, polymorphic

      #counter_cahce, touch

      if all_associations_name.blank?
        all_association_name = get_associations_name << self.name
      end

      # STI
      if column_names.include? inheritance_column
        where(id: ids).pluck(inheritance_column).uniq.each do |type|
          subklass = type.constantize
          subklass.delete_self_collection(ids, all_associations_name)
          delete_assoicated_collection(ids, subklass.has_many_assoications - has_many_assoications, all_associations_name)
        end
      else
        delete_self_collection(ids, all_associations_name)
      end
      delete_assoicated_collection(ids, has_many_assoications, all_associations_name)
    end

    def has_many_assoications
      reflect_on_all_associations(:has_many).select do |association|
        association.is_a?(ActiveRecord::Reflection::HasManyReflection) && association.options.deep_symbolize_keys.has_key?(:dependent)
      end
    end

    def can_directly_delete_all? all_associations_name
      not_handle_destroy_callback? && not_handle_counter_cache_or_touch?(all_associations_name)
    end

    def not_handle_destroy_callback?
      has_many_assoications.count == _destroy_callbacks.count
    end

    def not_handle_counter_cache_or_touch? all_associations_name
      belongs_to_assoications = reflect_on_all_associations(:belongs_to).select do |association|
                                  association.options.deep_symbolize_keys.has_key?(:touch) || association.options.deep_symbolize_keys.has_key?(:counter_cahce)
                                end
      associated_class_names = belongs_to_assoications.map(&:class_name)
      (all_associations_name & associated_class_names) == associated_class_names
    end

    def delete_self_collection ids, all_associations_name
      if can_directly_delete_all?(all_associations_name)
        where(id: ids).delete_all
      else
        where(id: ids).destroy_all
      end
    end

    def delete_assoicated_collection ids, associations, all_associations_name
      associations.each do |association|
        association_class = association.class_name.constantize

        #polymorphic
        if association.type
          association_class.delete_collection association_class.where(association.foreign_key => ids, association.type => self.name).pluck(:id), all_associations_name
        else
          association_class.delete_collection association_class.where(association.foreign_key => ids).pluck(:id), all_associations_name
        end
      end
    end

    def get_associations_name
      return [] if has_many_assoications.blank?
      associations_name = []

      has_many_assoications.each do |association|
        associations_name << association.class_name
        associations_name += association.class_name.constantize.get_associations_name
      end
      associations_name
    end
  end
end