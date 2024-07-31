module Loan
  class PayInstallment < ApplicationService
    attr_reader :loan, :installment, :user

    def initialize(loan, installment)
      @loan = loan
      @installment = installment
      @user = @loan.user
    end

    def call
      if @loan.payment_method == 'fw_wallet'
        user_balance = fetch_user_balance(user)
        if user_balance.to_f >= loan.amount_per_installment
          begin_repayment
          send_money_to_loan_wallet
        else

          document = installment.documents.create(due_by: installment.installment_due_date,
                                                  amount_to_pay: loan.amount_per_installment
          )
          Loan::CreateUnpaidInstallmentDocument.new(document, loan, installment, user).call

          if loan.amount_deduction_value > loan.installments.count && installment.installment_due_date.past?
            create_next_installment
            # Here we also have to notify user about missed installment due to low balance
          else
            return false
          end
        end
        # elsif @loan.payment_method == 'stripe_wallet'
        # some code here
      end
    end

    private

    def create_next_installment
      if loan.amount_deduction_type == 'week'
        loan.installments.create(installment_amount: loan.amount_per_installment,
                                  installment_due_date: installment.installment_due_date + 1.week,
                                  paid: false)
      else
        loan.installments.create(installment_amount: loan.amount_per_installment,
                                  installment_due_date: installment.installment_due_date + 1.month,
                                  paid: false)
      end
    end

    def calculate_remaining_amount
      loan.remaining_amount - loan.amount_per_installment
    end

    def update_loan_and_installment
      remaining = calculate_remaining_amount
      loan.update(remaining_amount: remaining)
      installment.update(paid: true)
    end

    def create_transaction_record
      TransactionRecord.create(sendable: user, receivable: SuperAdmin.first, amount: loan.amount_per_installment)
    end

    def processing_after_repayment
      create_transaction_record
      update_loan_and_installment
      if loan.amount_deduction_value > loan.installments.count
        create_next_installment
      else
        loan.completed!
        puts 'Installments completed'
        # We can generate a notification here to notify user about completion of loan installments
      end
    end

    def begin_repayment
      begin
        Stellar::BeneficiaryPayment.new(sender: user, amount: loan.amount_per_installment).call
        flag = true
      rescue
        flag = false
      end
      if flag
        create_pdf_document
        processing_after_repayment
      end
    end

    def send_money_to_loan_wallet
      Loan::GrantLoan.new(ENV['STELLAR_PUBLIC_KEY'], ENV['STELLAR_SECRET_KEY'], ENV['STELLAR_LOAN_WALLET_PUBLIC_KEY'], loan.amount_per_installment).call
    end

    def create_pdf_document
      document = installment.documents.create(due_by: installment.installment_due_date, status: 'paid', amount_to_pay: loan.amount_per_installment)
      Loan::CreatePaidInstallmentDocument.new(document, loan, installment, user).call
    end
  end
end
