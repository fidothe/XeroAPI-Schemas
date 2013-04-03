require 'nokogiri'
require 'open-uri'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

URL_BASE = "http://developer.xero.com/api/"
SCHEMA_BASE = File.expand_path("../v2.00", __FILE__)

RSpec::Matchers.define :validate_against do |validator|
  match do |xml|
    @errors = validator.validate(Nokogiri::XML(xml))
    @errors.empty?
  end

  failure_message_for_should do |xml|
    "expected the document to validate, but it didn't.\nDocument: #{xml}\n\nValidation errors: \n  #{@errors.map { |e| e.message }.join("\n  ")}"
  end
end

describe "Validating Xero API XML samples against their XML Schemas" do
  pages_and_schemas = {
    "banktransactions" => "BankTransaction.xsd",
    "contacts" => "Contact.xsd",
    "credit-notes" => "CreditNote.xsd",
    "employees" => "Employee.xsd",
    "expense-claims" => "ExpenseClaim.xsd",
    "invoices" => "Invoice.xsd",
    "items" => "Items.xsd",
    "manual-journals" => "ManualJournal.xsd",
    "payments" => "Payment.xsd",
    "receipts" => "Receipt.xsd"
  }

  pages_and_schemas.each do |page, schema|
    describe "Validating '#{page}' samples" do
      url = URL_BASE + page + '/'
      source = Nokogiri::HTML(open(url))
      samples = source.css('pre.xml').collect { |node| node.text }
  
      let(:validator) { Nokogiri::XML::Schema(File.open(File.join(SCHEMA_BASE, schema))) }

      samples.each_with_index do |sample, i|
        it "should validate example #{i + 1}" do
          sample.should validate_against(validator)
        end
      end
    end
  end
end
