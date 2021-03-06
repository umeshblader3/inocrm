class Grn < ActiveRecord::Base
  self.table_name = "inv_grn"

  include Backburner::Performable

  include Tire::Model::Search
  include Tire::Model::Callbacks

  belongs_to :store, class_name: "Organization"
  belongs_to :srn
  belongs_to :srr
  belongs_to :inventory_po, foreign_key: :po_id
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by
  belongs_to :supplier, class_name: "Organization" #, -> { where(id: 2) }#, foreign_key: :po_id

  has_many :grn_items
  has_many :grn_batches, through: :grn_items
  has_many :grn_serial_items, through: :grn_items

  def self.search(params)
    tire.search(page: (params[:page] || 1), per_page: 10) do
      if params[:query]
        params[:query] = params[:query].split(" AND ").map{|q| q.starts_with?("grn_no_format") ? "("+q+" OR #{q.gsub('grn_no_format', 'grn_no')})" : q }.join(" AND ")
      end
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          # must { term :store_id, params[:store_id] } if params[:store_id].present?
          must { range :created_at, lte: params[:range_to].to_date.end_of_day } if params[:range_to].present?
          must { range :created_at, gte: params[:range_from].to_date.beginning_of_day } if params[:range_from].present?
          # filter :range, published_at: { lte: Time.zone.now}
        end
      end
      sort { by :grn_no, {order: "desc", ignore_unmapped: true} }
      # raise to_curl

    end
  end


  mapping do
    indexes :store, type: "nested", include_in_parent: true
    indexes :srn, type: "nested", include_in_parent: true
    indexes :srr, type: "nested", include_in_parent: true
    indexes :grn_items, type: "nested", include_in_parent: true
    indexes :inventory_po, type: "nested", include_in_parent: true

  end

  def to_indexed_json
    Gin
    Grn
    to_json(
      only: [:id, :store_id, :grn_no, :created_by, :remarks, :po_no, :supplier_id, :created_at, :srr_id, :po_id],
      methods: [:store_name, :supplier_name, :grn_no_format, :formated_created_at, :created_by_from_user],
      include: {
        store: {
          only: [:id, :name],
        },
        grn_items: {
          only: [:id],
          include: {
            gin_sources:{
              only: [:id, :gin_item_id],
              include:{
                gin_item:{
                  only: [:id, :gin_id],
                },
              },
            },
            inventory_po_item: {
              only: [:id],
              include: {
                inventory_prn_item: {
                  only: [:id, :prn_id],
                },
              },
            },
          },
        },
        srr: {
          only: [:id],
          include: {
            srr_item_sources: {
              only: [:id, :srr_item_id, :gin_source_id],
              include: {
                gin_source: {
                  only: [:id, :gin_item_id],
                  include: {
                    gin_item: {
                      only: [:id, :gin_id],
                    },
                  },
                },
              },
            },
          },
        },
        srn: {
          only: [:id],
          include: {
            gins: {
              only: [:id],
            },
          },
        },
        inventory_po: {
          only: [:id],
          methods: [:formated_po_no],
        }
      },
    )

  end

  # after_save :update_children_indics

  def update_children_indics
    [:grn_items].each do |children|
      # send(children).import
      send(children).each do |child|
        child.async(queue: 'index-model').update_index
      end
      # send(children).async.each do |child|
      #   # child.update_index
      #   # parent.to_s.classify.constantize.find(self.send(parent).id).update_index
      #   # children.to_s.classify.constantize.find(child.id).update_index
      #   child.update_index

      #   if child.is_a? GrnItem
      #     child.update_relation_index
      #   end
      # end
    end
  end

  # handle_asynchronously :update_children_indics, queue: 'index-model', pri: 5001

  def grn_no_format
    grn_no.to_s.rjust(5, INOCRM_CONFIG["inventory_grn_no_format"])
  end

  def store_name
    store.name
  end

  def supplier_name
    supplier.try(:name)
  end

  def formated_created_at
    created_at.strftime(INOCRM_CONFIG["short_date_format"])
  end

  def created_by_from_user
    created_by_user.full_name
  end

  def assign_grn_no
    # self.grn_no = CompanyConfig.first.next_sup_last_grn_no
    self.grn_no = CompanyConfig.first.increase_inv_last_grn_no
  end

  before_create :assign_grn_no

end

