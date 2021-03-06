class UpdateDbCustomerContact < ActiveRecord::Migration
  def change
    create_table :mst_contact_type_validate, id: false do |t|
      t.column :id, "INT UNSIGNED NOT NULL AUTO_INCREMENT, PRIMARY KEY (id)"
      t.string :code, null: false
      t.string :name, null: false
    end

    add_column :mst_spt_customer_contact_type, :validate_id, "INT UNSIGNED NOT NULL"
    add_index :mst_spt_customer_contact_type, :validate_id, name: "fk_mst_spt_customer_contact_type_mst_spt_contact_type_valid_idx"

    add_column :mst_contact_types, :validate_id, "INT(10) UNSIGNED NOT NULL"
    add_index :mst_contact_types, :validate_id, name: "fk_mst_contact_types_mst_contact_type_validate1_idx"

    add_foreign_key :mst_spt_customer_contact_type, :mst_contact_type_validate, name: "fk_mst_spt_customer_contact_type_mst_contact_type_validate1", column: :validate_id
    add_foreign_key :mst_contact_types, :mst_contact_type_validate, name: "fk_mst_contact_types_mst_contact_type_validate1", column: :validate_id

    add_column :mst_spt_templates, :ticket_sticker_request_type, :string, default: "PRINT_SPPT_TICKET_STICKER"
    add_column :mst_spt_templates, :ticket_sticker, :text

  end
end
