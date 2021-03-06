class Product < ActiveRecord::Base
  self.table_name = "spt_product_serial"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  attr_accessor :current_user_id

  mapping do
    indexes :tickets, type: "nested", include_in_parent: true
  end

  def self.search(params)  
    tire.search(page: (params[:page] || 1), per_page: (params[:per_page] || 1000)) do
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          # must { range :published_at, lte: Time.zone.now }
          # must { term :author_id, params[:author_id] } if params[:author_id].present?
        end
      end
      sort { by :created_at, "desc" } if params[:query].blank?
      highlight :serial_no, :options => { :tag => '<strong class="highlight">' } if params[:query].present?
    end
      # query { string params[:query] } if params[:query].present?

      # filter :range, published_at: { lte: Time.zone.now} 
      # raise to_curl
  end

  def to_indexed_json
    Warranty
    to_json(
      only: [:id, :serial_no, :model_no, :product_no, :created_at, :owner_customer_id, :name, :description, :product_brand_id, :product_category_id, :updated_at],
      methods: [:category_full_name_index, :category_cat_id, :category_cat1_id, :category_cat2_id, :brand_name, :brand_id, :owner_customer_name, :location_address_full, :owner_customer_address],
      include: {
        tickets: {
          only: [:created_at, :cus_chargeable, :id],
          methods: [:customer_name, :ticket_status_name, :warranty_type_name, :support_ticket_no],
        },
        product_pop_status: {
          only: [:name, :code]
        },
        ticket_contracts: {
          only: [:id],
          include: {
            organization: {
              only: [:id, :name],
            }
          }
        }
      }
    )

  end

  def category1_name
    product_category.try(:product_category2).try(:product_category1).try(:name)
  end

  def category2_name
    product_category.try(:product_category2).try(:name)
  end

  def category3_name
    product_category.try(:name)
  end

  def category_full_name_index
    "#{category1_name}|#{category2_name}|#{category3_name}"
  end

  def category_full_name(divide_by)
    "#{category1_name}#{divide_by}#{category2_name}#{divide_by}#{category3_name}"
  end

  def category_cat_id
    product_category.try(:id)
  end
  def category_cat1_id
    product_category.try(:product_category2).try(:product_category1).try(:id)
  end
  def category_cat2_id
    product_category.try(:product_category2).try(:id)
  end
  def brand_id
    product_brand.try(:id)
  end
  def brand_name
    product_brand.try(:name)
  end

  def owner_customer_name
    owner_customer.try(:name)
  end

  def owner_customer_address
    if owner_customer.present?
      owner_customer.primary_address.try(:full_address)
    end
  end

  def location_address_full
    {full_address: location_address.try(:full_address), category: location_address.try(:category)}
  end

  mount_uploader :pop_doc_url, PopDocUrlUploader

  has_many :ticket_product_serials, foreign_key: :product_serial_id
  accepts_nested_attributes_for :ticket_product_serials, allow_destroy: true

  has_many :tickets, through: :ticket_product_serials
  has_many :warranties, foreign_key: :product_serial_id
  accepts_nested_attributes_for :warranties, allow_destroy: true
  has_many :contract_products, foreign_key: :product_serial_id
  has_many :ticket_contracts, through: :contract_products

  has_many :product_customer_histories, foreign_key: :product_serial_id, dependent: :delete_all

  has_many :ref_product_serials, class_name: "TicketProductSerial", foreign_key: :ref_product_serial_id
  accepts_nested_attributes_for :ref_product_serials, allow_destroy: true

  belongs_to :product_brand, foreign_key: :product_brand_id
  belongs_to :product_category, foreign_key: :product_category_id
  belongs_to :product_pop_status, foreign_key: :pop_status_id
  belongs_to :product_sold_country, foreign_key: :sold_country_id
  belongs_to :inv_serial_item, foreign_key: :inventory_serial_item_id
  belongs_to :owner_customer, class_name: "Organization"
  belongs_to :location_address, class_name: "Address"
  belongs_to :sla_time, foreign_key: :sla_id
  
  validates_presence_of [:serial_no, :product_brand_id, :product_category_id, :name]
  validates_uniqueness_of :serial_no, message: "This serial no has already been taken"

  # after_save :strip_serial_no

  # def append_pop_status
  #   self.pop_note = "#{self.pop_note} <span class='pop_note_e_time'>(edited on #{Time.now.strftime('%d %b, %Y at %H:%M:%S')})</span><br/>#{pop_note_was}"
  # end

  before_save do |product|

    if product.persisted? and product.pop_note_changed? and product.pop_note.present?
      product_pop_note = "#{product.pop_note} <span class='pop_note_e_time'> on #{Time.now.strftime('%d/ %m/%Y at %H:%M:%S')}</span> by <span class='pop_note_created_by'> #{User.cached_find_by_id(product.current_user_id).full_name}</span><br/>#{product.pop_note_was}"
    elsif product.new_record?
      product_pop_note = product.pop_note  
    else
      product_pop_note = product.pop_note_was
    end
    product.pop_note = product_pop_note
  end

  def cannot_removable_from_contract?(contract_id)
    ticket_contracts.find_by_id(contract_id) and ticket_contracts.find_by_id(contract_id).tickets.any? and ((ticket_ids - ticket_contracts.find_by_id(contract_id).ticket_ids) != ticket_ids)
  end

  def create_product_owner_history(owner_customer_id, created_by, note, created_mode)
    if owner_customer_id.present?
      if persisted?
        update owner_customer_id: owner_customer_id
        product_customer_histories.create(owner_customer_id: owner_customer_id, created_by: created_by, note: note)
      else
        owner_customer_id = owner_customer_id
        product_customer_histories.build(owner_customer_id: owner_customer_id, created_by: created_by, note: note)
      end
    end
    # if self.owner_customer_id != owner_customer_id
    # end
  end

  after_create -> { create_product_owner_history(owner_customer_id, create_by_id, "Added", 0) }

  def create_by_id
    @create_by_id
  end

  def create_by_id=(create_by_id)
    @create_by_id=create_by_id
  end

  def strip_serial_no
    self.update serial_no: self.serial_no.strip if self.serial_no.present?
  end

  def validate_destruction
    if tickets.any? or ticket_contracts.any?
      product_customer_histories.where(owner_customer_id: owner_customer_id).update_all(note: 'Removed from the customer')
      update!(owner_customer_id: nil)
    else
      destroy
    end
  end

