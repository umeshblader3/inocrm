window.Searches =

  setup: ->
    return

  reset_searchgrn:->
    $("#store_id").val("")
    $("#grn_no").val("")
    $("#range_from").val("")
    $("#range_to").val("")

  reset_searchinventory:->
    $("#search_inventory_brand").val("")
    $("#search_inventory_product").val("")
    $("#search_inventory_mst_inv_product_category3_id").val("")
    $("#search_inventory_inventory_product_generated_item_code").val("")
    $("#search_inventory_inventory_product_spare_part_no").val("")
    $("#search_inventory_inventory_product_model_no").val("")
    $("#search_inventory_inventory_product_product_no").val("")
    $("#search_inventory_inventory_product_serial_no").val("")
    $("#search_inventory_inventory_product_description").val("")

  reset_searchinventoryserialitem:->
    $("#search_inventory_remaining_grn_items_grn_store_id").val("")
    $("#search_inventory_brand").val("")
    $("#search_inventory_product").val("")
    $("#search_inventory_mst_inv_product_category3_id").val("")
    $("#search_inventory_inventory_product_generated_serial_no").val("")
    $("#search_inventory_inventory_product_generated_item_code").val("")
    $("#search_inventory_inventory_product_spare_part_no").val("")
    $("#search_inventory_inventory_product_model_no").val("")
    $("#search_inventory_inventory_product_description").val("")
    $("#search_inventory_inventory_product_product_no").val("")
    $("#search_inventory_generated_serial_no").val("")
    $("#search_inventory_ct_no").val("")

  reset_searchreceives:->
    $("#store_id").val("")
    $("#type").val("")
    $("#type_no").val("")
    $("#from_date").val("")
    $("#to_date").val("")

  reset_searchreturns:->
    $("#store_id").val("")
    $("#type").val("")
    $("#type_no").val("")
    $("#from_date").val("")
    $("#to_date").val("")

  reset_searchissues:->
    $("#store_id").val("")
    $("#type").val("")
    $("#type_no").val("")
    $("#from_date").val("")
    $("#to_date").val("")




    

    


  # edit_sitem_adcost: (para_addcost, sitem_id)->
  #   # alert para_addcost

  #   # $("#inv_sitem_addcost_id").val(this_val)
  #   $("#edit_id").removeClass("hide")
  #   # $("#actionfor_sitem_adcost").val(action)
  #   # $("#inventory_serial_items_additional_cost_serial_item_id").val(sitem_id)
  #   # $("#action_show").val(action)
  #   # alert sitem_id
  # add_sitem_adcost:->
  #   $("#edit_id").addClass("hide")