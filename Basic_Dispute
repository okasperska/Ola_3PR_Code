(
WITH DISPUTE_BASE as
(
SELECT 
a.ORDER_ID,
a.CONSUMER_UUID,
a.DISPUTE_CASE_ID,
dispute_external_id,
a.cur_amount,
a.source,
to_date(convert_timezone('UTC', 'America/Los_Angeles',a.action_time)) DISPUTE_CREATED_DATE ,
(convert_timezone('UTC', 'America/Los_Angeles',a.action_time)) DISPUTE_CREATED_DATETIME,
CASE WHEN a.ZENDESK_TICKET_ID is null then 'CUSTOMER SERVICE' else 'SELF SERVICE VIA APP' END AS DISPUTE_CHANNEL,
case when a.REASON = 'SINGLE_USE_CARD' THEN concat (a.REASON, ' - ',COALESCE(a.REASON_DETAIL, 'DETAIL NOT AVAILABLE')) ELSE a.REASON END AS DISPUTE_CATEGORY,  
a.SUBJECT DISPUTE_DESCRIPTION
FROM ap_raw_green.green.raw_p_e_dispute_case_process A
JOIN ap_raw_green.green.f_order B
ON a.order_id = b.id
WHERE b.country_code = 'US' and DISPUTE_CREATED_DATE between '2023-01-01' and '2024-06-30' 
AND a.ACTION = 'CREATE'
),

DISPUTE_RESOLUTION AS
(
select 
a.DISPUTE_CASE_ID,
a.ORDER_ID,
a.DISPUTE_CLOSED_DATE,
a.DISPUTE_CLOSED_DATETIME,
a.RESOLUTION
FROM 
            (select 
            a.DISPUTE_CASE_ID,
            a.ORDER_ID,
            to_date(convert_timezone('UTC', 'America/Los_Angeles',a.action_time)) DISPUTE_CLOSED_DATE,
            (convert_timezone('UTC', 'America/Los_Angeles',a.action_time)) DISPUTE_CLOSED_DATETIME,
            a.CUR_INTENT RESOLUTION,
            row_number() over (partition by a.DISPUTE_CASE_ID order by a.action_time asc) rnk
            FROM ap_raw_green.green.raw_p_e_dispute_case_process A
            JOIN DISPUTE_BASE B
            ON a.DISPUTE_CASE_ID = b.DISPUTE_CASE_ID
            WHERE a.cur_status = 'CLOSE'
            AND a.par_region = 'US' 
            and b.DISPUTE_CREATED_DATE between '2023-01-01' and '2024-06-30' 
            )a
WHERE a.rnk = 1
and a.DISPUTE_CLOSED_DATE <= '2024-06-30' 
),

SENT_TO_CONSUMER AS
(
select 
a.DISPUTE_CASE_ID,
a.ORDER_ID,
min(to_date(convert_timezone('UTC', 'America/Los_Angeles',a.action_time))) SENT_TO_CONSUMER -- adding min - there is a single dispute with two records 'pending consumer response' that happenned at the same time, for this exam we can assume that there can be only one
FROM ap_raw_green.green.raw_p_e_dispute_case_process A
JOIN DISPUTE_BASE B
ON a.DISPUTE_CASE_ID = b.DISPUTE_CASE_ID
WHERE a.cur_intent = 'PENDING_CONSUMER_RESPONSE'
AND a.par_region = 'US' 
and b.DISPUTE_CREATED_DATE between '2023-01-01' and '2024-06-30' 
group by 1,2
having SENT_TO_CONSUMER <= '2024-06-30'
),

REFUNDS AS
(
select 
a.DISPUTE_CASE_ID,
a.ORDER_ID,
sum(ABS(COALESCE(c.amount, 0)))  TOTAL_DISPUTE_BASED_REFUND_AMT,
sum(ABS(COALESCE(c.due_consumer_amount, 0))) DISPUTE_BASED_CASH_REFUND_AMT
FROM DISPUTE_BASE A
JOIN AP_RAW_GREEN.GREEN.F_REFUND C
ON a.dispute_external_id = c.request_id
WHERE c.refund_status_id in (3, 4)
and c.created_date <= '2024-06-30'
group by 1,2
),

TEMP as
(
SELECT 
a.ORDER_ID,
a.DISPUTE_CASE_ID,
a.DISPUTE_CREATED_DATETIME,
b.DISPUTE_CLOSED_DATETIME,
b.RESOLUTION
FROM DISPUTE_BASE a
LEFT JOIN DISPUTE_RESOLUTION b
on a.DISPUTE_CASE_ID = b.DISPUTE_CASE_ID
WHERE b.RESOLUTION in ('CONSUMER_FAVOR', 'MERCHANT_ACCEPTED')
),

REFUNDS_SOFT_MATCH AS --pick up refunds that occured during the dispute
(
select 
a.ORDER_ID,
a.DISPUTE_CASE_ID,
sum(ABS(COALESCE(c.amount, 0)))  TOTAL_SOFT_REFUND_AMT,
sum(ABS(COALESCE(c.due_consumer_amount, 0))) SOFT_CASH_REFUND_AMT
FROM TEMP A
JOIN AP_RAW_GREEN.GREEN.F_REFUND C
ON a.order_id = c.order_id
WHERE c.refund_status_id in (3, 4)
and c.created_datetime >= a.DISPUTE_CREATED_DATEtime and c.created_datetime <= DISPUTE_CLOSED_DATETIME
and c.created_date <= '2024-06-30'
group by 1,2
),

REPEAT_DISPUTE AS
(
SELECT 
a.ORDER_ID,
a.DISPUTE_CASE_ID, 
case when a.REASON = 'SINGLE_USE_CARD' THEN a.REASON_DETAIL ELSE a.REASON END AS DISPUTE_CATEGORY,
(row_number() over (partition by a.order_id, DISPUTE_CATEGORY, a.cur_amount order by to_date(convert_timezone('UTC', 'America/Los_Angeles',a.action_time)))) rnk -- if rnk>1 then we consider it a repeat
FROM ap_raw_green.green.raw_p_e_dispute_case_process A
JOIN DISPUTE_BASE B
ON a.DISPUTE_CASE_ID = b.DISPUTE_CASE_ID
WHERE a.par_region = 'US'  
and b.DISPUTE_CREATED_DATE between '2023-01-01' and '2024-06-30' 
AND ACTION = 'CREATE'
)


SELECT 
b.ORDER_ID,
b.CONSUMER_UUID,
b.DISPUTE_CASE_ID, 
b.DISPUTE_CREATED_DATE,
b.DISPUTE_CHANNEL,
b.source,
b.DISPUTE_CATEGORY,  
b.DISPUTE_DESCRIPTION,
CASE WHEN c.SENT_TO_CONSUMER is null THEN d.DISPUTE_CLOSED_DATE else c.SENT_TO_CONSUMER END as INVESTIGATION_RESULTS_SENT_TO_CONSUMER_DATE,
d.RESOLUTION,
CASE WHEN e.TOTAL_DISPUTE_BASED_REFUND_AMT = g.TOTAL_SOFT_REFUND_AMT THEN e.TOTAL_DISPUTE_BASED_REFUND_AMT WHEN g.TOTAL_SOFT_REFUND_AMT is null THEN e.TOTAL_DISPUTE_BASED_REFUND_AMT  else (coalesce(g.TOTAL_SOFT_REFUND_AMT,0) - coalesce(e.TOTAL_DISPUTE_BASED_REFUND_AMT,0)) END AS TOTAL_REFUND_AMT,

CASE WHEN e.DISPUTE_BASED_CASH_REFUND_AMT = g.SOFT_CASH_REFUND_AMT THEN e.DISPUTE_BASED_CASH_REFUND_AMT WHEN g.SOFT_CASH_REFUND_AMT is null THEN e.DISPUTE_BASED_CASH_REFUND_AMT else (coalesce(g.SOFT_CASH_REFUND_AMT,0) - coalesce(e.DISPUTE_BASED_CASH_REFUND_AMT,0)) END AS  CASH_REFUND_AMT,

CASE WHEN f.rnk>1 then 'YES' else 'NO' END AS REPEAT_DISPUTE_FLAG

from DISPUTE_BASE b
LEFT JOIN DISPUTE_RESOLUTION d
ON b.DISPUTE_CASE_ID = d.DISPUTE_CASE_ID
LEFT JOIN SENT_TO_CONSUMER c
ON b.DISPUTE_CASE_ID = c.DISPUTE_CASE_ID
LEFT JOIN REFUNDS e
ON  b.DISPUTE_CASE_ID = e.DISPUTE_CASE_ID
LEFT JOIN REPEAT_DISPUTE f
ON b.DISPUTE_CASE_ID = f.DISPUTE_CASE_ID
LEFT JOIN REFUNDS_SOFT_MATCH G
ON b.DISPUTE_CASE_ID = g.DISPUTE_CASE_ID
)