end

class ProductBrand < ActiveRecord::Base
  self.table_name = "mst_spt_product_brand"

  has_many :products, foreign_key: :product_brand_id
  has_many :so_pos, foreign_key: :product_brand_id
  has_many :product_category1s, foreign_key: :product_brand_id
  has_many :active_product_category1s, -> {where(active: true)}, foreign_key: :product_brand_id, class_name: "ProductCategory1"

  accepts_nested_attributes_for :product_category1s, allow_destroy: true
  has_many :product_category2s,through: :product_category1s
  has_many :return_parts_bundles

  validates_presence_of [:name, :sla_time, :parts_return_days, :currency_id]
  belongs_to :currency, foreign_key: :currency_id
  belongs_to :sla_time, foreign_key: :sla_id
  belongs_to :supplier, class_name: "Organization", foreign_key: :organization_id
  has_many :product_brand_costs
  accepts_nested_attributes_for :product_brand_costs, allow_destroy: true

  has_many :brand_documents,class_name: "Documents::BrandDocument"
  accepts_nested_attributes_for :brand_documents, allow_destroy: true

  validates_uniqueness_of :name

  validates_numericality_of [:parts_return_days]
  def is_used_anywhere?
    TicketSparePart
    products.any? or product_category1s.any? or return_parts_bundles.any? or so_pos.any? or brand_documents.any?
  end
end

class ProductCategory1 < ActiveRecord::Base
  self.table_name = "mst_spt_product_category1"
  belongs_to :product_brand
  has_many :product_category2s, foreign_key: :product_category1_id
  has_many :active_product_category2s, -> {where(active: true)}, foreign_key: :product_category1_id, class_name: "ProductCategory2"
  accepts_nested_attributes_for :product_category2s, allow_destroy: true
  has_many :product_category3s,through: :product_category2s
  # scope :active_product_category1s, -> {where(active: true)}

  def is_used_anywhere?
    product_category2s.any?
  end
end

class ProductCategory2 < ActiveRecord::Base
  self.table_name = "mst_spt_product_category2"
  belongs_to :product_category1
  has_many :product_categories, foreign_key: :product_category2_id
  has_many :active_product_categories, -> {where(active: true)}, foreign_key: :product_category2_id, class_name: "ProductCategory"
  accepts_nested_attributes_for :product_categories, allow_destroy: true
  def is_used_anywhere?
    product_categories.any?
  end
end

class ProductCategory < ActiveRecord::Base
  self.table_name = "mst_spt_product_category"

  has_many :products, foreign_key: :product_category_id
  belongs_to :product_category2
  belongs_to :sla_time, foreign_key: :sla_id

  validates_presence_of [:name]

  def is_used_anywhere?
    products.any?
  end
end

class ProductPopStatus < ActiveRecord::Base
  self.table_name = "mst_spt_pop_status"

  has_many :products, foreign_key: :pop_status_id
end

class ProductSoldCountry < ActiveRecord::Base
  self.table_name = "mst_country"

  validates :Country, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  has_many :products, foreign_key: :sold_country_id

  has_many :inventory_product_info, foreign_key: :country_id

  has_many :addresses
  has_many :contact_numbers

  def is_used_anywhere?
    Inventory
    products.any? or inventory_product_info.present?
  end
  

  def country_name_with_code
    "#{self.Country} (#{self.code})"
  end

end

class InvSerialItem < ActiveRecord::Base
  self.table_name = "inv_inventory_serial_item"

  has_many :products, foreign_key: :inventory_serial_item_id
end

class Accessory < ActiveRecord::Base
  Ticket
  self.table_name = "mst_spt_accessory"

  validates :accessory, presence: true, uniqueness: true
  has_many :ticket_accessories, foreign_key: :accessory_id
  has_many :tickets, through: :ticket_accessories

  validates_uniqueness_of :accessory, case_sensitive: false

  def is_used_anywhere?
    ticket_accessories.any? or tickets.any? 
  end
end

class ProductBrandCost < ActiveRecord::Base
  self.table_name = "mst_spt_product_brand_cost"

  belongs_to :product_brand
  belongs_to :currency
end

class ProductCustomerHistory < ActiveRecord::Base
  self.table_name = "spt_customer_product_history"

  belongs_to :product, foreign_key: :product_serial_id
  belongs_to :owner_customer, class_name: "Organization"
end