class GrnItem < ActiveRecord::Base
  self.table_name = "inv_grn_item"

  include Backburner::Performable

  include Tire::Model::Search
  include Tire::Model::Callbacks

  belongs_to :srn_item
  belongs_to :grn
  belongs_to :inventory_product, foreign_key: :product_id
  belongs_to :inventory_po_item, foreign_key: :po_item_id
  belongs_to :srr_item
  belongs_to :currency

  has_many :grn_batches
  accepts_nested_attributes_for :grn_batches, allow_destroy: true
  has_many :inventory_batches, through: :grn_batches
  accepts_nested_attributes_for :inventory_batches, allow_destroy: true

  has_many :grn_serial_items, foreign_key: :grn_item_id
  accepts_nested_attributes_for :grn_serial_items, allow_destroy: true
  has_many :inventory_serial_items, through: :grn_serial_items

  has_many :grn_serial_parts, foreign_key: :grn_item_id
  # has_many :inventory_serial_item_for_grn_serial_parts, through: :grn_serial_parts
  # has_many :inventory_serial_parts, through: :grn_serial_parts
  scope :only_grn_items, -> { joins(:grn_serial_items, :grn_batches).where("inv_grn_batch.grn_item_id != :id AND inv_grn_serial_item.grn_item_id != :id", {id: nil} )}

  has_many :damages
  accepts_nested_attributes_for :damages, allow_destroy: true

  has_many :gin_sources
  has_many :gin_serial_parts
  has_many :grn_item_current_unit_cost_histories, -> { order("created_at desc")}
  accepts_nested_attributes_for :grn_item_current_unit_cost_histories, allow_destroy: true

  # after_create :update_relation_index
  before_save :rectify_stock_cost

  def self.only_grn_items1
    # select{|grn_item| grn_item.grn_serial_items.blank? and grn_item.grn_batches.blank? and grn_item.grn_serial_parts.blank? and grn_item.remaining_quantity >0}

    joins(inventory_product: :inventory_product_info).where(mst_inv_product: {non_stock_item: false}, "mst_inv_product_info.need_serial" => false, "mst_inv_product_info.need_batch" => false).references(:mst_inv_product, :mst_inv_product_info).where("remaining_quantity > 0")
  end

  def any_remaining_serial_item
    grn_serial_items.any? { |s| s.remaining }
  end

  def grn_supplier_name
    grn.supplier.try(:name)
  end

  def total_grn_cost
    current_unit_cost * if inventory_serial_items.any?
      1

    elsif inventory_batches.any?
      grn_batches.sum(:remaining_quantity) + grn_batches.sum(:damage_quantity)
    else
      remaining_quantity.to_f + damage_quantity.to_f
    end

  end

  def update_relation_index
    async(delay: 5.seconds, queue: 'index-model').update_index_async

  end

  def update_index_async
    case inventory_product.product_type
      when "Serial"
        grn_serial_items.where(remaining: true).each do |grn_serial_item|
          grn_serial_item.inventory_serial_item.update_index
        end
      when "Batch"

        grn_batches.where('remaining_quantity > 0').each do |grn_batch|
          grn_batch.inventory_batch.update_index
        end
    end
  end

  def rectify_stock_cost
    grn_item = self

    if grn_item.persisted? and grn_item.remarks_changed? and grn_item.remarks.present?
      grn_item_remarks = "#{grn_item.remarks} <span class='pop_note_e_time'> on #{Time.now.strftime('%d/ %m/%Y at %H:%M:%S')}</span> by <span class='pop_note_created_by'> #{User.cached_find_by_id(grn_item.current_user_id).try(:full_name)}</span><br/>#{grn_item.remarks_was}"
    elsif grn_item.new_record?
      grn_item_remarks = grn_item.remarks  
    else
      grn_item_remarks = grn_item.remarks_was
    end
    grn_item.remarks = grn_item_remarks

    if (grn_item.current_unit_cost_changed? or grn_item.remaining_quantity_changed?) and grn_item.persisted?
      Inventory.where(product_id: grn_item.product_id, store_id: grn_item.grn.store_id).pluck(:id).uniq{|i| i }.each do |id|
        Rails.cache.delete([:stock_cost, grn_item.product_id, id ])

      end

      grn_item.inventory_serial_items.pluck(:product_id, :inventory_id).uniq{|i| i[0] and i[1]}.each do |a|
        Rails.cache.delete([:stock_cost, a[0], a[1] ])

      end

      grn_item.inventory_batches.pluck(:product_id, :inventory_id).uniq{|i| i[0] and i[1]}.each do |a|
        Rails.cache.delete([:stock_cost, a[0], a[1] ])

      end
    end
  end

  # handle_asynchronously :rectify_stock_cost, queue: 'index-model', pri: 5002

  # before_save do |grn_item|
  #   if grn_item.persisted? and grn_item.remarks_changed? and grn_item.remarks.present?
  #     grn_item_remarks = "#{grn_item.remarks} <span class='pop_note_e_time'> on #{Time.now.strftime('%d/ %m/%Y at %H:%M:%S')}</span> by <span class='pop_note_created_by'> #{User.cached_find_by_id(grn_item.current_user_id).try(:full_name)}</span><br/>#{grn_item.remarks_was}"
  #   elsif grn_item.new_record?
  #     grn_item_remarks = grn_item.remarks  
  #   else
  #     grn_item_remarks = grn_item.remarks_was
  #   end
  #   grn_item.remarks = grn_item_remarks

  #   if (grn_item.current_unit_cost_changed? or grn_item.remaining_quantity_changed?) and grn_item.persisted?
  #     Inventory.where(product_id: grn_item.product_id, store_id: grn_item.grn.store_id).pluck(:id).uniq{|i| i }.each do |id|
  #       Rails.cache.delete([:stock_cost, grn_item.product_id, id ])

  #     end

  #     grn_item.inventory_serial_items.pluck(:product_id, :inventory_id).uniq{|i| i[0] and i[1]}.each do |a|
  #       Rails.cache.delete([:stock_cost, a[0], a[1] ])

  #     end

  #     grn_item.inventory_batches.pluck(:product_id, :inventory_id).uniq{|i| i[0] and i[1]}.each do |a|
  #       Rails.cache.delete([:stock_cost, a[0], a[1] ])

  #     end
  #   end

  # end

  has_many :dyna_columns, as: :resourceable, autosave: true

  [:flagged_as, :current_user_id].each do |dyna_method|
    define_method(dyna_method) do
      dyna_columns.find_by_data_key(dyna_method).try(:data_value)
    end

    define_method("#{dyna_method}=") do |value|
      data = dyna_columns.find_or_initialize_by(data_key: dyna_method)
      data.data_value = (value.class==Fixnum ? value : value.strip)
      data.save# if data.persisted?
    end
  end

  validates_presence_of :recieved_quantity
  # validates_presence_of [:unit_cost, :current_unit_cost, :currency_id, :recieved_quantity, :remaining_quantity, :grn_id], on: :create
  # validates_presence_of :unit_cost, on: :create

  mapping do
    indexes :inventory_product, type: "nested", include_in_parent: true
    indexes :inventory_serial_items, type: "nested", include_in_parent: true
    indexes :grn, type: "nested", include_in_parent: true
    indexes :grn_serial_items, type: "nested", include_in_parent: true
    indexes :grn_item_current_unit_cost_histories, type: "nested", include_in_parent: true
  end

  def self.search(params)
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.3/query-dsl-query-string-query.html
    tire.search(page: (params[:page] || 1), per_page: 10) do
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          # must { term :store_id, params[:store_id] } if params[:store_id].present?
          # puts params[:store_id]
        end
      end
      sort { by :created_at, {order: "desc", ignore_unmapped: true} }
      # filter :range, published_at: { lte: Time.zone.now}
      # raise to_curl
    end
  end

  def to_indexed_json
    Inventory
    to_json(
      only: [:id, :serial_no, :ct_no, :created_at, :current_unit_cost, :inventory_not_updated, :remaining_quantity, :recieved_quantity, :reserved_quantity, :damage_quantity],
      methods: [:grn_supplier_name, :total_grn_cost],
      include: {
        inventory_product: {
          only: [:id, :description, :model_no, :product_no, :spare_part_no, :created_at],
          methods: [:category3_id, :category2_id, :category1_id, :generated_item_code],

          include: {
            inventories: {
              only: [:id, :store_id, :product_id],
              methods: [:inventory_stock_quantity, :product_stock_cost]
            }
          }
        },
        currency: {
          only: [:code],
        },
        inventory_serial_items: {
          only: [:serial_no, :ct_no, :damaged, :used, :scavenge, :repaired, :reserved, :parts_not_completed, :manufatured_date, :expiry_date, :remarks],
          include: {
            product_condition: {
              only: [:name]
            },
            inventory_serial_item_status: {
              only: [:name]
            }
          }
        },
        grn_serial_items: {
          only: [:id, :remaining]
        },
        grn: {
          only: [:grn_no, :created_at, :store_id, :remarks],
          methods: [:grn_no_format]
        },
        grn_item_current_unit_cost_histories: {
          only: [:id, :created_at, :current_unit_cost, :created_by],
        },
      }
    )

  end

