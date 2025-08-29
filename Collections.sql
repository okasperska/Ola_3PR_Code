
--old collection service
--referral balance

    select distinct fo.consumer_id
      ,im.instalment_id
      ,o.paylater_order_id as order_id
      ,order_date
      ,im.updated_due_date as payment_due_date
      ,p.currency
      ,lower(ag.agency) as agency
      ,min(j.opened_datetime) as referral_date
      ,max(amount_overdue) as referral_prin
      ,max(amount_overdue+late_fee_overdue) as referral_balance
    from AP_RAW_GREEN.GREEN.raw_c_f_col_payment_schedule p
             inner join AP_RAW_GREEN.GREEN.raw_c_f_col_order_detail o on p.fk_order_id=o.id and p.gdp_region=o.gdp_region
             inner join AP_RAW_GREEN.GREEN.raw_c_d_col_consumer c on o.fk_consumer_id=c.id and o.gdp_region=c.gdp_region
             inner join AP_RAW_GREEN.GREEN.raw_c_f_col_paylater_job j on c.par_paylater_job_id=j.paylater_job_id and c.gdp_region=j.gdp_region
             inner join AP_RAW_GREEN.GREEN.f_order fo on o.paylater_order_id=fo.id and o.gdp_region=fo.gdp_region
             inner join AP_CUR_BI_G.CURATED_ANALYTICS_GREEN.cur_c_m_instalment_master im  on fo.consumer_id=im.consumer_id and paylater_payment_id=im.instalment_id and im.par_region='US'
             left join AP_RAW_GREEN.GREEN.raw_c_d_col_consumer_agency_assoc ag on fo.consumer_id=ag.paylater_consumer_id
    where p.amount_overdue>0
      and p.gdp_region='US'
      and o.gdp_region='US'
      and c.gdp_region='US'
      and j.gdp_region='US'
      and fo.gdp_region='US'
      and ag.gdp_region='US'
    group by 1,2,3,4,5,6,7
    order by 1,3,2
;

--- old collection payment
with ap_payment as
(select cast(payment_id as varchar) as id
      ,paylater_consumer_id
      ,payment_amount
      ,payment_date
      ,payment_currency
      ,'AP' as paid_channel
from AP_RAW_GREEN.GREEN.raw_c_f_col_afterpay_payment
where par_region='US' and payment_date>='2023-01-01')

,dca_payment as
(select cast(b.id as varchar) as id
,case when a.paylater_consumer_id like '%047434"%'then 047434 when paylater_consumer_id  like '%131-53%' then 22385 else a.paylater_consumer_id  end as paylater_consumer_id
,a.amount as payment_amount
,a.payment_date
,b.currency as payment_currency
,'AG' as paid_channel
from AP_RAW_GREEN.GREEN.raw_c_f_col_agency_payment as a
inner join AP_RAW_GREEN.GREEN.f_payment  as b
on cast(a.id as varchar)=cast(b.external_transaction_id as varchar) and a.par_region=b.par_Region and a.paylater_consumer_id=b.consumer_id
and b.payment_status='Successful' and b.payment_source='Collections Service'
where a.par_region='US' and b.par_region='US' and a.payment_date>='2018-01-01')
,
collection_payment as
(select * from ap_payment
union
select * from dca_payment)
,
amount_paid as
  (select distinct payment_id
        ,instalment_id
        ,sum(amount_paid) as amount_paid
   from
      (select payment_id,instalment_id,amount_paid,late_fee_id from AP_RAW_GREEN.GREEN.f_instalment_events where par_region='US' and event_type='PAYMENT' and event_date>='2018-01-01'
       union
       select payment_id,instalment_id,amount_paid,late_fee_id from AP_RAW_GREEN.GREEN.f_late_fee_events where par_region='US' and event_type='PAYMENT' and event_date>='2018-01-01')
   group by 1,2)


select distinct p.id
      ,p.paylater_consumer_id
      ,p.payment_date
      ,p.payment_currency
      ,p.paid_channel
      ,im.instalment_id
      ,im.amount_paid
   from collection_payment p
inner join amount_paid im
  on p.id=im.payment_id
;


----new collection service
---referral balance  ---(first referral date for US new collection service was 2023-09-07 and Canada was 2023-09-01)

     select distinct r.CONSUMER_CONSUMER_ID as consumer_id
      ,im.instalment_id
      ,r.ORDER_ID
      ,fo.order_date
      ,im.updated_due_date as payment_due_date
      ,r.REFERRAL_BALANCE_CURRENCY as currency
      ,case when r.DCA_ASSOCIATION = 'indebted' then 'indebted us' else r.DCA_ASSOCIATION end as agency
      ,r.CONSUMER_STATUS
      ,r.REFERRAL_DATETIME ::date as referral_date
      ,REFERRAL_PRINCIPAL_AMOUNT as referral_prin
      ,REFERRAL_BALANCE_AMOUNT as referral_balance
