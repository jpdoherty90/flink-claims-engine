
  CREATE TABLE customers(
     `account_id` INT,
     `first_name` STRING,
     `last_name` STRING,
     `dob` STRING,
     `state_of_residence` STRING,
     `email` STRING,
     `drivers_license_num` STRING,
     `policy_expiration_date` DATE,
     `updated_at` TIMESTAMP_LTZ(3),
     WATERMARK FOR `updated_at` AS `updated_at`,
     PRIMARY KEY(`account_id`) NOT ENFORCED
   )
   DISTRIBUTED BY (account_id) INTO 1 BUCKETS
  ;

  CREATE TABLE customers(
     `account_id` INT,
     `first_name` STRING,
     `last_name` STRING,
     `dob` STRING,
     `state_of_residence` STRING,
     `email` STRING,
     `drivers_license_num` STRING,
     `policy_expiration_date` DATE,
     `updated_at` TIMESTAMP_LTZ(3),
     WATERMARK FOR `updated_at` AS `updated_at`,
     PRIMARY KEY(`account_id`) NOT ENFORCED
   )
   DISTRIBUTED BY (account_id) INTO 1 BUCKETS
  ;


  INSERT INTO customers
SELECT CAST(ACCOUNT_ID as INT),
        FIRST_NAME,
        LAST_NAME,
        DOB,
        STATE_OF_RESIDENCE,
        EMAIL,
        DRIVERS_LICENSE_NUM,
        CAST(POLICY_EXPIRATION_DATE as DATE),
        NOW()
FROM `ORCL.ADMIN1.CUSTOMERS`;


CREATE TABLE claims(
   `claim_id` STRING,
   `account_id` INT,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(0),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN,
   WATERMARK FOR `submitted_at` AS `submitted_at`
  )
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;



  INSERT INTO claims
   SELECT claim_id,
        account_id,
        loss_type,
        TO_DATE(date_of_loss),
        TO_TIMESTAMP_LTZ(submitted_at, 0),
        state_of_loss,
        amount_of_loss,
        police_report_uploaded,
        pictures_needed,
        pictures_uploaded
   FROM auto_fnol;






CREATE TABLE enriched_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE enriched_claims SET ('changelog.mode' = 'append');







INSERT INTO enriched_claims
   SELECT claims.claim_id,
        claims.account_id,
        customers.first_name,
        customers.last_name,
        customers.dob,
        customers.state_of_residence,
        customers.email,
        customers.drivers_license_num,
        customers.policy_expiration_date,
        claims.loss_type,
        claims.date_of_loss,
        claims.submitted_at,
        claims.state_of_loss,
        claims.amount_of_loss,
        claims.police_report_uploaded,
        claims.pictures_needed,
        claims.pictures_uploaded
   FROM claims
   JOIN customers 
   FOR SYSTEM_TIME AS OF claims.submitted_at
   ON claims.account_id = customers.account_id;





CREATE TABLE rejected_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE rejected_claims SET ('changelog.mode' = 'append');





-- Rejecting claims where their policy was expired
-- This select can be expanded to include many different rejection criteria
INSERT INTO rejected_claims
   SELECT *
   FROM enriched_claims
   WHERE date_of_loss > policy_expiration_date
   ;



CREATE TABLE potentially_fraudulent_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE potentially_fraudulent_claims SET ('changelog.mode' = 'append');





-- Accidents in states the driver doesn't live in have been flagged for fraud
-- We want to send these to a separate topic for review (either manual or automated)
-- In a real scenario, these fraud validations can be arbitrarily complex 
INSERT INTO potentially_fraudulent_claims
   SELECT *
   FROM enriched_claims
   WHERE date_of_loss < policy_expiration_date  -- NOT the rejected for being out-of-policy claims
  AND state_of_residence <> state_of_loss       
   ;

-- NOTE: Multi-way routing is done with multiple SQL statements, but once Table API is available they can be done with a single chained python or java function





CREATE TABLE validated_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE validated_claims SET ('changelog.mode' = 'append');





-- Claims are considered validated if they don't meet the rejection criteria or the fraud criteria
INSERT INTO validated_claims
   SELECT *
   FROM enriched_claims
   WHERE date_of_loss < policy_expiration_date
  AND state_of_residence = state_of_loss       
   ;




CREATE TABLE stp_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE stp_claims SET ('changelog.mode' = 'append');





-- Straight-Through-Processing (STP) can be done when police report is updated and pictures are not needed
INSERT INTO stp_claims
   SELECT *
   FROM validated_claims
   WHERE (police_report_uploaded = true) and (pictures_needed = false) and (amount_of_loss < 1000)
   ;



CREATE TABLE hitl_claims(
   `claim_id` STRING,
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` DATE,
   `loss_type` STRING,
   `date_of_loss` DATE,
   `submitted_at` TIMESTAMP_LTZ(3),
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
)
  DISTRIBUTED BY (claim_id) INTO 1 BUCKETS
  ;
ALTER TABLE hitl_claims SET ('changelog.mode' = 'append');





-- Human-in-the-loop (HITL) claims need a human to review because of missing info or size of claim
INSERT INTO hitl_claims
   SELECT *
   FROM validated_claims
   WHERE ((pictures_needed IS TRUE) AND (pictures_uploaded IS FALSE))
   OR (police_report_uploaded IS FALSE)
   OR (amount_of_loss > 1000)
   ;




create table if not exists thirty_second_sums(
  `window_start` TIMESTAMP_LTZ(3),
  `window_end` TIMESTAMP_LTZ(3),
  `loss_sums` INT
  );






insert into thirty_second_sums
select 
  window_start,
  window_end,
  sum(amount_of_loss) as sum_of_loss
FROM TABLE(TUMBLE(TABLE validated_claims, DESCRIPTOR($rowtime), INTERVAL '30' SECOND))
  group by window_start, window_end
;