end

class GrnBatch < ActiveRecord::Base
  self.table_name = "inv_grn_batch"

  include Backburner::Performable

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :grn_item, type: "nested", include_in_parent: true
    indexes :inventory_batch, type: "nested", include_in_parent: true
    indexes :gin_sources, type: "nested", include_in_parent: true
    indexes :damages, type: "nested", include_in_parent: true
  end

  def self.search(params)
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.3/query-dsl-query-string-query.html
    tire.search(page: (params[:page] || 1), per_page: 10) do
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          # must { term :store_id, params[:store_id] } if params[:store_id].present?
          # puts params[:store_id]
        end
      end
      sort { by :created_at, {order: "desc", ignore_unmapped: true} }
      # filter :range, published_at: { lte: Time.zone.now}
      # raise to_curl
    end
  end

  def to_indexed_json
    to_json(
      only: [:id, :remaining_quantity, :damage_quantity, :recieved_quantity, :damage_quantity, :grn_item_id],
      methods: [:batch_stock_cost],
      include: {
        grn_item: {
          only: [:id, :current_unit_cost, :remaining_quantity, :reserved_quantity, :remarks, :inventory_not_updated, :product_id],
          include: {
            currency: {
              only: [:currency, :code],
            },
            grn: {
              only: [:created_at, :store_id],
              methods: [:grn_no_format],
            },
          },
        },
        inventory_batch: {
          only: [:id, :lot_no, :batch_no, :inventory_id, :product_id, :manufatured_date, :expiry_date],
          include: {
            inventory: {
              only: [:id, :store_id, :product_id, :stock_quantity, :available_quantity],
            },

          },
        },
      },
    )

  end

  belongs_to :grn_item
  belongs_to :inventory_batch
  accepts_nested_attributes_for :inventory_batch, allow_destroy: true

  has_many :gin_sources
  has_many :damages

  validates_presence_of :recieved_quantity

  before_save do |grn_batch|
    if grn_batch.remaining_quantity_changed?
      Rails.cache.delete([:stock_cost, grn_batch.inventory_batch.product_id, grn_batch.inventory_batch.inventory_id ])

    end

  end

  after_save :to_do_for_after_save

  def to_do_for_after_save
    [:inventory_batch].each do |parent|
      parent.to_s.classify.constantize.find(self.send(parent).id).update_index
      
    end
  end

  def batch_stock_cost
    (damage_quantity.to_f + remaining_quantity.to_f) * grn_item.current_unit_cost
  end

