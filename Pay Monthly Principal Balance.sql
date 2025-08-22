WITH PM_ORDER_BALANCE_TEMP AS --we get balance as a final record in loanservice table
(
select      
distinct loan_id,
sum(interest_amount) as accrued_unpaid_interest,
sum(principal_amount) as unpaid_principal,
accrued_unpaid_interest + unpaid_principal as order_bal
                        from        (
                                    select      * 
                                    ,case when STATUS = 'CANCELED' THEN DATEDIFF(second, '1970-01-01'::DATE, CURRENT_TIMESTAMP()) else event_info_event_time end as event_info_event_time_2,

                                row_number() over (partition by key_installment_id order by (convert_timezone('UTC', 'America/Los_Angeles',to_timestamp(event_info_event_time_2))) desc) rnk
 --the condition was updated with the case statement on status - there are some rare scenarios when CANCELLED and OWED events come at exactly same timestamp and it makes paid off loans appear as open                                    
                                    from        ap_raw_green.green.raw_c_e_loanservice_loan_installment
                                    where       date(convert_timezone('UTC', 'America/Los_Angeles',to_timestamp(event_info_event_time))) <= '2024-06-30' 
                                    and gdp_region ='US'

                                    ) a
                        where       rnk = 1
                        and         status in ('OWED', 'OVERDUE')
                        group by    loan_id
),

PM_ORDERS AS 
(
select distinct loan_details_loan_id as loan_id,
ORDER_TRANSACTION_ID as order_id
from AP_RAW_GREEN.green.RAW_C_E_ORDER
where LOAN_DETAILS_LOAN_ID is not null
and par_region = 'US'
),

PM_ORDER_BALANCE_MAPPED AS
(
    SELECT
    a.loan_id,
    b.order_id,
    a.order_bal,
    a.accrued_unpaid_interest,
    a.unpaid_principal
    FROM pm_order_balance_temp  a
    LEFT JOIN PM_orders b 
    on a.loan_id = b.loan_id
)

select sum(order_bal) total_order_balance_amt, sum(accrued_unpaid_interest) interest_balance_amt, sum(unpaid_principal) principal_balance_amt, from PM_ORDER_BALANCE_MAPPED 
