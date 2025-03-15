#!/usr/bin/env ruby
require 'csv'
require 'set'

# Initialize data structure to store the results
results = {}
all_order_types = Set.new

# Read the CSV file content
csv_content = File.read('cookies.csv')

# Check for and remove BOM (Byte Order Mark) if present
if csv_content.start_with?("\xEF\xBB\xBF")
  csv_content = csv_content.force_encoding('UTF-8')
end

# Process the CSV data
CSV.parse(csv_content, headers: true) do |row|
  # Skip rows without valid data
  next unless row['Girl First Name'] && row['Girl Last Name'] && !row['Girl First Name'].empty? && !row['Girl Last Name'].empty?
  
  # Get girl scout name
  first_name = row['Girl First Name']
  last_name = row['Girl Last Name']
  scout_name = "#{first_name} #{last_name}"
  
  # Get order type and donation amount
  order_type = row['Order Type']
  
  # Skip rows without valid order type
  next unless order_type && !order_type.empty?
  
  # Get donation packages, interpreting as numeric value
  donation = row['Donation'].to_s.strip.to_i
  
  # Skip if no donations
  next if donation == 0
  
  # Keep track of all order types
  all_order_types.add(order_type)
  
  # Initialize nested hash structure if needed
  results[scout_name] ||= {}
  results[scout_name][order_type] ||= 0
  
  # Add donation to the total
  results[scout_name][order_type] += donation
end

# Generate CSV output
CSV.open('donation_summary.csv', 'w') do |csv|
  # Filter out "Shipped with Donation" from order types
  filtered_order_types = all_order_types.to_a.reject { |type| type == "Shipped with Donation" }.sort
  header = ['Girl Scout'] + filtered_order_types + ['Total']
  csv << header
  
  # Add a row for each scout
  results.keys.sort.each do |scout_name|
    next if scout_name.strip.empty?
    
    # Check if there are any donations (from any order type)
    has_any_donations = results[scout_name].values.sum > 0
    next unless has_any_donations
    
    # Create row with scout name and values for each order type
    row = [scout_name]
    
    # Add value for each order type, excluding "Shipped with Donation"
    total_for_scout = 0
    filtered_order_types.each do |order_type|
      donation_count = results[scout_name][order_type] || 0
      row << donation_count
      total_for_scout += donation_count
    end
    
    # Add total
    row << total_for_scout
    
    # Write the row to CSV
    csv << row
  end
end

puts "Output written to donation_summary.csv"