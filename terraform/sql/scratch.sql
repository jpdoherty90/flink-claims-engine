CREATE TABLE customers(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
  PRIMARY KEY(`account_id`) NOT ENFORCED
);

INSERT INTO customers
SELECT CAST(ACCOUNT_ID AS INT),
        FIRST_NAME,
        LAST_NAME,
        DOB,
        STATE_OF_RESIDENCE,
        EMAIL,
        DRIVERS_LICENSE_NUM,
        CAST(POLICY_EXPIRATION_DATE AS INT)
FROM `ORCL.ADMIN.CUSTOMERS`;


CREATE TABLE claims_enriched(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
   `loss_type` STRING,
   `date_of_loss` INT,
   `date_of_fnol` INT,
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
);

ALTER TABLE claims_enriched SET ('changelog.mode' = 'retract'); 

INSERT INTO claims_enriched
   SELECT A.account_id,
        C.first_name,
        C.last_name,
        C.dob,
        C.state_of_residence,
        C.email,
        C.drivers_license_num,
        CAST(C.policy_expiration_date AS INT),
        A.loss_type,
        A.date_of_loss,
        A.date_of_fnol,
        A.state_of_loss,
        A.amount_of_loss,
        A.police_report_uploaded,
        A.pictures_needed,
        A.pictures_uploaded
   FROM `auto_fnol` A
   INNER JOIN `customers` C
   ON A.account_id = C.account_id;

CREATE TABLE potentially_fraudulent_claims(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
   `loss_type` STRING,
   `date_of_loss` INT,
   `date_of_fnol` INT,
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
);

INSERT INTO potentially_fraudulent_claims
SELECT * FROM claims_enriched
WHERE state_of_residence <> state_of_loss;

CREATE TABLE initially_validated_claims(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
   `loss_type` STRING,
   `date_of_loss` INT,
   `date_of_fnol` INT,
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
);


INSERT INTO initially_validated_claims
SELECT * FROM claims_enriched
WHERE state_of_residence = state_of_loss;


CREATE TABLE stp_claims(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
   `loss_type` STRING,
   `date_of_loss` INT,
   `date_of_fnol` INT,
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
);


INSERT INTO stp_claims
SELECT * FROM initially_validated_claims
WHERE (police_report_uploaded = true) and (pictures_needed = false);


CREATE TABLE needs_manual_review(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT,
   `loss_type` STRING,
   `date_of_loss` INT,
   `date_of_fnol` INT,
   `state_of_loss` STRING,
   `amount_of_loss` INT,
   `police_report_uploaded` BOOLEAN,
   `pictures_needed` BOOLEAN,
   `pictures_uploaded` BOOLEAN
);


INSERT INTO needs_manual_review
SELECT * FROM initially_validated_claims
WHERE pictures_needed;
