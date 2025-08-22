SELECT
a.loan_id,
b.key_order_transaction_id order_id,
a.installment_sequence,
a.par_process_date,
timestamp 'epoch' + a.event_info_event_time * interval '1 second' AS date_time,
date(convert_timezone('UTC','CST',(timestamp 'epoch' + a.event_info_event_time * interval '1 second'))) CST,
date(convert_timezone('UTC','CDT',(timestamp 'epoch' + a.event_info_event_time * interval '1 second'))) CDT,
a.event_info_event_time,
a.status,
a.key_installment_id,
c.key_payment_schedule_id instalment_id,
a.principal_amount,	
a.interest_amount
FROM green.raw_c_e_loanservice_loan_installment a
JOIN green.raw_c_f_aurora_paylater_consumer_order_loan b
ON a.loan_id = b.key_loan_id
JOIN green.raw_c_f_aurora_paylater_consumer_order_loan_installment c
ON a.key_installment_id = c.loan_installment_ref
WHERE b.key_order_transaction_id in (100418587639)
order by par_process_date, key_installment_id, a.event_info_event_time



select 
a.key_loan_id,
b.key_order_transaction_id order_id,
a.key_calculation_date,
a.outstanding_principal_amount,
a.total_interest_amount,
a.single_day_interest_amount,
a.accrued_interest_amount,
a.outstanding_principal_amount 
from green.raw_c_e_loanservice_daily_accrual a
JOIN green.raw_c_f_aurora_paylater_consumer_order_loan b
ON a.key_loan_id = b.key_loan_id
where b.key_order_transaction_id in (100457615472,100457481020,100457106813,100456488813,100455905452,100454802371,100454453730,100452624350,100452022543,100449872154,100449385911,100449444122,100448675914,100440575117,100439519318,100420128467,100436808911,100426932287,100428525787,100441048421,100424907886,100440211937,100440684365,100453433124,100446733626,100422723339,100443820430,100429756573,100435879514,100429328355)
order by 2,3



SELECT
a.loan_id,
b.key_order_transaction_id order_id
FROM green.raw_c_e_loanservice_loan_installment a
JOIN green.raw_c_f_aurora_paylater_consumer_order_loan b
ON a.loan_id = b.key_loan_id
where b.key_order_transaction_id = '100392134629'









select * from raw_c_e_loanservice_loan_payment_installment_mapping
--where KEY_INSTALLMENT_MAPPING_ID = 2071004729
where INSTALLMENT_ID = 8103589

select * from raw_c_f_aurora_paylater_consumer_order_loan_installment
where KEY_PAYMENT_SCHEDULE_ID = 2071004729


select * from raw_c_e_loanservice_loan where key_loan_id = 'ebe44592-6fce-4d79-86a2-20736ab506e2'

select order_id, instalment_id, 
EVENT_DATE, event_type, 
--AMOUNT_INVOICED, AMOUNT_PAID, 
AMOUNT_REFUNDED_BEFORE_PAYMENT, AMOUNT_REFUNDED_AFTER_PAYMENT
--payment_id, refund_id
from f_instalment_events ev
join f_order fo
on ev.order_id = fo.id
where fo.payment_type = 'PCL'
and fo.country_code = 'US'
and event_type = 'REFUNDED'
and order_id = 100392038761

order by 1,2,3





select order_id, --instalment_id, 
EVENT_DATE, event_type, 
--AMOUNT_INVOICED, AMOUNT_PAID, 
sum(AMOUNT_REFUNDED_BEFORE_PAYMENT) before, sum(AMOUNT_REFUNDED_AFTER_PAYMENT) after
--payment_id, refund_id
from f_instalment_events ev
join f_order fo
on ev.order_id = fo.id
where fo.payment_type = 'PCL'
and fo.country_code = 'US'
group by 1,2,3
having before >0 and after > 0
and order_id in (100476701199,
100421769180,
100432679854,
100438802373,
100447499332,
100468711465,
100470922366,
100485241746
)

order by 3,2

limit 10


select key_loan_id, external_ref from raw_c_e_loanservice_loan
where external_ref ='100392038761' in (100392038761, 100392134629, 100392174229, 100392348264, 100392354158, 100392072156, 100392365499, 100392016509)


select * from ap_raw_green.green.raw_c_e_loanservice_loan_transaction
where KEY_LOAN_TRANSACTION_ID = 3992024


select distinct status from ap_raw_green.green.raw_c_e_loanservice_loan_payment_installment_mapping
where 1=1 
--and IS_MONEY_BACK_TO_CUSTOMER = 'TRUE' 
and WAIVED_INTEREST_AMOUNT is not null

LIMIT 5



