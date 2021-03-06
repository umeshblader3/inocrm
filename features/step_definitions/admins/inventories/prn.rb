When /^Go to admin PRN form screen in inventories.$/ do
  visit prn_admins_inventories_path
  expect(page).to have_current_path('/admins/inventories/prn')
  # expect(page.status_code).to eq 200
end

Given /^I able to see store information within (.*)$/ do |wrapper, table|
  within("##{wrapper}") do
    # expect(find(".list-group-item-heading")).to have_content name
    table.hashes.each do |hash|
      # FactoryGirl.create :organization, hash
      expect(find("#{hash['content_holder']}")).to have_content(hash['content'])
    end
  end
end

Given /^I able to see (.*) with dom element (.*)$/ do |element_name, dom_element|
  # wait_until { page.find("#"+dom_element).visible? }
  sleep 1
  expect(page).to have_selector("#"+dom_element)
end

# Given(/^I create store with:$/) do |table|
#   table.hashes.each do |hash|
#     FactoryGirl.create :organization, hash
#   end
# end