from ap_raw_green.green.RAW_R_E_COLLECTION_REFERRAL r
inner join  AP_CUR_BI_G.CURATED_ANALYTICS_GREEN.cur_c_m_instalment_master  im
on r.CONSUMER_CONSUMER_ID = im.consumer_id AND r.order_id = im.order_id and r.INSTALLMENT_ID  = im.instalment_id and im.par_region='US'
inner join AP_RAW_GREEN.green.f_order fo on r.order_id = fo.id
  where collection_exclusion_reason is null  ----- filter out exclusion date consumers
  and (r.REFERRAL_DATETIME ::date >= '2023-09-07' and r.REFERRAL_BALANCE_CURRENCY = 'USD')
  or (r.REFERRAL_DATETIME ::date >= '2023-09-01' and r.REFERRAL_BALANCE_CURRENCY = 'CAD')
  and order_type = 'PBI' ;

---new payment balance
--  payment table US new collection service launch date:
        -- US- ap payment: Sep 7th,2023, agency: payment Oct 17th, 2023;
        -- Canada - ap payment: Sep 1st,2023, agency: payment Oct 17th, 2023
        
with collection_payment as
(select p.CONSUMER_CONSUMER_ID
                      ,p.payment_date
                      ,p.PAYMENT_AMOUNT_CURRENCY
                      ,p.PAYMENT_SOURCE
                      ,cast(id1.id as string)  as sys_payment_id
                from  ap_raw_green.green.raw_r_e_collection_payment p
                inner join ap_raw_green.green.f_payment id1 on p.PAYMENT_ID = id1.id and id1.par_region= 'US'
                where p.PAYMENT_SOURCE !='COLLECTIONS_SERVICE' and p.CONSUMER_CONSUMER_ID != '5811664'
                union
               select p.CONSUMER_CONSUMER_ID
                      ,p.payment_date
                      ,p.PAYMENT_AMOUNT_CURRENCY
                      ,p.PAYMENT_SOURCE
                      ,cast(id2.id as string) as sys_payment_id
                from  ap_raw_green.green.raw_r_e_collection_payment p
                inner join ap_raw_green.green.f_payment id2 on p.receipt_id = id2.EXTERNAL_TRANSACTION_ID and id2.par_region= 'US'
                 where p.PAYMENT_SOURCE  = 'COLLECTIONS_SERVICE' and p.CONSUMER_CONSUMER_ID != '5811664')
,
amount_paid as
  (select distinct payment_id
          ,instalment_id
          ,currency
          ,sum(amount_paid) as amount_paid
               from
                      (select cast(payment_id as string) as payment_id,instalment_id,amount_paid,late_fee_id,currency from ap_raw_green.green.f_instalment_events where par_region='US' and event_type='PAYMENT'
                      union
                      select  cast(payment_id as string) as payment_id,instalment_id,amount_paid,late_fee_id,currency from ap_raw_green.green.f_late_fee_events where par_region='US' and event_type='PAYMENT')
            group by 1,2,3
   )


select
     distinct p.sys_payment_id as id
      ,p.CONSUMER_CONSUMER_ID
      ,p.payment_date
      ,p.PAYMENT_AMOUNT_CURRENCY
      ,case when p.PAYMENT_SOURCE = 'COLLECTIONS_SERVICE' then 'AG' else 'AP'end   as PAID_CHANNEL
      ,im.instalment_id
      ,im.amount_paid
from collection_payment p
inner join amount_paid im
          on p.sys_payment_id=im.payment_id and p.PAYMENT_AMOUNT_CURRENCY=im.currency

where  (p.payment_date >= '2023-09-07' and p.PAYMENT_AMOUNT_CURRENCY = 'USD' and paid_channel != 'AG')
  or (p.payment_date >= '2023-10-17' and p.PAYMENT_AMOUNT_CURRENCY = 'USD'and paid_channel = 'AG')
  or (p.payment_date >= '2023-09-01' and p.PAYMENT_AMOUNT_CURRENCY = 'CAD'and paid_channel != 'AG')
  or (p.payment_date >= '2023-10-17' and p.PAYMENT_AMOUNT_CURRENCY = 'CAD'and paid_channel = 'AG')

;
