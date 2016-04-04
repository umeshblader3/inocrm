class TicketEstimation < ActiveRecord::Base
  self.table_name = "spt_ticket_estimation"

  belongs_to :ticket

  has_many :ticket_estimation_externals, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :ticket_estimation_externals, allow_destroy: true

  has_many :job_estimations, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :job_estimations, allow_destroy: true

  has_many :act_job_estimations, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :act_job_estimations, allow_destroy: true

  has_many :ticket_estimation_parts, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :ticket_estimation_parts, allow_destroy: true

  has_many :ticket_estimation_additionals, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :ticket_estimation_additionals, allow_destroy: true

  belongs_to :estimation_status, foreign_key: :status_id
  belongs_to :currency, foreign_key: :currency_id


  has_many :customer_quotation_estimations, foreign_key: :estimation_id
  has_many :customer_quotations, through: :customer_quotation_estimations

  # belongs_to :ticket_payment_received, foreign_key: :adv_payment_received_id
  # accepts_nested_attributes_for :ticket_payment_received, allow_destroy: true

  before_save do |ticket_estimation|
    ticket_estimation.note = "#{self.note} <span class='pop_note_e_time'> on #{Time.now.strftime('%d/ %m/%Y at %H:%M:%S')}</span> by <span class='pop_note_created_by'> #{User.cached_find_by_id(ticket_estimation.current_user_id).email}</span><br/>#{ticket_estimation.note_was}" if ticket_estimation.persisted? and self.note_changed? and self.note.present?
  end

  # has_many :invoices, foreign_key: "customer_id"
  has_many :dyna_columns, as: :resourceable, autosave: true

  [:current_user_id].each do |dyna_method|
    define_method(dyna_method) do
      dyna_columns.find_by_data_key(dyna_method).try(:data_value)
    end

    define_method("#{dyna_method}=") do |value|
      data = dyna_columns.find_or_initialize_by(data_key: dyna_method)
      data.data_value = (value.class==Fixnum ? value : value.strip)
      data.save
    end
  end
end

class TicketEstimationExternal < ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_external"

  belongs_to :ticket

  belongs_to :ticket_estimation#, foreign_key: :ticket_estimation_id
  accepts_nested_attributes_for :ticket_estimation, allow_destroy: true

  belongs_to :organization, foreign_key: :repair_by_id
  accepts_nested_attributes_for :organization, allow_destroy: true

  has_many :ticket_estimation_external_taxes, foreign_key: :estimation_external_id

end

class TicketEstimationExternalTax <ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_external_tax"

  belongs_to :ticket_estimation_external
  belongs_to :tax
end

class EstimationStatus < ActiveRecord::Base
  self.table_name = "mst_spt_estimation_status"

  has_many :ticket_estimations, foreign_key: :status_id

end

class TicketEstimationPart < ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_part"

  belongs_to :ticket_estimation, foreign_key: :ticket_estimation_id
  belongs_to :ticket, foreign_key: :ticket_id

  # has_many :ticket_spare_part_stores, foreign_key: :ticket_estimation_part_id

  belongs_to :supplier, class_name: "Organization", foreign_key: :supplier_id

  belongs_to :ticket_spare_part, foreign_key: :ticket_spare_part_id
  accepts_nested_attributes_for :ticket_spare_part, allow_destroy: true

  has_many :ticket_estimation_part_taxes, foreign_key: :estimation_part_id

end

class TicketEstimationPartTax <ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_part_tax"

  belongs_to :ticket_estimation_part
  belongs_to :tax

end

class TicketEstimationAdditional < ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_additional"

  belongs_to :ticket_estimation, foreign_key: :ticket_estimation_id
  belongs_to :ticket, foreign_key: :ticket_id

  belongs_to :additional_charge, foreign_key: :additional_charge_id

  has_many :ticket_estimation_additional_taxes, foreign_key: :estimation_additional_id
  accepts_nested_attributes_for :ticket_estimation_additional_taxes, allow_destroy: true

end

class Tax < ActiveRecord::Base
  self.table_name = "mst_tax"

  has_many :ticket_estimation_additional_taxes
  has_many :ticket_estimation_external_taxes
  has_many :ticket_estimation_part_taxes
  has_many :tax_rates

end

class TaxRate < ActiveRecord::Base
  self.table_name = "mst_tax_rate"
  belongs_to :tax, foreign_key: :tax_id

  # has_many :ticket_estimation_additional_taxes
  # has_many :ticket_estimation_external_taxes
  # has_many :ticket_estimation_part_taxes

end

class TicketEstimationAdditionalTax < ActiveRecord::Base
  self.table_name = "spt_ticket_estimation_additional_tax"

  belongs_to :ticket_estimation_additional
  belongs_to :tax
end

class AdditionalCharge < ActiveRecord::Base
  self.table_name = "mst_spt_additional_charge"

  has_many :ticket_estimation_additionals, foreign_key: :additional_charge_id

end

class TicketPaymentReceived < ActiveRecord::Base
  self.table_name = "spt_ticket_payment_received"

  has_many :customer_feedbacks, foreign_key: :payment_received_id
  accepts_nested_attributes_for :customer_feedbacks, allow_destroy: true

  has_many :act_payment_receiveds, foreign_key: :ticket_payment_received_id
  accepts_nested_attributes_for :act_payment_receiveds, allow_destroy: true

  has_many :terminate_invoices, foreign_key: :payment_received_id
  accepts_nested_attributes_for :terminate_invoices, allow_destroy: true

  has_many :ticket_invoice_advance_payments, foreign_key: :payment_received_id
  accepts_nested_attributes_for :ticket_invoice_advance_payments, allow_destroy: true
  has_many :ticket_payment_receiveds, through: :ticket_invoice_advance_payments

  belongs_to :ticket
  belongs_to :ticket_payment_received_type, foreign_key: :type_id
  belongs_to :ticket_invoice, foreign_key: :invoice_id
  belongs_to :customer_quotation
  belongs_to :currency
  belongs_to :received_by_user, class_name: "User", foreign_key: :received_by

  validates_presence_of [:ticket_id, :received_at, :received_by, :amount, :type_id, :currency_id]

end