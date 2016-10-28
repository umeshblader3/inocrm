class Ticket < ActiveRecord::Base
  self.table_name = "spt_ticket"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :products, type: "nested", include_in_parent: true
  end

  def self.search(params)  
    tire.search(page: (params[:page] || 1), per_page: 10) do
      query do
        boolean do
          must { string params[:query] } if params[:query].present?
          must { range :created_at, lte: params[:range_to].to_date } if params[:range_to].present?
          must { range :created_at, gte: params[:range_from].to_date } if params[:range_from].present?
          # must { term :author_id, params[:author_id] } if params[:author_id].present?
        end
      end
      sort { by :created_at, {order: "asc", ignore_unmapped: true} }
      highlight customer_name: {number_of_fragments: 0}, ticket_status_name: {number_of_fragments: 0}, :options => { :tag => '<strong class="highlight">' } if params[:query].present?
      # filter :range, published_at: { lte: Time.zone.now}
      # raise to_curl
    end
  end

  def to_indexed_json
    Warranty
    to_json(
      only: [:created_at, :cus_chargeable, :id],
      methods: [:customer_name, :ticket_status_name, :warranty_type_name, :support_ticket_no],
      include: {
        products: {
          only: [:id, :serial_no, :model_no, :product_no, :created_at],
          methods: [:category_name, :warranty_type_name, :brand_name],
        }
      }
    )

  end

  belongs_to :ticket_type, foreign_key: :ticket_type_id
  belongs_to :warranty_type, foreign_key: :warranty_type_id
  belongs_to :job_type, foreign_key: :job_type_id
  belongs_to :inform_method, foreign_key: :informed_method_id
  belongs_to :problem_category, foreign_key: :problem_category_id
  belongs_to :ticket_contact_type, foreign_key: :contact_type_id
  belongs_to :ticket_contract, foreign_key: :contract_id
  belongs_to :ticket_status, foreign_key: :status_id
  belongs_to :ticket_currency, foreign_key: :base_currency_id
  belongs_to :customer, foreign_key: :customer_id

  belongs_to :contact_person1, foreign_key: :contact_person1_id
  belongs_to :contact_person2, foreign_key: :contact_person2_id
  belongs_to :report_person, foreign_key: :reporter_id

  has_many :ticket_product_serials, foreign_key: :ticket_id
  has_many :products, through: :ticket_product_serials
  accepts_nested_attributes_for :products, allow_destroy: true
  has_many :customer_quotations, foreign_key: :ticket_id
  accepts_nested_attributes_for :customer_quotations, allow_destroy: true

  has_many :q_and_answers, foreign_key: :ticket_id
  has_many :q_and_as, through: :q_and_answers
  accepts_nested_attributes_for :q_and_answers, allow_destroy: true, :reject_if => :all_blank

  has_many :ge_q_and_answers
  accepts_nested_attributes_for :ge_q_and_answers, allow_destroy: true

  has_many :ticket_accessories, foreign_key: :ticket_id
  has_many :accessories, through: :ticket_accessories
  accepts_nested_attributes_for :ticket_accessories, allow_destroy: true

  belongs_to :customer, class_name: "Customer", foreign_key: "customer_id"
  belongs_to :sla_time, foreign_key: :sla_id

  has_many :dyna_columns, as: :resourceable, autosave: true

  has_many :joint_tickets
  accepts_nested_attributes_for :joint_tickets, allow_destroy: true

  has_many :user_ticket_actions#, foreign_key: :action_id
  accepts_nested_attributes_for :user_ticket_actions, allow_destroy: true

  has_many :ticket_extra_remarks, foreign_key: :ticket_id
  has_many :extra_remarks, through: :ticket_extra_remarks
  accepts_nested_attributes_for :ticket_extra_remarks, allow_destroy: true

  has_many :ticket_workflow_processes

  belongs_to :ticket_status_resolve, foreign_key: :status_resolve_id
  belongs_to :repair_type, foreign_key: :repair_type_id
  belongs_to :manufacture_currency, class_name: "Currency", foreign_key: :manufacture_currency_id

  has_many :ticket_spare_parts
  accepts_nested_attributes_for :ticket_spare_parts, allow_destroy: true

  has_many :ticket_on_loan_spare_parts
  accepts_nested_attributes_for :ticket_on_loan_spare_parts, allow_destroy: true

  belongs_to :ticket_start_action, foreign_key: :job_started_action_id
  belongs_to :ticket_repair_type, foreign_key: :repair_type_id
  belongs_to :reason, foreign_key: :hold_reason_id

  has_many :ticket_fsrs
  accepts_nested_attributes_for :ticket_fsrs, allow_destroy: true

  has_many :ticket_deliver_units
  accepts_nested_attributes_for :ticket_deliver_units, allow_destroy: true

  has_many :act_terminate_job_payments
  accepts_nested_attributes_for :act_terminate_job_payments, allow_destroy: true

  has_many :ticket_estimations, foreign_key: :ticket_id
  accepts_nested_attributes_for :ticket_estimations, allow_destroy: true

  has_many :ticket_estimation_parts, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :ticket_estimation_parts, allow_destroy: true

  has_many :ticket_estimation_externals, foreign_key: :ticket_id
  accepts_nested_attributes_for :ticket_estimation_externals, allow_destroy: true

  has_many :ticket_estimation_additionals, foreign_key: :ticket_id
  accepts_nested_attributes_for :ticket_estimation_additionals, allow_destroy: true

  has_many :customer_quotations, foreign_key: :ticket_id
  accepts_nested_attributes_for :customer_quotations, allow_destroy: true

  has_many :ticket_invoices, foreign_key: :ticket_id
  accepts_nested_attributes_for :ticket_invoices, allow_destroy: true
  belongs_to :final_invoice, class_name: "TicketInvoice", foreign_key: :final_invoice_id

  has_many :ticket_payment_receiveds
  accepts_nested_attributes_for :ticket_payment_receiveds, allow_destroy: true
  has_many :invoices, through: :ticket_payment_receiveds

  has_many :ticket_engineers, class_name: "TicketEngineer", foreign_key: :ticket_id
  has_many :users, through: :ticket_engineers

  belongs_to :owner_engineer, class_name: "TicketEngineer"

  validates_presence_of [:ticket_no, :priority, :status_id, :problem_description, :informed_method_id, :job_type_id, :ticket_type_id, :warranty_type_id, :base_currency_id, :problem_category_id]

  validates_numericality_of [:ticket_no, :priority]
  validates_inclusion_of :cus_chargeable, in: [true, false]

  before_save do |ticket|
    if ticket.persisted? and ticket.remarks_changed? and ticket.remarks.present?
      ticket_remarks = "#{ticket.remarks} <span class='pop_note_e_time'> on #{Time.now.strftime('%d/ %m/%Y at %H:%M:%S')}</span> by <span class='pop_note_created_by'> #{User.cached_find_by_id(ticket.current_user_id).email}</span><br/>#{ticket.remarks_was}"
    elsif ticket.new_record?
      ticket_remarks = ticket.remarks  
    else
      ticket_remarks = ticket.remarks_was
    end
    ticket.remarks = ticket_remarks
  end

  [:initiated_by, :initiated_by_id, :current_user_id].each do |dyna_method|
    define_method(dyna_method) do
      dyna_columns.find_by_data_key(dyna_method).try(:data_value)
    end

    define_method("#{dyna_method}=") do |value|
      data = dyna_columns.find_or_initialize_by(data_key: dyna_method)
      data.data_value = (value.class==Fixnum ? value : value.strip)
      data.save# if data.persisted?
    end
  end

  before_create :update_ticket_no
  after_update :flash_cache


  def update_ticket_no
    self.ticket_no = (self.class.any? ? (self.class.order("created_at ASC").map{|t| t.ticket_no.to_i}.max + 1) : 1)
  end


  def cached_user_ticket_actions
    Rails.cache.fetch([self.id, :user_ticket_actions]){ self.user_ticket_actions.to_a }
  end

  def cached_ticket_spare_parts
    Rails.cache.fetch([self.id, :ticket_spare_parts]){ self.ticket_spare_parts.to_a }
  end

  def flash_cache
    Rails.cache.delete([:join, self.id])
  end

  def set_ticket_close
    manufacture_parts_po_completed = !ticket_spare_parts.any? { |t| t.ticket_spare_part_manufacture.try(:po_required) and not t.ticket_spare_part_manufacture.try(:po_completed) }

    if job_closed and (cus_payment_completed or !cus_payment_required) and (ticket_close_approved or !ticket_close_approval_required) and manufacture_parts_po_completed
      update status_id: TicketStatus.find_by_code("CLS").id, ticket_closed_at: DateTime.now # Ticket Closed
    end
  end

  def ticket_closed?
    ["CLS", "TBC"].include? ticket_status.try(:code)
  end

  def created_at
    super.try(:getlocal)
  end

  def updated_at
    super.try(:getlocal)
  end

  def job_started_at
    super.try(:getlocal)
  end

  def job_finished_at
    super.try(:getlocal)
  end

  def customer_name
    customer.full_name
  end

  def ticket_status_name
    ticket_status.name
  end

  def warranty_type_name
    warranty_type.name
  end

  def support_ticket_no
    ticket_no.to_s.rjust(6, INOCRM_CONFIG["ticket_no_format"])
  end