end

class GrnSerialItem < ActiveRecord::Base
  self.table_name = "inv_grn_serial_item"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  include Backburner::Performable

  mapping do
    indexes :grn_item, type: "nested", include_in_parent: true
    indexes :inventory_serial_item, type: "nested", include_in_parent: true
    indexes :gin_sources, type: "nested", include_in_parent: true
    indexes :damages, type: "nested", include_in_parent: true
  end

  def self.search(params)
    # https://www.elastic.co/guide/en/elasticsearch/reference/2.3/query-dsl-query-string-query.html
    tire.search( page: ( params[:page] || 1 ), per_page: ( params[:per_page] || 10 ) ) do
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          # must { term :store_id, params[:store_id] } if params[:store_id].present?
          # puts params[:store_id]
        end
      end
      sort { by :created_at, {order: (params[:order] || "desc"), ignore_unmapped: true} }
      # filter :range, published_at: { lte: Time.zone.now}
      # raise to_curl
    end
  end

  def to_indexed_json
    to_json(
      only: [:id, :remaining],
      methods: [:store_id],
      include: {
        grn_item: {
          only: [:remaining_quantity, :recieved_quantity, :inventory_not_updated, :product_id],
          include: {
            inventory_product: {
              only: [:id, :currency, :code],
            },
            grn: {
              only: [:created_at, :store_id],
              methods: [:grn_no_format],
            },
          },
        },
        inventory_serial_item: {
          only: [:id, :serial_no, :parts_not_completed, :scavenge, :damage, :repaired, :reserved, :ct_no, :remarks, :used, :manufatured_date, :expiry_date],
          methods: [ :batch_no, :lot_no, :status_name, :product_condition_condition ]

        },
      },
    )

  end

  belongs_to :grn_item, foreign_key: :grn_item_id
  accepts_nested_attributes_for :grn_item, allow_destroy: true
  belongs_to :inventory_serial_item, foreign_key: :serial_item_id
  accepts_nested_attributes_for :inventory_serial_item, allow_destroy: true

  has_many :gin_sources#, foreign_key: :gin_item_id
  has_many :damages

  def self.active_serial_items
    where(remaining: true)
  end

  before_create :set_remaining

  def set_remaining
    self.remaining = true
  end

  def store_id
    grn_item.grn.store_id
  end

end

class GrnSerialPart < ActiveRecord::Base
  self.table_name = "inv_grn_serial_part"

  belongs_to :grn_item
  accepts_nested_attributes_for :grn_item, allow_destroy: true
  belongs_to :inventory_serial_item, foreign_key: :serial_item_id
  belongs_to :inventory_serial_part, foreign_key: :inv_serial_part_id

  has_many :gin_sources, foreign_key: :grn_serial_part_id

  def self.active_serial_parts
    where(remaining: true)
  end

end

class GrnItemCurrentUnitCostHistory < ActiveRecord::Base
  self.table_name = "inv_grn_item_current_unit_cost_history"

  belongs_to :grn_item
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  after_save do |history|
    history.grn_item.update current_unit_cost: history.current_unit_cost

  end
end