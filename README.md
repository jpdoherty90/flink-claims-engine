This is a rudimentary prototype of an auto insurnace claim processing engine that utilizes Confluent's fully-managed Apache Kafka and Apache Flink services.

Portions of the boilerplate infrastructure code for this prototype, especially around deploying and populating the Oracle database, were adapted from Confluent's demo-database-modernization repo: https://github.com/confluentinc/demo-database-modernization.

The high level steps of running the prototype are:
1. Use Terraform to build all the resources.  This will require AWS and Confluent Cloud credentials.
1. Create and populate the Customers table in Oracle by running prepare_database.py
1. Set up a fully-managed Oracle CDC Connector in Confluent Cloud, using the json in connectors-config.
1. Build the main flow in Flink using the SQL found in flink-sql-statements/flink.sql.  These could be Terraform if desired, or can be submitted via REST API or CLI.  But the easiest way to run them is to paste them into Confluent's SQL Workspace, which can be found in the Confluent Cloud UI.
1. Start the python producer, which simulates auto insurnace claims flowing into the system.  At this point, you can go to Confluent's Stream Lineage and see the claims flowing through the system.
1. (Optionally) You can run continuous_update.py to make continuous updates to the Customers table, to simulate customer chagnes that are happening continuously as claims are happening.

More detailed instructions will be coming soon.

Please don't hesitate to reach out to me with any feedback.