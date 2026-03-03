CREATE OR REPLACE TABLE PERSONAL_OKASPERSKA.public.OK_CONSENT AS 
(
WITH FIRST_BNPL_ORDER AS -- first online and instore dates EXCLUDING order on Billing agreement
(
SELECT
A.consumer_id,
A.consumer_UUID,
A.first_online_order_datetime,
A.first_card_order_datetime,
A.first_card_order_date,
A.first_order_date,
A.first_BA_order_datetime,
A.first_BA_order_date
FROM	
		(SELECT
		B.consumer_id  consumer_id,
		C.uuid consumer_uuid,
        min(CASE WHEN B.order_transaction_source IN ('POS_CARD_ONLINE','ANYWHERE_CARD_ONLINE','POS_CARD', 'ANYWHERE_CARD') THEN B.order_datetime ELSE NULL END)         first_card_order_datetime,
         min(CASE WHEN B.order_transaction_source IN ('POS_CARD_ONLINE','ANYWHERE_CARD_ONLINE','POS_CARD', 'ANYWHERE_CARD') THEN B.order_date ELSE NULL END)         first_card_order_date,
		min(CASE WHEN (B.order_transaction_source NOT IN ('POS_CARD_ONLINE','ANYWHERE_CARD_ONLINE','POS_CARD', 'ANYWHERE_CARD') AND B.SOURCE_AGREEMENT_ID is null)  THEN B.order_datetime ELSE NULL END) first_online_order_datetime,
        min(CASE WHEN (B.order_transaction_source NOT IN ('POS_CARD_ONLINE','ANYWHERE_CARD_ONLINE','POS_CARD', 'ANYWHERE_CARD') AND B.SOURCE_AGREEMENT_ID is not null)  THEN B.order_datetime ELSE NULL END) first_BA_order_datetime,
            min(CASE WHEN (B.order_transaction_source NOT IN ('POS_CARD_ONLINE','ANYWHERE_CARD_ONLINE','POS_CARD', 'ANYWHERE_CARD') AND B.SOURCE_AGREEMENT_ID is not null)  THEN B.order_date ELSE NULL END) first_BA_order_date,
        min (B.order_date)  first_order_date
		FROM ap_raw_green.green.f_order	B
		JOIN ap_raw_green.green.d_consumer C 
		ON b.consumer_id = c.id
		WHERE B.order_transaction_status_id in (1)
		AND B.payment_TYPE <>'PCL'
		GROUP BY 1,2
	)A
),

CONSENT_VIA_CARD_ADDED AS -- collecting consent by adding card after 31 July
(
SELECT 
B.id consumer_id,
A.CORE_CONSUMER_UUID CONSUMER_UUID,
CASE WHEN A.CARD_TYPE = 'ANYWHERE' then 'PLUS_CARD_ADDED' ELSE 'INSTORE_CARD_ADDED' END  as CONSENT_SOURCE,
min(CASE WHEN B.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.EVENT_INFO_EVENT_TIME)
     Else null END) CARD_ADDED_DATETIME    
FROM ap_raw_green.green.d_consumer B
LEFT JOIN AP_RAW_GREEN.GREEN.RAW_P_E_CARD_ISSUING_LIFE_CYCLE A
ON b.uuid = a.core_consumer_UUID
LEFT JOIN FIRST_BNPL_ORDER C
ON b.uuid = c.consumer_uuid
WHERE to_date(CASE WHEN A.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.EVENT_INFO_EVENT_TIME)
     Else null END) > '2024-07-31'
AND A.event_type ='ADD_TO_WALLET'  
AND (c.first_order_date is null or c.first_order_date > '2024-07-31')
GROUP BY 1,2,3
),

CONSENT_VIA_CARD_CREATED AS 
(
SELECT 
B.id consumer_id,
A.CORE_CONSUMER_UUID CONSUMER_UUID,
C.first_card_order_date,
D.CARD_ADDED_DATETIME,
CASE WHEN A.CARD_TYPE = 'ANYWHERE' then 'PLUS_CARD_CREATED' ELSE 'INSTORE_CARD_CREATED' END  as CONSENT_SOURCE,
min(CASE WHEN B.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.EVENT_INFO_EVENT_TIME)
     Else null END) CARD_CREATED_DATETIME    
FROM ap_raw_green.green.d_consumer B 
LEFT JOIN AP_RAW_GREEN.GREEN.RAW_P_E_CARD_ISSUING_LIFE_CYCLE A
ON b.uuid = a.core_consumer_UUID
LEFT JOIN FIRST_BNPL_ORDER C
ON b.id = c.consumer_id
LEFT JOIN CONSENT_VIA_CARD_ADDED D
ON b.id = d.consumer_id
WHERE to_date(CASE WHEN A.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.EVENT_INFO_EVENT_TIME)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.EVENT_INFO_EVENT_TIME)
     Else null END) > '2024-07-31'
