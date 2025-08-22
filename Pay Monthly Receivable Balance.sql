select	a15.PAYMENT_TYPE,
	coalesce(pa12.id, pa13.id)  order_id,
	a15.ORDER_DATE  ORDER_DATE,
	(((COALESCE(max(pa12.WJXBFS1), 0) - COALESCE(max(pa12.WJXBFS2), 0)) - COALESCE(max(pa13.WJXBFS1), 0)) + COALESCE(max(pa13.WJXBFS2), 0))  balance
from	(select	a11.ORDER_ID  id,
		sum((Case when a11.EVENT_TYPE in ('INVOICED', 'OVERAGE') then a11.amount_invoiced else NULL end))  WJXBFS1,
		sum((Case when a11.EVENT_TYPE in ('PAYMENT') then a11.amount_paid else NULL end))  WJXBFS2
	from	AP_RAW_GREEN.green.F_INSTALMENT_EVENTS	a11
		join	AP_RAW_GREEN.green.F_ORDER	a12
		  on 	(a11.ORDER_ID = a12.id and 
		a11.PAR_REGION = a12.PAR_REGION)
	where	(a11.event_date <= '2024-07-31'-- as at date parameter
	 and a12.country_code = 'US'
	 and a12.PAYMENT_TYPE = 'PCL'
	 and (a11.EVENT_TYPE in ('INVOICED', 'OVERAGE')
	 or a11.EVENT_TYPE in ('PAYMENT')))
	group by	a11.ORDER_ID
	)	pa12
	full outer join	(select	a11.ORDER_ID  id,
		sum((Case when a12.refund_type not in ('InterestAccrual') then a11.amount_refunded_before_payment else NULL end))  WJXBFS1,
		sum((Case when a12.refund_type in ('InterestAccrual') then a11.amount_refunded_before_payment else NULL end))  WJXBFS2
	from	AP_RAW_GREEN.green.F_INSTALMENT_EVENTS	a11
		join	green.F_REFUND	a12
		  on 	(a11.GDP_REGION = a12.GDP_REGION and 
		a11.event_date = a12.CREATED_DATE and 
		a11.refund_id = a12.id 
		join	AP_RAW_GREEN.green.F_ORDER	a13
		  on 	(a11.ORDER_ID = a13.id and 
		a11.PAR_REGION = a13.PAR_REGION)
	where	(a11.event_date <= '2024-07-31'-- as at date parameter
	 and a13.country_code = 'US'
	 and a13.PAYMENT_TYPE = 'PCL' 
	 and a11.EVENT_TYPE in ('REFUNDED')
	 and (a12.refund_type not in ('InterestAccrual')
	 or a12.refund_type in ('InterestAccrual')))
	group by	a11.ORDER_ID
	)	pa13
	  on 	(pa12.id = pa13.id)
	join	AP_RAW_GREEN.green.F_ORDER	a15
	  on 	(coalesce(pa12.id, pa13.id) = a15.id)
group by	a15.PAYMENT_TYPE = 'PCL',
	coalesce(pa12.id, pa13.id),
	a15.ORDER_DATE
