WITH 
orders_origination_state_temp AS -- this is not necessary for the Interest but useful anyway
(
SELECT 
CONSUMER_ACCOUNT_CONTACT_ADDRESS_STATE ORIGINATION_STATE,
ORDER_TRANSACTION_ID ORDER_ID,
loan_details_loan_id  loan_id,
row_number() over (partition by ORDER_TRANSACTION_ID order by EVENT_INFO_EVENT_TIME desc) as rnk
from	ap_raw_green.green.RAW_C_E_ORDER
WHERE 1=1

AND PAR_REGION ='US'
),

ORIGINATION_STATE AS
(
SELECT ORDER_ID, ORIGINATION_STATE, loan_id
FROM orders_origination_state_temp
WHERE rnk = 1
),

ORDER_BASE AS
(
SELECT 
a.ID order_id,
b.loan_id,
a.order_date,
'PAY MONTHLY' AS PRODUCT_TYPE,
CASE    WHEN b.ORIGINATION_STATE is null then 'UNKNOWN' else b.ORIGINATION_STATE END AS ORIGINATION_STATE        
FROM AP_RAW_GREEN.GREEN.F_ORDER a
LEFT JOIN ORIGINATION_STATE b
ON a.id = b.order_id
WHERE 1=1 
--AND a.order_date <= '2024-06-30' 
AND a.order_date between '2023-01-01' and '2024-06-30'
AND a.country_code = 'US'
AND a.payment_type = 'PCL'
AND a.order_transaction_status_id in (1) 
),

interest_base as

(select  
b.order_id,
a.key_loan_id, 
to_date(convert_timezone('UTC', 'America/Los_Angeles',a.event_info_event_time)) date_pst,
a.accrued_interest_amount, 
a.single_day_interest_amount, 
row_number() over (partition by key_loan_id order by (convert_timezone('UTC', 'America/Los_Angeles',to_timestamp(a.event_info_event_time))) asc) rnk,
b.PRODUCT_TYPE,
b.origination_state,
b.order_date
from AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_DAILY_ACCRUAL a
join order_base b
on a.key_loan_id = b.loan_id
where 1=1
--and date_pst between '2023-01-01' and '2024-06-30'
and a.gdp_region = 'US'
--and key_loan_id = '1370cefa-15cf-42aa-95ef-ac389e893e69'

  ),

first_day_interest as
  (
  select order_id, 
  PRODUCT_TYPE,
  origination_state,
  coalesce(ACCRUED_INTEREST_AMOUNT,0) - coalesce(SINGLE_DAY_INTEREST_AMOUNT,0) first_day_amt
  from interest_base
  where rnk = 1
  and order_date >= '2023-01-01'

  ),

accrued_interest as 
(
select order_id, 
sum(SINGLE_DAY_INTEREST_AMOUNT) accrued_amt
from interest_base
where SINGLE_DAY_INTEREST_AMOUNT >0
group by 1
),

final_pass as
(
select a.order_id,
a.product_type,
a.origination_state,
coalesce(a.first_day_amt,0)+coalesce(b.accrued_amt,0) accrued_interest_amt
from first_day_interest a
join accrued_interest b
on a.order_id = b.order_id
)

SELECT 
PRODUCT_TYPE,
ORIGINATION_STATE,
sum(accrued_interest_amt) ACCRUED_INTEREST_AMT
FROM FINAL_PASS
GROUP by 1,2
order by 2