end

class TicketType < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_type"

  has_many :tickets, foreign_key: :ticket_type_id

  validates_presence_of [:code, :name]
end

class JobType < ActiveRecord::Base
  self.table_name = "mst_spt_job_type"

  has_many :tickets, foreign_key: :job_type_id

  validates_presence_of [:code, :name]
end

class InformMethod < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_informed_method"

  has_many :tickets, foreign_key: :informed_method_id

  validates_presence_of [:code, :name]
end

class ProblemCategory < ActiveRecord::Base
  self.table_name = "spt_problem_category"

  has_many :tickets, foreign_key: :problem_category_id

  has_many :q_and_as, foreign_key: :problem_category_id
  accepts_nested_attributes_for :q_and_as, allow_destroy: true

  validates_presence_of [:name]
  validates_uniqueness_of :name

  def is_used_anywhere?
    tickets.any? or q_and_as.any?
  end

end

class TicketContactType < ActiveRecord::Base
  self.table_name = "mst_spt_contact_type"

  has_many :tickets, foreign_key: :contact_type_id

  has_many :inform_customers, foreign_key: :contact_type_id
  accepts_nested_attributes_for :inform_customers, allow_destroy: true

  validates_presence_of [:code, :name]
end

class TicketContract < ActiveRecord::Base
  self.table_name = "spt_contract"

  has_many :tickets, foreign_key: :contract_id
  has_many :contract_products, foreign_key: :contract_id
  belongs_to :sla_time, foreign_key: :sla_id
  belongs_to :organization, foreign_key: :customer_id

  validates_presence_of [:customer_id, :sla_id, :created_by]

  validates_numericality_of [:sla_id]

  def is_used_anywhere?
    contract_products.any?
    tickets.any?
  end

