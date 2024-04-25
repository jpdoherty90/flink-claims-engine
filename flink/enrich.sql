CREATE TABLE customers(
   `account_id` INT,
   `first_name` STRING,
   `last_name` STRING,
   `dob` STRING,
   `state_of_residence` STRING,
   `email` STRING,
   `drivers_license_num` STRING,
   `policy_expiration_date` INT
);

INSERT INTO customers
SELECT ACCOUNT_ID,
        FIRST_NAME,
        LAST_NAME,
        DOB,
        STATE_OF_RESIDENCE,
        EMAIL,
        DRIVERS_LICENSE_NUM,
        CAST(POLICY_EXPIRATION_DATE AS INT)
FROM `ORCL.ADMIN.CUSTOMERS`
GROUP BY ACCOUNT_ID
ORDER BY current_ts 
DESC
LIMIT 1;

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
   `pictures_uploaded` BOOLEAN,
   WATERMARK FOR transaction_timestamp AS transaction_timestamp
);

INSERT INTO claims_enriched
   SELECT A.account_id,
        C.FIRST_NAME,
        C.LAST_NAME,
        C.DOB,
        C.STATE_OF_RESIDENCE,
        C.EMAIL,
        C.DRIVERS_LICENSE_NUM,
        CAST(C.POLICY_EXPIRATION_DATE AS INT),
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
   ON A.account_id = C.ACCOUNT_ID;

