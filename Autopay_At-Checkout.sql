WITH First_event_type_temp AS 
(
SELECT A.order_id, 
case when A.note like '%toggled Autopay off%' then 'Toggle Off' 
	when A.note like '%Autopay enabled' then 'Toggle On' 
	WHEN a.note = 'Consumer Autopay disabled' then 'Toggle Off' 
	WHEN a.note = 'Consumer Autopay enabled' then 'Toggle On' 
	else NULL END first_event_type,
row_number() over (partition by order_id order by created_datetime asc) RNK,
A.created_datetime
FROM AP_RAW_GREEN.GREEN.F_ORDER_TRANSACTION_NOTE A 
JOIN AP_RAW_GREEN.GREEN.F_ORDER B
ON A.ORDER_ID = B.id
WHERE 1=1 
--AND B.PAYMENT_TYPE = 'PCL' 
AND first_event_type IN ('Toggle On', 'Toggle Off')

),

First_event_type AS 
(
SELECT D.order_id order_id, 
D.first_event_type,
D.created_datetime first_change_datetime
FROM First_event_type_temp D	
WHERE D.RNK =1
),

State_at_checkout AS 
(
SELECT B.id ORDER_id,
F.FIRST_EVENT_TYPE FIRST_EVENT_TYPE,
B.order_datetime,
B.order_date,
F.first_change_datetime,
CASE WHEN F.FIRST_EVENT_TYPE = 'Toggle On' THEN 1 WHEN F.FIRST_EVENT_TYPE = 'Toggle Off' THEN 0 ELSE B.autopay_disabled END autpay_disabled_at_checkout_flag
FROM AP_RAW_GREEN.GREEN.F_ORDER B
LEFT JOIN First_event_type F
ON B.id = F.order_id
WHERE B.ORDER_TRANSACTION_STATUS = 'Approved'
)

SELECT 
Z.ORDER_ID,
Z.autpay_disabled_at_checkout_flag, to_date(Z.order_datetime) order_date,
CASE 
WHEN (Z.autpay_disabled_at_checkout_flag = 1 AND Z.FIRST_EVENT_TYPE IS NOT NULL) THEN Z.first_change_datetime -- Autopay Turned OFF  at checkout and later turned ON
WHEN (Z.autpay_disabled_at_checkout_flag = 1 AND Z.FIRST_EVENT_TYPE IS NULL) THEN null -- Autopay Turned OFF at checkout and never changed
WHEN (Z.autpay_disabled_at_checkout_flag = 0 AND Z.FIRST_EVENT_TYPE IS NULL) THEN Z.order_datetime --Autopay Turned ON at checkout and never changed
WHEN (Z.autpay_disabled_at_checkout_flag = 0 AND Z.FIRST_EVENT_TYPE IS NOT NULL) THEN Z.order_datetime -- Autopay Turned ON  at checkout and later turned OFF
ELSE '9999-01-01' END autopay_first_enabled_date
FROM State_at_checkout Z
WHERE 1=1 
and order_date > '2024-01-31'
AND z.order_id in (100633176360,100637225083)
