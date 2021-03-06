module InventoriesHelper
  def boolean_in_word boolean_value, true_word, false_word
    if boolean_value
      true_word.html_safe
    else
      false_word.html_safe
    end
  end

  def inventory_search_types( from_where, inventory_product = nil, *args )
    options = args.extract_options!

    if inventory_product.present?


      if options[:store_id].present?
        inventories = inventory_product.inventories.to_a.select{|i| options[:store_id].to_i == i.store_id.to_i }
        # store = inventory_product.inventories.find_by_store_id(options[:store_id])
        available_quantities = number_with_precision inventories.sum{|i| i.available_quantity.to_f }, precision: 2

        stock_quantity = inventories.sum{ |i| i.stock_quantity.to_f }

        store_info = {
          store: inventory_product.stores.select{|s| s.name if s.id.to_f == options[:store_id].to_f }.join(", ")
        }

        # i_pro = InventoryProduct.find inventory_product.id

        # stock_cost = inventories.sum{ |i| i_pro.stock_cost(i.id)}
        stock_cost = number_with_precision inventories.sum{ |i| i.product_stock_cost }, precision: 2
        # stock_cost = inventories.map{|i| [i.id, i.product_id, i.store_id, i.product_stock_cost]}#.sum{ |i| i.product_stock_cost}

      end


      more_info = {
        stock_quantity: stock_quantity
      }

      tooltip = {
        brand: inventory_product.category1_name,
        product: inventory_product.category2_name,
        category: inventory_product.category3_name,
        serial_code: inventory_product.generated_serial_no,
        model_no: inventory_product.model_no,
        product_no: inventory_product.product_no,
        part_no: inventory_product.spare_part_no,
        manufacture: inventory_product.manufacture,

      }

    end

    inventory_product_attr = {
      item_code: inventory_product.try(:generated_item_code),
      description: inventory_product.try(:description),
      type: inventory_product.try(:product_type),
      unit: inventory_product.try(:inventory_unit).try(:unit),
      tooltip: tooltip
    }

    if block_given?
      if options[:tooltip].present?
        yield(tooltip)
      else
        yield(more_info)
      end
    else
      case from_where
      when "search_inventory_product"
        inventory_product_attr.merge({
          available_quantity: available_quantities
        })
      when "inventories"
        inventory_product_attr.merge({
          available_quantity: {value: available_quantities, html: {class_attr: "text-right"}},
          currency: {value: inventory_product.try(:inventory_product_info).try(:currency_type), html: {class_attr: "text-right"}},
          stock_cost: {value: stock_cost, html: {class_attr: "text-right"}},
        })

      when "prn"
        inventory_product_attr.merge({
          available_quantity: available_quantities
        })

      when "part_of_main_unit"
        inventory_product_attr
      end
    end

  end
end