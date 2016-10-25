class TaskAction < ActiveRecord::Base
  self.table_name = "mst_spt_action"

  has_many :q_and_as, foreign_key: :action_id

  has_many :ge_q_and_as, foreign_key: :action_id

  has_many :user_ticket_actions, foreign_key: :action_id
end

class UserTicketAction < ActiveRecord::Base
  self.table_name = "spt_ticket_action"

  has_many :q_and_answers, foreign_key: :ticket_action_id

  has_many :terminate_invoice, foreign_key: :ticket_action_id

  has_many :ge_q_and_answers, foreign_key: :ticket_action_id

  belongs_to :ticket
  belongs_to :task_action, foreign_key: :action_id

  has_one :user_assign_ticket_action, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :user_assign_ticket_action, allow_destroy: true

  has_many :assign_regional_support_centers, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :assign_regional_support_centers, allow_destroy: true

  has_one :hp_case, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :hp_case, allow_destroy: true

  has_one :action_warranty_repair_type, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :action_warranty_repair_type, allow_destroy: true

  has_one :ticket_re_assign_request, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :ticket_re_assign_request, allow_destroy: true

  has_one :ticket_action_taken, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :ticket_action_taken, allow_destroy: true

  has_one :ticket_finish_job, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :ticket_finish_job, allow_destroy: true

  has_one :ticket_terminate_job, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :ticket_terminate_job, allow_destroy: true

  has_many :act_terminate_job_payments, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_terminate_job_payments, allow_destroy: true

  has_one :act_hold, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_hold, allow_destroy: true

  has_one :act_fsr, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_fsr, allow_destroy: true

  has_one :serial_request, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :serial_request, allow_destroy: true

  has_one :deliver_unit, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :deliver_unit, allow_destroy: true

  has_one :job_estimation, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :job_estimation, allow_destroy: true

  has_one :act_job_estimation, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :job_estimation, allow_destroy: true

  has_one :request_spare_part, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :request_spare_part, allow_destroy: true

  has_one :request_on_loan_spare_part, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :request_on_loan_spare_part, allow_destroy: true

  has_one :action_warranty_extend, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :action_warranty_extend, allow_destroy: true

  has_one :customer_feedback, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :customer_feedback, allow_destroy: true

  has_one :act_payment_received, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_payment_received, allow_destroy: true

  has_one :act_quality_control, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_quality_control, allow_destroy: true

  has_one :inform_customer, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :inform_customer, allow_destroy: true

  has_one :act_ticket_close_approve, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_ticket_close_approve, allow_destroy: true

  has_one :act_quotation, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_quotation, allow_destroy: true

  has_one :act_print_invoice, foreign_key: :ticket_action_id
  accepts_nested_attributes_for :act_print_invoice, allow_destroy: true

  after_create :flush_cache

  def cached_task_action
    Rails.cache.fetch([self.id, :task_action]){ self.task_action }
  end

  def flush_cache
    self.update action_at: DateTime.now
    Rails.cache.delete([self.ticket.id, :user_ticket_actions])
  end

  def created_at
    super.getlocal
  end

  def updated_at
    super.getlocal
  end

  def action_at
    super.getlocal
  end

end

class ActTicketCloseApprove < ActiveRecord::Base
  self.table_name = "spt_act_ticket_close_approve"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :reason, foreign_key: :reject_reason_id
  belongs_to :user, foreign_key: :owner_engineer_id

end

class UserAssignTicketAction < ActiveRecord::Base
  self.table_name = "spt_act_assign_ticket"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :sbu, foreign_key: :sbu_id
  belongs_to :assign_to_user, class_name: "User", foreign_key: :assign_to
end

class AssignRegionalSupportCenter < ActiveRecord::Base
  self.table_name = "spt_act_assign_regional_support_center"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :regional_support_center
end

class RegionalSupportCenter < ActiveRecord::Base
  self.table_name = "spt_regional_support_center"

  has_many :assign_regional_support_centers

  belongs_to :organization

  has_many :sbu_regional_engineers#, foreign_key: :regional_support_center_id
  accepts_nested_attributes_for :sbu_regional_engineers, allow_destroy: true
  has_many :engineers, through: :sbu_regional_engineers

  def is_used_anywhere?
    User
    assign_regional_support_centers.any? or sbu_regional_engineers.any? or engineers.any?
  end
end

