# Creates a stored procedure that initializes BLMS and database.
 # Creates a table in the database and populates a few rows of data.
 CREATE OR REPLACE PROCEDURE iceberg_demo.iceberg_setup_3_3 ()
 WITH CONNECTION `us.spark_connection`
 OPTIONS(engine="SPARK",
 jar_uris=["gs://spark-lib/biglake/biglake-catalog-iceberg1.2.0-0.1.0-with-dependencies.jar"],
 properties=[
 ("spark.jars.packages","org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.2.0"),
 ("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog"),
 ("spark.sql.catalog.iceberg.catalog-impl", "org.apache.iceberg.gcp.biglake.BigLakeCatalog"),
 ("spark.sql.catalog.iceberg.hms_uri: thrift://localhost:9083"),
 ("spark.sql.catalog.iceberg.gcp_project", "sap-iac-test"),
 ("spark.sql.catalog.iceberg.gcp_location", "us-central1"),
 ("spark.sql.catalog.iceberg.blms_catalog", "iceberg"),
 ("spark.sql.catalog.iceberg.warehouse", "gs://iceberg-demo")
 ]
 )
 LANGUAGE PYTHON AS R"""
 from pyspark.sql import SparkSession

 spark = SparkSession \
   .builder \
   .appName("BigLake Iceberg Example") \
   .enableHiveSupport() \
   .getOrCreate()

 spark.sql("CREATE NAMESPACE IF NOT EXISTS iceberg;")
 spark.sql("CREATE DATABASE IF NOT EXISTS iceberg.iceberg-biglake;")
 spark.sql("DROP TABLE IF EXISTS iceberg.iceberg-biglake.iceberg_table;")

 /* Create a BigLake Metastore table and a BigQuery Iceberg table. */
 spark.sql("CREATE TABLE IF NOT EXISTS iceberg.iceberg-biglake.iceberg_table (id bigint, demo_name string)
           USING iceberg
           TBLPROPERTIES(bq_table='iceberg_demo.iceberg', bq_connection='us.spark_connection');
           ")

 /* Copy a Hive Metastore table to BigLake Metastore. Can be used together with
    TBLPROPERTIES `bq_table` to create a BigQuery Iceberg table. */
 spark.sql("CREATE TABLE iceberg.iceberg-biglake.iceberg_table (id bigint, demo_name string)
            USING iceberg
            TBLPROPERTIES(hms_table='HMS_DB.HMS_TABLE');")
 """;