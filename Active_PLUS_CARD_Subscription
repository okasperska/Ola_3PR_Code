SELECT DISTINCT a.consumer_uuid
start_date, 
end_date, 
event_type, 
to_date(convert_timezone('America/New_York','America/Los_Angeles',(to_timestamp(EVENT_INFO_EVENT_TIME)))) event_date,
max(to_date(convert_timezone('America/New_York','America/Los_Angeles',(to_timestamp(a.EVENT_INFO_EVENT_TIME))))) over (partition by a.consumer_uuid ) AS max_date
FROM AP_RAW_GREEN.green.raw_c_e_membership_subscription A
JOIN
	(SELECT c.consumer_uuid, 
	max(to_date(convert_timezone('America/New_York','America/Los_Angeles',(to_timestamp(c.EVENT_INFO_EVENT_TIME))))) over (partition by c.consumer_uuid ) AS max_date
	FROM AP_RAW_GREEN.green.raw_c_e_membership_subscription c) B
ON A.consumer_uuid=b.consumer_uuid 
WHERE to_date(convert_timezone('America/New_York','America/Los_Angeles',(to_timestamp(a.EVENT_INFO_EVENT_TIME)))) = b.max_date
AND a.consumer_uuid = 'acbbe6ec-bcb2-4b1a-8bee-d04619b9dd2e'


SELECT a.CONSUMER_ACCOUNT_REFERENCE_CONSUMER_ID, 
a.EVENT_INFO_EVENT_TIME,
b.order_date
FROM AP_RAW_GREEN.GREEN.RAW_C_E_CONSUMER_SELF_EXCLUSION a
JOIN AP_RAW_GREEN.GREEN
WHERE STATUS_CHANGED_TO = 'REACTIVATED'
AND PAR_REGION = 'US'
AND YEAR IN ('2022','2023')
GROUP BY 1,2
