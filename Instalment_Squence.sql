WITH BASE AS

(
SELECT a.ID ORDER_ID,
a.CONSUMER_ID,
a.FIRST_PAYMENT_UP_FRONT,
a.MERCHANT_ID  MERCHANT_ID,
a.TRADING_NAME  MERCHANT_NAME,
a.ORDER_DATE  ORDER_DATE,
a.CONSUMER_AMOUNT  ORDER_AMT
FROM AP_RAW_GREEN.green.F_ORDER a
where	a.CONSUMER_ID in ()--examp,e of filtering
 and a.ORDER_DATE between '2020-03-16' and '2022-04-30'--examp,e of filtering
 and a.ORDER_TRANSACTION_STATUS = 'Approved'
 and a.payment_type <>'PCL'--examp,e of filtering
 and a.order_transaction_source not in ('ANYWHERE_CARD','ANYWHERE_CARD_ONLINE')--examp,e of filtering
),

INSTALMENT_SEQ AS

(
SELECT
distinct a.id instalment_id,
a.gdp_region,
a.order_id,
a.original_due_date,
row_number() over ( partition by a.order_id,gdp_region order by a.original_due_date asc )  as instalment_seq_id
FROM ap_raw_green.green.f_instalment a
JOIN BASE b
ON a.order_id = b.order_id
order by 2,3,1
),