select * from ap_raw_green.green.raw_c_f_aurora_paylater_consumer_order_loan_refund where requested_at > '2025-01-01' limit 100

select * from ap_raw_green.green.f_refund where id = 127230799

select * from 
RAW_C_R_AURORA_PAYLATER_CONSUMER_ORDER_LOAN_REFUND_TYPE
limit 5

select * from raw_c_e_loanservice_loan_installment_modification where loan_id = '05ad2d07-6b7c-4eb9-a2b7-d660260fed06'

select * from raw_c_e_loanservice_loan_installment where loan_id = '05ad2d07-6b7c-4eb9-a2b7-d660260fed06'


--- my old sql

SELECT
DISTINCT a.loan_id,
b.key_order_transaction_id order_id,
c.installment_id,
D.key_payment_id,
E.key_payment_schedule_id core_instalment_id,
D.TYPE,
G.Key_refund_id core_refund_id,
D.payment_time,
D.principal_amount Total_Refund,
C.PRINCIPAL_AMOUNT Refund_After_Payment,
(D.principal_amount-C.principal_amount) Principal_reduction
FROM ap_raw_green.green.raw_c_e_loanservice_loan_installment a
JOIN ap_raw_green.green.raw_c_f_aurora_paylater_consumer_order_loan b
ON a.loan_id = b.key_loan_id
JOIN AP_RAW_GREEN.green.RAW_C_E_LOANSERVICE_PAYMENT D 
ON d.loan_id = b.key_loan_id
Left JOIN AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_LOAN_PAYMENT_INSTALLMENT_MAPPING C
ON c.payment_id = d.key_payment_id 
LEFT JOIN AP_RAW_GREEN.green.RAW_C_E_LOANSERVICE_LOAN_INSTALLMENT F 
ON c.installment_id = f.key_installment_id 
LEFT JOIN AP_RAW_GREEN.GREEN.RAW_C_F_AURORA_PAYLATER_CONSUMER_ORDER_LOAN_INSTALLMENT E 
ON f.key_installment_id = e. loan_installment_ref 
JOIN AP_RAW_GREEN.GREEN.RAW_C_F_AURORA_PAYLATER_CONSUMER_ORDER_LOAN_REFUND G 
ON D.payment_source_reference = G.Ref
where b.key_order_transaction_id IN (100392038761) AND D.TYPE = 'REFUND'


-- from Shriram:
SELECT DISTINCT i.KEY_PAYMENT_SCHEDULE_ID, m.PRINCIPAL_AMOUNT, m.INTEREST_AMOUNT, m.WAIVED_INTEREST_AMOUNT
FROM AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_PAYMENT p
         JOIN AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_LOAN l
              ON p.LOAN_ID = l.KEY_LOAN_ID
                  AND p.type = 'REFUND'
         JOIN AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_LOAN_PAYMENT_INSTALLMENT_MAPPING m
              ON m.PAYMENT_ID = p.KEY_PAYMENT_ID
         JOIN AP_RAW_GREEN.GREEN.RAW_C_F_AURORA_PAYLATER_CONSUMER_ORDER_LOAN_INSTALLMENT i
              ON i.LOAN_INSTALLMENT_REF = m.INSTALLMENT_ID
WHERE l.EXTERNAL_REF = <order_id>;


--- From Kavitha