end

class ContractProduct < ActiveRecord::Base
  self.table_name = "spt_contract_product"
  belongs_to :ticket_contract, foreign_key: :contract_id
end

class TicketStatus < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_status"

  has_many :tickets, foreign_key: :status_id

  validates_presence_of [:code, :name]
end

class TicketCurrency < ActiveRecord::Base
  self.table_name = "mst_currency"

  has_many :tickets, foreign_key: :base_currency_id

  validates_presence_of [:currency, :code, :symbol]
  validates_inclusion_of :base_currency, in: [true, false]
end

class TicketPaymentReceivedType < ActiveRecord::Base
  self.table_name = "mst_spt_payment_received_type"

  has_many :ticket_payment_receiveds, foreign_key: :type_id

  TYPES = {"cash" => 1, "cheque" => 2, "credit card" => 3, "other" => 4}
end

class TicketProductSerial < ActiveRecord::Base
  self.table_name = "spt_ticket_product_serial"

  belongs_to :ticket, foreign_key: :ticket_id
  belongs_to :product, foreign_key: :product_serial_id

  belongs_to :ref_product_serial, class_name: "Product"
end

class TicketAccessory < ActiveRecord::Base
  self.table_name = "spt_ticket_accessory"

  belongs_to :accessory
  belongs_to :ticket
end

class JointTicket < ActiveRecord::Base
  self.table_name = "spt_joint_ticket"

  belongs_to :ticket
end

class ExtraRemark < ActiveRecord::Base
  self.table_name = "mst_spt_extra_remark"

  has_many :ticket_extra_remarks, foreign_key: :extra_remark_id
  has_many :tickets, through: :ticket_extra_remarks
end

class TicketExtraRemark < ActiveRecord::Base
  self.table_name = "spt_ticket_extra_remark"

  belongs_to :ticket, foreign_key: :ticket_id
  belongs_to :extra_remark, foreign_key: :extra_remark_id
end

class TicketWorkflowProcess < ActiveRecord::Base
  self.table_name = "spt_ticket_workflow_process"

  belongs_to :ticket
end

