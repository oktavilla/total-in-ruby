require "total_in"

RSpec.describe TotalIn do
  describe "parse" do
    before :all do
      @document = TotalIn.parse File.read File.join(__dir__, "fixtures/total_in_full.txt")
    end

    let :document do
      @document
    end

    it "find the document meta data" do
      expect(document.id).to eq "TI222222"
      expect(document.created_at.strftime("%Y-%m-%d %H:%M:%S")).to eq "2011-10-25 04:13:30"
      expect(document.delivery_number).to eq 1
      expect(document.file_type).to eq "TL1"
      expect(document.name).to eq "TOTALIN"
      expect(document.number_of_lines).to eq 61
    end

    it "finds two accounts" do
      expect(document.accounts.size).to eq 2
    end

    describe "first account" do
      let :account do
        document.accounts.first
      end

      it "stores the posting date" do
        expect(account.date.to_s).to eq "2011-10-24"
      end

      it "knows the number of transactions" do
        expect(account.number_of_transactions).to eq 6
      end

      it "has the total amount" do
        expect(account.amount).to eq 1919000
      end

      it "has the statement reference" do
        expect(account.statement_reference).to eq "20111024001"
      end

      describe "payments" do
        it "finds all the payments" do
          expect(account.payments.size).to eq 5
        end

        describe "first payment" do
          let :payment do
            account.payments[0]
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444451
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "extracts the amount in cents" do
            expect(payment.amount).to eq(302550)
          end

          it "finds all reference numbers" do
            expect(payment.reference_numbers).to eq [
              "38952344444",
              "38952345678",
              "38952145778"
            ]
          end

          it "parses all the messages" do
            expected_message = [
              "FAKTURANR:38952344444",
              "INTERN REF:  9780858",
              "FAKTURANR:38952345678",
              "38952145778ABC"
            ].join("\n")

            expect(payment.message).to eq expected_message
          end

          describe "#sender_account" do
            let :sender_account do
              payment.sender_account
            end

            it "parses the sender account" do
              expect(sender_account.account_number).to eq "1234567"
              expect(sender_account.origin_code).to eq 1
              expect(sender_account.company_organization_number).to eq "9999999999"
              expect(sender_account.name).to eq "TESTBOLAGET AB"
              expect(sender_account.address).to eq "GATAN 12"
              expect(sender_account.postal_code).to eq "12345"
              expect(sender_account.city).to eq "TESTSTAD"
            end
          end
        end

        describe "second payment" do
          let :payment do
            account.payments[1]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq []
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444455
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 429735
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "parses the message" do
            expect(payment.message).to eq "TACK FÖR LÅNET"
          end

          it "has a sender" do
            sender = payment.sender
            expect(sender.name).to eq "FÖRETAGET AB FRISKVÅRDAVD."
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "99999999"
            expect(sender_account.origin_code).to be nil
            expect(sender_account.company_organization_number).to be nil
            expect(sender_account.name).to eq "FÖRETAGET AB"
            expect(sender_account.address).to eq "GATAN 7"
            expect(sender_account.postal_code).to eq "88888"
            expect(sender_account.city).to eq "TESTORTEN"
          end
        end

        describe "third payment" do
          let :payment do
            account.payments[2]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq []
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444467
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 210900
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to eq "34523455"
          end

          it "parses the message" do
            expect(payment.message).to eq "BETALNING FÖR VARA 123"
          end

          it "has a sender" do
            sender = payment.sender
            expect(sender.name).to eq "TESTFABRIKEN AB"
            expect(sender.address).to eq "GATAN 22"
            expect(sender.postal_code).to eq "11111"
            expect(sender.city).to eq "TESTVIKEN"
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "98765433"
            expect(sender_account.origin_code).to eq 2
            expect(sender_account.company_organization_number).to eq "9999999999"
            expect(sender_account.name).to eq "NORDEA BANK AB"
            expect(sender_account.address).to be nil
            expect(sender_account.postal_code).to eq "10571"
            expect(sender_account.city).to eq "STOCKHOLM"
          end
        end

        describe "fourth payment" do
          let :payment do
            account.payments[3]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq []
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444472
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 148365
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "parses the message" do
            expect(payment.message).to be nil
          end

          it "has no sender" do
            expect(payment.sender).to be nil
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "1222211"
            expect(sender_account.origin_code).to eq 1
            expect(sender_account.company_organization_number).to eq "9999999999"
            expect(sender_account.name).to be nil
            expect(sender_account.address).to be nil
            expect(sender_account.postal_code).to be nil
            expect(sender_account.city).to be nil
          end
        end

        describe "fifth payment" do
          let :payment do
            account.payments[4]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq ["38952345555"]
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444423
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 880000
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "parses the message" do
            expect(payment.message).to eq "FAKT 38952345555,FAKTURANR"
          end

          it "has no sender" do
            expect(payment.sender).to be nil
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "2232567"
            expect(sender_account.origin_code).to eq 1
            expect(sender_account.company_organization_number).to eq "9999999999"
            expect(sender_account.name).to be nil
            expect(sender_account.address).to be nil
            expect(sender_account.postal_code).to be nil
            expect(sender_account.city).to be nil
          end

          it "is an international payment" do
            expect(payment.international?).to be true
            expect(payment.international.cost).to eq 0
            expect(payment.international.cost_currency).to be nil
            expect(payment.international.amount).to eq 100000
            expect(payment.international.amount_currency).to eq "EUR"
            expect(payment.international.exchange_rate).to eq 88000
          end
        end
      end

      describe "deductions" do
        it "finds one deduction" do
          expect(account.deductions.size).to eq 1
        end

        let :deduction do
          account.deductions.first
        end

        it "parses the amount" do
          expect(deduction.amount).to eq 52550
        end

        it "has no receiving bankgiro number" do
          expect(deduction.receiving_bankgiro_number).to be nil
        end

        it "has no code" do
          expect(deduction.code).to be nil
        end

        it "has one reference number" do
          expect(deduction.reference_numbers).to eq ["987654123"]
        end

        it "finds all messages" do
          expected_message = [
            "FAKTURA NR: 987654123 ABC",
            "KUNDNR: 123",
            "ÅTERBETALNING"
          ].join "\n"

          expect(deduction.message).to eq expected_message
        end

        it "parses the sender account" do
          sender_account = deduction.sender_account

          expect(sender_account.account_number).to eq "1234567"
          expect(sender_account.origin_code).to eq 1
          expect(sender_account.company_organization_number).to eq "9999999999"
          expect(sender_account.name).to eq "TESTBOLAGET AB"
          expect(sender_account.address).to eq "GATAN 12"
          expect(sender_account.postal_code).to eq "12345"
          expect(sender_account.city).to eq "TESTSTAD"
        end
      end
    end

    describe "second account" do
      let :account do
        document.accounts.last
      end

      it "knows the number of transactions" do
        expect(account.number_of_transactions).to eq 3
      end

      it "stores the posting date" do
        expect(account.date.to_s).to eq "2011-10-24"
      end

      it "has the total amount" do
        expect(account.amount).to eq 954434
      end

      it "has the statement reference" do
        expect(account.statement_reference).to eq "20111024001"
      end

      describe "payments" do
        it "finds all the payments" do
          expect(account.payments.size).to eq 3
        end

        describe "first payment" do
          let :payment do
            account.payments[0]
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 11111222223333344
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "extracts the amount in cents" do
            expect(payment.amount).to eq(923434)
          end

          it "has no reference numbers" do
            expect(payment.reference_numbers).to eq []
          end

          it "parses all the messages" do
            expect(payment.message).to eq "BETALNING AVSEENDE KÖP 110902"
          end

          describe "#sender_account" do
            let :sender_account do
              payment.sender_account
            end

            it "parses the sender account" do
              expect(sender_account.account_number).to eq "1234567"
              expect(sender_account.origin_code).to eq 1
              expect(sender_account.company_organization_number).to eq "9999999999"
              expect(sender_account.name).to eq "TESTBOLAGET AB"
              expect(sender_account.address).to eq "GATAN 12"
              expect(sender_account.postal_code).to eq "12345"
              expect(sender_account.city).to eq "TESTSTAD"
            end
          end
        end

        describe "second payment" do
          let :payment do
            account.payments[1]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq [
              "38952678900",
            ]
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444477
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 10500
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "has no message" do
            expect(payment.message).to be nil
          end

          it "has a sender" do
            sender = payment.sender
            expect(sender.name).to eq "TESTFÖRETAG ENHET 2.A"
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "54321"
            expect(sender_account.origin_code).to eq 1
            expect(sender_account.company_organization_number).to eq "9999999999"
            expect(sender_account.name).to eq "TESTFÖRETAG"
            expect(sender_account.address).to eq "TESTV 55"
            expect(sender_account.postal_code).to eq "12345"
            expect(sender_account.city).to eq "TESTSTAD"
          end
        end

        describe "third payment" do
          let :payment do
            account.payments[2]
          end

          it "does not have any reference numbers" do
            expect(payment.reference_numbers).to eq [
              "38952678888",
              "38952345999"
            ]
          end

          it "parses the serial number" do
            expect(payment.serial_number).to eq 22222333334444422
          end

          it "parses the amount in cents" do
            expect(payment.amount).to eq 20500
          end

          it "do not have a receiving_bankgiro_number" do
            expect(payment.receiving_bankgiro_number).to be nil
          end

          it "parses the message" do
            expect(payment.message).to eq "FAKTNR=38952348888 OCH\nFAKTNR=38952345999"
          end

          it "has no sender" do
            expect(payment.sender).to be nil
          end

          it "parses the sender account" do
            sender_account = payment.sender_account

            expect(sender_account.account_number).to eq "98765555"
            expect(sender_account.origin_code).to eq 1
            expect(sender_account.company_organization_number).to eq "9999999999"
            expect(sender_account.name).to eq "TESTER AB"
            expect(sender_account.address).to eq "VÄGEN 1"
            expect(sender_account.postal_code).to eq "88888"
            expect(sender_account.city).to eq "TESTORTEN"
          end
        end
      end

      it "has no deductions" do
        expect(account.deductions.size).to eq 0
      end
    end
  end
end