--total refund
USE DATABASE ap_raw_green;
--step 1 - Order master query
CREATE temp TABLE order_master  AS    --- your optional test environment table can be given for testing
--deduplicating loanservice table to get unique row for each order
WITH loan_progress AS (
SELECT * FROM (
SELECT        
              DISTINCT KEY_LOAN_ID,
              PAR_REGION,
              EVENT_INFO_EVENT_TIME AS event_time_progress,
              EXTERNAL_REF,
              term,
              period,
              TARGET_APR,
              EFFECTIVE_INTEREST_RATE,
              EFFECTIVE_APR,
              ORIGINATION_DATE,
              ORIGINATED_PRINCIPAL,
              INTEREST_CAP,
              COUNTRY_CODE,
              TIME_ZONE,
              STATUS AS STATUS_PROGRESS,
              CURRENCY_UNIT,
              REGION,
              ORDER_SOURCE,
              rank() over (partition by key_loan_id order by event_info_event_time desc) as rank
FROM AP_RAW_GREEN.green.raw_c_e_loanservice_loan
WHERE status = 'IN_PROGRESS'
AND start_date IS NOT NULL
AND ORIGINATION_DATE >= '2022-10-03'
AND ORIGINATION_DATE  <=  date(current_timestamp)- 2
               )
WHERE RANK = 1
UNION 
SELECT * FROM (
 SELECT DISTINCT KEY_LOAN_ID,
              PAR_REGION,
              EVENT_INFO_EVENT_TIME AS event_time_progress,
              EXTERNAL_REF,
              term,
              period,
              TARGET_APR,
              EFFECTIVE_INTEREST_RATE,
              EFFECTIVE_APR,
              ORIGINATION_DATE,
              ORIGINATED_PRINCIPAL,
              INTEREST_CAP,
              COUNTRY_CODE,
              TIME_ZONE,
              'IN_PROGRESS' AS STATUS_PROGRESS,
              CURRENCY_UNIT,
              REGION,
              ORDER_SOURCE,
              rank() over (partition by key_loan_id order by event_info_event_time desc) as rank
FROM AP_RAW_GREEN.green.raw_c_e_loanservice_loan
WHERE EXTERNAL_REF NOT IN 
             (
SELECT
DISTINCT EXTERNAL_REF
FROM AP_RAW_GREEN.green.raw_c_e_loanservice_loan
WHERE status = 'IN_PROGRESS'
AND start_date IS NOT NULL
             )
AND STatus = 'CLOSED'
AND start_date IS NOT NULL
AND ORIGINATION_DATE >= '2022-10-03'
AND ORIGINATION_DATE  <=  date(current_timestamp)- 2
)
WHERE RANK = 1
)
,loans_base AS (
SELECT id AS ORDER_id,
       order_Date AS origination_Date,
       order_datetime AS origination_timestamp_local,
       CONSUMER_AMOUNT,
       CONSUMER_ID,
       MERCHANT_COUNTRY_CODE,
       MERCHANT_ID, 
       convert_timezone('America/Los_Angeles', 'America/New_York',to_timestamp(order_datetime)) AS origination_timestamp_EST
      -- convert_timezone('America/Los_Angeles', 'UTC',to_timestamp(order_datetime)) AS origination_timestamp_UTC
FROM ap_raw_green.green.f_order 
WHERE order_date >= '2022-10-03'
AND PAYMENT_TYPE = 'PCL'
AND ORDER_TRANSACTION_STATUS = 'Approved'
AND ORder_DATE  <=  date(current_timestamp)- 2
)
/* getting status where orders are closed */
,loan_closed AS (
SELECT * FROM ( 
              SELECT DISTINCT key_loan_id,
              close_date,
              status AS status_closed,
              to_timestamp(event_info_event_time) AS close_timestamp_UTC,
              --convert_timezone('UTC', 'America/Los_Angeles',to_timestamp(event_info_event_time)) AS close_timestamp_PST,
              --convert_timezone('UTC', 'America/New_York',to_timestamp(event_info_event_time)) AS close_timestamp_EST,
              external_Ref,
               rank() over (partition by key_loan_id order by event_info_event_time desc) as rank             
 FROM AP_RAW_GREEN.green.raw_c_e_loanservice_loan 
 WHERE status = 'CLOSED'
 AND CLOSE_DATE IS NOT NULL 
 )
 WHERE RANK = 1
 )
 ,loan_originated AS (
SELECT * FROM ( 
              SELECT DISTINCT key_loan_id,
              ORIGINATION_DATE,
              external_Ref,
              rank() over (partition by key_loan_id order by event_info_event_time desc) as rank             
 FROM AP_RAW_GREEN.green.raw_c_e_loanservice_loan 
 WHERE status = 'ORIGINATED'
 AND START_DATE IS NOT NULL 
 AND ORIGINATION_DATE >= '2022-10-03'
 )
 WHERE RANK = 1
 )
 /* getting settlement details */
,orders AS (
SELECT * FROM (
SELECT DISTINCT loan_details_loan_id AS loan_id,
                consumer_consumer_id AS consumer_id,
                b.SETTLEMENT_DATE,
                rank() over (partition by b.KEY_LOAN_ID  order by b.event_info_event_time) as rank,
                b.EVENT_INFO_EVENT_TIME AS settlement_timestamp,
                order_transaction_id AS order_id
FROM AP_RAW_GREEN.green.RAW_C_E_ORDER  a
                left join AP_RAW_GREEN.green.raw_c_e_loanservice_settlement b
                on a.loan_details_loan_id = b.key_loan_id
                where LOAN_DETAILS_LOAN_ID is not NULL
                
                )
  WHERE RANK = 1
  )
  
