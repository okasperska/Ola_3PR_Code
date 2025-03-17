WITH SCRA_BASE AS 
(
select 
a.ORDER_ID,
a.created_date SCRA_APPLIED_DATE,
REGEXP_SUBSTR(a.Note, '[zZ][dD][^0-9]*[0-9]+') AS Ticket_string,
REGEXP_SUBSTR(ticket_string, '([0-9]+)', 1, 1, 'e', 1) AS zd_ticket_id,
a.note
from ap_raw_green.green.F_ORDER_TRANSACTION_NOTE a
WHERE a.note like '%SCRA Status%'
)

select 
a.ORDER_ID,
c.payment_type,
b.UUID,
b.COUNTRY_CODE,
b.state,
a.zd_ticket_id,
a.note,
to_date(convert_timezone('UTC', 'America/Los_Angeles',f.created_at)) REQUEST_DATE,
a.SCRA_APPLIED_DATE,
f.CUSTOM_COMPLAINT_TIER COMPLAINT_TIER
from SCRA_BASE a
JOIN ap_raw_green.green.f_order c
ON a.order_id = c.id
JOIN ap_raw_green.green.d_consumer b
ON c.consumer_id = b.id
LEFT JOIN ap_raw_green.green.raw_o_e_zendesk_ticket f
ON f.key_id = ZD_TICKET_ID
WHERE 1=1
and c.payment_type ='PCL'
and b.country_code = 'US'

order by 6
