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

ALTER TABLE enriched_claims SET ('changelog.mode' = 'retract');

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