AND A.event_type ='CREATE_CARD'
AND C.first_card_order_date > '2024-07-31'
AND D.CARD_ADDED_DATETIME is null
AND (c.first_order_date is null or c.first_order_date > '2024-07-31')
GROUP BY 1,2,3,4,5
),

BA_CONSENT AS
(
SELECT 
B.id consumer_id,
B.UUID CONSUMER_UUID,
'BILLING_AGREEMENT'  as CONSENT_SOURCE,
min(CASE WHEN B.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.CREATED_AT)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.CREATED_AT)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.CREATED_AT)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.CREATED_AT)
     Else null END) BA_CREATED_DATETIME    
FROM ap_raw_green.green.raw_c_d_aurora_paylater_agreement A
JOIN ap_raw_green.green.d_consumer B
ON (b.consumer_account_id = a.consumer_account_id and a.par_region=b.par_region)
LEFT JOIN FIRST_BNPL_ORDER E
ON b.uuid = e.consumer_uuid
WHERE to_date(CASE WHEN B.country_code IN ('US','CA') then convert_timezone('UTC', 'America/Los_Angeles',A.CREATED_AT)
     WHEN B.country_code = 'AU' then convert_timezone('UTC', 'Australia/Sydney',A.CREATED_AT)
     WHEN B.country_code = 'NZ' then convert_timezone('UTC', 'Pacific/Auckland',A.CREATED_AT)
     WHEN B.country_code ='GB' then convert_timezone('UTC', 'Europe/London',A.CREATED_AT)
     Else null END)>'2024-07-31'
AND (e.first_order_date is null or e.first_order_date > '2024-07-31')     
GROUP BY 1,2,3
),

BNPL_CONSENT_CONSOLIDATE AS 
(
SELECT 
consumer_id,
consumer_UUID,
'BNPL_ONLINE' AS CONSENT_SOURCE,
first_online_order_datetime consent_datetime
FROM FIRST_BNPL_ORDER A
WHERE first_order_date > '2024-07-31' 


UNION 

SELECT
consumer_id,
consumer_UUID,
CONSENT_SOURCE,
CARD_ADDED_DATETIME consent_datetime
FROM CONSENT_VIA_CARD_ADDED

UNION 

SELECT
consumer_id,
consumer_UUID,
CONSENT_SOURCE,
CARD_CREATED_DATETIME consent_datetime
FROM CONSENT_VIA_CARD_CREATED

UNION

SELECT
consumer_id,
consumer_UUID,
CONSENT_SOURCE,
BA_CREATED_DATETIME consent_datetime
FROM BA_CONSENT
),

BNPL_CONSENT_INTERIM AS 
(SELECT *,
row_number() over (partition by consumer_uuid order by consent_datetime asc) as rnk
FROM BNPL_CONSENT_CONSOLIDATE
),

BNPL_CONSENT AS
(
SELECT 
consumer_id,
consumer_UUID,
CONSENT_SOURCE,
consent_datetime
FROM BNPL_CONSENT_INTERIM
WHERE rnk = 1
)

SELECT 
a.id consumer_id,
a.uuid consumer_UUID,
a.country_code,
CASE WHEN b.consent_datetime is not null then b.CONSENT_SOURCE else null end consent_source,
b.consent_datetime,
CASE WHEN b.consent_datetime is not null THEN 'CONSENT COLLECTED'
WHEN b.consent_datetime is null AND c.first_order_date <= '2024-07-31' THEN 'PRE-EXISTING CUSTOMER'
WHEN b.consent_datetime is null AND c.first_order_date is null THEN 'AWAITING CONSENT - NO ACTIVITY'
WHEN b.consent_datetime is null AND (c.first_card_order_date > '2024-07-31' OR  c.first_ba_order_date > '2024-07-31') THEN 'AWAITING CONSENT - TRANSACTING'
Else 'UNKNOWN' END AS CONSENT_STATUS,
CASE WHEN CONSENT_STATUS = 'AWAITING CONSENT - TRANSACTING' and c.first_card_order_date is null THEN 'TRANSACTING UNDER BA'
WHEN CONSENT_STATUS = 'AWAITING CONSENT - TRANSACTING' and c.first_ba_order_date is null THEN 'TRANSACTING INSTORE'
WHEN CONSENT_STATUS = 'AWAITING CONSENT - TRANSACTING' and c.first_ba_order_date is not null and first_card_order_date is not null THEN 'TRANSACTING INSTORE and under BA'
ELSE NULL END AS OUTLIER_SCENARIO,
c.first_order_date,
c.first_card_order_date,
c.first_ba_order_date,
TO_DATE(C.first_online_order_datetime) first_online_order_date
FROM ap_raw_green.green.d_consumer A
LEFT JOIN BNPL_CONSENT B
ON a.id = b.consumer_id
LEFT JOIN FIRST_BNPL_ORDER C
ON a.id = c.consumer_id
)
