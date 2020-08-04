# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # 'group' => ['category', 'another-top-level-category', ['parent-category', 'sub-category']],
      # 'everyone' makes every user watch the listed categories
      # 'everyone' => ['announcements']
      'Moderators' => ['helios']
#      'digcol-cmte' => [['private', 'digital-collections-committee']]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)





    #this is actually watching first post, not tracking
    groups_cats = {
      'cybertechnician' => ['age', ['age', 'wiki'], 'eis', ['eis', 'wiki'], 'agn',['agn','wiki'],'saas',['saas','wiki'],'third-party', ['third-party','wiki'], 'iis',['iis','wiki'], ['internal', 'ctsad'],['internal','announcements'],['internal', 'rtline'] ],
      'everyone' => [['internal','announcements'],'helios','age','eis','agn','saas','third-party','iis']
    }

    WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)


  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == 'everyone'
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              muted_categories = CategoryUser.lookup(user, :muted).pluck(:category_id)
              watching_categories = CategoryUser.lookup(user, :watching).pluck(:category_id)
              tracking_categories = CategoryUser.lookup(user, :tracking).pluck(:category_id)
              if not muted_categories.include?(category.id)
                if not watching_categories.include?(category.id)
                  if not tracking_categories.include?(category.id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
                  end
                end
              end
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              muted_categories = CategoryUser.lookup(user, :muted).pluck(:category_id)
              watching_categories = CategoryUser.lookup(user, :watching).pluck(:category_id)
              tracking_categories = CategoryUser.lookup(user, :tracking).pluck(:category_id)
              if not muted_categories.include?(category.id)
                if not watching_categories.include?(category.id)
                  if not tracking_categories.include?(category.id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
                  end
                end
              end
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 1.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