,interest_paid AS (
SELECT DISTINCT loan_id,
       INTEREST_AMOUNT AS interest_paid,
       convert_timezone('UTC', 'America/New_York',to_timestamp(event_info_event_time)) AS PAYMENT_TIME 
FROM AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_PAYMENT 
WHERE TYPE IN  ('PAYMENT')
)
SELECT      loan_progress.PAR_REGION,         
             loans_base.order_id,
             loan_progress.COUNTRY_CODE,
             loans_base.origination_timestamp_local,
             loans_base.origination_date,
             loans_base.consumer_amount,
             loans_base.consumer_id,
             loan_progress.ORIGINATED_PRINCIPAL,
             loan_progress.CURRENCY_UNIT,
             loan_progress.KEY_LOAN_ID AS loan_id, 
             loan_progress.term,
             loans_base.origination_timestamp_EST,
             loan_progress.period,
             loan_progress.TARGET_APR,
             loan_progress.EFFECTIVE_INTEREST_RATE,
              loan_progress.EFFECTIVE_APR,
             loan_progress.INTEREST_CAP,
              loan_progress.TIME_ZONE,
              loan_progress.REGION AS order_origination_state,
              loan_progress.ORDER_SOURCE,
              CASE 
              	WHEN loan_closed.status_closed IS NOT NULL THEN loan_closed.status_closed
              	else LOAN_PROGRESS.STATUS_PROGRESS
              END AS original_STATUS,
              loan_closed.close_timestamp_UTC,
              loan_closed.close_date,
             orders.SETTLEMENT_DATE
 FROM loans_base 
 LEFT JOIN loan_progress
 ON loans_base.order_id = loan_progress.external_ref
 LEFT JOIN loan_closed  
 ON loan_progress.key_loan_id = loan_closed.key_loan_id 
 LEFT JOIN loan_originated
 ON loan_progress.key_loan_id = loan_originated.key_loan_id
 LEFT JOIN orders 
 on loan_progress.key_loan_id = orders.loan_id
;
--step 2 - Total Refunds
CREATE OR REPLACE TEMP TABLE total_refunds AS (
SELECT order_id,loan_id,sum(total_refund) AS total_refund 
FROM (
SELECT order_id,k.loan_id,KEY_PAYMENT_ID,D.principal_amount AS total_refund
FROM order_master k 
JOIN AP_RAW_GREEN.green.RAW_C_E_LOANSERVICE_PAYMENT D 
ON d.loan_id = k.loan_id
where D.TYPE = 'REFUND'
AND D.key_payment_id NOT IN 
(SELECT DISTINCT KEY_PAYMENT_ID 
FROM ap_raw_green.green.raw_c_e_loanservice_payment
WHERE status = 'REVERSAL'
AND TYPE = 'REFUND')
AND date(payment_time)BETWEEN  '2023-10-01' AND '2023-12-31'
AND k.settlement_Date <= '2023-12-31'
AND order_origination_state = 'GA'
AND ORIGINATED_PRINCIPAL <= 3000
--and k.order_id = '100531628741'
)
GROUP BY 1,2
)
--step 3 - Refunds after payment
CREATE OR REPLACE TEMP TABLE refund_after_payment AS (
SELECT order_id,loan_id,ifnull(sum(PRINCIPAL_AMOUNT),0) AS refund_after_payment_principal,ifnull(sum(INTEREST_AMOUNT),0) AS refund_after_payment_interest
FROM 
(
SELECT B.INSTALLMENT_ID,A.TYPE,A.KEY_PAYMENT_ID,B.PAYMENT_ID,B.PRINCIPAL_AMOUNT,k.loan_id,k.order_id,b.INTEREST_AMOUNT 
FROM order_master K 
JOIN AP_RAW_GREEN.green.RAW_C_E_LOANSERVICE_PAYMENT a
ON K.LOAN_ID = A.LOAN_ID 
LEFT JOIN AP_RAW_GREEN.GREEN.RAW_C_E_LOANSERVICE_LOAN_PAYMENT_INSTALLMENT_MAPPING b
ON a.KEY_PAYMENT_ID = b.PAYMENT_ID 
WHERE  A.TYPE = 'REFUND' 
AND A.key_payment_id NOT IN 
(SELECT DISTINCT KEY_PAYMENT_ID 
FROM ap_raw_green.green.raw_c_e_loanservice_payment
WHERE status = 'REVERSAL'
AND TYPE = 'REFUND')
AND date(payment_time) BETWEEN  '2023-10-01' AND '2023-12-31'
AND k.settlement_Date <= '2023-12-31'
AND order_origination_state = 'GA'
AND ORIGINATED_PRINCIPAL <= 3000
--and k.order_id = '100531628741'
)
GROUP BY 1,2
)
--step 4 - Refund by type split
SELECT total_refund,
(total_refund - refund_after_payment_principal-refund_after_payment_interest) as refund_before_payment
,refund_after_payment_interest,refund_after_payment_principal,
a.order_id,a.loan_id
FROM total_refunds a
LEFT JOIN refund_after_payment b
ON a.order_id = b.order_id