class TicketStatusResolve < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_status_resolve"

  has_many :tickets, foreign_key: :status_resolve_id

end

class PrintTemplate < ActiveRecord::Base
  self.table_name = "mst_spt_templates"

  # has_many :tickets, foreign_key: :status_resolve_id

end

class TicketStartAction < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_start_action"

  validates :action, presence: true, uniqueness: true
  has_many :tickets, foreign_key: :job_started_action_id
  accepts_nested_attributes_for :tickets, allow_destroy: true

  def is_used_anywhere?
    tickets.any?
  end

end

class TicketRepairType < ActiveRecord::Base
  self.table_name = "mst_spt_ticket_repair_type"

  has_many :tickets, foreign_key: :job_started_action_id
  accepts_nested_attributes_for :tickets, allow_destroy: true

  has_many :action_warranty_repair_types, foreign_key: :ticket_repair_type_id

end

class Reason < ActiveRecord::Base
  self.table_name = "mst_spt_reason"

  validates :reason, presence: true, uniqueness: true

  has_many :tickets, foreign_key: :hold_reason_id
  accepts_nested_attributes_for :tickets, allow_destroy: true

  has_many :ticket_re_assign_requests
  accepts_nested_attributes_for :ticket_re_assign_requests, allow_destroy: true

  has_many :ticket_terminate_jobs
  accepts_nested_attributes_for :ticket_terminate_jobs, allow_destroy: true

  has_many :act_holds
  accepts_nested_attributes_for :act_holds, allow_destroy: true

  has_many :unused_reasons, class_name: "TicketSparePart", foreign_key: :unused_reason_id
  accepts_nested_attributes_for :unused_reasons, allow_destroy: true

  has_many :part_terminated_reasons, class_name: "TicketSparePart", foreign_key: :part_terminated_reason_id
  accepts_nested_attributes_for :part_terminated_reasons, allow_destroy: true

  has_many :return_part_damage_reasons, class_name: "TicketSparePartStore", foreign_key: :return_part_damage_reason_id
  accepts_nested_attributes_for :return_part_damage_reasons, allow_destroy: true

  # has_many :onloan_return_part_damage_reasons, class_name: "TicketOnLoanSparePart"#, foreign_key: :part_terminated_reason_id
  # accepts_nested_attributes_for :return_part_damage_reasons, allow_destroy: true

  has_many :on_loan_unused_reasons, class_name: "TicketOnLoanSparePart", foreign_key: :unused_reason_id
  accepts_nested_attributes_for :on_loan_unused_reasons, allow_destroy: true

  has_many :on_loan_part_terminated_reasons, class_name: "TicketOnLoanSparePart", foreign_key: :part_terminated_reason_id
  accepts_nested_attributes_for :on_loan_part_terminated_reasons, allow_destroy: true

  has_many :reject_return_part_reasons, class_name: "RequestSparePart", foreign_key: :reject_return_part_reason_id
  accepts_nested_attributes_for :reject_return_part_reasons, allow_destroy: true

  has_many :action_warranty_extends, foreign_key: :reject_reason_id
  accepts_nested_attributes_for :action_warranty_extends, allow_destroy: true

  has_many :act_terminate_job_payments, foreign_key: :adjust_reason_id

  has_many :act_ticket_close_approves, class_name: "ActTicketCloseApprove", foreign_key: :reject_reason_id

  def is_used_anywhere?
    TaskAction
    TicketSparePart
    Warranty

    tickets.any? or ticket_re_assign_requests.any? or ticket_terminate_jobs.any? or act_holds.any? or unused_reasons.any? or part_terminated_reasons.any? or on_loan_unused_reasons.any? or reject_return_part_reasons.any? or act_terminate_job_payments.any? or action_warranty_extends.any? or act_ticket_close_approves.any? or return_part_damage_reasons.any?
     # or onloan_return_part_damage_reasons.any?

    # tickets.any? or ticket_re_assign_requests.any? or ticket_terminate_jobs.any? or act_holds.any? or unused_reasons.any? or part_terminated_reasons.any? or return_part_damage_reasons.any? or on_loan_unused_reasons.any? or on_loan_part_terminated_reasons.any? or reject_return_part_reasons.any? or action_warranty_extends.any? or act_terminate_job_payments.any? or act_ticket_close_approves.any?
  end
end

class TicketReAssignRequest < ActiveRecord::Base
  self.table_name = "spt_act_re_assign_request"

  belongs_to :reason
  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

end