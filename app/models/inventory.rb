class Inventory < ActiveRecord::Base
  self.table_name = "inv_inventory"

  belongs_to :organization, -> { where(type_id: 4) }, foreign_key: :store_id
  belongs_to :inventory_product, foreign_key: :product_id
end

class InventoryProduct < ActiveRecord::Base
  self.table_name = "mst_inv_product"

  belongs_to :inventory_category3, foreign_key: :category3_id

  belongs_to :inventory, foreign_key: :product_id

end

class InventoryCategory3 < ActiveRecord::Base
  self.table_name = "mst_inv_category3"

  belongs_to :inventory_category2, foreign_key: :category2_id
  has_many :inventory_products, foreign_key: :category3_id
end

class InventoryCategory2 < ActiveRecord::Base
  self.table_name = "mst_inv_category2"

  belongs_to :inventory_category1, foreign_key: :category1_id

  has_many :inventory_category3s, foreign_key: :category2_id
end

class InventoryCategory1 < ActiveRecord::Base
  self.table_name = "mst_inv_category1"

  has_many :inventory_category2s, foreign_key: :category1_id

end

class InventoryCategoryCaption < ActiveRecord::Base
  self.table_name = "mst_inv_category_caption"
end