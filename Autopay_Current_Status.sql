WITH AUTOPAY_AT_ORDER AS 
            (---- to get the status as at order
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
            AND B.order_datetime between '2022-10-18' and '2024-07-31' --autopay flag was introduced on 17 Oct 2022; second date aligns with cut off
            --AND B.PAYMENT_TYPE = 'PCL'
            WHERE first_event_type IN ('Toggle On', 'Toggle Off')
            
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
            B.payment_type,
            F.FIRST_EVENT_TYPE FIRST_EVENT_TYPE,
            B.order_datetime,
            B.order_date,
            F.first_change_datetime,
            CASE WHEN F.FIRST_EVENT_TYPE = 'Toggle On' THEN 1 WHEN F.FIRST_EVENT_TYPE = 'Toggle Off' THEN 0 ELSE B.autopay_disabled END as autpay_disabled_at_checkout_flag
            FROM AP_RAW_GREEN.GREEN.F_ORDER B
            LEFT JOIN First_event_type F
            ON B.id = F.order_id
            WHERE B.ORDER_TRANSACTION_STATUS = 'Approved'
            AND B.order_datetime between '2022-10-18' and '2024-07-31' -- autopay flag was introduced on 17 Oct 2022; second date aligns with cut off
            --AND B.PAYMENT_TYPE = 'PCL'
            )


            
            SELECT 
            Z.ORDER_ID,
            Z.payment_type,
            Z.autpay_disabled_at_checkout_flag, 
            to_date(Z.order_datetime) order_date
           
            FROM State_at_checkout Z 
),

-- to pick up the last change before the cut off date
CHANGE_BEFORE_CUT_OFF AS
(
SELECT A.order_id, 
            case when A.note like '%toggled Autopay off%' then 'Toggle Off' 
            	when A.note like '%Autopay enabled' then 'Toggle On' 
            	WHEN a.note = 'Consumer Autopay disabled' then 'Toggle Off' 
            	WHEN a.note = 'Consumer Autopay enabled' then 'Toggle On' 
            	else NULL END event_type,
            row_number() over (partition by order_id order by created_datetime desc) as RNK,
            A.created_datetime
            FROM AP_RAW_GREEN.GREEN.F_ORDER_TRANSACTION_NOTE A 
            WHERE event_type IN ('Toggle On', 'Toggle Off')
            AND to_date(a.created_datetime) between '2022-10-18' and '2024-07-31' --autopay flag was introduced on 17 Oct 2022; second date aligns with cut off
            
  ),

  LAST_CHANGE_BEFORE_CUT_OFF AS
  (
  SELECT order_id,
  event_type last_event_type,
  created_datetime
  FROM CHANGE_BEFORE_CUT_OFF
  WHERE RNK = 1
  ),

  
  CONSOLIDATED AS
  (
  SELECT 
  A.ORDER_ID,
  A.autpay_disabled_at_checkout_flag, 
  A.order_date,
  B.last_event_type,
  b.created_datetime
  FROM AUTOPAY_AT_ORDER A
  LEFT JOIN LAST_CHANGE_BEFORE_CUT_OFF B
  ON a.order_id = b.order_id
  ),

  ---- if no changes before the cut off date, use status from order time
CLEANED_UP AS
(
SELECT 
order_id,
order_date,
CASE WHEN last_event_type is not null then last_event_type else autpay_disabled_at_checkout_flag END AS autopay_at_cutoff
FROM CONSOLIDATED 
)


SELECT order_id,
case when autopay_at_cutoff in ('true','Toggle Off') then 'autopay_disabled' 
when autopay_at_cutoff in ('false','Toggle On') then 'autopay_enabled' 
else null end as autopay_at_cutoff
from CLEANED_UP 

