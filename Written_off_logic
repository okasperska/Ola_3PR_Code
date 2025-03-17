select	a14.CAL_MONTH  event_month_id,
a15.CAL_MONTH_SHORT_DESC  event_month,
	sum(a11.AMOUNT_WRITTEN_OFF)  written_off_amt,
    count(distinct a11.order_id) written_off_cnt
from	AP_RAW_GREEN.green.F_WRITE_OFF_EVENTS	a11
	join	AP_RAW_GREEN.green.F_ORDER	a12
	  on 	(a11.ORDER_ID = a12.id and a11.PAR_REGION = a12.PAR_REGION)
	join	AP_RAW_GREEN.green.D_DATE	a14
	  on 	(a11.event_date = a14.CAL_DATE)
    join	AP_RAW_GREEN.green.D_DATE_MONTH	a15
	  on 	(a14.CAL_MONTH = a15.CAL_MONTH)
where	a12.country_code = 'US'
 and (a12.ORDER_TRANSACTION_SOURCE not in ('ANYWHERE_CARD', 'ANYWHERE_CARD_ONLINE') and a12.PAYMENT_TYPE <> 'PCL') --this is a BNPL condition
 and a11.event_date between '2022-01-01' and '2024-07-31'
 and a11.EVENT_TYPE in ('Write Off')
 and a11.WRITE_OFF_EVENT_SOURCE in ('Payment')
group by	1,2
order by 1
