update CUSTOMERS set policy_expiration_date = TO_DATE('2027-04-20', 'YYYY-MM-DD') where MOD(account_id, 1) = 0;
update CUSTOMERS set policy_expiration_date = TO_DATE('2024-04-20', 'YYYY-MM-DD') where MOD(account_id, 3) = 0;

-- delete from CUSTOMERS;
-- alter table CUSTOMERS modify (policy_expiration_date DATE);