class HpCase < ActiveRecord::Base
  self.table_name = "spt_act_hp_case_action"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
end

class TicketActionTaken < ActiveRecord::Base
  self.table_name = "spt_act_action_taken"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
end

class TicketFinishJob < ActiveRecord::Base
  self.table_name = "spt_act_finish_job"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
end

class TicketTerminateJob < ActiveRecord::Base
  self.table_name = "spt_act_terminate_job"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :reason, foreign_key: :reason_id
end

class ActTerminateJobPayment < ActiveRecord::Base
  self.table_name = "spt_act_terminate_job_payment"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :ticket, foreign_key: :ticket_id
  belongs_to :payment_item, foreign_key: :payment_item_id

  belongs_to :currency
  belongs_to :reason, foreign_key: :adjust_reason_id

  has_many :ticket_invoice_terminates, foreign_key: :terminate_job_payment_id
  has_many :act_terminate_job_payments, through: :ticket_invoice_terminates

end

class PaymentItem < ActiveRecord::Base
  self.table_name = "mst_spt_payment_item"

  has_many :act_terminate_job_payments, foreign_key: :payment_item_id
  accepts_nested_attributes_for :act_terminate_job_payments, allow_destroy: true

  validates :default_amount, presence: true, :format => { :with => /\A\d{1,10}(\.\d{0,2})?\z/ }, :numericality => {:greater_than => -1, :less_than => 9999999999.99}
  validates :name, presence: true, uniqueness: true, :format => { :with => /\A[a-zA-Z ]+\Z/ }
  # validates :default_amount, :length => { :minimum => 6, :maximum => 6 }

  def is_used_anywhere?
    act_terminate_job_payments.any?
  end
end

class ActHold < ActiveRecord::Base
  self.table_name = "spt_act_hold"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :reason, foreign_key: :reason_id

  validates :reason_id, presence: true

end

class ActFsr < ActiveRecord::Base
  self.table_name = "spt_act_fsr"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :ticket_fsr, foreign_key: :fsr_id
  accepts_nested_attributes_for :ticket_fsr, allow_destroy: true
end

class SerialRequest < ActiveRecord::Base
  self.table_name = "spt_act_edit_serial_request"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
end

class DeliverUnit < ActiveRecord::Base
  self.table_name = "spt_act_deliver_unit"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_deliver_unit, foreign_key: :ticket_deliver_unit_id

end

class JobEstimation < ActiveRecord::Base
  self.table_name = "spt_act_job_estimate"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_estimation, foreign_key: :ticket_estimation_id

  belongs_to :organization, foreign_key: :supplier_id

end

class ActJobEstimation < ActiveRecord::Base
  self.table_name = "spt_act_job_estimate"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_estimation, foreign_key: :ticket_estimation_id

  belongs_to :organization, foreign_key: :supplier_id

end

class RequestSparePart < ActiveRecord::Base
  self.table_name = "spt_act_request_spare_part"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_spare_part, foreign_key: :ticket_spare_part_id

  belongs_to :reject_return_part_reason, -> { where(reject_returned_part: true) }, class_name: "Reason", foreign_key: :reject_return_part_reason_id
  belongs_to :part_terminate_reason, class_name: "Reason", foreign_key: :part_terminate_reason_id

end

class RequestOnLoanSparePart < ActiveRecord::Base
  self.table_name = "spt_act_request_on_loan_spare_part"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_on_loan_spare_part, foreign_key: :ticket_on_loan_spare_part_id

end

class InformCustomer < ActiveRecord::Base
  self.table_name = "spt_act_inform_customer"

  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

  belongs_to :ticket_contact_type, foreign_key: :contact_type_id

end

class ActPaymentReceived < ActiveRecord::Base

  self.table_name = "spt_act_payment_received"
  belongs_to :ticket_payment_received, foreign_key: :ticket_payment_received_id
  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

end

class ActQualityControl < ActiveRecord::Base

  self.table_name = "spt_act_qc"
  belongs_to :user_ticket_action, foreign_key: :ticket_action_id

end

class ActQuotation < ActiveRecord::Base

  self.table_name = "spt_act_quotation"
  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :customer_quotation

end

class ActPrintInvoice < ActiveRecord::Base

  self.table_name = "spt_act_print_invoice"
  belongs_to :user_ticket_action, foreign_key: :ticket_action_id
  belongs_to :invoice

end